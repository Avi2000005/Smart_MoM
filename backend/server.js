require("dotenv").config();

const app = require("./src/app");
const connectDB = require("./src/db/db");

const startReminderService = require("./src/services/reminder.service");

connectDB();

startReminderService();


app.listen(process.env.PORT, '0.0.0.0', () => {
  console.log("Server running on port", process.env.PORT);

  // Self-ping to prevent Render free tier sleep
  const selfPing = async () => {
    try {
      await axios.get('https://smart-mom.onrender.com/ping');
      console.log('Self-ping OK');
    } catch (e) {
      console.log('Self-ping failed:', e.message);
    }
  };

  selfPing();
  setInterval(selfPing, 14 * 60 * 1000);
});

