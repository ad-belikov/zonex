// FILE: .\lib\features\active_session\ui\widgets\session_finished_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/active_session_bloc.dart';
import '../../bloc/active_session_event.dart';

class SessionFinishedWidget extends StatelessWidget {
  const SessionFinishedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Тренировка завершена!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                context.read<ActiveSessionBloc>().add(const StopSession()),
            child: const Text('Начать заново'),
          ),
        ],
      ),
    );
  }
}
