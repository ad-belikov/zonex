// FILE: .\lib\features\active_session\ui\widgets\no_session_widget.dart
import 'package:flutter/material.dart';

class NoSessionWidget extends StatelessWidget {
  const NoSessionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Сессия не запущена',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Подключите тренажер на вкладке Finder',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
