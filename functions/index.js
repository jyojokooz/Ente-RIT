// ===============================
// FILE NAME: index.js
// FILE PATH: functions/index.js
// ===============================

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

// --- ROBUST INITIALIZATION ---
// This prevents the app from being initialized multiple times.
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// --- 1. Deletes user from Auth when Firestore doc is deleted ---
exports.deleteUserAccount = functions.firestore
  .document("users/{userId}")
  .onDelete(async (snap, context) => {
    const userId = context.params.userId;

    try {
      console.log(`Attempting to delete user from Auth: ${userId}`);
      await admin.auth().deleteUser(userId);
      console.log(`Successfully deleted user from Auth: ${userId}`);
      return null;
    } catch (error) {
      console.error(`Error deleting user from Auth for user ${userId}:`, error);
      return null;
    }
  });

// --- 2. Sends Push Notification when a notification doc is created ---
exports.sendPushNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notificationData = snapshot.data();
    if (!notificationData) {
      console.log("Notification data is empty.");
      return null;
    }

    const userId = notificationData.userId;
    if (!userId) {
      console.log("No userId found in notification data.");
      return null;
    }

    // Get the User's FCM Token from Firestore
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      console.log("No user found for ID:", userId);
      return null;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      console.log("No FCM Token found for user:", userId);
      return null;
    }

    // Construct the Message
    const message = {
      token: fcmToken,
      notification: {
        title: notificationData.title || "New Activity",
        body: notificationData.body || "You have a new notification.",
      },
      data: {
        type: notificationData.type || "general",
        relatedDocId: notificationData.relatedDocId || "",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    // Send the message
    try {
      await admin.messaging().send(message);
      console.log("Notification sent successfully to:", userId);
    } catch (error) {
      console.error(`Error sending notification to user ${userId}:`, error);
    }

    return null;
  });
