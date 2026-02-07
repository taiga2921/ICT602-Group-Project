import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserModel?> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            return UserModel.fromMap(data);
          }
        }

        // Create new user document if it doesn't exist
        UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          isAdmin: false,
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
      return null;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailPassword(String email, String password,
      {bool isAdmin = false}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Create user document in Firestore
        UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          isAdmin: isAdmin,
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
      return null;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          return UserModel.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin() async {
    if (currentUser == null) return false;
    UserModel? user = await getUserData(currentUser!.uid);
    return user?.isAdmin ?? false;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }
}
