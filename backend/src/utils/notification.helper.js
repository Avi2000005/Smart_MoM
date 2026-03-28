// utils/notification.helper.js
const Notification = require("../models/notification.model");

async function notify(userId, message, type, relatedMeeting = null) {
  try {
    await Notification.create({
      user: userId,
      message,
      type,
      relatedMeeting
    });
  } catch (err) {
    console.error("Failed to create notification:", err.message);
  }
}

module.exports = notify;