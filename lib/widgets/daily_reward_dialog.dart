import 'package:flutter/material.dart';
import '../core/audio/audio_manager.dart';
import '../core/game_state.dart';
import '../core/models/daily_reward.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'game_button.dart';
import 'glass_panel.dart';

/// Full-screen "daily drop" popup: a 7-day login streak calendar. Shown once
/// automatically the first time the player opens the main menu each day (if
/// unclaimed), and re-openable any time from its menu tile.
class DailyRewardDialog extends StatefulWidget {
  const DailyRewardDialog({super.key, required this.state});

  final GameState state;

  static Future<void> showIfAvailable(BuildContext context, GameState state) async {
    if (!state.canClaimDailyReward) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => DailyRewardDialog(state: state),
    );
  }

  static Future<void> show(BuildContext context, GameState state) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => DailyRewardDialog(state: state),
    );
  }

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog> {
  bool _claimed = false;
  DailyRewardDef? _claimedReward;

  Future<void> _claim() async {
    final reward = await widget.state.claimDailyReward();
    AudioManager.instance.playUpgrade();
    setState(() {
      _claimed = true;
      _claimedReward = reward;
    });
  }

  @override
  Widget build(BuildContext context) {
    final streakDay = widget.state.dailyRewardStreakDay;
    final alreadyClaimed = !widget.state.canClaimDailyReward || _claimed;
    final rewardToday = _claimedReward ?? widget.state.todaysDailyReward;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: GlassPanel(
          borderRadius: 26,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎁 Daily Drop!', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(
                alreadyClaimed
                    ? 'Come back tomorrow for the next reward.'
                    : 'Day $streakDay of the streak - come back every day for bigger rewards!',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 92,
                child: Row(
                  children: List.generate(DailyRewardCatalog.cycleLength, (i) {
                    final day = i + 1;
                    final def = DailyRewardCatalog.forDay(day);
                    final isPast = day < streakDay || (day == streakDay && alreadyClaimed);
                    final isToday = day == streakDay && !alreadyClaimed;
                    return Expanded(child: _DayChip(def: def, isPast: isPast, isToday: isToday));
                  }),
                ),
              ),
              const SizedBox(height: 18),
              if (!alreadyClaimed)
                GameButton(
                  label: 'CLAIM +${rewardToday.coins}${rewardToday.tips > 0 ? ' & +${rewardToday.tips} tips' : ''}',
                  icon: Icons.card_giftcard_rounded,
                  style: GameButtonStyle.success,
                  width: double.infinity,
                  onPressed: _claim,
                )
              else
                GameButton(
                  label: 'NICE!',
                  style: GameButtonStyle.primary,
                  width: double.infinity,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              if (!alreadyClaimed) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text('Maybe later', style: AppTextStyles.caption.copyWith(color: Colors.white54)),
                ),
              ] else
                const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.def, required this.isPast, required this.isToday});

  final DailyRewardDef def;
  final bool isPast;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final borderColor = isToday ? AppColors.accent : (isPast ? AppColors.success.withValues(alpha: 0.6) : Colors.white24);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isToday ? AppColors.accent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isToday ? 2 : 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('D${def.day}', style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 2),
            Opacity(
              opacity: isPast ? 0.45 : 1,
              child: Image.asset(def.iconPath, width: 30, height: 30),
            ),
            const SizedBox(height: 2),
            if (isPast)
              const Icon(Icons.check_circle, size: 14, color: AppColors.success)
            else
              Text('${def.coins}', style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
