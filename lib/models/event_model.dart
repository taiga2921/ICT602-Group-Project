import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final String venue;
  final String beaconUuid;
  final int beaconMajor;
  final int beaconMinor;
  final bool isActive;
  final DateTime createdAt;
  final double? latitude; // GPS coordinates
  final double? longitude; // GPS coordinates

  EventModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.beaconUuid,
    required this.beaconMajor,
    required this.beaconMinor,
    required this.isActive,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  // Convert EventModel to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'venue': venue,
      'beaconUuid': beaconUuid,
      'beaconMajor': beaconMajor,
      'beaconMinor': beaconMinor,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create EventModel from Firebase Map
  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    return EventModel(
      id: id,
      name: map['name'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      venue: map['venue'] ?? '',
      beaconUuid: map['beaconUuid'] ?? '',
      beaconMajor: map['beaconMajor'] ?? 0,
      beaconMinor: map['beaconMinor'] ?? 0,
      isActive: map['isActive'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  // Check if event is currently active (within time window)
  bool isEventActive() {
    final now = DateTime.now();
    return isActive && now.isAfter(startTime) && now.isBefore(endTime);
  }

  // Copy with method
  EventModel copyWith({
    String? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    String? venue,
    String? beaconUuid,
    int? beaconMajor,
    int? beaconMinor,
    bool? isActive,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      venue: venue ?? this.venue,
      beaconUuid: beaconUuid ?? this.beaconUuid,
      beaconMajor: beaconMajor ?? this.beaconMajor,
      beaconMinor: beaconMinor ?? this.beaconMinor,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
