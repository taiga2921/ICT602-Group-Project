import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final String eventId;
  final String beaconId;
  final DateTime checkInTime;
  final String? userEmail;
  final String? userName;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.beaconId,
    required this.checkInTime,
    this.userEmail,
    this.userName,
  });

  // Convert AttendanceModel to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'beaconId': beaconId,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'userEmail': userEmail,
      'userName': userName,
    };
  }

  // Create AttendanceModel from Firebase Map
  factory AttendanceModel.fromMap(String id, Map<String, dynamic> map) {
    return AttendanceModel(
      id: id,
      userId: map['userId'] ?? '',
      eventId: map['eventId'] ?? '',
      beaconId: map['beaconId'] ?? '',
      checkInTime: (map['checkInTime'] as Timestamp).toDate(),
      userEmail: map['userEmail'],
      userName: map['userName'],
    );
  }

  // Copy with method
  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? beaconId,
    DateTime? checkInTime,
    String? userEmail,
    String? userName,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      beaconId: beaconId ?? this.beaconId,
      checkInTime: checkInTime ?? this.checkInTime,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
    );
  }
}
