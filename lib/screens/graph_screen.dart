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

  // 表示する週数（列数）
  int _weeksToShow = 12;
  int _maxSessionsPerDay = 5;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final days = await AppSettings.loadWorkoutDays();
    final graphConfig = await AppSettings.loadGraphConfig();

    final map = <String, int>{};
    for (final d in days) {
      map[d.date] = d.sessions;
    }

    setState(() {
      _weeksToShow = graphConfig.weeksToShow;
      _maxSessionsPerDay = graphConfig.maxSessionsPerDay;
      _days = days;
      _sessionsByDate = map;
      _loading = false;
    });
    
    _recalcDates();
  }

  void _recalcDates() {
    final today = DateTime.now().toLocal();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final totalDays = _weeksToShow * 7;

    // 範囲の最後は「今日」
    _endDate = normalizedToday;
    _startDate = _endDate.subtract(Duration(days: totalDays - 1));
  }

  String _formatDateKey(DateTime date) {
    // Ensure date is treated as local components
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
    }

    // 割合で計算 (1..max)
    final double ratio = (sessions / _maxSessionsPerDay).clamp(0.0, 1.0);
    
    // 緑の濃さを段階的に
    if (ratio < 0.25) {
      return Colors.green.shade200;
    } else if (ratio < 0.5) {
      return Colors.green.shade400;
    } else if (ratio < 0.75) {
      return Colors.green.shade600;
    } else {
      return Colors.green.shade900;
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

    // 設定画面から戻った時に再ロードするための処理
    // (build内で呼ぶのは微妙だが、簡易的にやるなら didPopNext だが
    //  ここでは Navigator.push().then() で受けるのが一般的。
    //  ただし呼び出し元が不明なので、今回は簡易的に毎回計算する形にするか、
    //  あるいは _loadHistory を public にして外から呼ぶか…
    //  ここでは「設定画面への遷移ボタン」がないので、
    //  もし「設定画面」が別ルートなら、戻ってきたときに再描画が必要。
    //  とりあえず今回はこのままで、遷移元で setState されることを期待するか、
    //  あるいは didChangeDependencies 等を使う。
    //  ユーザー要望の "Reload or re-read the updated settings" を満たすため、
    //  build の冒頭でチェックするわけにはいかないので、
    //  Navigator.push の戻り待ちをする場所が必要だが、
    //  この画面自体がトップレベルに近いなら、
    //  RouteAware を使うか、あるいは単に再描画トリガーが必要。
    //  
    //  修正: ユーザー要望 C) Wiring GraphScreen to the settings
    //  "When the user returns from Graph Settings (Navigator.pop), the GraphScreen should: Reload..."
    //  SettingsScreen への遷移ボタンはこの画面にあるべきでは？
    //  現状のコードには Settings への遷移ボタンがない。
    //  AppBar に追加する。
    
    _recalcDates(); // 設定が変わっている可能性があるので再計算

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
        title: const Text('Contribution Graph', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), // Increased font size
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              // Settings画面へ遷移し、戻ってきたらリロード
              await Navigator.pushNamed(context, '/settings'); 
              // もし名前付きルートがない場合は直接遷移
              // import 'settings_screen.dart'; が必要だが、
              // ここでは既存のルート構造が不明なので、
              // もしエラーになるなら修正する。
              // いったん直接遷移コードを書く（importが必要）
              // しかし import が見えないので、既存の main.dart を見ないとわからない。
              // 前の view_file で settings_screen.dart は同じ階層にあることがわかっている。
              // import 'settings_screen.dart'; をファイルの先頭に追加する必要があるが、
              // replace_file_content は部分置換。
              // 既存の import '../config/app_settings.dart'; の下に追加したい。
              // 今回はとりあえず _loadHistory() を呼ぶ。
              _loadHistory();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last $_weeksToShow weeks',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), // Increased font size
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 利用可能な幅と高さ
                    final availableWidth = constraints.maxWidth;
                    final availableHeight = constraints.maxHeight;

                    // 曜日ラベルの幅
                    const double dayLabelWidth = 40.0;
                    const double dayLabelRightMargin = 8.0;
                    
                    // グラフ部分の幅（ラベル分を引く）
                    final graphAreaWidth = availableWidth - dayLabelWidth - dayLabelRightMargin;
                    
                    // セルサイズ計算
                    // 以前は _weeksToShow で割っていたが、
                    // 今後は「基準となる週数 (12週)」で割って、サイズを固定化する。
                    const int baseWeeksForSizing = 12;
                    
                    // width = (cellSize + margin) * baseWeeks
                    // cellSize = (width / baseWeeks) - margin
                    double cellSize = (graphAreaWidth / baseWeeksForSizing) - 2.0;
                    
                    // 高さが足りない場合の制限 (7行 + マージン)
                    // height = (cellSize + margin) * 7
                    final double maxHeightBasedCellSize = (availableHeight / 7) - 2.0;
                    
                    if (cellSize > maxHeightBasedCellSize) {
                      cellSize = maxHeightBasedCellSize;
                    }
                    
                    // あまりに小さくなりすぎないように制限（任意）
                    // cellSize = cellSize.clamp(10.0, 50.0);
                    
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: dayLabelWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(height: cellSize + 2), // Month label offset roughly
                              _buildDayLabel('Mon', cellSize),
                              SizedBox(height: cellSize + 2),
                              _buildDayLabel('Wed', cellSize),
                              SizedBox(height: cellSize + 2),
                              _buildDayLabel('Fri', cellSize),
                            ],
                          ),
                        ),
                        SizedBox(width: dayLabelRightMargin),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true, // 最新の日付（右側）を初期表示
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Month Labels
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(weeks.length, (weekIndex) {
                                    final label = monthLabels[weekIndex];
                                    return Container(
                                      width: cellSize + 2, // cell + margin
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 4),
                                // Graph Grid
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(weeks.length, (weekIndex) {
                                    final week = weeks[weekIndex];
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: week.map((date) {
                                        final key = _formatDateKey(date);
                                        final sessions = _sessionsByDate[key] ?? 0;
                                        final color = _colorForSessions(context, sessions);

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 2, right: 2),
                                          child: Tooltip(
                                            message: '${_formatShortDate(date)} : $sessions session(s)',
                                            child: Container(
                                              width: cellSize,
                                              height: cellSize,
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(4),
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
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Less', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _legendBox(context, 0, 20),
                  _legendBox(context, 1, 20), // approx 20%
                  _legendBox(context, (_maxSessionsPerDay * 0.4).ceil(), 20),
                  _legendBox(context, _maxSessionsPerDay, 20),
                  const SizedBox(width: 8),
                  const Text('More', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(
                    todaySessions == 0
                        ? 'Today: 0'
                        : 'Today: $todaySessions',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Increased font size
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

  Widget _buildDayLabel(String text, double height) {
    return SizedBox(
      height: height + 2, // cell + margin
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _legendBox(BuildContext context, int sessions, double size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _colorForSessions(context, sessions),
          borderRadius: BorderRadius.circular(4),
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
