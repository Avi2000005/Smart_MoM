const express = require("express");
const router = express.Router();

const meetingController = require("../controllers/meeting.controller");
const auth = require("../middleware/auth.middleware");

// CREATE MEETING
router.post("/create", auth, meetingController.createMeeting);

// GET ALL MEETINGS
router.get("/", auth, meetingController.getMeetings);

// GET SINGLE MEETING
router.get("/:id", auth, meetingController.getMeetingDetails);

// EXPORT PDF
router.get("/export/:id", auth, meetingController.exportMeetingPDF);

// DELETE MEETING
router.delete("/:id", auth, meetingController.deleteMeeting);

module.exports = router;