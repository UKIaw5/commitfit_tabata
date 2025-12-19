import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TimerConfig {
  final int workSeconds;
  final int restSeconds;
  final int rounds;

  const TimerConfig({
    required this.workSeconds,
    required this.restSeconds,
    required this.rounds,
  });

  TimerConfig copyWith({
    int? workSeconds,
    int? restSeconds,
    int? rounds,
  }) {
    return TimerConfig(
      workSeconds: workSeconds ?? this.workSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      rounds: rounds ?? this.rounds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workSeconds': workSeconds,
      'restSeconds': restSeconds,
      'rounds': rounds,
    };
  }

  factory TimerConfig.fromJson(Map<String, dynamic> json) {
    return TimerConfig(
      workSeconds: json['workSeconds'] as int? ?? 20,
      restSeconds: json['restSeconds'] as int? ?? 10,
      rounds: json['rounds'] as int? ?? 8,
    );
  }
}

/// 1日分のワークアウト記録
class WorkoutDay {
  final String date; // 'YYYY-MM-DD'
  final int sessions;

  const WorkoutDay({
    required this.date,
    required this.sessions,
  });

  WorkoutDay copyWith({
    String? date,
    int? sessions,
  }) {
    return WorkoutDay(
      date: date ?? this.date,
      sessions: sessions ?? this.sessions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'sessions': sessions,
    };
  }

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      date: json['date'] as String,
      sessions: json['sessions'] as int? ?? 0,
    );
  }
}

class AppSettings {
  // Timer 設定用キー
  static const _keyWorkSeconds = 'timer_work_seconds';
  static const _keyRestSeconds = 'timer_rest_seconds';
  static const _keyRounds = 'timer_rounds';

  // ワークアウト履歴用キー
  static const _keyWorkoutDays = 'workout_days';

  static const TimerConfig _defaultTimerConfig = TimerConfig(
    workSeconds: 20,
    restSeconds: 10,
    rounds: 8,
  );

  /// タイマー設定を読み込み（なければデフォルト）
  static Future<TimerConfig> loadTimerConfig() async {
    final prefs = await SharedPreferences.getInstance();

    final work = prefs.getInt(_keyWorkSeconds);
    final rest = prefs.getInt(_keyRestSeconds);
    final rounds = prefs.getInt(_keyRounds);

    if (work == null || rest == null || rounds == null) {
      return _defaultTimerConfig;
    }

    return TimerConfig(
      workSeconds: work,
      restSeconds: rest,
      rounds: rounds,
    );
  }

