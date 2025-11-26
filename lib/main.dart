import 'package:flutter/material.dart';

import 'screens/timer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/graph_screen.dart';

void main() {
  runApp(const CommitFitApp());
}

class CommitFitApp extends StatelessWidget {
  const CommitFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CommitFit Tabata',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // 👇 起動直後にいきなりタイマー画面
      home: const TimerScreen(),
      routes: {
        // 必要なら '/' も TimerScreen にしておく
        '/timer': (context) => const TimerScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/graph': (context) => const GraphScreen(),
      },
    );
  }
}

