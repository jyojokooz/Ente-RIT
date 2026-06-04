// ===============================
// FILE NAME: auth_service.dart
// FILE PATH: lib/features/auth/data/auth_service.dart
// ===============================

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Signs a new user up with Name, Email, Password, and Username.
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
    String username,
    String name,
  ) async {
    if (!email.trim().toLowerCase().endsWith('@rit.ac.in')) {
      throw Exception(
        'Only @rit.ac.in institution emails are allowed for sign up.',
      );
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;

        await user.updateDisplayName(name);

        // Send email verification link
        await user.sendEmailVerification();

        final finalUsername =
            username.trim().isNotEmpty
                ? username.trim()
                : email.split('@').first;

        await _firestore.collection('users').doc(user.uid).set({
          'displayName': name.trim(),
          'email': user.email,
          'uid': user.uid,
          'profilePhotoUrl': user.photoURL ?? '',
          'lastLogin': Timestamp.now(),
          'createdAt': Timestamp.now(),
          'username': finalUsername,
          'searchableUsername': finalUsername.toLowerCase(),
          'searchableDisplayName': name.trim().toLowerCase(),
          'role': 'student',
          'isPrivate': false, // <-- Added default value
          'isAdmin': false, // <-- Added default value
        });

        log('New user signed up: $name ($finalUsername)', name: 'AuthService');
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'An unknown sign-up error occurred.');
    } catch (e) {
      log('Sign-up error: $e', name: 'AuthService');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      log('Error during sign out: $e', name: 'AuthService');
    }
  }
}
