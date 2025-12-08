// ===============================
// FILE NAME: index.js
// FILE PATH: functions/index.js
// ===============================

// --- KEY FIX: Explicitly require v1 to avoid version conflicts ---
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

// Initialize Admin SDK once
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * 1. DELETE USER ACCOUNT TRIGGER (V1)
 */
exports.deleteUserAccount = functions.firestore
  .document("users/{userId}")
  .onDelete(async (snap, context) => {
    const userId = context.params.userId;
    try {
      console.log(`Attempting to delete Auth user: ${userId}`);
      await admin.auth().deleteUser(userId);
      console.log(`Successfully deleted Auth user: ${userId}`);
    } catch (error) {
      console.error("Error deleting user from Auth:", error);
    }
  });

/**
 * 2. SOCIAL NOTIFICATIONS TRIGGER (V1)
 */
exports.sendPushNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notificationData = snapshot.data();
    const userId = notificationData.userId;

    if (!userId) {
      console.log("No userId found in notification doc.");
      return;
    }

    try {
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (!userDoc.exists) return;

      const fcmToken = userDoc.data()?.fcmToken;

      if (!fcmToken) return;

      const message = {
        token: fcmToken,
        notification: {
          title: notificationData.title || "New Activity",
          body: notificationData.body || "You have a new notification.",
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          relatedDocId: notificationData.relatedDocId || "",
          type: notificationData.type || "general",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              contentAvailable: true,
            },
          },
        },
      };

      await admin.messaging().send(message);
      console.log(`Social notification sent to ${userId}`);
    } catch (error) {
      console.error("Error sending social notification:", error);
    }
  });

/**
 * 3. EVENT REMINDER TRIGGER (V1 - Manual Push)
 */
exports.sendEventReminder = functions.firestore
  .document("notification_requests/{requestId}")
  .onCreate(async (snapshot, context) => {
    const requestData = snapshot.data();

    if (requestData.status === "sent" || requestData.status === "error") {
      return;
    }

    const title = requestData.title;
    const body = requestData.body;

    console.log(`Processing broadcast: ${title}`);

    try {
      const usersSnapshot = await admin.firestore().collection("users").get();
      const tokens = [];

      usersSnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.fcmToken) {
          tokens.push(data.fcmToken);
        }
      });

      if (tokens.length === 0) {
        return snapshot.ref.update({ status: "no_tokens" });
      }

      const messages = tokens.map((token) => ({
        token: token,
        notification: {
          title: title,
          body: body,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "event_reminder",
          eventId: requestData.eventId || "",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
          },
        },
      }));

      const batchSize = 500;
      let successCount = 0;
      let failureCount = 0;

      for (let i = 0; i < messages.length; i += batchSize) {
        const batch = messages.slice(i, i + batchSize);
        const response = await admin.messaging().sendEach(batch);
        successCount += response.successCount;
        failureCount += response.failureCount;
      }

      return snapshot.ref.update({
        status: "sent",
        sentCount: successCount,
        failedCount: failureCount,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error("Error sending event broadcast:", error);
      return snapshot.ref.update({ status: "error", error: error.message });
    }
  });
