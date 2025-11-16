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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '267885782991-prhluvmnmdrstfcmh1sd69i4j77m8qrb.apps.googleusercontent.com',
  );

  /// Signs the user in with their Google account.
  ///
  /// This method now includes logic to differentiate between a new user
  /// and a returning user to support the mandatory username creation step.
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
      log('Successfully signed in to Firebase with Google.', name: 'AuthService');

      // --- USER PROFILE HANDLING LOGIC ---
      // After signing in, check if this is the user's first time.
      if (userCredential.user != null) {
        final userDocRef =
            _firestore.collection('users').doc(userCredential.user!.uid);

        final docSnapshot = await userDocRef.get();

        // SCENARIO 1: NEW USER
        // If the document does NOT exist, it's their first time signing in.
        // We create their document but WITHOUT a 'username' field.
        // This will cause the AuthGate to redirect them to CreateUsernameScreen.
        if (!docSnapshot.exists) {
          log(
            'New user detected. Creating profile for ${userCredential.user!.uid} without a username.',
            name: 'AuthService',
          );
          await userDocRef.set({
            'displayName': userCredential.user!.displayName,
            'email': userCredential.user!.email,
            'uid': userCredential.user!.uid,
            'profilePhotoUrl': userCredential.user!.photoURL,
            'lastLogin': Timestamp.now(),
            'createdAt': Timestamp.now(),
            // 'username' is intentionally omitted to trigger the setup flow.
          });
        }
        // SCENARIO 2: RETURNING USER
        // If the document already exists, they are a returning user.
        // We simply update their last login time.
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
    }
    // --- CRITICAL CHANGE: DETAILED ERROR HANDLING ---
    // Catch the specific error from the native Google Sign-In SDK.
    on PlatformException catch (error) {
      log(
        'Google Sign-In failed with a PlatformException. THIS IS THE KEY ERROR!',
        name: 'AuthService',
      );
      // This will print the specific error code like '10' (DEVELOPER_ERROR)
      // or '8' (INTERNAL_ERROR) that tells us exactly what is wrong.
      log('Error Code: ${error.code}', name: 'AuthService');
      log('Error Message: ${error.message}', name: 'AuthService');
      log('Error Details: ${error.details}', name: 'AuthService');
      return null;
    }
    // Catch any other general errors.
    catch (e) {
      log('An unexpected error occurred during Google sign-in: $e', name: 'AuthService');
      return null;
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