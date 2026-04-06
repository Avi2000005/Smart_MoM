// services/reminder.service.js

const cron    = require("node-cron");
const Meeting = require("../models/meeting.model");
const User    = require("../models/user.model");
const notify  = require("../utils/notification.helper");

function startReminderService() {

  // ── Daily reminders at 9:00 AM ────────────────────────────────────────────
  cron.schedule("0 9 * * *", async () => {
    console.log("⏰ Running daily reminder check...");

    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const tomorrow = new Date(today);
      tomorrow.setDate(today.getDate() + 1);

      const meetings = await Meeting.find({});

      for (const meeting of meetings) {

        // ── Meeting reminder 1 day before ───────────────────────────────────
        const meetingDate = new Date(meeting.date);
        meetingDate.setHours(0, 0, 0, 0);

        if (meetingDate.getTime() === tomorrow.getTime()) {
          for (const participantId of meeting.participants || []) {

            // Only notify verified users
            const user = await User.findOne({
              _id: participantId,
              isEmailVerified: true
            });
            if (!user) continue;

            await notify(
              participantId,
              `📅 Reminder: Meeting "${meeting.title}" is scheduled for tomorrow (${new Date(meeting.date).toLocaleDateString()}).`,
              "meeting_reminder",
              meeting._id
            );
          }
        }

        // ── Task checks ─────────────────────────────────────────────────────
        for (const task of meeting.tasks || []) {

          if (task.completed || !task.deadline || !task.assignedTo) continue;

          // Only notify verified users
          const user = await User.findOne({
            _id: task.assignedTo,
            isEmailVerified: true
          });
          if (!user) continue;

          const deadline = new Date(task.deadline);
          deadline.setHours(0, 0, 0, 0);

          // Deadline tomorrow
          if (deadline.getTime() === tomorrow.getTime()) {
            await notify(
              task.assignedTo,
              `⏰ Your task "${task.title}" in meeting "${meeting.title}" is due tomorrow (${new Date(task.deadline).toLocaleDateString()}).`,
              "task_deadline",
              meeting._id
            );
          }

          // Overdue
          if (deadline.getTime() < today.getTime()) {
            await notify(
              task.assignedTo,
              `🚨 Your task "${task.title}" in meeting "${meeting.title}" is overdue! Please complete it ASAP.`,
              "task_overdue",
              meeting._id
            );
          }
        }
      }

      console.log("✅ Daily reminder check complete.");

    } catch (error) {
      console.error("Reminder service error:", error.message);
    }
  });

  // ── Cleanup unverified users every day at midnight ────────────────────────
  cron.schedule("0 0 * * *", async () => {
    console.log("🧹 Cleaning up unverified users...");

    try {
      const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);
      const result = await User.deleteMany({
        isEmailVerified: false,
        createdAt: { $lt: cutoff }
      });
      console.log(`🗑️  Deleted ${result.deletedCount} unverified users`);
    } catch (error) {
      console.error("Cleanup error:", error.message);
    }
  });

  console.log("✅ Reminder service started — runs daily at 9:00 AM");
  console.log("✅ Cleanup service started — runs daily at midnight");
}

module.exports = startReminderService;