// FILE: .\lib\features\active_session\ui\active_session_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ble_parsers/ble_parser.dart';
import '../../shared/ble_connection_bloc/ble_connection_bloc.dart';
import '../../shared/ble_connection_bloc/ble_connection_event.dart';
import '../../shared/ble_connection_bloc/ble_connection_state.dart';
import '../bloc/active_session_bloc.dart';
import '../bloc/active_session_event.dart';
import '../bloc/active_session_state.dart';
// Импорт всех декомпозированных виджетов
import 'widgets/bike_metrics_grid.dart';
import 'widgets/metric_card.dart';
import 'widgets/no_session_widget.dart';
import 'widgets/reconnect_overlay.dart';
import 'widgets/rower_metrics_grid.dart';
import 'widgets/session_finished_widget.dart';
import 'widgets/stepper_metrics_grid.dart';
import 'widgets/treadmill_metrics_grid.dart';

class ActiveSessionScreen extends StatelessWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveSessionBloc, ActiveSessionState>(
      builder: (context, sessionState) {
        return sessionState.when(
          initial: () => const NoSessionWidget(),
          finished: () => const SessionFinishedWidget(),
          data:
              (
                equipmentType,
                equipmentName,
                heartRate,
                distance,
                strokeRate,
                strokeCount,
                formattedPace,
                rowerPower,
                bikeSpeed,
                bikeCadence,
                bikePower,
                resistanceLevel,
                runSpeed,
                runPace,
                runCadence,
                incline,
                floorsCount,
                stepRate,
              ) {
                return Stack(
                  children: [
                    Scaffold(
                      body: SafeArea(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white10
                                  : Colors.black12,
                              width: double.infinity,
                              child: Text(
                                'Подключено: $equipmentName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: _buildMetricsGrid(
                                equipmentType,
                                heartRate,
                                distance,
                                strokeRate,
                                strokeCount,
                                formattedPace,
                                rowerPower,
                                bikeSpeed,
                                bikeCadence,
                                bikePower,
                                resistanceLevel,
                                runSpeed,
                                runPace,
                                runCadence,
                                incline,
                                floorsCount,
                                stepRate,
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
                                  onPressed: () => _showConfirmDialog(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Изолированный слушатель оверлея
                    BlocBuilder<BleConnectionBloc, BleConnectionState>(
                      builder: (context, connectionState) {
                        return connectionState.maybeWhen(
                          connecting: (_, attempt) => ReconnectOverlay(
                            attempt: attempt,
                            onCancelPressed: () => _showConfirmDialog(context),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ],
                );
              },
        );
      },
    );
  }

  Widget _buildMetricsGrid(
    EquipmentType equipmentType,
    int heartRate,
    double distance,
    double strokeRate,
    int strokeCount,
    String formattedPace,
    double rowerPower,
    double bikeSpeed,
    double bikeCadence,
    double bikePower,
    int resistanceLevel,
    double runSpeed,
    String runPace,
    double runCadence,
    double incline,
    int floorsCount,
    double stepRate,
  ) {
    switch (equipmentType) {
      case EquipmentType.rower:
        return RowerMetricsGrid(
          heartRate: heartRate,
          formattedPace: formattedPace,
          rowerPower: rowerPower,
          strokeRate: strokeRate,
          distance: distance,
          strokeCount: strokeCount,
        );
      case EquipmentType.bike:
        return BikeMetricsGrid(
          heartRate: heartRate,
          speed: bikeSpeed,
          cadence: bikeCadence,
          bikePower: bikePower,
          resistanceLevel: resistanceLevel,
          distance: distance,
        );
      case EquipmentType.treadmill:
        return TreadmillMetricsGrid(
          heartRate: heartRate,
          runPace: runPace,
          runSpeed: runSpeed,
          runCadence: runCadence,
          incline: incline,
          distance: distance,
        );
      case EquipmentType.stepper:
        return StepperMetricsGrid(
          heartRate: heartRate,
          floorsCount: floorsCount,
          stepRate: stepRate,
          distance: distance,
        );
      case EquipmentType.unknown:
        return GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          padding: const EdgeInsets.all(16.0),
          children: [
            MetricCard(
              title: 'ДИСТАНЦИЯ',
              value: '${distance.round()}',
              unit: ' M',
              icon: Icons.map,
              accentColor: Colors.green,
            ),
          ],
        );
    }
  }

  void _showConfirmDialog(BuildContext context) {
    final activeSessionBloc = context.read<ActiveSessionBloc>();
    final bleConnectionBloc = context.read<BleConnectionBloc>();

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
              activeSessionBloc.add(const StopSession());
              bleConnectionBloc.add(DisconnectFromDevice());
            },
            child: const Text('ДА, ЗАВЕРШИТЬ'),
          ),
        ],
      ),
    );
  }
}
