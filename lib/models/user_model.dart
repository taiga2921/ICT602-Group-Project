class UserModel {
  final String uid;
  final String email;
  final bool isAdmin;
  final String? displayName;

  UserModel({
    required this.uid,
    required this.email,
    required this.isAdmin,
    this.displayName,
  });

  // Convert UserModel to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'isAdmin': isAdmin,
      'displayName': displayName,
    };
  }

  // Create UserModel from Firebase Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      displayName: map['displayName'],
    );
  }

  // Copy with method for updating user properties
  UserModel copyWith({
    String? uid,
    String? email,
    bool? isAdmin,
    String? displayName,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      displayName: displayName ?? this.displayName,
    );
  }
}
