import 'package:flutter/material.dart';
import 'core/game_state.dart';
import 'core/game_state_scope.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

class HenhavenDashApp extends StatefulWidget {
  const HenhavenDashApp({super.key});

  @override
  State<HenhavenDashApp> createState() => _HenhavenDashAppState();
}

class _HenhavenDashAppState extends State<HenhavenDashApp> {
  final GameState _gameState = GameState();

  @override
  Widget build(BuildContext context) {
    return GameStateScope(
      state: _gameState,
      child: MaterialApp(
        title: 'Henhaven Dash',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: SplashScreen(gameState: _gameState),
      ),
    );
  }
}
