import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../config/app_settings.dart';
import 'settings_screen.dart';
import 'graph_screen.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  TimerConfig? _config;
  bool _loading = true;

  Timer? _timer;
  bool _isRunning = false;
  bool _isWorkPhase = true; // true = Work, false = Rest
  int _currentRound = 1;
  int _remainingSeconds = 0;

  final AudioPlayer _player = AudioPlayer(); // 効果音再生用

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await AppSettings.loadTimerConfig();
    if (!mounted) return;
    setState(() {
      _config = config;
      _resetStateFromConfig();
      _loading = false;
    });
  }

  void _resetStateFromConfig() {
    if (_config == null) return;
    _isRunning = false;
    _isWorkPhase = true;
    _currentRound = 1;
    _remainingSeconds = _config!.workSeconds;
    _timer?.cancel();
  }

  Future<void> _playSound(String assetPath) async {
    try {
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // 音が鳴らなくてもアプリは落とさない
    }
  }

  void _startTimer() {
    if (_config == null) return;
    if (_isRunning) return;

    // 最初のWORK開始ブザー
    _playSound('sounds/buzzer.mp3');

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_remainingSeconds > 0) {
          // 残り5〜1秒のときは毎秒カウント音
          if (_remainingSeconds <= 5) {
            _playSound('sounds/tick.mp3');
          }
          _remainingSeconds--;
        } else {
          // 0秒になった → フェーズ切り替え or セッション完了
          if (_isWorkPhase) {
            // Work → Rest への切り替え
            _playSound('sounds/buzzer.mp3'); // 終了ブザー

            _isWorkPhase = false;
            _remainingSeconds = _config!.restSeconds;
          } else {
            // Rest フェーズ終了 → 次ラウンド or 全部終わり
            if (_currentRound < _config!.rounds) {
              // 次のラウンドのWORKへ
              _playSound('sounds/buzzer.mp3'); // 開始ブザー

              _currentRound++;
              _isWorkPhase = true;
              _remainingSeconds = _config!.workSeconds;
            } else {
              // 全ラウンド完了
              _completeSession();
            }
          }
        }
      });
    });
  }

  void _pauseTimer() {
    if (!_isRunning) return;
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _resetStateFromConfig();
    });
  }

  // 全工程完了時：今日のセッション＋1
  Future<void> _completeSession() async {
    _timer?.cancel();
    _isRunning = false;

    // 完了音
    _playSound('sounds/complete.mp3');

    final updatedSessions = await AppSettings.addSessionForToday();

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session complete!'),
        content: Text(
          'Nice work. Today you have completed '
          '$updatedSessions session(s).',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _resetStateFromConfig();
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ここが1つ目の return Scaffold（「読み込み中」専用）
    if (_loading || _config == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('CommitFit – Tabata'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 読み込み完了後のメインUI
    final phaseText = _isWorkPhase ? 'WORK' : 'REST';
    final phaseColor = _isWorkPhase ? Colors.red : Colors.blue;

    // ここが2つ目の return Scaffold（通常画面）
    return Scaffold(
      appBar: AppBar(
        title: const Text('CommitFit – Tabata'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on),
            tooltip: 'Contribution graph',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GraphScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
              // 戻ってきたら設定を再読み込み
              if (mounted) {
                _loadConfig();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // プリセット表示
            Text(
              'Preset: ${_config!.workSeconds}s work / '
              '${_config!.restSeconds}s rest × ${_config!.rounds} rounds',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),

            // ラウンド & フェーズ表示
            Text(
              'Round $_currentRound / ${_config!.rounds}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: phaseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                phaseText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: phaseColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 残り時間
            Text(
              _formatTime(_remainingSeconds),
              style: const TextStyle(
                fontSize: 48,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 24),

            // ラウンド進捗（○○○○ みたいな）
            Wrap(
              spacing: 4,
              children: List.generate(_config!.rounds, (index) {
                final roundNumber = index + 1;
                final isDone = roundNumber < _currentRound;
                final isCurrent = roundNumber == _currentRound;

                Color color;
                if (isDone) {
                  color = Colors.green;
                } else if (isCurrent) {
                  color = Colors.green.withOpacity(0.6);
                } else {
                  color = Colors.grey.withOpacity(0.3);
                }

                return Icon(
                  Icons.circle,
                  size: 12,
                  color: color,
                );
              }),
            ),

            const Spacer(),

            // コントロールボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
              ElevatedButton.icon(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? 'Pause' : 'Start'),
                ),
                OutlinedButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

