// FILE: lib/features/equipment_finder/models/discovered_device.dart
import '../../../core/ble_parsers/ble_parser.dart';

class DiscoveredDevice {
  final String id;
  final String name;
  final int rssi;
  final EquipmentType type;

  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredDevice &&
          runtimeType == runtimeType &&
          id == other.id &&
          name == other.name &&
          rssi == other.rssi &&
          type == other.type;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ rssi.hashCode ^ type.hashCode;
}
