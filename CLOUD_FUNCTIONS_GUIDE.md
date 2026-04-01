# Firebase Cloud Functions: Smart Notifications Setup

To fully enable smart push notifications, you need to deploy the following Cloud Functions to your Firebase project. This handles the "Backend Trigger" logic.

## 📁 Functions Structure (index.js)
```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * 📣 Triggered when an issue status changes
 */
exports.onIssueUpdate = functions.firestore
    .document('issues/{issueId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const oldData = change.before.data();
        
        // Status changed logic
        if (newData.status !== oldData.status) {
            const studentId = newData.createdBy;
            const studentDoc = await admin.firestore().collection('users').doc(studentId).get();
            const fcmToken = studentDoc.data().fcmToken;

            if (fcmToken) {
                const message = {
                    notification: {
                        title: `Issue Update: ${newData.title}`,
                        body: `Your issue status has been updated to "${newData.status}".`,
                    },
                    token: fcmToken,
                    data: {
                        issueId: context.params.issueId,
                        click_action: "FLUTTER_NOTIFICATION_CLICK"
                    }
                };
                return admin.messaging().send(message);
            }
        }
        return null;
    });

/**
 * 💬 Triggered when a new chat message is sent
 */
exports.onNewMessage = functions.firestore
    .document('issues/{issueId}/messages/{messageId}')
    .onCreate(async (snapshot, context) => {
        const messageData = snapshot.data();
        const issueId = context.params.issueId;
        const issueDoc = await admin.firestore().collection('issues').doc(issueId).get();
        const issue = issueDoc.data();

        // Determine recipient (If sender is admin, send to student. If student, send to admin if possible)
        let recipientId = (messageData.senderId === issue.createdBy) ? "admin_uid" : issue.createdBy;
        
        // Note: For multi-admin apps, you would loop through all users with role 'admin'
        const recipientDoc = await admin.firestore().collection('users').doc(recipientId).get();
        const fcmToken = recipientDoc.data().fcmToken;

        if (fcmToken) {
            const payload = {
                notification: {
                    title: `New message on issue: ${issue.title}`,
                    body: messageData.text,
                },
                token: fcmToken,
                data: { issueId: issueId }
            };
            return admin.messaging().send(payload);
        }
        return null;
    });
```

## 🚀 How to deploy:
1.  On your local machine, run: `firebase init functions`.
2.  Choose **JavaScript**.
3.  Paste the above code into `functions/index.js`.
4.  Run: `firebase deploy --only functions`.

## ✅ Why this works:
- **Server-Side Automation:** You don't need to manually send notifications from the app. Firebase automatically detects the Firestore change and sends the message.
- **Off-device processing:** Works even if the person who triggers the change (e.g., an Admin) is not the one receiving the notification.
- **SLA Breach Notification:** You can create a Scheduled Function (Cron job) in Firebase to run every 15 minutes, check `deadline` vs `now`, and send a "Late" notification.
