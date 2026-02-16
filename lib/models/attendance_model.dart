import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final String eventId;
  final String beaconId;
  final DateTime checkInTime;
  final String? userEmail;
  final String? userName;
  final double? latitude; // User's GPS location at check-in
  final double? longitude; // User's GPS location at check-in

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.beaconId,
    required this.checkInTime,
    this.userEmail,
    this.userName,
    this.latitude,
    this.longitude,
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
      'latitude': latitude,
      'longitude': longitude,
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
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
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
    double? latitude,
    double? longitude,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      beaconId: beaconId ?? this.beaconId,
      checkInTime: checkInTime ?? this.checkInTime,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
