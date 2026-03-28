const express = require("express");
const cookieParser = require("cookie-parser");
const cors = require("cors");
const helmet = require("helmet");

const authRoutes = require("./routes/auth.routes");
const meetingRoutes = require("./routes/meeting.routes");
const taskRoutes = require("./routes/task.routes");
const dashboardRoutes = require("./routes/dashboard.routes");
const notificationRoutes = require("./routes/notification.routes");
const userRoutes = require("./routes/user.routes");

const errorHandler = require("./middleware/error.middleware");
const sendEmail = require("./utils/email");

const app = express();


// ---------------- Middleware ----------------

app.use(express.json());
app.use(cookieParser());

app.use(cors({
  origin: "*"
}));

app.use(helmet());


// ---------------- Routes ----------------

app.use("/api/auth", authRoutes);

app.use("/api/users", userRoutes);

app.use("/api/meetings", meetingRoutes);

app.use("/api/tasks", taskRoutes);

app.use("/api/dashboard", dashboardRoutes);

app.use("/api/notifications", notificationRoutes);




// ---------------- Error Handler ----------------

app.use(errorHandler);


module.exports = app;