// ===============================
// FILE NAME: index.js
// FILE PATH: functions/index.js
// ===============================

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

// IMPORTS FOR EMAIL OTP
const nodemailer = require("nodemailer");
const cors = require("cors")({
  origin: [
    "https://fir-auth-bfed9.web.app",
    "https://fir-auth-bfed9.firebaseapp.com",
  ],
});

const OTP_WINDOW_MS = 10 * 60 * 1000;
const OTP_MAX_REQUESTS = 5;
const otpRequestTracker = new Map();

function isOtpRateLimited(identifier) {
  const now = Date.now();
  const record = otpRequestTracker.get(identifier);

  if (!record || now - record.windowStart > OTP_WINDOW_MS) {
    otpRequestTracker.set(identifier, {count: 1, windowStart: now});
    return false;
  }

  if (record.count >= OTP_MAX_REQUESTS) {
    return true;
  }

  record.count += 1;
  return false;
}

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

/**
 * 4. SECURE OTP EMAIL SENDER (V1 - HTTP API)
 */
exports.sendOtpEmail = functions
  .runWith({ secrets: ["SMTP_EMAIL", "SMTP_PASSWORD"] })
  .https.onRequest((req, res) => {
    cors(req, res, async () => {
      if (req.method !== "POST") {
        return res.status(405).send({ error: "Only POST requests accepted" });
      }

      const { email, name, otp } = req.body;

      if (!email || !otp) {
        return res.status(400).send({ error: "Email and OTP are required" });
      }

      const normalizedEmail = String(email).trim().toLowerCase();
      const otpCode = String(otp).trim();
      const clientIp =
        (req.headers["x-forwarded-for"] || "").toString().split(",")[0].trim() ||
        req.ip ||
        "unknown";

      if (!normalizedEmail.endsWith("@rit.ac.in")) {
        return res.status(403).send({ error: "Unauthorized domain." });
      }
      if (!/^\d{4,8}$/.test(otpCode)) {
        return res.status(400).send({ error: "Invalid OTP format." });
      }
      if (isOtpRateLimited(`${normalizedEmail}:${clientIp}`)) {
        return res.status(429).send({ error: "Too many OTP requests. Try later." });
      }

      // Read secrets securely
      const senderEmail = process.env.SMTP_EMAIL;
      const senderPassword = process.env.SMTP_PASSWORD;

      // Configure NodeMailer
      const transporter = nodemailer.createTransport({
        service: "gmail",
        auth: {
          user: senderEmail,
          pass: senderPassword, // This MUST be the 16-character App Password
        },
      });

      const mailOptions = {
        from: `"Ente RIT Support" <${senderEmail}>`,
        to: normalizedEmail,
        subject: "Your Verification Code for Ente RIT",
        html: `
          <div style="font-family: Arial, sans-serif; padding: 20px;">
            <h2>Welcome to Ente RIT!</h2>
            <p>Hi ${name || "there"},</p>
            <p>Your verification code is:</p>
            <h1 style="letter-spacing: 5px;">${otpCode}</h1>
            <p>This code expires in 10 minutes.</p>
          </div>
        `,
      };

      try {
        await transporter.sendMail(mailOptions);
        console.log("Email sent successfully to:", normalizedEmail);
        return res.status(200).send({ success: true });
      } catch (error) {
        console.error("SMTP ERROR:", error);
        return res.status(500).send({ error: "Failed to send email" });
      }
    });
  });
