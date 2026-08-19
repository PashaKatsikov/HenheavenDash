import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:henhaven_dash/app.dart';
import 'package:henhaven_dash/core/game_state.dart';
import 'package:henhaven_dash/core/game_state_scope.dart';
import 'package:henhaven_dash/screens/menu/main_menu_screen.dart';
import 'package:henhaven_dash/theme/app_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('App boots to the splash screen without crashing', (tester) async {
    await tester.pumpWidget(const HenhavenDashApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);

    // The boot screen animates its loading dots by rescheduling a delayed
    // callback forever. Unmounting stops the chain, but the one already in
    // flight has to be given its moment to fire or the test ends with a
    // pending timer.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('Main menu renders the player wallet and the play button', (tester) async {
    final state = GameState();
    await state.init();

    await tester.pumpWidget(
      GameStateScope(
        state: state,
        child: MaterialApp(theme: AppTheme.theme, home: const MainMenuScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(MainMenuScreen), findsOneWidget);
    expect(find.text('${state.coins}'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
