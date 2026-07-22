import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/currency_chip.dart';
import '../../widgets/game_progress_bar.dart';
import '../../widgets/glass_panel.dart';
import '../level_session.dart';

class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.session, required this.onPause});

  final LevelSession session;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final minutes = (session.timeRemaining.clamp(0, double.infinity) / 60).floor();
    final seconds = (session.timeRemaining.clamp(0, double.infinity) % 60).floor();
    final timeLabel = '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CurrencyChip(iconPath: 'assets/images/rewards/rw_coin_sack_tan.png', value: session.coinsEarned, compact: true),
        const SizedBox(width: 8),
        CurrencyChip(iconPath: 'assets/images/rewards/rw_coin_sack_brown.png', value: session.tipsEarned, compact: true),
        const SizedBox(width: 8),
        if (session.combo > 0)
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderRadius: 30,
            borderColor: AppColors.accent,
            child: Text('🔥 x${session.combo}', style: AppTextStyles.hudNumber.copyWith(fontSize: 16)),
          ),
        const Spacer(),
        Expanded(
          flex: 3,
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            borderRadius: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Orders', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                    const Spacer(),
                    Text(
                      '${session.ordersServed}/${session.config.targetOrders}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textOnDark),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                GameProgressBar(value: session.levelProgress, height: 8),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          borderRadius: 20,
          borderColor: session.timeRemaining < 15 ? AppColors.cta : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                session.timeRemaining < 15
                    ? 'assets/images/kitchen/kit_timer_red.png'
                    : 'assets/images/kitchen/kit_timer_blue.png',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 6),
              Text(timeLabel, style: AppTextStyles.hudNumber.copyWith(fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onPause,
          child: const GlassPanel(
            padding: EdgeInsets.all(10),
            borderRadius: 30,
            child: Icon(Icons.pause, color: AppColors.accent),
          ),
        ),
      ],
    );
  }
}
