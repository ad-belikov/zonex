import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/ble_connection_bloc/ble_connection_bloc.dart'; // ДОБАВЛЕНО
import '../../shared/ble_connection_bloc/ble_connection_event.dart'; // ДОБАВЛЕНО
import '../bloc/active_session_bloc.dart';
import '../bloc/active_session_event.dart';
import '../bloc/active_session_state.dart';

class ActiveSessionScreen extends StatelessWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveSessionBloc, ActiveSessionState>(
      builder: (context, state) {
        if (state is ActiveSessionInitial) {
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

        if (state is ActiveSessionFinished) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 72,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Тренировка завершена!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<ActiveSessionBloc>().add(StopSession());
                  },
                  child: const Text('Начать заново'),
                ),
              ],
            ),
          );
        }

        if (state is ActiveSessionData) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      padding: const EdgeInsets.all(16.0),
                      mainAxisSpacing: 12.0,
                      crossAxisSpacing: 12.0,
                      children: [
                        _buildMetricCard(
                          context,
                          title: 'ТЕМП (/500м)',
                          value: state.formattedPace,
                          icon: Icons.speed,
                          accentColor: Colors.blueAccent,
                        ),
                        _buildMetricCard(
                          context,
                          title: 'ПУЛЬС',
                          value: state.heartRate > 0
                              ? '${state.heartRate}'
                              : '--',
                          unit: ' BPM',
                          icon: Icons.favorite,
                          accentColor: Colors.redAccent,
                        ),
                        _buildMetricCard(
                          context,
                          title: 'МОЩНОСТЬ',
                          value: '${state.power.round()}',
                          unit: ' W',
                          icon: Icons.bolt,
                          accentColor: Colors.amber,
                        ),
                        _buildMetricCard(
                          context,
                          title: 'ЧАСТОТА ГРЕБКОВ',
                          value: state.strokeRate.toStringAsFixed(1),
                          unit: ' SPM',
                          icon: Icons.rowing,
                          accentColor: Colors.purpleAccent,
                        ),
                        _buildMetricCard(
                          context,
                          title: 'ДИСТАНЦИЯ',
                          value: '${state.distance.round()}',
                          unit: ' M',
                          icon: Icons.map,
                          accentColor: Colors.green,
                        ),
                        _buildMetricCard(
                          context,
                          title: 'ВСЕГО ГРЕБКОВ',
                          value: '${state.strokeCount}',
                          icon: Icons.functions,
                          accentColor: Colors.teal,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 110.0,
                      left: 24.0,
                      right: 24.0,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.stop, size: 28),
                        label: const Text(
                          'ЗАВЕРШИТЬ ТРЕНИРОВКУ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        onPressed: () {
                          _showConfirmDialog(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    String unit = '',
    required IconData icon,
    required Color accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Завершить тренировку?'),
        content: const Text('Текущий прогресс сессии будет остановлен.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ОТМЕНА'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(dialogContext);
              // ИСПРАВЛЕНО: Передаем событие остановки сессии в тренировочный Блок
              context.read<ActiveSessionBloc>().add(StopSession());
              // ДОБАВЛЕНО: Разорвать Bluetooth-соединение с тренажером, освободив модуль связи
              context.read<BleConnectionBloc>().add(DisconnectFromDevice());
            },
            child: const Text('ДА, ЗАВЕРШИТЬ'),
          ),
        ],
      ),
    );
  }
}
