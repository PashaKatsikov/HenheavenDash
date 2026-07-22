import 'package:flutter/material.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/game_state_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_progress_bar.dart';
import '../../widgets/glass_panel.dart';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  @override
  Widget build(BuildContext context) {
    final state = GameStateScope.of(context);
    final tasks = state.dailyTasks;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/backgrounds/kitchen_festival.webp', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.42)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const GlassPanel(
                          padding: EdgeInsets.all(10),
                          borderRadius: 30,
                          child: Icon(Icons.arrow_back, color: AppColors.accent),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text('Daily Tasks', style: AppTextStyles.h2),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: GlassPanel(
                          child: Row(
                            children: [
                              Image.asset('assets/images/rewards/rw_medal_gold.png', width: 48, height: 48),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.def.description,
                                      style: AppTextStyles.h3.copyWith(color: AppColors.textOnDark),
                                    ),
                                    const SizedBox(height: 8),
                                    GameProgressBar(
                                      value: task.progress / task.def.target,
                                      height: 10,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${task.progress}/${task.def.target}  ·  Reward: ${task.def.coinReward} coins',
                                      style: AppTextStyles.caption.copyWith(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              GameButton(
                                label: task.claimed ? 'DONE' : 'CLAIM',
                                width: 100,
                                height: 44,
                                fontSize: 14,
                                style: GameButtonStyle.success,
                                onPressed: (task.isComplete && !task.claimed)
                                    ? () async {
                                        final reward = await state.claimDailyTask(task.def.id);
                                        if (reward != null) {
                                          AudioManager.instance.playUnlock();
                                          setState(() {});
                                        }
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
