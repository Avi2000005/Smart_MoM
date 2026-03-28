const Notification = require("../models/notification.model");

async function getNotifications(req,res){

  const notifications = await Notification.find({
    user:req.userId
  }).sort({createdAt:-1});

  res.json(notifications);

}

module.exports = {getNotifications};