import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../core/services/profile_service.dart';
import '../infra/gate_store.dart';
import '../infra/link_probe.dart';
import '../infra/masked_agent.dart';
import '../infra/push_relay.dart';
import 'offline_page.dart';

/// Full-screen WebView shell for the gray flow. Applies the safe-area, zoom,
/// tap-polish, keyboard and inline-media injections, and the cold-start
/// viewport fix (immersive settle + post-load resize/reload in the current
/// orientation).
class WebCounter extends StatefulWidget {
  const WebCounter({
    super.key,
    required this.url,
    required this.store,
    required this.probe,
    required this.push,
    required this.agent,
    this.coldLaunch = false,
  });

  final String url;
  final GateStore store;
  final LinkProbe probe;
  final PushRelay push;
  final MaskedAgent agent;
  final bool coldLaunch;

  @override
  State<WebCounter> createState() => _WebCounterState();
}

class _WebCounterState extends State<WebCounter> with WidgetsBindingObserver {
  late final WebViewController _controller;
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;
  bool _viewportReady = false;
  bool _coldReloadIssued = false;
  bool _offlineShown = false;
  int _redirectAttempts = 0;
  String? _lastMainUrl;
  Timer? _metricsDebounce;
  Size? _lastMetricsSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enterImmersive();
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final params = Platform.isIOS
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();
    _controller =
        WebViewController.fromPlatformCreationParams(
            params,
            onPermissionRequest: (request) {
              // Camera / microphone access from the WebView is only granted
              // when the user has already opened the native camera through the
              // white-part chef-profile feature. That first use causes iOS to
              // show the NSCameraUsageDescription prompt legitimately. Until
              // then the request is silently denied so the system permission
              // dialog is never triggered from inside the WebView without a
              // prior white-part justification.
              final needsCameraLike = request.types.any((t) =>
                  t == WebViewPermissionResourceType.camera ||
                  t == WebViewPermissionResourceType.microphone);
              if (needsCameraLike &&
                  !ProfileService.instance.hasCameraPermission) {
                request.deny();
                return;
              }
              request.grant();
            },
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..setUserAgent(widget.agent.userAgent)
          ..enableZoom(false)
          ..setNavigationDelegate(_navigation());
    if (_controller.platform is WebKitWebViewController) {
      (_controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }

    widget.push.onDestination = (url) {
      final uri = Uri.tryParse(url);
      if (mounted && uri != null && uri.hasScheme) {
        _controller.loadRequest(uri);
      }
    };
    _networkSubscription = widget.probe.changes.listen((states) {
      if (states.every((state) => state == ConnectivityResult.none)) {
        // Connectivity is definitively gone — show offline immediately, no DNS
        // probe (a probe hangs for seconds while offline and lets the WebView
        // render its built-in error page first).
        _goOffline();
      }
    });

    if (widget.coldLaunch) {
      _settleColdViewport();
    } else {
      _viewportReady = true;
      _controller.loadRequest(Uri.parse(widget.url));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePending());
  }

  void _enterImmersive() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _settleColdViewport() async {
    _enterImmersive();
    // Let immersive mode settle in the phone's ACTUAL orientation before the
    // WebView mounts, so WKWebView measures the correct viewport. No landscape
    // nudge — any residual stretch is fixed after load by the resize + single
    // reload in onPageFinished, in the current orientation.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    setState(() => _viewportReady = true);
    await _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    setState(() {});
    final view = View.of(context);
    final size = view.physicalSize;
    final rotated = _lastMetricsSize != null &&
        ((_lastMetricsSize!.width < _lastMetricsSize!.height) !=
            (size.width < size.height));
    _lastMetricsSize = size;
    if (!rotated) return;
    _enterImmersive();
    _metricsDebounce?.cancel();
    _pokeReflow(const [40, 160, 320, 560, 850]);
  }

  void _pokeReflow(List<int> delaysMs) {
    for (final ms in delaysMs) {
      Timer(Duration(milliseconds: ms), () {
        if (!mounted) return;
        _controller.runJavaScript(
          'window.dispatchEvent(new Event("orientationchange"));'
          'window.dispatchEvent(new Event("resize"));'
          'if(window.visualViewport)'
          '  window.visualViewport.dispatchEvent(new Event("resize"));',
        ).catchError((_) {});
      });
    }
    _metricsDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      _installInsetGuard();
      _installZoomLock();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enterImmersive();
      _consumePending();
    }
  }

  Future<void> _consumePending() async {
    final value = await widget.store.consumePushUrl();
    final uri = value == null ? null : Uri.tryParse(value);
    if (mounted && uri != null && uri.hasScheme) {
      await _controller.loadRequest(uri);
    }
  }

