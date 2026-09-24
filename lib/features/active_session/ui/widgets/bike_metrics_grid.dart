// FILE: .\lib\features\active_session\ui\widgets\bike_metrics_grid.dart
import 'package:flutter/material.dart';

import 'metric_card.dart';

class BikeMetricsGrid extends StatelessWidget {
  final int heartRate;
  final double speed;
  final double cadence;
  final double bikePower;
  final int resistanceLevel;
  final double distance;

  const BikeMetricsGrid({
    super.key,
    required this.heartRate,
    required this.speed,
    required this.cadence,
    required this.bikePower,
    required this.resistanceLevel,
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
          title: 'СКОРОСТЬ',
          value: speed.toStringAsFixed(1),
          unit: ' KM/H',
          icon: Icons.speed,
          accentColor: Colors.blueAccent,
        ),
        MetricCard(
          title: 'КАДЕНС',
          value: cadence.toStringAsFixed(0),
          unit: ' RPM',
          icon: Icons.cached,
          accentColor: Colors.orangeAccent,
        ),
        MetricCard(
          title: 'МОЩНОСТЬ',
          value: '${bikePower.round()}',
          unit: ' W',
          icon: Icons.bolt,
          accentColor: Colors.amber,
        ),
        MetricCard(
          title: 'СОПРОТИВЛЕНИЕ',
          value: '$resistanceLevel',
          unit: ' LVL',
          icon: Icons.tune,
          accentColor: Colors.purpleAccent,
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
