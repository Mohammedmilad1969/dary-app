const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

exports.getGeminiApiKey = functions.https.onCall(async (data, context) => {
  // Optional: Add authentication check
  // (uncomment if you want to restrict access)
  // if (!context.auth) {
  //   throw new functions.https.HttpsError(
  //     'unauthenticated',
  //     'User must be authenticated to get API key'
  //   );
  // }

  // Use environment variable (recommended) or fallback to config
  const config = functions.config();
  const apiKey = process.env.GEMINI_API_KEY ||
    (config.gemini && config.gemini.api_key ? config.gemini.api_key : null);

  if (!apiKey) {
    throw new functions.https.HttpsError(
      "internal",
      "API key not configured in Firebase Functions",
    );
  }

  return { apiKey: apiKey };
});

exports.onNewChatMessage = onDocumentCreated("conversations/{conversationId}/messages/{messageId}", async (event) => {
  const message = event.data.data();
  const conversationId = event.params.conversationId;

  if (!message) {
    console.log("No message data found.");
    return null;
  }

  // 1. Get conversation metadata to find participants
  const convRef = admin.firestore().collection("conversations").doc(conversationId);
  const convSnap = await convRef.get();
  if (!convSnap.exists) {
    console.log(`Conversation ${conversationId} does not exist.`);
    return null;
  }
  const conversation = convSnap.data();

  // 2. Identify the recipient (the one who didn't send the message)
  const recipientId = (conversation.buyerId === message.senderId) ?
    conversation.sellerId :
    conversation.buyerId;

  if (!recipientId) {
    console.log("No recipient found for conversation.");
    return null;
  }

  // 3. Get recipient's FCM token from their user profile
  console.log(`Searching for recipient token: ${recipientId}`);
  const userSnap = await admin.firestore().collection("users").doc(recipientId).get();
  if (!userSnap.exists) {
    console.log(`User ${recipientId} does not exist in Firestore.`);
    return null;
  }
  const userData = userSnap.data();
  const fcmToken = userData.fcmToken;

  if (!fcmToken) {
    console.log(`No token found for recipient: ${recipientId}`);
    return;
  }

  console.log(`Sending to token: ${fcmToken}`);

  // 4. Construct and send the push notification
  const payload = {
    notification: {
      title: `رسالة جديدة من ${message.senderName}`,
      body: message.content,
    },
    data: {
      type: "chat_message",
      chatId: conversationId,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: `رسالة جديدة من ${message.senderName}`,
            body: message.content,
          },
          sound: "default",
          badge: 1,
          "content-available": 1,
          "mutable-content": 1,
        },
      },
      headers: {
        "apns-priority": "10", // High priority for immediate delivery
        "apns-push-type": "alert", // Required for alert notifications
      },
    },
    token: fcmToken,
  };

  try {
    await admin.messaging().send(payload);
    console.log(`Successfully sent notification to user ${recipientId}`);
  } catch (error) {
    console.error("Error sending notification:", error);
  }
  return null;
});

/**
 * Automatically unpublish properties that have passed their expiration date.
 * Runs every hour.
 */
exports.autoUnpublishExpired = onSchedule("every 1 hours", async (event) => {
  const now = admin.firestore.Timestamp.now();
  const propertiesRef = admin.firestore().collection("properties");

  console.log("Checking for expired properties...");

  try {
    // Only query properties that are currently published and have an expiration date in the past
    const snap = await propertiesRef
      .where("isPublished", "==", true)
      .where("expiresAt", "<", now)
      .get();

    if (snap.empty) {
      console.log("No expired properties found.");
      return null;
    }

    console.log(`Found ${snap.size} expired properties. Processing unpublish...`);

    const batch = admin.firestore().batch();
    snap.forEach((doc) => {
      batch.update(doc.ref, {
        isPublished: false,
        isExpired: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
    console.log(`Successfully unpublished ${snap.size} properties.`);
  } catch (error) {
    console.error("Error in autoUnpublishExpired:", error);
  }

  return null;
});
