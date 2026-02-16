import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../widgets/custom_button.dart';
import '../../services/ble_service.dart';
import '../../services/gps_service.dart';
import 'check_in_screen.dart';
import 'package:geolocator/geolocator.dart';

class EventSelectionScreen extends StatefulWidget {
  final EventModel event;

  const EventSelectionScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventSelectionScreen> createState() => _EventSelectionScreenState();
}

class _EventSelectionScreenState extends State<EventSelectionScreen> {
  final _bleService = BleService();
  final _gpsService = GpsService();

  Future<void> _startMonitoring() async {
    // Check and request permissions before navigating
    final blePermissions = await _bleService.requestPermissions();
    final gpsPermission = await _gpsService.requestPermission();

    if (!blePermissions || gpsPermission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bluetooth and Location permissions are required'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () async {
                await _bleService.requestPermissions();
              },
            ),
          ),
        );
      }
      return;
    }

    // Navigate to check-in screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckInScreen(event: widget.event),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.event.isEventActive()
                          ? 'ACTIVE NOW'
                          : 'UPCOMING', // ← widget.event
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.event.name, // ← widget.event
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildInfoTile(
                    Icons.location_on,
                    'Venue',
                    widget.event.venue,
                  ),
                  SizedBox(height: 16),
                  _buildInfoTile(
                    Icons.calendar_today,
                    'Date',
                    dateFormat.format(widget.event.startTime),
                  ),
                  SizedBox(height: 16),
                  _buildInfoTile(
                    Icons.access_time,
                    'Time',
                    '${timeFormat.format(widget.event.startTime)} - ${timeFormat.format(widget.event.endTime)}',
                  ),
                  SizedBox(height: 32),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Automatic check-in will start when you\'re near the event venue. Make sure Bluetooth and Location are enabled.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  CustomButton(
                    text: 'Start Monitoring',
                    icon: Icons.bluetooth_searching,
                    onPressed: _startMonitoring,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
