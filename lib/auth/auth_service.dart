// ===============================
// FILE NAME: auth_service.dart
// FILE PATH: lib/auth/auth_service.dart
// ===============================

import 'dart:developer';
import 'package:flutter/services.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Signs a new user up with their Email & Password.
  /// Allowed for ALL email domains.
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // --- REMOVED RIT EMAIL VALIDATION ---
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // --- NEW USER PROFILE CREATION ---
      if (userCredential.user != null) {
        final user = userCredential.user!;
        // Auto-generate username from email prefix
        final username = email.split('@').first;

        await _firestore.collection('users').doc(user.uid).set({
          'displayName': user.displayName ?? '', 
          'email': user.email,
          'uid': user.uid,
          'profilePhotoUrl': user.photoURL ?? '',
          'lastLogin': Timestamp.now(),
          'createdAt': Timestamp.now(),
          'username': username, 
          'role': 'student', 
        });
        log(
          'New user signed up and profile created for $username',
          name: 'AuthService',
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'An unknown sign-up error occurred.');
    } catch (e) {
      log(
        'An unexpected error occurred during email sign-up: $e',
        name: 'AuthService',
      );
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Signs the user in with their Google account.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      // --- REMOVED RIT EMAIL VALIDATION ---

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      
      // --- USER PROFILE HANDLING LOGIC ---
      if (userCredential.user != null) {
        final userDocRef = _firestore
            .collection('users')
            .doc(userCredential.user!.uid);

        final docSnapshot = await userDocRef.get();

        if (!docSnapshot.exists) {
          final username = userCredential.user!.email!.split('@').first;
          await userDocRef.set({
            'displayName': userCredential.user!.displayName,
            'email': userCredential.user!.email,
            'uid': userCredential.user!.uid,
            'profilePhotoUrl': userCredential.user!.photoURL,
            'lastLogin': Timestamp.now(),
            'createdAt': Timestamp.now(),
            'username': username,
            'role': 'student',
          });
        } else {
          await userDocRef.update({'lastLogin': Timestamp.now()});
        }
      }

      return userCredential;
    } on PlatformException catch (error) {
      log('Google Sign-In Platform Exception: ${error.message}', name: 'AuthService');
      throw Exception('A platform error occurred during sign-in.');
    } catch (e) {
      log('Unexpected error: $e', name: 'AuthService');
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      log('Error during sign out: $e', name: 'AuthService');
    }
  }
}