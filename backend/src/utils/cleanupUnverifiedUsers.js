// utils/cleanupUnverifiedUsers.js
// Run ONCE to remove existing ghost users from your database
// Command: node src/utils/cleanupUnverifiedUsers.js

require("dotenv").config({ path: require("path").join(__dirname, "../../.env") });
const mongoose = require("mongoose");
const User     = require("../models/user.model");

async function cleanup() {

  console.log("Connecting to database...");
  await mongoose.connect(process.env.MONGO_URI);
  console.log("Connected!");

  const unverified = await User.find({ isEmailVerified: false });
  console.log("Found " + unverified.length + " unverified users:");
  unverified.forEach(u => console.log(" - " + u.username + " (" + u.email + ")"));

  if (unverified.length === 0) {
    console.log("Nothing to clean up!");
    await mongoose.disconnect();
    return;
  }

  const result = await User.deleteMany({ isEmailVerified: false });
  console.log("Deleted " + result.deletedCount + " unverified users");

  await mongoose.disconnect();
  console.log("Done!");
}

cleanup().catch(console.error);