const Meeting = require("../models/meeting.model");
const generateMeetingPDF = require("../utils/pdfGenerator");
const notify = require("../utils/notification.helper");
const mongoose = require("mongoose");

/* EXPORT PDF */
async function exportMeetingPDF(req, res) {
  const meeting = await Meeting.findOne({
    _id: req.params.id,
    participants: req.userId
  })
    .populate("participants", "username email")
    .populate("tasks.assignedTo", "username");

  if (!meeting) {
    return res.status(404).json({ message: "Meeting not found" });
  }

  generateMeetingPDF(res, meeting);
}

/* CREATE MEETING */
async function createMeeting(req, res) {
  try {
    const { title, client, date, participants, tasks } = req.body;

    const uniqueParticipants = [
      ...new Set([req.userId, ...participants])
    ];

    const meeting = await Meeting.create({
      title,
      client,
      date,
      participants: uniqueParticipants,
      tasks,
      createdBy: req.userId
    });

    // ── Notify all participants except creator ──────────────────────────
    for (const participantId of uniqueParticipants) {
      if (participantId.toString() === req.userId.toString()) continue;

      await notify(
        participantId,
        `📅 You have been added to a new meeting: "${title}" on ${new Date(date).toLocaleDateString()}.`,
        "meeting_created",
        meeting._id
      );
    }

    // ── Notify assigned users for pre-added tasks ───────────────────────
    for (const task of tasks || []) {
      if (!task.assignedTo) continue;
      if (task.assignedTo.toString() === req.userId.toString()) continue;

      const deadlineStr = task.deadline
        ? ` Deadline: ${new Date(task.deadline).toLocaleDateString()}.`
        : "";

      await notify(
        task.assignedTo,
        `📋 You have been assigned a task: "${task.title}" in meeting "${title}".${deadlineStr}`,
        "task_assigned",
        meeting._id
      );
    }

    res.status(201).json({ message: "Meeting created", meeting });

  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
}

/* GET MEETINGS */
async function getMeetings(req, res) {
  try {
    const meetings = await Meeting.find({ participants: req.userId })
      .populate("participants", "username email")
      .populate("tasks.assignedTo", "username email")
      .sort({ createdAt: -1 });

    res.json(meetings);
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
}

/* GET MEETING DETAILS */
async function getMeetingDetails(req, res) {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: "Invalid meeting id" });
    }

    const meeting = await Meeting.findById(id)
      .populate("participants", "username email")
      .populate("tasks.assignedTo", "username");

    if (!meeting) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    res.json(meeting);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
}

/* DELETE MEETING */
async function deleteMeeting(req, res) {
  try {
    const meeting = await Meeting.findById(req.params.id);

    if (!meeting) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    if (String(meeting.createdBy) !== String(req.userId)) {
      return res.status(403).json({ message: "Only meeting creator can delete" });
    }

    // ── Notify all participants the meeting was deleted ─────────────────
    for (const participantId of meeting.participants || []) {
      if (participantId.toString() === req.userId.toString()) continue;

      await notify(
        participantId,
        `🗑️ Meeting "${meeting.title}" has been cancelled and deleted.`,
        "general",
        null
      );
    }

    await Meeting.findByIdAndDelete(req.params.id);

    res.json({ message: "Meeting deleted" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
}

module.exports = {
  createMeeting,
  getMeetings,
  getMeetingDetails,
  exportMeetingPDF,
  deleteMeeting
};