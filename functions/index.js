const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * 📣 Triggered when an issue is status-updated (Notify STUDENT)
 */
exports.onIssueUpdate = functions.firestore
  .document("issues/{issueId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const issueId = context.params.issueId;

    // 1. Check if status actually changed
    if (newData.status === oldData.status) return null;

    // 2. Find the student who created it
    const studentId = newData.createdBy;
    const studentDoc = await admin.firestore().collection("users").doc(studentId).get();
    
    if (!studentDoc.exists) return null;
    const fcmToken = studentDoc.data().fcmToken;

    if (fcmToken) {
      const message = {
        notification: {
          title: `Issue Update: ${newData.title}`,
          body: `Your issue status has been updated to "${newData.status.toUpperCase()}".`,
        },
        token: fcmToken,
        data: {
          issueId: issueId,
          type: "status_update",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };
      console.log(`Sending status update notification to ${studentId}`);
      return admin.messaging().send(message);
    }
    return null;
  });

/**
 * 💬 Triggered when a new chat message is sent (Notify RECIPIENT)
 */
exports.onNewMessage = functions.firestore
  .document("issues/{issueId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();
    const issueId = context.params.issueId;
    
    // Get the parent issue to find participants
    const issueDoc = await admin.firestore().collection("issues").doc(issueId).get();
    if (!issueDoc.exists) return null;
    const issue = issueDoc.data();

    const senderId = messageData.senderId;
    const tokens = [];

    // --- LOGIC: WHO SHOULD RECEIVE THIS? ---
    
    // Case 1: Student sent the message -> Notify Admins and Assigned Staff
    if (senderId === issue.createdBy) {
      // A. Find all admins
      const adminSnapshot = await admin.firestore().collection("users")
        .where("role", "==", "admin")
        .get();
      
      adminSnapshot.forEach(doc => {
        const token = doc.data().fcmToken;
        if (token) tokens.push(token);
      });

      // B. Find assigned staff
      if (issue.assignedStaffId) {
        const staffDoc = await admin.firestore().collection("users").doc(issue.assignedStaffId).get();
        if (staffDoc.exists && staffDoc.data().fcmToken) {
          tokens.push(staffDoc.data().fcmToken);
        }
      }
    } 
    // Case 2: Someone else sent (Admin/Staff) -> Notify the Student
    else {
      const studentDoc = await admin.firestore().collection("users").doc(issue.createdBy).get();
      if (studentDoc.exists && studentDoc.data().fcmToken) {
        tokens.push(studentDoc.data().fcmToken);
      }
    }

    if (tokens.length === 0) return null;

    // Remove duplicates
    const uniqueTokens = [...new Set(tokens)];

    const payload = {
      notification: {
        title: `Message on: ${issue.title}`,
        body: `${messageData.senderName}: ${messageData.text}`,
      },
      data: {
        issueId: issueId,
        type: "chat",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    console.log(`Sending chat notifications to ${uniqueTokens.length} devices.`);
    
    // Multicast sends to multiple tokens at once
    return admin.messaging().sendEachForMulticast({
      tokens: uniqueTokens,
      ...payload
    });
  });
