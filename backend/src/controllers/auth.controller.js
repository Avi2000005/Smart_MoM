const User = require("../models/user.model");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const { sendVerificationOTP } = require("../services/brevo.service");
 
// ─── Helpers ────────────────────────────────────────────────────────────────
 
/** Generates a cryptographically-simple 6-digit OTP string. */
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}
 
/** Returns a JWT signed with the app secret. */
function signToken(userId) {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: "7d" });
}
 
// ─── REGISTER ───────────────────────────────────────────────────────────────
 
/**
 * POST /auth/register
 * Body: { username, email, password, mobile? }
 *
 * Creates the user in an UNVERIFIED state and sends a 6-digit OTP via Brevo.
 * No JWT is returned until the user verifies their email.
 */
async function registerUser(req, res) {
 
  try {
 
    const { username, email, password, mobile } = req.body;
 
    // ── Validation ──────────────────────────────────────────────────────────
    if (!username || !email || !password) {
      return res.status(400).json({ message: "All fields required" });
    }
 
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ message: "Invalid email format" });
    }
 
    if (password.length < 6) {
      return res.status(400).json({ message: "Password must be at least 6 characters" });
    }
 
    if (mobile && !/^\+?[0-9]{7,15}$/.test(mobile)) {
      return res.status(400).json({ message: "Invalid mobile number format" });
    }
 
    // ── Duplicate check ─────────────────────────────────────────────────────
    const existing = await User.findOne({ $or: [{ username }, { email }] });
 
    if (existing) {
      // Allow re-registration if the previous attempt was never verified
      if (existing.isEmailVerified) {
        return res.status(409).json({ message: "User already exists" });
      }
 
      // Re-send OTP for the same unverified account
      const otp    = generateOTP();
      const expiry = new Date(Date.now() + 10 * 60 * 1000); // 10 min
 
      existing.emailVerificationOTP       = otp;
      existing.emailVerificationOTPExpiry = expiry;
      if (mobile) existing.mobile         = mobile;
 
      await existing.save();
      await sendVerificationOTP(email, username, otp);
 
      return res.status(200).json({
        message: "OTP resent. Please verify your email.",
        email
      });
    }
 
    // ── Create user ─────────────────────────────────────────────────────────
    const hash   = await bcrypt.hash(password, 10);
    const otp    = generateOTP();
    const expiry = new Date(Date.now() + 10 * 60 * 1000);
 
    await User.create({
      username,
      email,
      password: hash,
      mobile:   mobile || "",
      isEmailVerified:          false,
      emailVerificationOTP:     otp,
      emailVerificationOTPExpiry: expiry
    });
 
    // ── Send OTP via Brevo ──────────────────────────────────────────────────
    await sendVerificationOTP(email, username, otp);
 
    res.status(201).json({
      message: "Registration successful. Please verify your email with the OTP sent.",
      email
    });
 
  } catch (error) {
    console.error("Register Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
 
}
 
// ─── VERIFY EMAIL ────────────────────────────────────────────────────────────
 
/**
 * POST /auth/verify-email
 * Body: { email, otp }
 *
 * Marks the user as verified and returns a JWT on success.
 */
async function verifyEmail(req, res) {
 
  try {
 
    const { email, otp } = req.body;
 
    if (!email || !otp) {
      return res.status(400).json({ message: "Email and OTP are required" });
    }
 
    const user = await User
      .findOne({ email })
      .select("+emailVerificationOTP +emailVerificationOTPExpiry");
 
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
 
    if (user.isEmailVerified) {
      return res.status(400).json({ message: "Email is already verified" });
    }
 
    if (!user.emailVerificationOTP || user.emailVerificationOTP !== otp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }
 
    if (user.emailVerificationOTPExpiry < new Date()) {
      return res.status(400).json({ message: "OTP has expired. Please register again to get a new OTP." });
    }
 
    // ── Mark verified, clear OTP fields ─────────────────────────────────────
    user.isEmailVerified          = true;
    user.emailVerificationOTP     = undefined;
    user.emailVerificationOTPExpiry = undefined;
 
    await user.save();
 
    const token = signToken(user._id);
 
    res.status(200).json({
      message: "Email verified successfully",
      token,
      user: {
        id:       user._id,
        username: user.username,
        email:    user.email,
        mobile:   user.mobile
      }
    });
 
  } catch (error) {
    console.error("Verify Email Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
 
}
 
// ─── RESEND OTP ──────────────────────────────────────────────────────────────
 
/**
 * POST /auth/resend-otp
 * Body: { email }
 */
async function resendOTP(req, res) {
 
  try {
 
    const { email } = req.body;
 
    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }
 
    const user = await User
      .findOne({ email })
      .select("+emailVerificationOTP +emailVerificationOTPExpiry");
 
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
 
    if (user.isEmailVerified) {
      return res.status(400).json({ message: "Email is already verified" });
    }
 
    const otp    = generateOTP();
    const expiry = new Date(Date.now() + 10 * 60 * 1000);
 
    user.emailVerificationOTP       = otp;
    user.emailVerificationOTPExpiry = expiry;
 
    await user.save();
    await sendVerificationOTP(email, user.username, otp);
 
    res.status(200).json({ message: "OTP resent successfully" });
 
  } catch (error) {
    console.error("Resend OTP Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
 
}
 
// ─── LOGIN ───────────────────────────────────────────────────────────────────
 
/**
 * POST /auth/login
 * Body: { email, password }
 *
 * Blocks login if email is not yet verified.
 */
async function LoginUser(req, res) {
 
  try {
 
    const { email, password } = req.body;
 
    if (!email || !password) {
      return res.status(400).json({ message: "Email and password required" });
    }
 
    const user = await User.findOne({ email }).select("+password");
 
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
 
    // ── Block unverified users ───────────────────────────────────────────────
    if (!user.isEmailVerified) {
      return res.status(403).json({
        message: "Email not verified. Please verify your email first.",
        requiresVerification: true,
        email: user.email
      });
    }
 
    if (!user.password) {
      return res.status(500).json({ message: "User password missing. Please register again." });
    }
 
    const isMatch = await bcrypt.compare(password, user.password);
 
    if (!isMatch) {
      return res.status(401).json({ message: "Invalid password" });
    }
 
    const token = signToken(user._id);
 
    res.status(200).json({
      message: "Login successful",
      token,
      user: {
        id:       user._id,
        username: user.username,
        email:    user.email,
        mobile:   user.mobile
      }
    });
 
  } catch (error) {
    console.error("Login Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
 
}
 
// ─── LOGOUT ──────────────────────────────────────────────────────────────────
 
function logout(req, res) {
  res.json({ message: "Logged out" });
}
 
// ─── EXPORTS ─────────────────────────────────────────────────────────────────
 
module.exports = {
  registerUser,
  verifyEmail,
  resendOTP,
  LoginUser,
  logout
};
 