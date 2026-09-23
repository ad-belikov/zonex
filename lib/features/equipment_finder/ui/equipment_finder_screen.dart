import 'dart:async'; // ДОБАВЛЕНО: Импорт для поддержки функции unawaited()
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/ble_parsers/ble_parser.dart';
import '../../../core/ble_parsers/ble_parser_factory.dart';
import '../../../core/ble_service/ble_service.dart';
import '../../../core/di/injection.dart';
import '../../shared/ble_connection_bloc/ble_connection_bloc.dart';
import '../../shared/ble_connection_bloc/ble_connection_event.dart';
import '../../shared/ble_connection_bloc/ble_connection_state.dart';

class EquipmentFinderScreen extends StatefulWidget {
  const EquipmentFinderScreen({super.key});

  @override
  State<EquipmentFinderScreen> createState() => _EquipmentFinderScreenState();
}

class _EquipmentFinderScreenState extends State<EquipmentFinderScreen> {
  final BleService _bleService = getIt<BleService>();
  bool _hasPermissions = false;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _checkAndRequestPermissions();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    // ИСПРАВЛЕНО: Добавлен unawaited, так как stopScan возвращает Future, а dispose не может быть async
    unawaited(_bleService.stopScan());
    super.dispose();
  }

  Future<void> _checkAndRequestPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    bool allGranted = false;

    if (Platform.isAndroid) {
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      allGranted = statuses.values.every((status) => status.isGranted);
    } else if (Platform.isIOS) {
      final PermissionStatus bluetoothStatus = await Permission.bluetooth
          .request();
      allGranted = bluetoothStatus.isGranted;
    }

    if (mounted) {
      setState(() {
        _hasPermissions = allGranted;
        _isCheckingPermissions = false;
      });

      // ИСПРАВЛЕНО: Добавлен оператор `await` для удовлетворения правила unawaited_futures.
      // Поскольку это последний вызов в async методе, выполнение не заблокирует интерфейс.
      if (_hasPermissions) {
        await _bleService.startScan();
      }
    }
  }

  IconData _getEquipmentIcon(EquipmentType type) {
    switch (type) {
      case EquipmentType.rower:
        return Icons.rowing;
      case EquipmentType.bike:
        return Icons.directions_bike;
      case EquipmentType.treadmill:
        return Icons.directions_run;
      case EquipmentType.stepper:
        return Icons.height;
      default:
        return Icons.bluetooth;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasPermissions) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gpp_bad, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text(
                'Доступ к Bluetooth отклонен',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Для поиска спортивных тренажеров приложению ZonEx необходимы разрешения на работу с Bluetooth.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Открыть настройки'),
                onPressed: () => openAppSettings(),
              ),
              TextButton(
                onPressed: _checkAndRequestPermissions,
                child: const Text('Повторить запрос'),
              ),
            ],
          ),
        ),
      );
    }

    return BlocListener<BleConnectionBloc, BleConnectionState>(
      listener: (context, state) {
        if (state is BleConnectionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: StreamBuilder<List<ScanResult>>(
        stream: _bleService.scanResults,
        builder: (context, snapshot) {
          final results = snapshot.data ?? [];

          if (results.isEmpty) {
            return const Center(
              child: Text(
                'Тренажеры поблизости не найдены',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 120, top: 8),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final r = results[index];
              final currentAddress = r.device.remoteId.toString();

              final parser = BleParserFactory.getParser(
                r.advertisementData.advName,
                r.advertisementData.manufacturerData,
                r.advertisementData.serviceUuids
                    .map((e) => e.toString())
                    .toList(),
              );
              final type = parser?.type ?? EquipmentType.unknown;

              return BlocBuilder<BleConnectionBloc, BleConnectionState>(
                builder: (context, state) {
                  Color iconColor = Colors.grey;
                  bool isThisConnecting = false;

                  if (state is BleConnected &&
                      state.deviceAddress == currentAddress) {
                    iconColor = Colors.green;
                  } else if (state is BleConnecting &&
                      state.connectingAddress == currentAddress) {
                    iconColor = Colors.orangeAccent;
                    isThisConnecting = true;
                  }

                  return ListTile(
                    title: Text(
                      r.advertisementData.advName.isEmpty
                          ? 'Unknown Device'
                          : r.advertisementData.advName,
                    ),
                    subtitle: const Text('(currentAddress\nRSSI:){r.rssi} dBm'),
                    trailing: isThisConnecting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Icon(
                            _getEquipmentIcon(type),
                            color: iconColor,
                            size: 28,
                          ),
                    onTap: isThisConnecting
                        ? null
                        : () {
                            context.read<BleConnectionBloc>().add(
                              ConnectToDevice(currentAddress),
                            );
                          },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
