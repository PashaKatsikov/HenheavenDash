import 'dart:math';
import '../models/daily_task.dart';
import '../persistence/save_service.dart';

class ActiveDailyTask {
  ActiveDailyTask({required this.def, required this.progress, required this.claimed});
  final DailyTaskDef def;
  int progress;
  bool claimed;

  bool get isComplete => progress >= def.target;
}

/// Picks 3 deterministic daily tasks per calendar day (seeded by the date so
/// every player sees a stable set for the day) and tracks/persists progress.
class DailyTasksService {
  DailyTasksService._();
  static final DailyTasksService instance = DailyTasksService._();

  List<ActiveDailyTask> tasks = [];

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> init() async {
    final save = SaveService.instance;
    final today = _todayKey;
    if (save.dailyTasksDate != today) {
      await save.setDailyTasksDate(today);
      await save.resetDailyTasks();
    }
    final seed = today.hashCode & 0x7fffffff;
    final rnd = Random(seed);
    final pool = List<DailyTaskDef>.from(DailyTaskCatalog.pool)..shuffle(rnd);
    final chosen = pool.take(3).toList();
    final progressMap = save.dailyTasksProgress;

    tasks = chosen
        .map((def) => ActiveDailyTask(
              def: def,
              progress: progressMap[def.id] ?? 0,
              claimed: (progressMap['${def.id}_claimed'] ?? 0) == 1,
            ))
        .toList();
  }

  Future<void> reportProgress(DailyTaskMetric metric, int amount) async {
    var changed = false;
    for (final task in tasks) {
      if (task.def.metric == metric && !task.isComplete) {
        task.progress = (task.progress + amount).clamp(0, task.def.target);
        changed = true;
      }
    }
    if (changed) await _persist();
  }

  /// For metrics that track a "best" value (like a combo streak) rather
  /// than an accumulating total.
  Future<void> reportMaxProgress(DailyTaskMetric metric, int value) async {
    var changed = false;
    for (final task in tasks) {
      if (task.def.metric == metric && !task.isComplete && value > task.progress) {
        task.progress = value.clamp(0, task.def.target);
        changed = true;
      }
    }
    if (changed) await _persist();
  }

  Future<void> reportLevelCleanFinish(bool noMistakes) async {
    if (!noMistakes) return;
    await reportProgress(DailyTaskMetric.levelNoMistakes, 1);
  }

  Future<int?> claim(String taskId) async {
    final task = tasks.firstWhere((t) => t.def.id == taskId);
    if (!task.isComplete || task.claimed) return null;
    task.claimed = true;
    await _persist();
    return task.def.coinReward;
  }

  Future<void> _persist() async {
    final map = <String, int>{};
    for (final t in tasks) {
      map[t.def.id] = t.progress;
      map['${t.def.id}_claimed'] = t.claimed ? 1 : 0;
    }
    await SaveService.instance.setDailyTasksProgress(map);
  }
}
