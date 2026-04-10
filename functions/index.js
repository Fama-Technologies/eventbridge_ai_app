const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

admin.initializeApp();

exports.createFirebaseCustomToken = onRequest(
  {
    cors: true,
    invoker: "public",
    serviceAccount: `${process.env.GCLOUD_PROJECT}@appspot.gserviceaccount.com`,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }

    const {userId, email, name, role} = req.body || {};
    if (!userId) {
      res.status(400).json({error: "userId is required"});
      return;
    }

    try {
      const customToken = await admin.auth().createCustomToken(userId, {
        email: email || "",
        name: name || "",
        role: role || "",
        backendUserId: userId,
      });

      res.json({customToken});
    } catch (error) {
      logger.error("Failed to create custom token", error);
      res.status(500).json({error: "Failed to create custom token"});
    }
  },
);

exports.onMessageCreate = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const messageSnapshot = event.data;
    if (!messageSnapshot) return;

    const message = messageSnapshot.data();
    const chatId = event.params.chatId;

    const chatSnapshot = await admin.firestore().doc(`chats/${chatId}`).get();
    if (!chatSnapshot.exists) {
      logger.warn("Chat document missing for message", {chatId});
      return;
    }

    const chat = chatSnapshot.data() || {};
    const senderId = String(message.senderId || "");
    
    // Robust ID resolution: 
    // Usually customerId and vendorId are in the doc data.
    // If not, we check if chatId is formatted as {customerId}_{vendorId}
    let customerId = String(chat.customerId || "");
    let vendorId = String(chat.vendorId || "");

    if ((!customerId || !vendorId) && chatId.includes("_") && !chatId.startsWith("lead_")) {
      const parts = chatId.split("_");
      if (parts.length === 2) {
        if (!customerId) customerId = parts[0];
        if (!vendorId) vendorId = parts[1];
      }
    }

    const recipientId = senderId === customerId ? vendorId : customerId;

    if (!recipientId || recipientId === "undefined" || recipientId === "") {
      logger.warn("Recipient missing for chat message", {chatId, senderId, customerId, vendorId});
      return;
    }

    const tokenSnapshot = await admin
        .firestore()
        .doc(`notificationTokens/${recipientId}`)
        .get();

    const token = tokenSnapshot.data()?.token;
    if (!token) {
      logger.info("No notification token found for recipient", {
        chatId,
        recipientId,
      });
      return;
    }

    const senderName = senderId === customerId ?
      String(chat.customerName || "Customer") :
      String(chat.vendorName || "Vendor");
    const preview = message.type === "image" ?
      "Sent a photo" :
      String(message.text || "New message");
    const isPendingInquiry = senderId === customerId &&
      String(chat.status || "pending") !== "accepted";
    const notificationTitle = isPendingInquiry ?
      `New inquiry from ${senderName}` :
      senderName;
    const notificationType = isPendingInquiry ? "lead" : "chat";
    const payloadData = {
      type: notificationType,
      chat_id: chatId,
      sender_name: senderName,
      text: preview,
      ...(chat.leadId ? {lead_id: String(chat.leadId)} : {}),
    };

    try {
      await admin.messaging().send({
        token,
        notification: {
          title: notificationTitle,
          body: preview,
        },
        data: payloadData,
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });
      logger.info("Push notification sent", {chatId, recipientId});
    } catch (error) {
      logger.error("Failed to send push notification", error, {
        chatId,
        recipientId,
      });
    }
  },
);
