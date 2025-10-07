// lib/auth/auth_service.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// AuthService handles all Firebase Authentication logic, including syncing
/// user profiles to Firestore in a way that supports the username creation flow.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Signs the user in with their Google account.
  ///
  /// This method now includes logic to differentiate between a new user
  /// and a returning user to support the mandatory username creation step.
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

      // --- MODIFIED LOGIC FOR USERNAME FLOW ---
      // After signing in, we check if this is the user's first time.
      if (userCredential.user != null) {
        final userDocRef = _firestore
            .collection('users')
            .doc(userCredential.user!.uid);

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
            'profilePhotoUrl':
                userCredential.user!.photoURL, // Pre-fill with Google photo
            'lastLogin': Timestamp.now(),
            'createdAt': Timestamp.now(),
            // 'username' is intentionally omitted to trigger the setup flow.
          });
        }
        // SCENARIO 2: RETURNING USER
        // If the document already exists, they are a returning user.
        // We simply update their last login time and don't touch anything else.
        else {
          log(
            'Returning user detected: ${userCredential.user!.uid}. Updating last login.',
            name: 'AuthService',
          );
          await userDocRef.update({'lastLogin': Timestamp.now()});
        }
      }
      // --- END OF MODIFIED LOGIC ---

      return userCredential;
    } catch (e) {
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
