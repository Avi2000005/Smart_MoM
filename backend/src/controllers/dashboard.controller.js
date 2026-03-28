const Meeting = require("../models/meeting.model");

async function getDashboard(req, res) {

  try {

    const meetings = await Meeting.find({
      participants: req.userId
    })
    .populate("participants","username")
    .populate("tasks.assignedTo","username");

    let totalMeetings = meetings.length;
    let totalTasks = 0;
    let completedTasks = 0;
    let pendingTasks = 0;

    const participantStats = {};

    meetings.forEach(meeting => {

      meeting.tasks.forEach(task => {

        totalTasks++;

        const user = task.assignedTo?.username;

        if(user){

          if(!participantStats[user]){

            participantStats[user] = {
              assigned:0,
              completed:0
            };

          }

          participantStats[user].assigned++;

        }

        if(task.completed){

          completedTasks++;

          if(user){
            participantStats[user].completed++;
          }

        } else {
          pendingTasks++;
        }

      });

    });

    const completionRate =
      totalTasks === 0
        ? 0
        : Math.round((completedTasks / totalTasks) * 100);

    const participants = Object.keys(participantStats).map(name => {

      const assigned = participantStats[name].assigned;
      const completed = participantStats[name].completed;

      return {
        name,
        assigned,
        completed,
        completionRate:
          assigned === 0
            ? 0
            : Math.round((completed / assigned) * 100)
      };

    });

    res.json({

      totalMeetings,
      totalTasks,
      completedTasks,
      pendingTasks,
      completionRate,
      participants

    });

  } catch (err) {

    res.status(500).json({
      message:"Dashboard error"
    });

  }

}

module.exports = { getDashboard };