  NavigationDelegate _navigation() {
    return NavigationDelegate(
      onPageStarted: (url) {
        _lastMainUrl = url;
      },
      onPageFinished: (_) {
        _redirectAttempts = 0;
        _installInsetGuard();
        _installZoomLock();
        _installTapPolish();
        _installKeyboardLift();
        _installFocusScaleGuard();
        _installInlinePlayback();
        Future<void>.delayed(const Duration(milliseconds: 800), () async {
          if (!mounted) return;
          setState(() {});
          await _controller.runJavaScript(
            'window.dispatchEvent(new Event("resize"));'
            'window.visualViewport?.dispatchEvent(new Event("resize"));',
          );
          _installInsetGuard();
          if (widget.coldLaunch && !_coldReloadIssued) {
            _coldReloadIssued = true;
            await _controller.reload();
          }
        });
      },
      onWebResourceError: (error) {
        // -999 = cancelled (a new navigation superseded this one).
        if (error.errorCode == -999) return;
        // WKWebView sometimes reports isForMainFrame as null for the main
        // navigation — treat null as main-frame so a real load failure is
        // never silently swallowed.
        final mainFrame = error.isForMainFrame ?? true;
        final lower = error.description.toLowerCase();
        final redirectLoop =
            error.errorCode == -1007 ||
            lower.contains('too_many_redirects') ||
            lower.contains('too many redirects');
        if (redirectLoop && _lastMainUrl != null && _redirectAttempts < 3) {
          _redirectAttempts++;
          _controller.loadRequest(Uri.parse(_lastMainUrl!));
          return;
        }
        if (!mainFrame) return;
        _showOfflineAfterProbe();
      },
      onNavigationRequest: (request) {
        final uri = Uri.tryParse(request.url);
        if (uri == null) return NavigationDecision.prevent;
        if (<String>{
          'http',
          'https',
          'about',
          'data',
          'blob',
        }.contains(uri.scheme)) {
          if (request.isMainFrame) _lastMainUrl = request.url;
          return NavigationDecision.navigate;
        }
        launchUrl(uri, mode: LaunchMode.externalApplication);
        return NavigationDecision.prevent;
      },
    );
  }

  /// Confirms the outage with a reachability probe (WebView load errors can be
  /// transient) before routing to the offline screen.
  Future<void> _showOfflineAfterProbe() async {
    if (_offlineShown) return;
    bool online = true;
    try {
      online = await widget.probe.canReachNetwork();
    } catch (_) {
      online = false;
    }
    if (online) return;
    _goOffline();
  }

