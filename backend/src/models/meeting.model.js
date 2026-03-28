const mongoose = require('mongoose');

const meetingSchema = new mongoose.Schema({

  title:{
    type:String,
    required:true,
    trim:true
  },

  client:{
    type:String,
    trim:true
  },

  date:{
    type:Date,
    required:true
  },

  createdBy:{
    type:mongoose.Schema.Types.ObjectId,
    ref:"User",
    required:true
  },

  participants:[{
    type:mongoose.Schema.Types.ObjectId,
    ref:"User"
  }],

  tasks:[{

    title:String,

    action:String,

    category:{
      type:String,
    },

    assignedTo:{
      type:mongoose.Schema.Types.ObjectId,
      ref:"User"
    },

    deadline:Date,

    completed:{
      type:Boolean,
      default:false
    }

  }]

},{timestamps:true});

module.exports = mongoose.model('Meeting', meetingSchema);