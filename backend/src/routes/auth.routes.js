// routes/auth.routes.js
 
const express = require("express");
const router  = express.Router();
 
const authController = require("../controllers/auth.controller");
 
router.post("/register",     authController.registerUser);
router.post("/verify-email", authController.verifyEmail);
router.post("/resend-otp",   authController.resendOTP);
router.post("/login",        authController.LoginUser);
router.post("/logout",       authController.logout);
router.post("/forgot-password",  authController.forgotPassword);   // Step 1 — send OTP
router.post("/verify-reset-otp", authController.verifyResetOtp);   // Step 2 — verify OTP
router.post("/reset-password",   authController.resetPassword);    // Step 3 — new password

module.exports = router;