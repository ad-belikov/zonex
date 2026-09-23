import 'ble_parser.dart';
import 'starthouse_rs500_parser.dart';

class BleParserFactory {
  static BleParser? getParser(String? localName, Map<int, List<int>> manufacturerData, List<String> serviceUuids) {
    if (localName != null && localName.contains('StartHouse RS 500')) {
      return StartHouseRS500Parser();
    }
    if (serviceUuids.any((uuid) => uuid.toLowerCase().contains('1826'))) {
      return StartHouseRS500Parser(); 
    }
    return null;
  }
}
