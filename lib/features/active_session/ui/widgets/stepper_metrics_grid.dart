// FILE: .\lib\features\active_session\ui\widgets\stepper_metrics_grid.dart
import 'package:flutter/material.dart';

import 'metric_card.dart';

class StepperMetricsGrid extends StatelessWidget {
  final int heartRate;
  final int floorsCount;
  final double stepRate;
  final double distance;

  const StepperMetricsGrid({
    super.key,
    required this.heartRate,
    required this.floorsCount,
    required this.stepRate,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      padding: const EdgeInsets.all(16.0),
      mainAxisSpacing: 12.0,
      crossAxisSpacing: 12.0,
      children: [
        MetricCard(
          title: 'ПУЛЬС',
          value: heartRate > 0 ? '$heartRate' : '--',
          unit: ' BPM',
          icon: Icons.favorite,
          accentColor: Colors.redAccent,
        ),
        MetricCard(
          title: 'ПРОЙДЕНО ЭТАЖЕЙ',
          value: '$floorsCount',
          unit: ' FLR',
          icon: Icons.stairs,
          accentColor: Colors.deepPurpleAccent,
        ),
        MetricCard(
          title: 'СКОРОСТЬ ШАГОВ',
          value: stepRate.toStringAsFixed(0),
          unit: ' SPM',
          icon: Icons.height,
          accentColor: Colors.orangeAccent,
        ),
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
