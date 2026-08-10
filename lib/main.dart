import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/profile_service.dart';
import 'gate/config/dash_gate_config.dart';
import 'gate/gate_pilot.dart';
import 'gate/infra/gate_dispatch.dart';
import 'gate/infra/gate_store.dart';
import 'gate/infra/link_probe.dart';
import 'gate/infra/masked_agent.dart';
import 'gate/infra/push_relay.dart';
import 'gate/infra/trail_signal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = GateStore();
  final agent = MaskedAgent();
  await Future.wait<void>(<Future<void>>[
    store.initialize(),
    agent.warmUp(),
    ProfileService.instance.init(),
  ]);

  // Firebase (push + App Check) only comes up when the gray credentials are
  // present. Attribution + config still run without it; only FCM needs it.
  var productionServicesReady = false;
  if (DashGateConfig.grayCredentialsReady) {
    try {
      await Firebase.initializeApp();
      productionServicesReady = true;
    } catch (_) {}
    if (productionServicesReady) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
      } catch (_) {
        // App Check must never block FCM / gray routing.
      }
    }
  }

  final probe = LinkProbe();
  final push = PushRelay(store, enabled: productionServicesReady);
  final trail = TrailSignal(agent);
  final pilot = GatePilot(
    store: store,
    probe: probe,
    trail: trail,
    dispatch: GateDispatch(agent, store),
    push: push,
    agent: agent,
    runtimeEnabled: DashGateConfig.grayCredentialsReady,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF2EBD3),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(HenhavenDashApp(pilot: pilot));
}
