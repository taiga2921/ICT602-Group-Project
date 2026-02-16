import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/event_model.dart';
import '../../models/attendance_model.dart';
import '../../services/ble_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/gps_service.dart';

class CheckInScreen extends StatefulWidget {
  final EventModel event;

  const CheckInScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _bleService = BleService();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _gpsService = GpsService();

  bool _isScanning = false;
  bool _hasCheckedIn = false;
  String _statusMessage = 'Initializing...';
  StreamSubscription? _beaconSubscription;
  Position? _currentLocation;
  String _gpsStatus = 'Getting GPS location...';

  @override
  void initState() {
    super.initState();
    _initializeCheckIn();
  }

  @override
  void dispose() {
    _beaconSubscription?.cancel();
    _bleService.stopScanning();
    super.dispose();
  }

  Future<void> _initializeCheckIn() async {
    // Get GPS location first
    try {
      Position? position = await _gpsService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentLocation = position;
          _gpsStatus =
              'GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        });
      } else {
        setState(() {
          _gpsStatus = 'GPS location unavailable';
        });
      }
    } catch (e) {
      setState(() {
        _gpsStatus = 'GPS error: $e';
      });
    }

    // Check if user already checked in
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _statusMessage = 'User not authenticated';
      });
      return;
    }

    final alreadyCheckedIn = await _firestoreService.hasUserCheckedIn(
      userId,
      widget.event.id,
    );

    if (alreadyCheckedIn) {
      setState(() {
        _hasCheckedIn = true;
        _statusMessage = 'You have already checked in to this event';
      });
      return;
    }

    // Check if event is active
    if (!widget.event.isEventActive()) {
      setState(() {
        _statusMessage = 'Event is not currently active';
      });
      return;
    }

    // Request permissions and start scanning
    await _startBleScanning();
  }

  Future<void> _startBleScanning() async {
    setState(() {
      _statusMessage = 'Checking permissions...';
    });

    // Check if Bluetooth is supported
    final isSupported = await _bleService.isBluetoothSupported();
    if (!isSupported) {
      setState(() {
        _statusMessage = 'Bluetooth is not supported on this device';
      });
      return;
    }

    // Request Bluetooth and Location permissions
    final hasPermissions = await _bleService.requestPermissions();
    if (!hasPermissions) {
      setState(() {
        _statusMessage = 'Permissions not granted';
      });
      _showPermissionDialog();
      return;
    }

    // Also ensure GPS service can access location
    final gpsPermission = await _gpsService.checkPermission();
    if (gpsPermission == LocationPermission.denied ||
        gpsPermission == LocationPermission.deniedForever) {
      setState(() {
        _statusMessage = 'Location permission required for GPS tracking';
      });
      _showPermissionDialog();
      return;
    }

    // Check if Bluetooth is enabled
    final isEnabled = await _bleService.isBluetoothEnabled();
    if (!isEnabled) {
      setState(() {
        _statusMessage = 'Please enable Bluetooth';
      });
      await _bleService.enableBluetooth();
      return;
    }

    // Check if Location service is enabled
    final locationEnabled = await _gpsService.isLocationServiceEnabled();
    if (!locationEnabled) {
      setState(() {
        _statusMessage = 'Please enable Location services';
      });
      final opened = await _gpsService.openLocationSettings();
      if (!opened) {
        _showLocationSettingsDialog();
      }
      return;
    }

    // Start scanning
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for beacon...';
    });

    final started = await _bleService.startScanning();
    if (!started) {
      setState(() {
        _statusMessage = 'Failed to start scanning';
        _isScanning = false;
      });
      return;
    }

    // Listen for beacon detection
    _beaconSubscription = _bleService.beaconStream.listen((result) {
      if (!_hasCheckedIn) {
        _handleBeaconDetected(result);
      }
    });

    // Auto-restart scanning
    _startContinuousScanning();
  }

  void _startContinuousScanning() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted || _hasCheckedIn) {
        timer.cancel();
        return;
      }

      if (_isScanning) {
        _bleService.stopScanning().then((_) {
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted && !_hasCheckedIn) {
              _bleService.startScanning();
            }
          });
        });
      }
    });
  }

  Future<void> _handleBeaconDetected(ScanResult result) async {
    setState(() {
      _statusMessage = 'Beacon detected! RSSI: ${result.rssi}';
    });

    // Verify conditions for check-in
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    // Check if event is still active
    if (!widget.event.isEventActive()) {
      setState(() {
        _statusMessage = 'Event time window has passed';
      });
      return;
    }

    // Check if already checked in (double-check)
    final alreadyCheckedIn = await _firestoreService.hasUserCheckedIn(
      userId,
      widget.event.id,
    );

    if (alreadyCheckedIn) {
      setState(() {
        _hasCheckedIn = true;
        _statusMessage = 'Already checked in';
      });
      return;
    }

    // Perform check-in
    await _performCheckIn(userId);
  }

  Future<void> _performCheckIn(String userId) async {
    setState(() {
      _statusMessage = 'Checking in...';
    });

    try {
      final user = _authService.currentUser;
      final attendance = AttendanceModel(
        id: '',
        userId: userId,
        eventId: widget.event.id,
        beaconId: '${BleService.BEACON_NAME}_${BleService.BEACON_MAC}',
        checkInTime: DateTime.now(),
        userEmail: user?.email,
        userName: user?.displayName,
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
      );

      final attendanceId = await _firestoreService.createAttendance(attendance);

      if (attendanceId != null) {
        setState(() {
          _hasCheckedIn = true;
          _statusMessage = 'Check-in successful!';
        });

        // Stop scanning
        await _bleService.stopScanning();
        _isScanning = false;

        // Show success dialog
        _showSuccessDialog();
      } else {
        setState(() {
          _statusMessage = 'Check-in failed. You may have already checked in.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during check-in: $e';
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permissions Required'),
        content: Text(
          'This app needs:\n\n'
          '• Bluetooth permission - to detect the beacon\n'
          '• Location permission - for BLE scanning and GPS tracking\n\n'
          'Please grant these permissions in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bleService.requestPermissions();
            },
            child: Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Services Disabled'),
        content: Text(
          'Please enable Location services in your device settings to use GPS tracking and BLE scanning.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _gpsService.openLocationSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 8),
            Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have successfully checked in to:'),
            SizedBox(height: 8),
            Text(
              widget.event.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Time: ${DateTime.now().toString().substring(0, 19)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _bleService.stopScanning();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Auto Check-In'),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isScanning && !_hasCheckedIn) ...[
                  Container(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.bluetooth_searching,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ] else if (_hasCheckedIn) ...[
                  Icon(
                    Icons.check_circle,
                    size: 120,
                    color: Colors.green,
                  ),
                ] else ...[
                  Icon(
                    Icons.bluetooth_disabled,
                    size: 120,
                    color: Colors.grey,
                  ),
                ],
                SizedBox(height: 32),
                if (_currentLocation != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.gps_fixed,
                                color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'GPS Location Captured',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          _gpsStatus,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 16),
                Text(
                  widget.event.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 32),
                if (_isScanning && !_hasCheckedIn)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Move closer to the entrance. Check-in will happen automatically.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!_isScanning && !_hasCheckedIn)
                  ElevatedButton.icon(
                    onPressed: _startBleScanning,
                    icon: Icon(Icons.refresh),
                    label: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
