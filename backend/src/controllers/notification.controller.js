// controllers/notification.controller.js
 
const Notification = require("../models/notification.model");
 
// ── GET all notifications for logged-in user ──────────────────────────────────
async function getNotifications(req, res) {
  try {
    const notifications = await Notification.find({
      user: req.userId
    }).sort({ createdAt: -1 });
 
    res.json(notifications);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
}
 
// ── GET unread count ──────────────────────────────────────────────────────────
async function getUnreadCount(req, res) {
  try {
    const count = await Notification.countDocuments({
      user: req.userId,
      read: false
    });
    res.json({ count });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
}
 
// ── PATCH mark single notification as read ────────────────────────────────────
async function markAsRead(req, res) {
  try {
    await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.userId },
      { read: true }
    );
    res.json({ message: "Marked as read" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
}
 
// ── PATCH mark ALL notifications as read ─────────────────────────────────────
async function markAllAsRead(req, res) {
  try {
    await Notification.updateMany(
      { user: req.userId, read: false },
      { read: true }
    );
    res.json({ message: "All marked as read" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
}
 
// ── DELETE a notification ─────────────────────────────────────────────────────
async function deleteNotification(req, res) {
  try {
    await Notification.findOneAndDelete({
      _id: req.params.id,
      user: req.userId
    });
    res.json({ message: "Notification deleted" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
}
 
module.exports = {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification
};