import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/attendance_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== EVENT OPERATIONS ==========

  // Create a new event
  Future<String> createEvent(EventModel event) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('events').add(event.toMap());
      return docRef.id;
    } catch (e) {
      print('Create event error: $e');
      rethrow;
    }
  }

  // Get all active events
  Stream<List<EventModel>> getActiveEvents() {
    return _firestore
        .collection('events')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      // Sort in code instead of Firestore query
      final events = snapshot.docs.map((doc) {
        return EventModel.fromMap(doc.id, doc.data());
      }).toList();

      // Sort by: 1) Active status first, 2) Start time descending (latest first)
      events.sort((a, b) {
        // First, sort by active status (active events first)
        bool aIsActive = a.isEventActive();
        bool bIsActive = b.isEventActive();

        if (aIsActive != bIsActive) {
          return bIsActive ? 1 : -1; // Active events come first
        }

        // Then sort by start time descending (latest first)
        return b.startTime.compareTo(a.startTime);
      });

      return events;
    });
  }

  // Get all events (for admin)
  Stream<List<EventModel>> getAllEvents() {
    return _firestore
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get single event by ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('events').doc(eventId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          return EventModel.fromMap(doc.id, data);
        }
      }
      return null;
    } catch (e) {
      print('Get event error: $e');
      return null;
    }
  }

  // Update event
  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('events').doc(eventId).update(data);
    } catch (e) {
      print('Update event error: $e');
      rethrow;
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      // First, delete all attendance records for this event
      QuerySnapshot attendanceQuery = await _firestore
          .collection('attendance')
          .where('eventId', isEqualTo: eventId)
          .get();

      // Delete all attendance records in a batch
      WriteBatch batch = _firestore.batch();
      for (var doc in attendanceQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Then delete the event itself
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      print('Delete event error: $e');
      rethrow;
    }
  }

  // ========== ATTENDANCE OPERATIONS ==========

  // Check if user already checked in for event
  Future<bool> hasUserCheckedIn(String userId, String eventId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Check attendance error: $e');
      return false;
    }
  }

  // Create attendance record (check-in)
  Future<String?> createAttendance(AttendanceModel attendance) async {
    try {
      // Double-check if user already checked in
      bool alreadyCheckedIn =
          await hasUserCheckedIn(attendance.userId, attendance.eventId);

      if (alreadyCheckedIn) {
        print('User already checked in for this event');
        return null;
      }

      DocumentReference docRef =
          await _firestore.collection('attendance').add(attendance.toMap());

      return docRef.id;
    } catch (e) {
      print('Create attendance error: $e');
      rethrow;
    }
  }

  // Get attendance records for an event
  Stream<List<AttendanceModel>> getEventAttendance(String eventId) {
    return _firestore
        .collection('attendance')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
      // Sort in code instead of Firestore query
      final attendanceList = snapshot.docs.map((doc) {
        return AttendanceModel.fromMap(doc.id, doc.data());
      }).toList();

      // Sort by checkInTime descending (most recent first)
      attendanceList.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return attendanceList;
    });
  }

  // Get attendance count for an event
  Future<int> getEventAttendanceCount(String eventId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('attendance')
          .where('eventId', isEqualTo: eventId)
          .get();

      return query.docs.length;
    } catch (e) {
      print('Get attendance count error: $e');
      return 0;
    }
  }

  // Get user's attendance history
  Stream<List<AttendanceModel>> getUserAttendance(String userId) {
    return _firestore
        .collection('attendance')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      // Sort in code instead of Firestore query
      final attendanceList = snapshot.docs.map((doc) {
        return AttendanceModel.fromMap(doc.id, doc.data());
      }).toList();

      // Sort by checkInTime descending
      attendanceList.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return attendanceList;
    });
  }

  // Get specific attendance record
  Future<AttendanceModel?> getAttendanceRecord(
      String userId, String eventId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          return AttendanceModel.fromMap(doc.id, data);
        }
      }
      return null;
    } catch (e) {
      print('Get attendance record error: $e');
      return null;
    }
  }
}
