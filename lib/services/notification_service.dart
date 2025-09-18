import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_project/screens/post_detail_screen.dart';
import 'package:my_project/screens/pages/profile_screen.dart';

class NotificationService {
  // The instance of the local notifications plugin.
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // A global key to access the navigator for tap handling.
  static GlobalKey<NavigatorState>? navigatorKey;

  // A subscription to the Firestore stream, so we can start and stop it.
  static StreamSubscription<QuerySnapshot>? _notificationSubscription;

  /// Initializes the notification service.
  /// This should be called once in main.dart.
  static void init(GlobalKey<NavigatorState> key) {
    navigatorKey = key;

    // Settings for Android. 'app_icon' must be a drawable resource.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    // Settings for iOS/macOS.
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Initialize the plugin with the settings and the tap handler.
    _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );
  }

  /// Handles the navigation when a user taps on a notification.
  static void onNotificationTap(NotificationResponse response) {
    if (response.payload == null || response.payload!.isEmpty) return;

    final payloadData = jsonDecode(response.payload!);
    final String? type = payloadData['type'];
    final String? id = payloadData['id'];

    if (id == null) return;

    // Navigate to the appropriate screen based on the notification type.
    if (type == 'like' || type == 'comment') {
      navigatorKey?.currentState?.push(
        MaterialPageRoute(builder: (context) => PostDetailScreen(postId: id)),
      );
    } else if (type == 'follow') {
      navigatorKey?.currentState?.push(
        MaterialPageRoute(builder: (context) => ProfileScreen(userId: id)),
      );
    }
  }

  /// Starts listening for new notifications in Firestore for the current user.
  /// Should be called from the AuthGate when a user logs in.
  static void startListeningForNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // IMPORTANT: Cancel any previous listener before starting a new one.
    _notificationSubscription?.cancel();

    // Create a new listener for undelivered notifications.
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isDelivered', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final payload = jsonEncode({
              'type': data['type'],
              'id': data['relatedDocId'],
            });

            // Show the local notification on the device.
            showNotification(
              id: doc.id.hashCode,
              title: data['title'],
              body: data['body'],
              payload: payload,
            );

            // Mark as delivered to prevent re-showing.
            doc.reference.update({'isDelivered': true});
          }
        });
  }

  /// Stops the Firestore listener.
  /// Should be called from the AuthGate when a user logs out.
  static void stopListeningForNotifications() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  /// Displays a local notification on the device.
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'my_project_channel', // A unique ID for the channel.
          'My Project Notifications', // The channel name displayed to the user.
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
