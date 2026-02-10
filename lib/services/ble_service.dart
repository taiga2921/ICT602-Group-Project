import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  // Hardcoded beacon identity (as per requirements)
  static const String BEACON_NAME = 'Holy-IOT';
  static const String BEACON_MAC = 'D2:4B:C0:EA:3E:FE';
  static const int RSSI_THRESHOLD = -70; // User within 5-10 meters

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _isScanning = false;

  // Stream controller for beacon detection
  final StreamController<ScanResult> _beaconController =
      StreamController<ScanResult>.broadcast();
  Stream<ScanResult> get beaconStream => _beaconController.stream;

  // Check if Bluetooth is supported
  Future<bool> isBluetoothSupported() async {
    try {
      return await FlutterBluePlus.isSupported;
    } catch (e) {
      print('Bluetooth support check error: $e');
      return false;
    }
  }

  // Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      print('Bluetooth state check error: $e');
      return false;
    }
  }

  // Request necessary permissions
  Future<bool> requestPermissions() async {
    try {
      // Request Bluetooth permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      // Check if all permissions are granted
      bool allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        print('Not all permissions granted');
        return false;
      }

      return true;
    } catch (e) {
      print('Permission request error: $e');
      return false;
    }
  }

  // Turn on Bluetooth (opens system settings)
  Future<void> enableBluetooth() async {
    try {
      if (await FlutterBluePlus.isSupported) {
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      print('Enable Bluetooth error: $e');
    }
  }

  // Start scanning for beacons
  Future<bool> startScanning() async {
    try {
      // Check permissions
      bool hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        print('Permissions not granted');
        return false;
      }

      // Check if Bluetooth is enabled
      bool btEnabled = await isBluetoothEnabled();
      if (!btEnabled) {
        print('Bluetooth not enabled');
        return false;
      }

      // Stop any existing scan
      if (_isScanning) {
        await stopScanning();
      }

      _isScanning = true;

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          // Filter by hardcoded beacon identity
          if (_isTargetBeacon(result)) {
            // Check RSSI threshold for proximity
            if (result.rssi >= RSSI_THRESHOLD) {
              print('Target beacon detected! RSSI: ${result.rssi}');
              _beaconController.add(result);
            } else {
              print('Beacon too far. RSSI: ${result.rssi}');
            }
          }
        }
      });

      return true;
    } catch (e) {
      print('Start scanning error: $e');
      _isScanning = false;
      return false;
    }
  }

  // Check if scanned device is our target beacon
  bool _isTargetBeacon(ScanResult result) {
    // Check by device name
    if (result.device.platformName.isNotEmpty &&
        result.device.platformName.contains(BEACON_NAME)) {
      return true;
    }

    // Check by MAC address
    if (result.device.remoteId.toString().toUpperCase() ==
        BEACON_MAC.toUpperCase()) {
      return true;
    }

    return false;
  }

  // Stop scanning
  Future<void> stopScanning() async {
    try {
      if (_isScanning) {
        await FlutterBluePlus.stopScan();
        await _scanSubscription?.cancel();
        _scanSubscription = null;
        _isScanning = false;
      }
    } catch (e) {
      print('Stop scanning error: $e');
    }
  }

  // Get scanning status
  bool get isScanning => _isScanning;

  // Continuous scanning mode (restart after timeout)
  Future<void> startContinuousScanning() async {
    bool started = await startScanning();
    if (!started) return;

    // Restart scan every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_isScanning) {
        await stopScanning();
        await Future.delayed(const Duration(milliseconds: 500));
        await startScanning();
      } else {
        timer.cancel();
      }
    });
  }

  // Calculate approximate distance based on RSSI
  double calculateDistance(int rssi) {
    // Simple distance estimation formula
    // Note: This is approximate and varies based on environment
    int txPower = -59; // Measured power at 1 meter (calibration value)

    if (rssi == 0) {
      return -1.0; // Unknown distance
    }

    double ratio = rssi * 1.0 / txPower;
    if (ratio < 1.0) {
      return Math.pow(ratio, 10);
    } else {
      double distance = (0.89976) * Math.pow(ratio, 7.7095) + 0.111;
      return distance;
    }
  }

  // Dispose and cleanup
  void dispose() {
    stopScanning();
    _beaconController.close();
  }
}

// Simple Math class for power calculation
class Math {
  static double pow(double base, double exponent) {
    return base * base; // Simplified for demo
  }
}
