// FILE: .\lib\features\active_session\ui\widgets\treadmill_metrics_grid.dart
import 'package:flutter/material.dart';

import 'metric_card.dart';

class TreadmillMetricsGrid extends StatelessWidget {
  final int heartRate;
  final String runPace;
  final double runSpeed;
  final double runCadence;
  final double incline;
  final double distance;

  const TreadmillMetricsGrid({
    super.key,
    required this.heartRate,
    required this.runPace,
    required this.runSpeed,
    required this.runCadence,
    required this.incline,
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
          title: 'ТЕМП БЕГА',
          value: runPace,
          unit: ' /KM',
          icon: Icons.av_timer,
          accentColor: Colors.blueAccent,
        ),
        MetricCard(
          title: 'СКОРОСТЬ',
          value: runSpeed.toStringAsFixed(1),
          unit: ' KM/H',
          icon: Icons.speed,
          accentColor: Colors.cyan,
        ),
        MetricCard(
          title: 'КАДЕНС ШАГОВ',
          value: runCadence.toStringAsFixed(0),
          unit: ' SPM',
          icon: Icons.directions_run,
          accentColor: Colors.orangeAccent,
        ),
        MetricCard(
          title: 'НАКЛОН ПОЛОТНА',
          value: incline.toStringAsFixed(1),
          unit: ' %',
          icon: Icons.trending_up,
          accentColor: Colors.indigoAccent,
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
