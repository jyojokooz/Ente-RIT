// ===============================
// FILE NAME: auth_service.dart
// FILE PATH: C:\kampus_konnect\appmaking2\lib\auth\auth_service.dart
// ===============================

import 'dart:developer';
import 'package:flutter/services.dart'; // Required for PlatformException
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// AuthService handles all Firebase Authentication logic, including syncing
/// user profiles to Firestore in a way that supports the username creation flow.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- CRITICAL CHANGE ---
  // Initialize GoogleSignIn with the Web Client ID.
  // This is essential for release builds to work correctly.
  // Replace the placeholder with your actual Web Client ID from the Google Cloud Console.
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Signs a new user up with their Email & Password.
  /// Enforces RIT email and auto-creates the user profile with a username.
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // --- RIT EMAIL VALIDATION ---
    if (!email.trim().toLowerCase().endsWith('@rit.ac.in')) {
      throw Exception('Only emails from rit.ac.in are allowed for sign up.');
    }

    try {
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
          'displayName': user.displayName ?? '', // User will set this later
          'email': user.email,
          'uid': user.uid,
          'profilePhotoUrl': user.photoURL ?? '',
          'lastLogin': Timestamp.now(),
          'createdAt': Timestamp.now(),
          'username': username, // Set auto-generated username
          'role': 'student', // Assign default role
        });
        log(
          'New user signed up and profile created for $username',
          name: 'AuthService',
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Re-throw with a more user-friendly message
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
  /// Enforces RIT email and auto-creates the user profile with a username for new users.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // It's good practice to sign out first to ensure the account picker is always shown.
      await _googleSignIn.signOut();

      // Start the Google Sign-In flow.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in process.
        log('Google Sign-In was cancelled by the user.', name: 'AuthService');
        return null;
      }

      // --- RIT EMAIL VALIDATION ---
      if (!googleUser.email.toLowerCase().endsWith('@rit.ac.in')) {
        await _googleSignIn.signOut(); // Sign them out immediately
        throw Exception('Only Google accounts from rit.ac.in are allowed.');
      }

      // Get the authentication tokens from the Google user.
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential.
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      log(
        'Successfully signed in to Firebase with Google.',
        name: 'AuthService',
      );

      // --- USER PROFILE HANDLING LOGIC ---
      // After signing in, check if this is the user's first time.
      if (userCredential.user != null) {
        final userDocRef = _firestore
            .collection('users')
            .doc(userCredential.user!.uid);

        final docSnapshot = await userDocRef.get();

        // SCENARIO 1: NEW USER
        if (!docSnapshot.exists) {
          log(
            'New user detected via Google. Creating profile for ${userCredential.user!.uid}.',
            name: 'AuthService',
          );
          // Auto-generate username from email prefix
          final username = userCredential.user!.email!.split('@').first;
          await userDocRef.set({
            'displayName': userCredential.user!.displayName,
            'email': userCredential.user!.email,
            'uid': userCredential.user!.uid,
            'profilePhotoUrl': userCredential.user!.photoURL,
            'lastLogin': Timestamp.now(),
            'createdAt': Timestamp.now(),
            'username': username, // Set auto-generated username
            'role': 'student', // Assign default role
          });
        }
        // SCENARIO 2: RETURNING USER
        else {
          log(
            'Returning user detected: ${userCredential.user!.uid}. Updating last login.',
            name: 'AuthService',
          );
          await userDocRef.update({'lastLogin': Timestamp.now()});
        }
      }
      // --- END OF USER PROFILE LOGIC ---

      return userCredential;
    } on PlatformException catch (error) {
      log(
        'Google Sign-In failed with a PlatformException. THIS IS THE KEY ERROR!',
        name: 'AuthService',
      );
      log('Error Code: ${error.code}', name: 'AuthService');
      log('Error Message: ${error.message}', name: 'AuthService');
      throw Exception(
        'A platform error occurred during sign-in. Please try again.',
      );
    } catch (e) {
      log(
        'An unexpected error occurred during Google sign-in: $e',
        name: 'AuthService',
      );
      // Re-throw the specific exception message if it came from our validation
      if (e is Exception) {
        rethrow;
      }
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Signs the current user out from both Firebase and Google.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      log('User successfully signed out.', name: 'AuthService');
    } catch (e) {
      log('Error during sign out: $e', name: 'AuthService');
    }
  }
}
