import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/game_button.dart';
import '../../widgets/glass_panel.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
    required this.sfxEnabled,
    required this.onToggleSfx,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final bool sfxEnabled;
  final ValueChanged<bool> onToggleSfx;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: GlassPanel(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paused', style: AppTextStyles.h1.copyWith(fontSize: 30)),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(value: sfxEnabled, onChanged: onToggleSfx),
                  const Text('SFX', style: TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 20),
              GameButton(label: 'Resume', width: 220, onPressed: onResume),
              const SizedBox(height: 12),
              GameButton(label: 'Restart', width: 220, style: GameButtonStyle.outline, onPressed: onRestart),
              const SizedBox(height: 12),
              GameButton(label: 'Exit to Menu', width: 220, style: GameButtonStyle.outline, onPressed: onExit),
            ],
          ),
        ),
      ),
    );
  }
}
