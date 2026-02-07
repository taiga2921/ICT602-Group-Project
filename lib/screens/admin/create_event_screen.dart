import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/event_model.dart';
import '../../widgets/custom_button.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  final _beaconUuidController = TextEditingController();
  final _beaconMajorController = TextEditingController();
  final _beaconMinorController = TextEditingController();

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 59);

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _beaconUuidController.dispose();
    _beaconMajorController.dispose();
    _beaconMinorController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        beaconUuid: _beaconUuidController.text.trim(),
        beaconMajor: int.parse(_beaconMajorController.text),
        beaconMinor: int.parse(_beaconMinorController.text),
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createEvent(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
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
        title: const Text('Create Event'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Event Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Event Name',
                prefixIcon: const Icon(Icons.event),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _venueController,
              decoration: InputDecoration(
                labelText: 'Venue / Entrance',
                prefixIcon: const Icon(Icons.location_on),
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
            const SizedBox(height: 24),
            const Text(
              'Date & Time',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(dateFormat.format(_startDate)),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, true),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    title: const Text('Start Time'),
                    subtitle: Text(timeFormat.format(DateTime(
                      2024,
                      1,
                      1,
                      _startTime.hour,
                      _startTime.minute,
                    ))),
                    leading: const Icon(Icons.access_time),
                    onTap: () => _selectTime(context, true),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(dateFormat.format(_endDate)),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    title: const Text('End Time'),
                    subtitle: Text(timeFormat.format(DateTime(
                      2024,
                      1,
                      1,
                      _endTime.hour,
                      _endTime.minute,
                    ))),
                    leading: const Icon(Icons.access_time),
                    onTap: () => _selectTime(context, false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Beacon Configuration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _beaconUuidController,
              decoration: InputDecoration(
                labelText: 'Beacon UUID',
                prefixIcon: const Icon(Icons.bluetooth),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: 'e.g., FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter beacon UUID';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _beaconMajorController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Major',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _beaconMinorController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Minor',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
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
