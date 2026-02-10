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

      // Wait a moment for auth state to settle
      await Future.delayed(Duration(milliseconds: 300));

      User? user = _auth.currentUser; // Use currentUser instead of result.user

      if (user != null) {
        // Try to get user data from Firestore
        try {
          DocumentSnapshot doc =
              await _firestore.collection('users').doc(user.uid).get();

          if (doc.exists && doc.data() != null) {
            final data = doc.data();
            if (data is Map<String, dynamic>) {
              print('User data loaded from Firestore');
              return UserModel.fromMap(data);
            }
          }
        } catch (firestoreError) {
          print('Firestore read error: $firestoreError');
        }

        // If user doc doesn't exist or error occurred, create it
        print('Creating new user document in Firestore');
        UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          isAdmin: false,
          displayName: user.displayName,
        );

        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap(), SetOptions(merge: true));
          print('User document created successfully');
        } catch (writeError) {
          print('Firestore write error: $writeError');
        }

        return newUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Sign in error: ${e.runtimeType} - $e');
      // If it's the type cast error, ignore it and proceed
      if (e.toString().contains('PigeonUserDetails')) {
        print('Ignoring PigeonUserDetails error, using currentUser');

        // Wait and use currentUser
        await Future.delayed(Duration(milliseconds: 500));
        User? user = _auth.currentUser;

        if (user != null) {
          // Get from Firestore
          try {
            DocumentSnapshot doc =
                await _firestore.collection('users').doc(user.uid).get();

            if (doc.exists && doc.data() != null) {
              final data = doc.data();
              if (data is Map<String, dynamic>) {
                return UserModel.fromMap(data);
              }
            }
          } catch (_) {}

          // Return basic user model
          return UserModel(
            uid: user.uid,
            email: user.email ?? '',
            isAdmin: false,
            displayName: user.displayName,
          );
        }
      }
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