  /// Routes to the offline screen immediately (no probe). Safe from multiple
  /// triggers thanks to the [_offlineShown] guard.
  Future<void> _goOffline() async {
    if (_offlineShown || !mounted) return;
    _offlineShown = true;
    String current;
    try {
      current = await _controller.currentUrl() ?? widget.url;
    } catch (_) {
      current = widget.url;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OfflinePage(
          probe: widget.probe,
          retryBuilder: (_) => WebCounter(
            url: current,
            store: widget.store,
            probe: widget.probe,
            push: widget.push,
            agent: widget.agent,
          ),
        ),
      ),
    );
  }

  void _installInsetGuard() {
    _controller.runJavaScript(r'''
(() => {
  const scope = window;
  if (scope.__hdInsetGuard) return;
  scope.__hdInsetGuard = true;
  const tag = 'hd-inset-layer';
  const css = [
    ':root{',
    '--safe-area-inset-top:0px!important;',
    '--safe-area-inset-right:0px!important;',
    '--safe-area-inset-bottom:0px!important;',
    '--safe-area-inset-left:0px!important;',
    '--sat:0px!important;--sar:0px!important;',
    '--sab:0px!important;--sal:0px!important;',
    '--safe-top:0px!important;--safe-right:0px!important;',
    '--safe-bottom:0px!important;--safe-left:0px!important;',
    '}',
    'html,body{overscroll-behavior:none!important;',
    'overscroll-behavior-y:none!important;}'
  ].join('');
  const keyboardOpen = () => {
    const vv = scope.visualViewport;
    return !!vv && vv.height < scope.innerHeight * 0.75;
  };
  const apply = () => {
    if (keyboardOpen()) return;
    const host = document.head || document.documentElement;
    if (!host) return;
    let meta = document.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.name = 'viewport';
      meta.content = 'width=device-width, initial-scale=1, viewport-fit=contain';
      host.appendChild(meta);
    } else {
      const base = (meta.content || '')
        .replace(/,?\s*viewport-fit\s*=\s*\w+/ig, '').trim();
      meta.content = `${base}${base ? ', ' : ''}viewport-fit=contain`;
    }
    let layer = document.getElementById(tag);
    if (!layer) {
      layer = document.createElement('style');
      layer.id = tag;
      host.appendChild(layer);
    }
    layer.textContent = css;
  };
  const later = () => {
    scope.setTimeout(apply, 170);
    scope.setTimeout(apply, 640);
  };
  ['pushState', 'replaceState'].forEach((name) => {
    const original = history[name];
    history[name] = function(...args) {
      const out = original.apply(this, args);
      later();
      return out;
    };
  });
  scope.addEventListener('popstate', later);
  apply();
  scope.setInterval(apply, 2900);
})();
''');
  }

  void _installZoomLock() {
    _controller.runJavaScript(r'''
(() => {
  if (window.__hdZoomLock) return;
  window.__hdZoomLock = true;
  const pin = () => {
    const host = document.head || document.documentElement;
    if (!host) return;
    let meta = document.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.setAttribute('name', 'viewport');
      host.appendChild(meta);
    }
    meta.setAttribute('content',
      'width=device-width, initial-scale=1.0, maximum-scale=1.0, ' +
      'minimum-scale=1.0, user-scalable=no, viewport-fit=contain');
  };
  pin();
  const block = (e) => { e.preventDefault(); };
  ['gesturestart', 'gesturechange', 'gestureend'].forEach((t) =>
    document.addEventListener(t, block, {passive: false}));
  document.addEventListener('touchmove', (e) => {
    if (e.scale !== undefined && e.scale !== 1) e.preventDefault();
  }, {passive: false});
  let lastTouch = 0;
  document.addEventListener('touchend', (e) => {
    const now = Date.now();
    if (now - lastTouch <= 300) e.preventDefault();
    lastTouch = now;
  }, {passive: false});
  ['pushState', 'replaceState'].forEach((name) => {
    const original = history[name];
    history[name] = function(...args) {
      const out = original.apply(this, args);
      setTimeout(pin, 150);
      return out;
    };
  });
  window.addEventListener('popstate', () => setTimeout(pin, 150));
})();
''');
  }

  void _installTapPolish() {
    _controller.runJavaScript(r'''
(() => {
  if (window.__hdTapPolish) return;
  window.__hdTapPolish = true;
  const layer = document.createElement('style');
  layer.id = 'hd-tap-polish';
  layer.textContent =
    '*{-webkit-tap-highlight-color:transparent!important;}' +
    '*:not(input):not(textarea):not([contenteditable="true"]){' +
      '-webkit-touch-callout:none!important;}';
  (document.head || document.documentElement).appendChild(layer);
})();
''');
  }

  void _installKeyboardLift() {
    _controller.runJavaScript(r'''
(() => {
  if (window.__hdInputLift) return;
  window.__hdInputLift = true;
  const isEditable = (node) => !!node && (
    node.matches?.('input, textarea, select, [contenteditable="true"]')
  );
  const reveal = () => {
    const active = document.activeElement;
    if (!isEditable(active)) return;
    active.scrollIntoView({behavior: 'auto', block: 'nearest'});
  };
  document.addEventListener('focusin', (event) => {
    if (isEditable(event.target)) window.setTimeout(reveal, 350);
  }, true);
})();
''');
  }

  void _installFocusScaleGuard() {
    if (!Platform.isIOS) return;
    _controller.runJavaScript(r'''
(() => {
  if (window.__hdFocusScale) return;
  window.__hdFocusScale = true;
  const layer = document.createElement('style');
  layer.textContent =
    'input,textarea,select,[contenteditable="true"]{' +
    'font-size:max(16px,1em)!important;}';
  (document.head || document.documentElement).appendChild(layer);
})();
''');
  }

  void _installInlinePlayback() {
    _controller.runJavaScript(r'''
(() => {
  if (window.__hdInlineMedia) return;
  window.__hdInlineMedia = true;
  const wake = (video) => {
    if (!(video instanceof HTMLVideoElement)) return;
    video.setAttribute('playsinline', '');
    video.setAttribute('webkit-playsinline', '');
    video.playsInline = true;
    video.autoplay = true;
    const attempt = video.play();
    if (attempt?.catch) attempt.catch(() => {});
  };
  const sweep = (node) => {
    if (node instanceof HTMLVideoElement) wake(node);
    node.querySelectorAll?.('video').forEach(wake);
  };
  sweep(document);
  new MutationObserver((records) => {
    records.forEach((record) => record.addedNodes.forEach(sweep));
  }).observe(document.documentElement, {childList: true, subtree: true});
})();
''');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _metricsDebounce?.cancel();
    _networkSubscription?.cancel();
    widget.push.onDestination = null;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).viewPadding;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _controller.canGoBack()) {
          await _controller.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: _viewportReady
            ? Padding(
                padding: EdgeInsets.only(
                  top: safe.top,
                  bottom: safe.bottom,
                  left: safe.left,
                  right: safe.right,
                ),
                child: WebViewWidget(controller: _controller),
              )
            : const ColoredBox(color: Colors.black),
      ),
    );
  }
}
