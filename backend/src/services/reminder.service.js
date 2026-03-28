const cron = require("node-cron");
const Meeting = require("../models/meeting.model");
const User = require("../models/user.model");
const Notification = require("../models/notification.model");
const sendEmail = require("../utils/email");

function startReminderService(){

cron.schedule("0 9 * * *", async () => {

  console.log("Checking task deadlines...");

  const today = new Date();
  const tomorrow = new Date();

  tomorrow.setDate(today.getDate() + 1);

  const meetings = await Meeting.find({
  "tasks.deadline": { $exists:true }
});

  for(const meeting of meetings){

    for(const task of meeting.tasks){

      if(!task.completed && task.deadline){

        const deadline = new Date(task.deadline);

        if(deadline.toDateString() === tomorrow.toDateString()){

          const user = await User.findById(task.assignedTo);

          if(user){

            const message = `Reminder: Your task "${task.title}" deadline is tomorrow.`;

            // send email
            await sendEmail(
              user.email,
              "Task Deadline Reminder",
              message
            );

            // save in-app notification
            await Notification.create({
              user:user._id,
              message:message
            });

            console.log("Reminder sent to",user.email);

          }

        }

      }

    }

  }

});

}

module.exports = startReminderService;