  /// タイマー設定を保存
  static Future<void> saveTimerConfig(TimerConfig config) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_keyWorkSeconds, config.workSeconds);
    await prefs.setInt(_keyRestSeconds, config.restSeconds);
    await prefs.setInt(_keyRounds, config.rounds);
  }

  /// すべてのワークアウト履歴を取得
  static Future<List<WorkoutDay>> loadWorkoutDays() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyWorkoutDays);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((e) => WorkoutDay.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// ワークアウト履歴を保存
  static Future<void> saveWorkoutDays(List<WorkoutDay> days) async {
    final prefs = await SharedPreferences.getInstance();
    // 必要に応じて古いデータを削る（例: 最新365日だけ残す）なども後で追加できる
    final jsonString =
        jsonEncode(days.map((d) => d.toJson()).toList());
    await prefs.setString(_keyWorkoutDays, jsonString);
  }

  /// 今日の日付キー 'YYYY-MM-DD' (Local time)
  static String _todayKey() {
    final now = DateTime.now().toLocal();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// 今日のセッション数を +1 して、更新後の数を返す
  static Future<int> addSessionForToday() async {
    final today = _todayKey();
    final days = await loadWorkoutDays();

    int index =
        days.indexWhere((element) => element.date == today);

    if (index == -1) {
      // 新規
      days.add(WorkoutDay(date: today, sessions: 1));
      await saveWorkoutDays(days);
      return 1;
    } else {
      final updated = days[index]
          .copyWith(sessions: days[index].sessions + 1);
      days[index] = updated;
      await saveWorkoutDays(days);
      return updated.sessions;
    }
  }

  /// 今日のセッション数を取得（なければ0）
  static Future<int> getTodaySessions() async {
    final today = _todayKey();
    final days = await loadWorkoutDays();
    final day =
        days.where((element) => element.date == today).toList();
    if (day.isEmpty) return 0;
    return day.first.sessions;
  }

  // Graph 設定用キー
  static const _keyGraphWeeks = 'graph_weeks_to_show';
  static const _keyGraphMaxSessions = 'graph_max_sessions';

  static const GraphConfig _defaultGraphConfig = GraphConfig(
    weeksToShow: 12,
    maxSessionsPerDay: 5,
  );

  /// グラフ設定を読み込み
  static Future<GraphConfig> loadGraphConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final weeks = prefs.getInt(_keyGraphWeeks);
    final maxSessions = prefs.getInt(_keyGraphMaxSessions);

    if (weeks == null || maxSessions == null) {
      return _defaultGraphConfig;
    }

    return GraphConfig(
      weeksToShow: weeks,
      maxSessionsPerDay: maxSessions,
    );
  }

  /// グラフ設定を保存
  static Future<void> saveGraphConfig(GraphConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGraphWeeks, config.weeksToShow);
    await prefs.setInt(_keyGraphMaxSessions, config.maxSessionsPerDay);
  }
  // Theme 設定用キー
  static const _keyThemeColor = 'theme_color_value';

  /// テーマカラーを読み込み（デフォルトは緑）
  static Future<int> loadThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyThemeColor) ?? 0xFF2EA043;
  }

  /// テーマカラーを保存
  static Future<void> saveThemeColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeColor, colorValue);
  }

  /// デモ用にフェイク履歴をシードする (Debug only)
  static Future<void> seedDemoData() async {
    // Release build guard
    if (!isDebugBuild) return;

    final now = DateTime.now().toLocal();
    final days = <WorkoutDay>[];
    final random = DateTime.now().millisecondsSinceEpoch; 
    
    // 過去180日分 (Dense data for screenshots)
    for (int i = 0; i < 180; i++) {
      final date = now.subtract(Duration(days: 179 - i));
      final y = date.year.toString().padLeft(4, '0');
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      final dateKey = '$y-$m-$d';

      // Dense pattern: High probability of activity
      int sessions = 0;
      final val = (random + i * 1327) % 100;
      
      if (val < 10) {
        // 10% chance of 0 (gap)
        sessions = 0;
      } else if (val < 20) {
        // 10% chance of 1
        sessions = 1;
      } else if (val < 40) {
        // 20% chance of 2
        sessions = 2;
      } else if (val < 60) {
        // 20% chance of 3
        sessions = 3;
      } else if (val < 80) {
        // 20% chance of 4
        sessions = 4;
      } else {
        // 20% chance of 5
        sessions = 5;
      }
      
      if (sessions > 0) {
        days.add(WorkoutDay(date: dateKey, sessions: sessions));
      }
    }
    
    await saveWorkoutDays(days);
  }

  /// すべてのデータをリセット (Debug only)
  static Future<void> resetAllData() async {
    if (!isDebugBuild) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Debug build check using assert
  static bool get isDebugBuild {
    bool debug = false;
    assert(debug = true);
    return debug;
  }
}

class GraphConfig {
  final int weeksToShow;
  final int maxSessionsPerDay;

  const GraphConfig({
    required this.weeksToShow,
    required this.maxSessionsPerDay,
  });

  GraphConfig copyWith({
    int? weeksToShow,
    int? maxSessionsPerDay,
  }) {
    return GraphConfig(
      weeksToShow: weeksToShow ?? this.weeksToShow,
      maxSessionsPerDay: maxSessionsPerDay ?? this.maxSessionsPerDay,
    );
  }
}

