// We specifically require 'v1' to fix the TypeError
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

// This function listens for when a document is deleted from the 'users' collection
exports.deleteUserAccount = functions.firestore
  .document("users/{userId}")
  .onDelete(async (snap, context) => {
    const userId = context.params.userId;

    try {
      console.log(`Attempting to delete user from Auth: ${userId}`);

      // Delete the user from Firebase Authentication
      await admin.auth().deleteUser(userId);

      console.log(`Successfully deleted user from Auth: ${userId}`);
      return null;
    } catch (error) {
      console.error(`Error deleting user from Auth: ${error}`);
      return null;
    }
  });
