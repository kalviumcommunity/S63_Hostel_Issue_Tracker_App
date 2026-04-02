const admin = require("firebase-admin");
const path = require("path");

/**
 * ⚡ HOSTEL ISSUE TRACKER - LOCAL NOTIFICATION TRIGGER
 * ---------------------------------------------------
 * This script runs ON YOUR PC with NO DEPLOYment.
 * It uses the service_account.json to listen to Firestore real-time snapshots
 * and send push notifications instantly.
 */

// 1. Path to your service account key (Root/assets/service_account.json)
const SERVICE_ACCOUNT_PATH = path.join(__dirname, "assets", "service_account.json");

// 2. Initialize Firebase Admin SDK
try {
  admin.initializeApp({
    credential: admin.credential.cert(SERVICE_ACCOUNT_PATH),
  });
  console.log("✅ Firebase Admin Initialized Successfully!");
} catch (error) {
  console.error("❌ Failed to initialize Admin SDK. Check service_account.json path!");
  console.error(error);
  process.exit(1);
}

const db = admin.firestore();
const fcm = admin.messaging();

console.log("🚀 Listening for chat messages locally...");

// Tracker for start time to avoid notifying about history
const SCRIPT_START_TIME = Date.now();
let isFirstSnapshot = true;

/**
 * 💬 REAL-TIME CHAT LISTENER
 */
db.collectionGroup("messages").onSnapshot(async (snapshot) => {
  // If this is the initial data dump, we mark it done and skip processing
  if (isFirstSnapshot) {
    console.log(`✅ Initial data load complete (${snapshot.docs.length} historical messages ignored)`);
    isFirstSnapshot = false;
    return;
  }

  const changes = snapshot.docChanges();
  
  for (const change of changes) {
    if (change.type === "added") {
      const messageData = change.doc.data();
      
      // Safety filter: Ensure message is truly new (sent within the last 15 seconds)
      const msgTime = messageData.timestamp && messageData.timestamp.toDate 
          ? messageData.timestamp.toDate().getTime() 
          : new Date(messageData.timestamp).getTime();

      if (msgTime < SCRIPT_START_TIME - 15000) continue; // Ignore historical data

      try {
        // Resolve parent issueId from doc path: /issues/{issueId}/messages/{messageId}
        const pathParts = change.doc.ref.path.split("/");
        const issueId = pathParts[1]; 
        
        console.log(`💬 New message detected in Issue [${issueId}] from [${messageData.senderName}]`);

        // Get Issue details to find recipient
        const issueDoc = await db.collection("issues").doc(issueId).get();
        if (!issueDoc.exists) continue;
        const issue = issueDoc.data();

        const senderId = messageData.senderId;
        const tokens = [];

        // Logic: Who receives the message?
        if (senderId === issue.createdBy) {
          // A student sent it -> Notify Admins
          const adminSnap = await db.collection("users").where("role", "==", "admin").get();
          console.log(`🔍 Found ${adminSnap.docs.length} admins in Firestore.`);
          
          adminSnap.forEach(doc => {
            const data = doc.data();
            console.log(`   - Admin: ${data.name} | Has Token: ${!!data.fcmToken}`);
            if (data.fcmToken) tokens.push(data.fcmToken);
          });
          
          // Notify Assigned Staff
          if (issue.assignedStaffId) {
            const staffDoc = await db.collection("users").doc(issue.assignedStaffId).get();
            if (staffDoc.exists) {
              const data = staffDoc.data();
              console.log(`   - Assigned Staff: ${data.name} | Has Token: ${!!data.fcmToken}`);
              if (data.fcmToken) tokens.push(data.fcmToken);
            }
          }
        } else {
          // An Admin/Staff sent it -> Notify Student
          const studentDoc = await db.collection("users").doc(issue.createdBy).get();
          if (studentDoc.exists) {
            const data = studentDoc.data();
            console.log(`   - Student: ${data.name} | Has Token: ${!!data.fcmToken}`);
            if (data.fcmToken) tokens.push(data.fcmToken);
          }
        }

        const uniqueTokens = [...new Set(tokens)];
        if (uniqueTokens.length === 0) {
          console.log("⚠️ No active tokens found for recipients. Skip.");
          continue;
        }

        // Send Push Notifications
        const payload = {
          notification: {
            title: `New message on: ${issue.title}`,
            body: `${messageData.senderName}: ${messageData.text}`,
          },
          data: {
            issueId: issueId,
            type: "chat",
            click_action: "FLUTTER_NOTIFICATION_CLICK"
          }
        };

        const response = await fcm.sendEachForMulticast({
          tokens: uniqueTokens,
          ...payload
        });

        console.log(`✅ Push Sent! (Success: ${response.successCount}, Failed: ${response.failureCount})`);

      } catch (err) {
        console.error("❌ Error processing notification:", err);
      }
    }
  }
}, (error) => {
  console.error("🔥 Chat Snapshot listener error:", error);
});


/**
 * 📊 REAL-TIME ISSUE STATUS LISTENER
 * ---------------------------------
 * This watches for status changes and notifies the creator (Student).
 */
let isFirstIssueSnapshot = true;

db.collection("issues").onSnapshot(async (snapshot) => {
  if (isFirstIssueSnapshot) {
    console.log(`📊 Status listener active (Ignoring ${snapshot.docs.length} existing issues)`);
    isFirstIssueSnapshot = false;
    return;
  }

  const changes = snapshot.docChanges();

  for (const change of changes) {
    // We only care about modified issues (status changes)
    if (change.type === "modified") {
      const newData = change.doc.data();
      const oldData = change.before.data();

      // IF THE STATUS CHANGED 🔄
      if (newData.status !== oldData.status) {
        console.log(`🔔 STATUS CHANGE: [${newData.title}] is now [${newData.status}]`);

        try {
          const studentDoc = await db.collection("users").doc(newData.createdBy).get();
          if (!studentDoc.exists || !studentDoc.data().fcmToken) {
            console.log("⚠️ No student token found for status notification. Skip.");
            continue;
          }

          const fcmToken = studentDoc.data().fcmToken;
          let bodyText = "";

          // Humanize the status
          switch (newData.status) {
            case "assigned":
              bodyText = `A maintenance specialist has been assigned to "${newData.title}".`;
              break;
            case "in_progress":
              bodyText = `Work has officially started on your report: "${newData.title}". 🛠️`;
              break;
            case "resolved":
              bodyText = `Great news! Your issue "${newData.title}" was marked as Resolved. ✅`;
              break;
            default:
              bodyText = `Your issue "${newData.title}" has been updated to: ${newData.status.toUpperCase()}`;
          }

          const payload = {
            notification: {
              title: "Issue Update Received",
              body: bodyText,
            },
            data: {
              issueId: change.doc.id,
              type: "status_update",
              click_action: "FLUTTER_NOTIFICATION_CLICK"
            },
            token: fcmToken
          };

          await fcm.send(payload);
          console.log(`✅ Status Notification Sent to [${studentDoc.data().name}]`);

        } catch (err) {
          console.error("❌ Error sending status alert:", err);
        }
      }
    }
  }
}, (error) => {
  console.error("🔥 Status Snapshot listener error:", error);
});
