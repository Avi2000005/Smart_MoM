const Meeting = require("../models/meeting.model");


/* CREATE TASK */

async function createTask(req,res){

  try{

    const { meetingId, title, action, assignedTo, deadline } = req.body;

    const meeting = await Meeting.findById(meetingId);

    if(!meeting){
      return res.status(404).json({
        message:"Meeting not found"
      });
    }

    meeting.tasks.push({
      title,
      action,
      assignedTo,
      deadline
    });

    await meeting.save();

    res.status(201).json({
      message:"Task created"
    });

  }catch(err){

    res.status(500).json({
      message:"Server error"
    });

  }

}


/* GET TASKS ASSIGNED TO CURRENT USER */

async function getTasks(req,res){

  try{

    const meetings = await Meeting.find({
      "tasks.assignedTo": req.userId
    });

    const tasks = [];

    meetings.forEach(m=>{

      m.tasks.forEach(t=>{

        if(String(t.assignedTo) === String(req.userId)){

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

  }catch(err){

    res.status(500).json({
      message:"Server error"
    });

  }

}


/* TOGGLE TASK */

async function toggleTask(req,res){

  try{

    const { meetingId } = req.body;
    const { taskId } = req.params;

    const meeting = await Meeting.findById(meetingId);

    if(!meeting){
      return res.status(404).json({
        message:"Meeting not found"
      });
    }

    const task = meeting.tasks.id(taskId);

    if(!task){
      return res.status(404).json({
        message:"Task not found"
      });
    }

    task.completed = !task.completed;

    await meeting.save();

    res.json({
      message:"Task updated"
    });

  }catch(err){

    res.status(500).json({
      message:"Server error"
    });

  }

}


/* DELETE TASK */

async function deleteTask(req,res){

  try{

    const meetingId = req.query.meetingId;
    const { taskId } = req.params;

    const meeting = await Meeting.findById(meetingId);

    if(!meeting){
      return res.status(404).json({
        message:"Meeting not found"
      });
    }

    meeting.tasks.id(taskId).deleteOne();

    await meeting.save();

    res.json({
      message:"Task deleted"
    });

  }catch(err){

    res.status(500).json({
      message:"Server error"
    });

  }

}


module.exports = {
  createTask,
  getTasks,
  toggleTask,
  deleteTask
};