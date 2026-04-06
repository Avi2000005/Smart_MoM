// controllers/user.controller.js

const User    = require("../models/user.model");
const bcrypt  = require("bcryptjs");


// ── GET ALL VERIFIED USERS ────────────────────────────────────────────────────
async function getUsers(req, res) {
  try {

    const users = await User.find(
      { isEmailVerified: true },      // ← only verified users
      "_id username email"
    );

    res.status(200).json(users);

  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
}


// ── SEARCH VERIFIED USERS — GET /api/users/search?q=john ─────────────────────
async function searchUsers(req, res) {
  try {

    const query = (req.query.q || "").trim();

    if (query.length < 2) {
      return res.status(400).json({
        message: "Search query must be at least 2 characters"
      });
    }

    const users = await User.find({
      isEmailVerified: true,          // ← only verified users
      $or: [
        { username: { $regex: query, $options: "i" } },
        { email:    { $regex: query, $options: "i" } }
      ]
    })
    .select("_id username email")
    .limit(20);

    res.status(200).json(users);

  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
}


// ── GET CURRENT USER ──────────────────────────────────────────────────────────
async function getCurrentUser(req, res) {
  try {

    const user = await User.findById(req.userId)
      .select("_id username email");

    if (!user) return res.status(404).json({ message: "User not found" });

    res.json(user);

  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
}


// ── CHANGE PASSWORD ───────────────────────────────────────────────────────────
async function changePassword(req, res) {
  try {

    const { password } = req.body;

    if (!password) {
      return res.status(400).json({ message: "Password required" });
    }

    const hash = await bcrypt.hash(password, 10);
    await User.findByIdAndUpdate(req.userId, { password: hash });

    res.json({ message: "Password updated successfully" });

  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
}


module.exports = {
  getUsers,
  searchUsers,
  getCurrentUser,
  changePassword
};