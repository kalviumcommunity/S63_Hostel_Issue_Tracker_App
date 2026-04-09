const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin for Cloud Environment
// (In production, Firebase automatically provides service account credentials)
admin.initializeApp();


const db = admin.firestore();
const fcm = admin.messaging();

/**
 * 📣 NOTIFY RECIPIENT ON NEW CHAT MESSAGE
 */
exports.onNewMessage = functions.firestore
  .document("issues/{issueId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const issueId = context.params.issueId;

    const issueDoc = await db.collection("issues").doc(issueId).get();
    if (!issueDoc.exists) return null;
    const issueData = issueDoc.data();

    const senderId = message.senderId;
    const tokens = [];

    // Case 1: Student sent -> Notify Admin & Staff
    if (senderId === issueData.createdBy) {
      const admins = await db.collection("users").where("role", "==", "admin").get();
      admins.forEach(doc => { if (doc.data().fcmToken) tokens.push(doc.data().fcmToken); });

      if (issueData.assignedStaffId) {
        const staffDoc = await db.collection("users").doc(issueData.assignedStaffId).get();
        if (staffDoc.exists && staffDoc.data().fcmToken) tokens.push(staffDoc.data().fcmToken);
      }
    } else {
      // Case 2: Admin/Staff sent -> Notify Student
      const studentDoc = await db.collection("users").doc(issueData.createdBy).get();
      if (studentDoc.exists && studentDoc.data().fcmToken) tokens.push(studentDoc.data().fcmToken);
    }

    const uniqueTokens = [...new Set(tokens)];
    if (uniqueTokens.length === 0) return null;

    // 🔥 GUARANTEED FIX: Send to each token individually to ensure maximum reliability
    const sendPromises = uniqueTokens.map(token => {
      return fcm.send({
        token: token,
        notification: {
          title: `New Message: ${issueData.title}`,
          body: `${message.senderName}: ${message.text}`,
        },
        data: {
          issueId: issueId,
          type: "chat",
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        },
        android: {
          priority: "high",
          notification: {
             channelId: "high_importance_channel"
          }
        }
      });
    });

    console.log(`Sending notifications to ${uniqueTokens.length} devices.`);
    return Promise.all(sendPromises);
  });

/**
 * 🔔 NOTIFY STUDENT ON STATUS/ASSIGNMENT UPDATE
 */
exports.onIssueUpdate = functions.firestore
  .document("issues/{issueId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const issueId = context.params.issueId;

    if (newData.status !== oldData.status) {
      const studentDoc = await db.collection("users").doc(newData.createdBy).get();
      const token = studentDoc.data()?.fcmToken;
      if (token) {
        return fcm.send({
          token: token,
          notification: {
            title: "Issue Status Updated",
            body: `Your issue "${newData.title}" is now: ${newData.status.toUpperCase()}`,
          },
          data: { issueId: issueId, type: "status" },
          android: { priority: "high", notification: { channelId: "high_importance_channel" } }
        });
      }
    }

    if (newData.assignedStaffId && newData.assignedStaffId !== oldData.assignedStaffId) {
      const staffDoc = await db.collection("users").doc(newData.assignedStaffId).get();
      const token = staffDoc.data()?.fcmToken;
      if (token) {
        return fcm.send({
          token: token,
          notification: {
            title: "New Job Assigned",
            body: `Description: ${newData.title}`,
          },
          data: { issueId: issueId, type: "assignment" },
          android: { priority: "high", notification: { channelId: "high_importance_channel" } }
        });
      }
    }
    return null;
  });
