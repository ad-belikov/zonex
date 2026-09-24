// FILE: .\lib\features\equipment_finder\bloc\ble_scan_bloc.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'; // ИСПРАВЛЕНО: Импорт для работы debugPrint
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/ble_parsers/ble_parser.dart';
import '../../../core/ble_parsers/ble_parser_factory.dart';
import '../../../core/ble_service/ble_service.dart';
import '../models/discovered_device.dart';
import 'ble_scan_event.dart';
import 'ble_scan_state.dart';

class BleScanBloc extends Bloc<BleScanEvent, BleScanState> {
  final BleService _bleService;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  bool _isScanningCurrent = false;
  List<ScanResult> _currentResults = [];

  BleScanBloc(this._bleService) : super(const BleScanState.initial()) {
    on<StartScanRequested>(_onStartScan);
    on<StopScanRequested>(_onStopScan);
    on<ScanResultsUpdated>(_onScanResultsUpdated);

    // ИСПРАВЛЕНО: Явная регистрация события адаптера устраняет ворнинг "isn't referenced"
    on<AdapterStateUpdated>(_onAdapterStateUpdated);

    _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (!isClosed) add(AdapterStateUpdated(state));
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      _isScanningCurrent = isScanning;

      final isInProgressState = state.maybeWhen(
        inProgress: (_, _) => true,
        orElse: () => false,
      );

      if (!isClosed && isInProgressState) {
        add(ScanResultsUpdated(_currentResults));
      }
    });
  } // ИСПРАВЛЕНО: Конструктор Блока корректно закрывается здесь

  Future<void> _onStartScan(
    StartScanRequested event,
    Emitter<BleScanState> emit,
  ) async {
    // ИСПРАВЛЕНО: Убрано дублирование. Запрашиваем разрешения один раз в зависимости от ОС
    bool permissionsGranted = false;

    try {
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();
        permissionsGranted = statuses.values.every(
          (status) => status.isGranted,
        );
      } else if (Platform.isIOS) {
        final status = await Permission.bluetooth.request();
        permissionsGranted = status.isGranted;
      }

      // ИСПРАВЛЕНО: Guard clause для защиты от асинхронных гонок, если Блок закрыли во время всплывающего окна прав
      if (isClosed || emit.isDone) return;

      if (!permissionsGranted) {
        emit(const BleScanState.noPermissions());
        return;
      }

      final adapterNow = FlutterBluePlus.adapterStateNow;
      if (adapterNow != BluetoothAdapterState.on) {
        emit(BleScanState.adapterOff(adapterNow));
        return;
      }

      // Принудительно очищаем старые сессии перед новым поиском
      await _bleService.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;

      if (isClosed || emit.isDone) return;

      _scanSubscription = _bleService.scanResults
          .sampleTime(const Duration(milliseconds: 1000))
          .listen((results) {
            if (!isClosed) add(ScanResultsUpdated(results));
          });

      await _bleService.startScan();
    } catch (e) {
      // ИСПРАВЛЕНО: Перевод в noPermissions() и логирование вместо вызова несуществующей фабрики .error()
      debugPrint('🚨 Критическая ошибка инициализации BLE: $e');
      if (!isClosed && !emit.isDone) {
        emit(const BleScanState.noPermissions());
      }
    }
  }

  // ИСПРАВЛЕНО: Имя метода приведено в строгое соответствие с регистратором в конструкторе
  Future<void> _onStopScan(
    StopScanRequested event,
    Emitter<BleScanState> emit,
  ) async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _bleService.stopScan();

    if (!isClosed && !emit.isDone) {
      emit(const BleScanState.initial());
    }
  }

  void _onScanResultsUpdated(
    ScanResultsUpdated event,
    Emitter<BleScanState> emit,
  ) {
    if (isClosed || emit.isDone) return;

    final List<ScanResult> sortedResults = List.from(event.results);
    sortedResults.sort((a, b) => b.rssi.compareTo(a.rssi));
    _currentResults = sortedResults;

    final List<DiscoveredDevice> uiDevices = sortedResults.map((r) {
      final name = r.advertisementData.advName.isEmpty
          ? 'Unknown Device'
          : r.advertisementData.advName;

      final parser = BleParserFactory.getParser(
        r.advertisementData.advName,
        r.advertisementData.manufacturerData,
        r.advertisementData.serviceUuids.map((e) => e.toString()).toList(),
      );

      return DiscoveredDevice(
        id: r.device.remoteId.toString(),
        name: name,
        rssi: r.rssi,
        type: parser?.type ?? EquipmentType.unknown,
      );
    }).toList();

    emit(
      BleScanState.inProgress(
        results: uiDevices,
        isScanning: _isScanningCurrent,
      ),
    );
  }

  // ИСПРАВЛЕНО: Метод теперь находится вне конструктора, являясь полноценным методом класса
  void _onAdapterStateUpdated(
    AdapterStateUpdated event,
    Emitter<BleScanState> emit,
  ) {
    if (isClosed || emit.isDone) return;

    if (event.adapterState != BluetoothAdapterState.on) {
      _scanSubscription?.cancel();
      _scanSubscription = null;
      _bleService.stopScan();
      emit(BleScanState.adapterOff(event.adapterState));
    } else {
      final isInitialOrAdapterOff = state.maybeWhen(
        initial: () => true,
        adapterOff: (_) => true,
        orElse: () => false,
      );

      // ИСПРАВЛЕНО: Поиск стартует только если мы перешли из выключенного состояния Bluetooth, исключая рекурсию
      if (isInitialOrAdapterOff) {
        add(StartScanRequested());
      }
    }
  }

  @override
  Future<void> close() async {
    await _scanSubscription?.cancel();
    await _adapterSubscription?.cancel();
    await _isScanningSubscription?.cancel();

    try {
      await _bleService.stopScan();
    } catch (_) {}

    return super.close();
  }
}
