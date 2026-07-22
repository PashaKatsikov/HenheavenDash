import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_panel.dart';

/// Generic in-app WebView used for Privacy Policy / Support so players never
/// have to leave the app. Handles back navigation (Android back button pops
/// the web history first, then the screen), shows a themed loading
/// indicator, and never crashes the app on network/page errors - it simply
/// shows a friendly retry state instead.
class PolicyWebViewScreen extends StatefulWidget {
  const PolicyWebViewScreen({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<PolicyWebViewScreen> createState() => _PolicyWebViewScreenState();
}

class _PolicyWebViewScreenState extends State<PolicyWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _loading = true;
            _error = false;
          }),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (_) => setState(() {
            _loading = false;
            _error = true;
          }),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  Future<void> _close() async {
    final shouldPop = await _handleBack();
    if (shouldPop && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBack();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            if (_error)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        "Couldn't load this page. Check your connection and try again.",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyRegular,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _controller.reload(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              WebViewWidget(controller: _controller),
            if (_loading && !_error)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            // Drawn as its own Stack layer *above* the WebView (rather than
            // a Scaffold `appBar`) and styled like every other screen's
            // top-left circular back button - webview_flutter's native
            // platform view can otherwise end up capturing taps meant for a
            // Material AppBar action on some devices/composition modes,
            // which is exactly what left players unable to back out of this
            // screen without restarting the app. Being a plain Flutter
            // GestureDetector painted on top guarantees it's always the
            // widget that receives the tap.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _close,
                      child: const GlassPanel(
                        padding: EdgeInsets.all(10),
                        borderRadius: 30,
                        child: Icon(Icons.arrow_back, color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GlassPanel(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        borderRadius: 20,
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h3.copyWith(color: AppColors.textOnDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
