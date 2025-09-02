// lib/auth/auth_service.dart

import 'dart:developer'; // <<< --- THIS IS THE CORRECTED IMPORT ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// AuthService handles all Firebase Authentication logic, including syncing
/// user profiles to Firestore.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Signs the user in with their Google account.
  /// On EVERY successful sign-in, it creates or updates the user's profile
  /// in the Firestore 'users' collection. This is a robust "upsert" operation.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Sign out first to always show the Google account picker.
      await _googleSignIn.signOut();

      // Start the Google Sign-In flow.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in process.
        return null;
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

      // --- THE ROBUST FIX: CREATE OR UPDATE USER PROFILE ---
      // This logic runs on every successful sign-in to guarantee that a
      // user profile exists in Firestore and that their name is up-to-date.
      if (userCredential.user != null) {
        // The 'log' method now works because of the correct import.
        log(
          'Upserting user profile for ${userCredential.user!.uid}',
          name: 'AuthService',
        );

        final userDocRef = _firestore
            .collection('users')
            .doc(userCredential.user!.uid);

        // Use .set() with SetOptions(merge: true).
        // This creates the document if it's missing.
        // If it already exists, it updates the fields specified without
        // overwriting other fields (like a manually set 'isAdmin' flag).
        await userDocRef.set({
          'name': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'uid': userCredential.user!.uid,
          'lastLogin': Timestamp.now(), // Good practice to track user activity.
        }, SetOptions(merge: true));
      }
      // --- END OF THE ROBUST FIX ---

      return userCredential;
    } catch (e) {
      // The 'log' method now works here too.
      log('Google sign-in error: $e', name: 'AuthService');
      return null;
    }
  }

  /// Signs the current user out from both Firebase and Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
