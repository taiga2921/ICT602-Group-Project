import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../models/event_model.dart';
import '../../models/attendance_model.dart';
import '../../services/ble_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class CheckInScreen extends StatefulWidget {
  final EventModel event;

  const CheckInScreen({super.key, required this.event});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _bleService = BleService();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  bool _isScanning = false;
  bool _hasCheckedIn = false;
  String _statusMessage = 'Initializing...';
  StreamSubscription? _beaconSubscription;

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
      _statusMessage = 'Checking Bluetooth permissions...';
    });

    // Check if Bluetooth is supported
    final isSupported = await _bleService.isBluetoothSupported();
    if (!isSupported) {
      setState(() {
        _statusMessage = 'Bluetooth is not supported on this device';
      });
      return;
    }

    // Request permissions
    final hasPermissions = await _bleService.requestPermissions();
    if (!hasPermissions) {
      setState(() {
        _statusMessage = 'Bluetooth permissions not granted';
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
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _hasCheckedIn) {
        timer.cancel();
        return;
      }

      if (_isScanning) {
        _bleService.stopScanning().then((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
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
        title: const Text('Permissions Required'),
        content: const Text(
          'This app needs Bluetooth and Location permissions to detect the beacon for automatic check-in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
        title: const Row(
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
            const Text('You have successfully checked in to:'),
            const SizedBox(height: 8),
            Text(
              widget.event.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
            child: const Text('Done'),
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
          title: const Text('Auto Check-In'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isScanning && !_hasCheckedIn) ...[
                  SizedBox(
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
                  const Icon(
                    Icons.check_circle,
                    size: 120,
                    color: Colors.green,
                  ),
                ] else ...[
                  const Icon(
                    Icons.bluetooth_disabled,
                    size: 120,
                    color: Colors.grey,
                  ),
                ],
                const SizedBox(height: 32),
                Text(
                  widget.event.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 32),
                if (_isScanning && !_hasCheckedIn)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
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
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
