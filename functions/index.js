const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Triggered when a new chat message is created.
 * Sends a push notification to the recipient.
 */
exports.sendChatNotification = functions.firestore
  .document("issues/{issueId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const issueId = context.params.issueId;

    try {
      const issueSnap = await admin.firestore()
        .collection("issues").doc(issueId).get();
      if (!issueSnap.exists) return null;

      const issueData = issueSnap.data();
      let recipientId;

      if (message.isAdmin || message.senderId === issueData.assignedStaffId) {
        recipientId = issueData.createdBy;
      } else {
        recipientId = issueData.assignedStaffId;
      }

      if (!recipientId) return null;

      const userSnap = await admin.firestore()
        .collection("users").doc(recipientId).get();
      if (!userSnap.exists) return null;

      const fcmToken = userSnap.data().fcmToken;
      if (!fcmToken) return null;

      const payload = {
        notification: {
          title: `New message for: ${issueData.title}`,
          body: `${message.senderName}: ${message.text}`,
        },
        data: {
          issueId: issueId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      await admin.messaging().sendToDevice(fcmToken, payload);
      return null;
    } catch (error) {
      console.error("Error sending chat notification:", error);
      return null;
    }
  });

