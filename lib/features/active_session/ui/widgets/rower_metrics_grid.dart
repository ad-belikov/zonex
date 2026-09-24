// FILE: .\lib\features\active_session\ui\widgets\rower_metrics_grid.dart
import 'package:flutter/material.dart';

import 'metric_card.dart';

class RowerMetricsGrid extends StatelessWidget {
  final int heartRate;
  final String formattedPace;
  final double rowerPower;
  final double strokeRate;
  final double distance;
  final int strokeCount;

  const RowerMetricsGrid({
    super.key,
    required this.heartRate,
    required this.formattedPace,
    required this.rowerPower,
    required this.strokeRate,
    required this.distance,
    required this.strokeCount,
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
          title: 'ТЕМП (/500м)',
          value: formattedPace,
          icon: Icons.speed,
          accentColor: Colors.blueAccent,
        ),
        MetricCard(
          title: 'МОЩНОСТЬ',
          value: '${rowerPower.round()}',
          unit: ' W',
          icon: Icons.bolt,
          accentColor: Colors.amber,
        ),
        MetricCard(
          title: 'ЧАСТОТА ГРЕБКОВ',
          value: strokeRate.toStringAsFixed(1),
          unit: ' SPM',
          icon: Icons.rowing,
          accentColor: Colors.purpleAccent,
        ),
        MetricCard(
          title: 'ДИСТАНЦИЯ',
          value: '${distance.round()}',
          unit: ' M',
          icon: Icons.map,
          accentColor: Colors.green,
        ),
        MetricCard(
          title: 'ВСЕГО ГРЕБКОВ',
          value: '$strokeCount',
          icon: Icons.functions,
          accentColor: Colors.teal,
        ),
      ],
    );
  }
}
