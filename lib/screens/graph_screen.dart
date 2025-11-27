import 'package:flutter/material.dart';

import '../config/app_settings.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  bool _loading = true;
  List<WorkoutDay> _days = [];
  late Map<String, int> _sessionsByDate; // 'YYYY-MM-DD' -> sessions
  late DateTime _startDate;
  late DateTime _endDate;

  // 表示する週数（列数）…あとで好きに変えてOK
  final int _weeksToShow = 8; // 8週間 = 56日分

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final days = await AppSettings.loadWorkoutDays();
    final map = <String, int>{};
    for (final d in days) {
      map[d.date] = d.sessions;
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final totalDays = _weeksToShow * 7;

    // 範囲の最後は「今日」
    _endDate = normalizedToday;
    _startDate = _endDate.subtract(Duration(days: totalDays - 1));

    setState(() {
      _days = days;
      _sessionsByDate = map;
      _loading = false;
    });
  }

  String _formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatShortDate(DateTime date) {
    // 2025-11-22 → 11/22 みたいな感じ
    return '${date.month}/${date.day}';
  }

  Color _colorForSessions(BuildContext context, int sessions) {
    if (sessions <= 0) {
      return Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.grey.shade300;
    } else if (sessions == 1 || sessions == 2) {
      return Colors.green.shade200;
    } else if (sessions == 3 || sessions == 4) {
      return Colors.green.shade400;
    } else {
      return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      final loadingScaffold = Scaffold(
        appBar: AppBar(
          title: const Text('Contribution Graph'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx > 12 &&
              details.globalPosition.dx < 80 &&
              Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        child: loadingScaffold,
      );
    }

    final totalDays = _weeksToShow * 7;

    // 古い日付 → 新しい日付のリスト
    final dates = List<DateTime>.generate(totalDays, (index) {
      return _startDate.add(Duration(days: index));
    });

    // 週ごとのリストに分割（1週 = 7日）
    final List<List<DateTime>> weeks = [];
    for (int w = 0; w < _weeksToShow; w++) {
      final startIndex = w * 7;
      final endIndex = startIndex + 7;
      if (startIndex >= dates.length) break;
      weeks.add(dates.sublist(
        startIndex,
        endIndex > dates.length ? dates.length : endIndex,
      ));
    }

    // 月ラベル用
    final List<String> monthLabels = [];
    int? lastMonth;
    for (final week in weeks) {
      if (week.isEmpty) {
        monthLabels.add('');
        continue;
      }
      final firstDay = week.first;
      final currentMonth = firstDay.month;
      if (lastMonth != currentMonth) {
        // 月が変わったタイミングだけラベル表示
        final monthName = _monthShortName(currentMonth);
        monthLabels.add(monthName);
        lastMonth = currentMonth;
      } else {
        monthLabels.add('');
      }
    }

    final todayKey = _formatDateKey(_endDate);
    final todaySessions = _sessionsByDate[todayKey] ?? 0;

    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('Contribution Graph'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last $_weeksToShow weeks',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          SizedBox(height: 10),
                          Text('Mon', style: TextStyle(fontSize: 10)),
                          SizedBox(height: 18),
                          Text('Wed', style: TextStyle(fontSize: 10)),
                          SizedBox(height: 18),
                          Text('Fri', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  List.generate(weeks.length, (weekIndex) {
                                final label = monthLabels[weekIndex];
                                return Container(
                                  width: 18,
                                  alignment: Alignment.centerLeft,
                                  margin: const EdgeInsets.only(right: 2),
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  List.generate(weeks.length, (weekIndex) {
                                final week = weeks[weekIndex];
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: week.map((date) {
                                    final key = _formatDateKey(date);
                                    final sessions =
                                        _sessionsByDate[key] ?? 0;
                                    final color = _colorForSessions(
                                        context, sessions);

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 1,
                                        horizontal: 1,
                                      ),
                                      child: Tooltip(
                                        message:
                                            '${_formatShortDate(date)} : $sessions session(s)',
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Less', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  _legendBox(context, 0),
                  _legendBox(context, 1),
                  _legendBox(context, 3),
                  _legendBox(context, 5),
                  const SizedBox(width: 4),
                  const Text('More', style: TextStyle(fontSize: 10)),
                  const Spacer(),
                  Text(
                    todaySessions == 0
                        ? 'Today: 0'
                        : 'Today: $todaySessions',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 12 &&
            details.globalPosition.dx < 80 &&
            Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: scaffold,
    );
  }

  Widget _legendBox(BuildContext context, int sessions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: _colorForSessions(context, sessions),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  String _monthShortName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }
}
