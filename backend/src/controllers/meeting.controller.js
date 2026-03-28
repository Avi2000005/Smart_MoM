const Meeting = require("../models/meeting.model");
const generateMeetingPDF = require("../utils/pdfGenerator");


async function exportMeetingPDF(req,res){

  const meeting = await Meeting.findOne({
    _id:req.params.id,
    participants:req.userId
  })
  .populate("participants","username email")
  .populate("tasks.assignedTo","username");

  if(!meeting){
    return res.status(404).json({
      message:"Meeting not found"
    });
  }

  generateMeetingPDF(res,meeting);

}


/* CREATE MEETING */

async function createMeeting(req,res){

  try{

    const { title, client, date, participants, tasks } = req.body;

    // remove duplicates
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

    res.status(201).json({
      message:"Meeting created",
      meeting
    });

  }catch(err){

    res.status(500).json({
      message:"Server error"
    });

  }

}


/* GET MEETINGS */

async function getMeetings(req,res){

  try{

    const meetings = await Meeting.find({
      participants: req.userId
    })
    .populate("participants","username email")
    .populate("tasks.assignedTo","username email") // IMPORTANT
    .sort({createdAt:-1});

    res.json(meetings);

  }catch(err){

    res.status(500).json({
      message:"Server error"
    });

  }

}

/* GET MEETING DETAILS */

const mongoose = require("mongoose");

async function getMeetingDetails(req,res){

  try{

    const { id } = req.params;

    // prevent invalid ObjectId error
    if(!mongoose.Types.ObjectId.isValid(id)){
      return res.status(400).json({
        message:"Invalid meeting id"
      });
    }

    const meeting = await Meeting.findById(id)
      .populate("participants","username email")
      .populate("tasks.assignedTo","username");

    if(!meeting){
      return res.status(404).json({
        message:"Meeting not found"
      });
    }

    res.json(meeting);

  }catch(error){

    res.status(500).json({
      message:"Server error"
    });

  }

}

/* DELETE MEETING */

async function deleteMeeting(req,res){

  try{

    const meeting = await Meeting.findById(req.params.id);

    if(!meeting){
      return res.status(404).json({
        message:"Meeting not found"
      });
    }

    // check creator
    if(String(meeting.createdBy) !== String(req.userId)){
      return res.status(403).json({
        message:"Only meeting creator can delete"
      });
    }

    await Meeting.findByIdAndDelete(req.params.id);

    res.json({
      message:"Meeting deleted"
    });

  }catch(err){

    console.error(err);

    res.status(500).json({
      message:"Server error"
    });

  }

}


module.exports = {
  createMeeting,
  getMeetings,
  getMeetingDetails,
  exportMeetingPDF,
  deleteMeeting
};