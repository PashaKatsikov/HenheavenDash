import 'package:flutter/widgets.dart';
import 'game_state.dart';

/// Lightweight dependency injection for [GameState] - avoids pulling in a
/// full state-management package for what is fundamentally a handful of
/// persisted counters shared across a few screens.
class GameStateScope extends InheritedNotifier<GameState> {
  const GameStateScope({super.key, required GameState state, required super.child})
      : super(notifier: state);

  static GameState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GameStateScope>();
    assert(scope != null, 'No GameStateScope found in context');
    return scope!.notifier!;
  }
}
