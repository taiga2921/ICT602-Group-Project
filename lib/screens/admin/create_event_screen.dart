import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/gps_service.dart';
import '../../models/event_model.dart';
import '../../widgets/custom_button.dart';
import 'package:geolocator/geolocator.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _gpsService = GpsService();

  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  final _beaconUuidController = TextEditingController();
  final _beaconMajorController = TextEditingController();
  final _beaconMinorController = TextEditingController();

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay(hour: 23, minute: 59);

  bool _isLoading = false;
  Position? _currentLocation;
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _beaconUuidController.dispose();
    _beaconMajorController.dispose();
    _beaconMinorController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      Position? position = await _gpsService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentLocation = position;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location captured successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location. Please enable GPS.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        throw Exception('End time must be after start time');
      }

      final event = EventModel(
        id: '',
        name: _nameController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
        venue: _venueController.text.trim(),
        beaconUuid: _beaconUuidController.text.trim().isEmpty
            ? 'N/A'
            : _beaconUuidController.text.trim(),
        beaconMajor: _beaconMajorController.text.isEmpty
            ? 0
            : int.parse(_beaconMajorController.text),
        beaconMinor: _beaconMinorController.text.isEmpty
            ? 0
            : int.parse(_beaconMinorController.text),
        isActive: true,
        createdAt: DateTime.now(),
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
      );

      await _firestoreService.createEvent(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Event'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text(
              'Event Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Event Name',
                prefixIcon: Icon(Icons.event),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter event name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _venueController,
              decoration: InputDecoration(
                labelText: 'Venue / Entrance',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter venue';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            Text(
              'GPS Location (Optional)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  if (_currentLocation != null) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Latitude: ${_currentLocation!.latitude.toStringAsFixed(6)}',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Longitude: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.my_location),
                    label: Text(_currentLocation == null
                        ? 'Capture Event Location'
                        : 'Update Location'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Date & Time',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text('Start Date'),
                    subtitle: Text(dateFormat.format(_startDate)),
                    leading: Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, true),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    title: Text('Start Time'),
                    subtitle: Text(timeFormat.format(DateTime(
                      2024,
                      1,
                      1,
                      _startTime.hour,
                      _startTime.minute,
                    ))),
                    leading: Icon(Icons.access_time),
                    onTap: () => _selectTime(context, true),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text('End Date'),
                    subtitle: Text(dateFormat.format(_endDate)),
                    leading: Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    title: Text('End Time'),
                    subtitle: Text(timeFormat.format(DateTime(
                      2024,
                      1,
                      1,
                      _endTime.hour,
                      _endTime.minute,
                    ))),
                    leading: Icon(Icons.access_time),
                    onTap: () => _selectTime(context, false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Beacon Configuration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'UUID, Major, and Minor are optional. The app uses hardcoded beacon MAC address (D2:4B:C0:EA:3E:FE) for detection. These fields are for documentation only.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _beaconUuidController,
              decoration: InputDecoration(
                labelText: 'Beacon UUID (Optional)',
                prefixIcon: Icon(Icons.bluetooth),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: 'e.g., FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
                helperText: 'Leave blank if unknown',
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _beaconMajorController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Major (Optional)',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      helperText: 'Leave blank if unknown',
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _beaconMinorController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Minor (Optional)',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      helperText: 'Leave blank if unknown',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            CustomButton(
              text: 'Create Event',
              onPressed: _createEvent,
              isLoading: _isLoading,
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}
