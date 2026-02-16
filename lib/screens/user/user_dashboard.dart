import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/event_model.dart';
import '../../models/attendance_model.dart';
import '../../widgets/event_card.dart';
import '../login_screen.dart';
import 'event_selection_screen.dart';
import 'package:intl/intl.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  int _selectedIndex = 0;

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Available Events' : 'My Attendance'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildEventsTab() : _buildAttendanceTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'My Attendance',
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return StreamBuilder<List<EventModel>>(
      stream: _firestoreService.getActiveEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No active events',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return EventCard(
              event: event,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventSelectionScreen(event: event),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return Center(child: Text('Not logged in'));
    }

    return StreamBuilder<List<AttendanceModel>>(
      stream: _firestoreService.getUserAttendance(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final attendanceList = snapshot.data ?? [];

        if (attendanceList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No attendance records',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Check in to events to see your history',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: attendanceList.length,
          itemBuilder: (context, index) {
            final attendance = attendanceList[index];
            final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

            return FutureBuilder<EventModel?>(
              future: _firestoreService.getEventById(attendance.eventId),
              builder: (context, eventSnapshot) {
                // Don't show anything while loading
                if (eventSnapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox.shrink();
                }

                // If event doesn't exist (deleted), don't show this attendance
                if (!eventSnapshot.hasData || eventSnapshot.data == null) {
                  return SizedBox.shrink(); // Hide this item
                }

                final event = eventSnapshot.data!;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check_circle, color: Colors.white),
                    ),
                    title: Text(
                      event.name,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Expanded(child: Text(event.venue)),
                          ],
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              dateFormat.format(attendance.checkInTime),
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Attended',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}