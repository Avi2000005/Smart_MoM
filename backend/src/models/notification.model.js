// models/notification.model.js
const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true
  },
  message: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: [
      "task_assigned",       // someone assigned you a task
      "task_deadline",       // task deadline is tomorrow (cron)
      "task_overdue",        // task is overdue (cron)
      "task_completed",      // someone marked a task as done
      "meeting_reminder",    // meeting is tomorrow (cron)
      "meeting_created",     // you were added to a new meeting
      "participant_added",   // you were added to an existing meeting
      "general"
    ],
    default: "general"
  },
  read: {
    type: Boolean,
    default: false
  },
  relatedMeeting: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Meeting",
    default: null
  }
}, { timestamps: true });

module.exports = mongoose.model("Notification", notificationSchema);