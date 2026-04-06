const User = require("../models/user.model");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const { sendVerificationOTP, sendPasswordResetOTP } = require("../services/Brevo.service");

// ─── Helpers ────────────────────────────────────────────────────────────────

function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function signToken(userId) {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: "7d" });
}

// ─── REGISTER ───────────────────────────────────────────────────────────────

async function registerUser(req, res) {
  try {
    let { username, email, password, mobile } = req.body;
    if (email) email = email.toLowerCase();

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

    const existingVerified = await User.findOne({
      email,
      isEmailVerified: true
    });

    if (existingVerified) {
      return res.status(409).json({ message: "User already exists with this email" });
    }

    // Safely wipe out any uncompleted/unverified registration attempts 
    // that might be hoarding this email in the DB.
    await User.deleteMany({
      email,
      isEmailVerified: false
    });

    const hash   = await bcrypt.hash(password, 10);
    const otp    = generateOTP();
    const expiry = new Date(Date.now() + 10 * 60 * 1000);

    const newUser = await User.create({
      username,
      email,
      password: hash,
      mobile:   mobile || "",
      isEmailVerified:            false,
      emailVerificationOTP:       otp,
      emailVerificationOTPExpiry: expiry
    });

    await sendVerificationOTP(email, username, otp);

    res.status(201).json({
      message: "Registration started. Please verify your email with the OTP sent.",
      email
    });

  } catch (error) {
    console.error("Register Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
}

// ─── VERIFY EMAIL ────────────────────────────────────────────────────────────

async function verifyEmail(req, res) {
  try {
    let { email, otp } = req.body;
    if (email) email = email.toLowerCase();

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

    user.isEmailVerified            = true;
    user.emailVerificationOTP       = undefined;
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

async function resendOTP(req, res) {
  try {
    let { email } = req.body;
    if (email) email = email.toLowerCase();

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

async function LoginUser(req, res) {
  try {
    let { email, password } = req.body;
    if (email) email = email.toLowerCase();

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password required" });
    }

    const user = await User.findOne({ email }).select("+password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

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

// ─── FORGOT PASSWORD — STEP 1: Send OTP ─────────────────────────────────────

async function forgotPassword(req, res) {
  try {
    let { email } = req.body;
    if (email) email = email.toLowerCase();

    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }

    const user = await User
      .findOne({ email })
      .select("+resetOtp +resetOtpExpiry");

    // Always return success to prevent email enumeration
    if (!user || !user.isEmailVerified) {
      return res.status(200).json({
        message: "If this email exists, an OTP has been sent."
      });
    }

    const otp    = generateOTP();
    const expiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    user.resetOtp       = otp;
    user.resetOtpExpiry = expiry;
    await user.save();

    await sendPasswordResetOTP(email, user.username, otp);

    res.status(200).json({
      message: "If this email exists, an OTP has been sent."
    });

  } catch (error) {
    console.error("Forgot Password Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
}

// ─── FORGOT PASSWORD — STEP 2: Verify OTP ───────────────────────────────────

async function verifyResetOtp(req, res) {
  try {
    let { email, otp } = req.body;
    if (email) email = email.toLowerCase();

    if (!email || !otp) {
      return res.status(400).json({ message: "Email and OTP are required" });
    }

    const user = await User
      .findOne({ email })
      .select("+resetOtp +resetOtpExpiry +password");

    if (!user || !user.resetOtp) {
      return res.status(400).json({ message: "Invalid or expired OTP" });
    }

    if (new Date() > user.resetOtpExpiry) {
      user.resetOtp       = undefined;
      user.resetOtpExpiry = undefined;
      await user.save();
      return res.status(400).json({
        message: "OTP has expired. Please request a new one."
      });
    }

    if (user.resetOtp !== otp) {
      return res.status(400).json({ message: "Incorrect OTP" });
    }

    // Issue a short-lived reset token — invalidates after password changes
    const resetToken = jwt.sign(
      { id: user._id },
      process.env.JWT_SECRET + user.password,
      { expiresIn: "10m" }
    );

    res.status(200).json({ message: "OTP verified", resetToken });

  } catch (error) {
    console.error("Verify Reset OTP Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
}

// ─── FORGOT PASSWORD — STEP 3: Reset Password ───────────────────────────────

async function resetPassword(req, res) {
  try {
    let { email, resetToken, newPassword } = req.body;
    if (email) email = email.toLowerCase();

    if (!email || !resetToken || !newPassword) {
      return res.status(400).json({ message: "All fields are required" });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        message: "Password must be at least 6 characters"
      });
    }

    const user = await User
      .findOne({ email })
      .select("+password +resetOtp +resetOtpExpiry");

    if (!user) {
      return res.status(400).json({ message: "Invalid request" });
    }

    // Verify reset token — will throw if expired or tampered
    try {
      jwt.verify(resetToken, process.env.JWT_SECRET + user.password);
    } catch (e) {
      return res.status(400).json({
        message: "Reset session expired. Please start again."
      });
    }

    // Hash and save new password, clear OTP fields
    user.password       = await bcrypt.hash(newPassword, 10);
    user.resetOtp       = undefined;
    user.resetOtpExpiry = undefined;
    await user.save();

    res.status(200).json({
      message: "Password reset successful. Please log in."
    });

  } catch (error) {
    console.error("Reset Password Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
}

// ─── EXPORTS ─────────────────────────────────────────────────────────────────

module.exports = {
  registerUser,
  verifyEmail,
  resendOTP,
  LoginUser,
  logout,
  forgotPassword,
  verifyResetOtp,
  resetPassword
};