import 'package:flutter/material.dart';

class GraphScreen extends StatelessWidget {
  const GraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribution Graph'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.grid_on, size: 48),
            SizedBox(height: 16),
            Text(
              'Your Tabata contributions will appear here\n'
              'like a GitHub contribution graph.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

