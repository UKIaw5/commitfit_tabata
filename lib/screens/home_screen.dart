import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_settings.dart';
import 'settings_screen.dart';
import 'graph_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TimerConfig? _config;
  bool _loading = true;

  final AudioPlayer _player = AudioPlayer(); // 効果音再生用
  Timer? _timer;
  Timer? _preCountdownTimer;

  bool _isRunning = false;
  bool _isWorkPhase = true; // true = Work, false = Rest
  int _currentRound = 1;
  int _remainingSeconds = 0;

  static const int _preCountdownTotal = 10;
  bool _isPreCountdown = false;
  int _preCountdownSeconds = _preCountdownTotal;
  bool _hasSessionStarted = false;
  bool _isSessionComplete = false;

  // AdMob Banner
  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    // Production banner ad unit (DO NOT USE IN DEVELOPMENT, ONLY KEEP AS COMMENT)
    // const String prodBannerAdUnitId = 'ca-app-pub-7982112708155827/3074866842';

    // Use the official Google test banner ad unit for now:
    const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

    _bannerAd = BannerAd(
      adUnitId: testBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
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
    _preCountdownTimer?.cancel();
    _isRunning = false;
    _isPreCountdown = false;
    _preCountdownSeconds = _preCountdownTotal;
    _hasSessionStarted = false;
    _isSessionComplete = false;
    _isWorkPhase = true;
    _currentRound = 1;
    _remainingSeconds = _config!.workSeconds;
    _timer?.cancel();
  }

  Future<void> _playSound(String assetPath, {bool stopFirst = false}) async {
    try {
      // Stop any currently playing sound if requested (e.g., for complete sound)
      if (stopFirst) {
        await _player.stop();
      }
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // 音が鳴らなくてもアプリは落とさない
    }
  }

  bool get _isTimerActive => _isRunning || _isPreCountdown;

  void _startTimer() {
    if (_config == null) return;

    // If session is complete, reset state first, then start a new session
    if (_isSessionComplete) {
      _timer?.cancel();
      _preCountdownTimer?.cancel();
      // Reset all state to initial values
      setState(() {
        _resetStateFromConfig();
      });
      // Start new session with pre-countdown after reset completes
      // Use a microtask to ensure setState completes first
      Future.microtask(() {
        if (mounted && !_isTimerActive) {
          _beginPreCountdown();
        }
      });
      return;
    }

    // Normal start behavior - don't start if timer is already active
    if (_isTimerActive) return;

    if (_hasSessionStarted) {
      _beginMainTimer();
    } else {
      _beginPreCountdown();
    }
  }

  void _beginPreCountdown() {
    _preCountdownTimer?.cancel();
    setState(() {
      _isPreCountdown = true;
      _preCountdownSeconds = _preCountdownTotal;
    });
    // 事前カウントダウンフェーズ：READY音→10秒カウント
    _playSound('sounds/ready.mp3');

    _preCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (preTimer) {
      if (!mounted) return;
      setState(() {
        if (_preCountdownSeconds > 0) {
          if (_preCountdownSeconds <= 5) {
            _playSound('sounds/tick.mp3');
          }
          _preCountdownSeconds--;
        }
        if (_preCountdownSeconds == 0) {
          _isPreCountdown = false;
          preTimer.cancel();
          _beginMainTimer();
        }
      });
    });
  }

  void _beginMainTimer() {
    if (_config == null) return;
    _timer?.cancel();
    _preCountdownTimer?.cancel();
    setState(() {
      _isRunning = true;
      _hasSessionStarted = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      bool shouldComplete = false;

      setState(() {
        if (_remainingSeconds > 0) {
          if (_remainingSeconds <= 5) {
            _playSound('sounds/tick.mp3');
          }
          _remainingSeconds--;
        } else {
          if (_isWorkPhase) {
            // Work phase finished
            if (_currentRound >= _config!.rounds) {
              // Last Work phase finished - complete session (no Rest)
              timer.cancel();
              _timer?.cancel();
              _isRunning = false;
              _hasSessionStarted = false;
              shouldComplete = true;
            } else {
              // Not the last round - transition to Rest
              _isWorkPhase = false;
              _remainingSeconds = _config!.restSeconds;
            }
          } else {
            // Rest phase finished - move to next Work round
            _currentRound++;
            _isWorkPhase = true;
            _remainingSeconds = _config!.workSeconds;
          }
        }
      });

      // Call _completeSession outside setState to ensure sound plays correctly
      if (shouldComplete) {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    if (!_isTimerActive) return;
    _timer?.cancel();
    _preCountdownTimer?.cancel();
    setState(() {
      _isRunning = false;
      if (_isPreCountdown) {
        _isPreCountdown = false;
        _preCountdownSeconds = _preCountdownTotal;
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _preCountdownTimer?.cancel();
    setState(() {
      _resetStateFromConfig();
    });
  }

  // 全工程完了時：今日のセッション＋1
  Future<void> _completeSession() async {
    _timer?.cancel();
    _preCountdownTimer?.cancel();
    _isRunning = false;
    _hasSessionStarted = false;

    // Play finish sound - stop any current playback first to ensure it plays
    await _playSound('sounds/complete.mp3', stopFirst: true);

    // Haptic feedback (mobile only)
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {
      // Ignore if haptics not available (desktop/web)
    }

    final updatedSessions = await AppSettings.addSessionForToday();

    if (!mounted) return;

    setState(() {
      _isSessionComplete = true;
      _remainingSeconds = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Session committed! Today: $updatedSessions session(s).',
        ),
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
    _preCountdownTimer?.cancel();
    _player.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  int _phaseTotalSeconds() {
    if (_config == null) return 1;
    return _isWorkPhase ? _config!.workSeconds : _config!.restSeconds;
  }

  double _progressValue() {
    if (_isSessionComplete) return 1.0; // Full circle when finished
    if (_isPreCountdown) {
      return 1 - (_preCountdownSeconds / _preCountdownTotal);
    }
    final total = _phaseTotalSeconds();
    if (total <= 0) return 0;
    return 1 - (_remainingSeconds / total);
  }

  int _totalSessionSeconds() {
    if (_config == null) return 0;
    // Total time: all Work rounds + (rounds - 1) Rest phases
    // (No Rest after the final Work)
    final restRoundCount = _config!.rounds > 0 ? _config!.rounds - 1 : 0;
    return (_config!.workSeconds * _config!.rounds) +
        (_config!.restSeconds * restRoundCount);
  }

  @override
  Widget build(BuildContext context) {
    // ここが1つ目の return Scaffold（「読み込み中」専用）
    if (_loading || _config == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Commitfit'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final displayedTime = _isPreCountdown
        ? _formatTime(_preCountdownSeconds)
        : _formatTime(_remainingSeconds);
    final totalSessionTime = _formatTime(_totalSessionSeconds());

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Color for circular progress - brighter green when finished
    final progressColor = _isSessionComplete
        ? colorScheme.primary.withOpacity(0.8)
        : colorScheme.primary;

    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('GitFit'),
        actions: [
          IconButton(
            iconSize: 32,
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
            iconSize: 32,
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
              if (mounted) {
                _loadConfig();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    Text(
                      'Preset: ${_config!.workSeconds}s / '
                      '${_config!.restSeconds}s • ${_config!.rounds} rounds',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 260,
                            height: 260,
                            child: CircularProgressIndicator(
                              value: _progressValue().clamp(0.0, 1.0),
                              backgroundColor: colorScheme.surfaceVariant,
                              color: progressColor,
                              strokeWidth: 12,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_isSessionComplete)
                                Text(
                                  displayedTime,
                                  style: textTheme.displaySmall?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              if (_isSessionComplete) const SizedBox(height: 8),
                              Text(
                                _phaseLabel(),
                                style: _isSessionComplete
                                    ? textTheme.headlineMedium?.copyWith(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 4,
                                        color: _phaseColor(),
                                      )
                                    : textTheme.headlineSmall?.copyWith(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 3,
                                        color: _phaseColor(),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _InfoStat(
                          label: 'SETS',
                          value: '$_currentRound / ${_config!.rounds}',
                        ),
                        _InfoStat(
                          label: 'TOTAL TIME',
                          value: totalSessionTime,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: _isTimerActive
                                  ? colorScheme.secondary
                                  : colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _isTimerActive ? _pauseTimer : _startTimer,
                            child: Text(_isTimerActive ? 'PAUSE' : 'START'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              side: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _resetTimer,
                            child: const Text('RESET'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isBannerReady && _bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );

    return scaffold;
  }

  String _phaseLabel() {
    if (_isSessionComplete) return 'FINISHED!';
    if (_isPreCountdown) return 'READY';
    if (_isTimerActive) {
      return _isWorkPhase ? 'WORK' : 'REST';
    }
    if (_hasSessionStarted) return 'PAUSED';
    return _isWorkPhase ? 'WORK' : 'REST';
  }

  Color _phaseColor() {
    if (_isSessionComplete) return const Color(0xFF166534); // Dark green for finished
    if (_isPreCountdown) return const Color(0xFF155E75);
    if (_isTimerActive) {
      return _isWorkPhase
          ? const Color(0xFF166534)
          : const Color(0xFF9A3412);
    }
    if (_hasSessionStarted) return const Color(0xFF111827);
    return const Color(0xFF166534);
  }
}

class _InfoStat extends StatelessWidget {
  const _InfoStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

