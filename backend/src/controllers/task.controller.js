const Meeting = require("../models/meeting.model");
const notify = require("../utils/notification.helper");

/* CREATE TASK */
async function createTask(req, res) {
  try {
    const { meetingId, title, action, assignedTo, deadline } = req.body;

    const meeting = await Meeting.findById(meetingId);

    if (!meeting) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    meeting.tasks.push({ title, action, assignedTo, deadline });
    await meeting.save();

    // ── Notify assigned user ────────────────────────────────────────────
    if (assignedTo && assignedTo.toString() !== req.userId.toString()) {
      const deadlineStr = deadline
        ? ` Deadline: ${new Date(deadline).toLocaleDateString()}.`
        : "";

      await notify(
        assignedTo,
        `📋 You have been assigned a new task: "${title}" in meeting "${meeting.title}".${deadlineStr}`,
        "task_assigned",
        meetingId
      );
    }

    res.status(201).json({ message: "Task created" });

  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
}

/* GET TASKS ASSIGNED TO CURRENT USER */
async function getTasks(req, res) {
  try {
    const meetings = await Meeting.find({
      "tasks.assignedTo": req.userId
    });

    const tasks = [];

    meetings.forEach(m => {
      m.tasks.forEach(t => {
        if (String(t.assignedTo) === String(req.userId)) {
          tasks.push({
            _id: t._id,
            title: t.title,
            action: t.action,
            deadline: t.deadline,
            completed: t.completed,
            meetingId: m._id
          });
        }
      });
    });

    res.json(tasks);
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
}

/* TOGGLE TASK */
async function toggleTask(req, res) {
  try {
    const { meetingId } = req.body;
    const { taskId } = req.params;

    const meeting = await Meeting.findById(meetingId);

    if (!meeting) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    const task = meeting.tasks.id(taskId);

    if (!task) {
      return res.status(404).json({ message: "Task not found" });
    }

    task.completed = !task.completed;
    await meeting.save();

    // ── Notify meeting creator when task is marked complete ─────────────
    if (
      task.completed &&
      meeting.createdBy.toString() !== req.userId.toString()
    ) {
      await notify(
        meeting.createdBy,
        `✅ Task "${task.title}" in meeting "${meeting.title}" has been marked as completed.`,
        "task_completed",
        meetingId
      );
    }

    // ── Notify assigned user when task is uncompleted ───────────────────
    if (
      !task.completed &&
      task.assignedTo &&
      task.assignedTo.toString() !== req.userId.toString()
    ) {
      await notify(
        task.assignedTo,
        `🔄 Task "${task.title}" in meeting "${meeting.title}" has been marked as incomplete.`,
        "task_assigned",
        meetingId
      );
    }

    res.json({ message: "Task updated" });

  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
}

/* DELETE TASK */
async function deleteTask(req, res) {
  try {
    const meetingId = req.query.meetingId;
    const { taskId } = req.params;

    const meeting = await Meeting.findById(meetingId);

    if (!meeting) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    const task = meeting.tasks.id(taskId);

    // ── Notify assigned user their task was deleted ─────────────────────
    if (
      task &&
      task.assignedTo &&
      task.assignedTo.toString() !== req.userId.toString()
    ) {
      await notify(
        task.assignedTo,
        `🗑️ Task "${task.title}" in meeting "${meeting.title}" has been deleted.`,
        "general",
        meetingId
      );
    }

    task.deleteOne();
    await meeting.save();

    res.json({ message: "Task deleted" });

  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
}

module.exports = {
  createTask,
  getTasks,
  toggleTask,
  deleteTask
};