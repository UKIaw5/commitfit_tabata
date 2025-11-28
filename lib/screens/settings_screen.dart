import 'package:flutter/material.dart';
import '../config/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  int _workSeconds = 20;
  int _restSeconds = 10;
  int _rounds = 8;

  // Graph settings
  int _graphWeeks = 12;
  int _graphMaxSessions = 5;

  static const int _minSeconds = 5;
  static const int _maxSeconds = 300;
  static const int _minRounds = 1;
  static const int _maxRounds = 20;

  static const int _minGraphWeeks = 4;
  static const int _maxGraphWeeks = 52;
  static const int _minGraphMaxSessions = 1;
  static const int _maxGraphMaxSessions = 10;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final timerConfig = await AppSettings.loadTimerConfig();
    final graphConfig = await AppSettings.loadGraphConfig();
    setState(() {
      _workSeconds = timerConfig.workSeconds;
      _restSeconds = timerConfig.restSeconds;
      _rounds = timerConfig.rounds;

      _graphWeeks = graphConfig.weeksToShow;
      _graphMaxSessions = graphConfig.maxSessionsPerDay;

      _loading = false;
    });
  }

  Future<void> _save() async {
    final timerConfig = TimerConfig(
      workSeconds: _workSeconds,
      restSeconds: _restSeconds,
      rounds: _rounds,
    );

    final graphConfig = GraphConfig(
      weeksToShow: _graphWeeks,
      maxSessionsPerDay: _graphMaxSessions,
    );

    await AppSettings.saveTimerConfig(timerConfig);
    await AppSettings.saveGraphConfig(graphConfig);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
    Navigator.pop(context);
  }

  void _adjustWork(int delta) {
    setState(() {
      _workSeconds =
          (_workSeconds + delta).clamp(_minSeconds, _maxSeconds).toInt();
    });
  }

  void _adjustRest(int delta) {
    setState(() {
      _restSeconds =
          (_restSeconds + delta).clamp(_minSeconds, _maxSeconds).toInt();
    });
  }

  void _adjustRounds(int delta) {
    setState(() {
      _rounds = (_rounds + delta).clamp(_minRounds, _maxRounds).toInt();
    });
  }

  void _adjustGraphWeeks(int delta) {
    setState(() {
      _graphWeeks =
          (_graphWeeks + delta).clamp(_minGraphWeeks, _maxGraphWeeks).toInt();
    });
  }

  void _adjustGraphMaxSessions(int delta) {
    setState(() {
      _graphMaxSessions = (_graphMaxSessions + delta)
          .clamp(_minGraphMaxSessions, _maxGraphMaxSessions)
          .toInt();
    });
  }

  Widget _buildStepper({
    required String label,
    required String unit,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onMinus,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: onPlus,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('Timer & Graph Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    const Text(
                      'Timer Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStepper(
                      label: 'Work duration',
                      unit: 'seconds',
                      value: _workSeconds,
                      onMinus: () => _adjustWork(-5),
                      onPlus: () => _adjustWork(5),
                    ),
                    const SizedBox(height: 16),
                    _buildStepper(
                      label: 'Rest duration',
                      unit: 'seconds',
                      value: _restSeconds,
                      onMinus: () => _adjustRest(-5),
                      onPlus: () => _adjustRest(5),
                    ),
                    const SizedBox(height: 16),
                    _buildStepper(
                      label: 'Rounds',
                      unit: 'sets',
                      value: _rounds,
                      onMinus: () => _adjustRounds(-1),
                      onPlus: () => _adjustRounds(1),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Graph Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStepper(
                      label: 'Weeks to show',
                      unit: 'weeks',
                      value: _graphWeeks,
                      onMinus: () => _adjustGraphWeeks(-4),
                      onPlus: () => _adjustGraphWeeks(4),
                    ),
                    const SizedBox(height: 16),
                    _buildStepper(
                      label: 'Max intensity threshold',
                      unit: 'sessions/day',
                      value: _graphMaxSessions,
                      onMinus: () => _adjustGraphMaxSessions(-1),
                      onPlus: () => _adjustGraphMaxSessions(1),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Save settings'),
                      ),
                    ),
                    const SizedBox(height: 32),
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
}
