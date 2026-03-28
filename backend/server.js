require("dotenv").config();

const app = require("./src/app");
const connectDB = require("./src/db/db");

const startReminderService = require("./src/services/reminder.service");

connectDB();

startReminderService();

app.listen(process.env.PORT,()=>{
  console.log("Server running on port",process.env.PORT);
});