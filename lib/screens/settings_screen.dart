import 'package:flutter/material.dart';
import '../config/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _workController;
  late TextEditingController _restController;
  late TextEditingController _roundsController;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _workController = TextEditingController();
    _restController = TextEditingController();
    _roundsController = TextEditingController();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await AppSettings.loadTimerConfig();
    setState(() {
      _workController.text = config.workSeconds.toString();
      _restController.text = config.restSeconds.toString();
      _roundsController.text = config.rounds.toString();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _workController.dispose();
    _restController.dispose();
    _roundsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final work = int.tryParse(_workController.text) ?? 20;
    final rest = int.tryParse(_restController.text) ?? 10;
    final rounds = int.tryParse(_roundsController.text) ?? 8;

    final config = TimerConfig(
      workSeconds: work,
      restSeconds: rest,
      rounds: rounds,
    );

    await AppSettings.saveTimerConfig(config);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Timer settings saved')),
    );
    Navigator.pop(context); // Home に戻る
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer & Graph Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: _workController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Work duration (seconds)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _restController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Rest duration (seconds)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _roundsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Number of rounds',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save settings'),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Graph Settings (coming soon)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You will be able to customize graph intensity and range later.',
                  ),
                ],
              ),
            ),
    );
  }
}
