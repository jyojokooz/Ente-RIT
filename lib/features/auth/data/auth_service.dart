// ===============================
// FILE NAME: auth_service.dart
// FILE PATH: lib/features/auth/data/auth_service.dart
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

  /// Signs a new user up with Name, Email, Password, and Username.
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
    String username,
    String name,
  ) async {
    // 1. App-Level Security Check
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

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        // 2. Google Sign-In Security Logic
        // If it's a brand new user, enforce the @rit.ac.in rule.
        // If it's an existing user (e.g., admin added a @gmail.com account), allow login.
        if (isNewUser) {
          if (!user.email!.toLowerCase().endsWith('@rit.ac.in')) {
            // Revert the account creation immediately
            await user.delete();
            await _googleSignIn.signOut();
            await _auth.signOut();
            throw Exception(
              'Only @rit.ac.in emails are allowed for new accounts. Contact admin for exceptions.',
            );
          }
        }

        final userDocRef = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await userDocRef.get();

        if (!docSnapshot.exists) {
          final username = user.email!.split('@').first;
          await userDocRef.set({
            'displayName': user.displayName ?? 'User',
            'email': user.email,
            'uid': user.uid,
            'profilePhotoUrl': user.photoURL,
            'lastLogin': Timestamp.now(),
            'createdAt': Timestamp.now(),
            'username': username,
            'searchableUsername': username.toLowerCase(),
            'searchableDisplayName': (user.displayName ?? '').toLowerCase(),
            'role': 'student',
          });
        } else {
          await userDocRef.update({'lastLogin': Timestamp.now()});
        }
      }

      return userCredential;
    } on PlatformException catch (error) {
      log(
        'Google Sign-In Platform Exception: ${error.message}',
        name: 'AuthService',
      );
      throw Exception('A platform error occurred during sign-in.');
    } catch (e) {
      log('Unexpected error: $e', name: 'AuthService');
      // Forward the exact error message if it's our custom exception
      if (e.toString().contains('Only @rit.ac.in emails are allowed')) {
        rethrow;
      }
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
