import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class BleScanEvent {}

/// Событие запроса на запуск сканирования с проверкой разрешений
class StartScanRequested extends BleScanEvent {}

/// Событие принудительной остановки сканирования
class StopScanRequested extends BleScanEvent {}

/// Внутреннее событие BLoC для обновления списка найденных устройств из стрима
class ScanResultsUpdated extends BleScanEvent {
  final List<ScanResult> results;
  ScanResultsUpdated(this.results);
}

/// Внутреннее событие BLoC для обновления статуса адаптера (Вкл/Выкл)
class AdapterStateUpdated extends BleScanEvent {
  final BluetoothAdapterState adapterState;
  AdapterStateUpdated(this.adapterState);
}
