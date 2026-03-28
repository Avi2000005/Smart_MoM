const mongoose = require("mongoose");
 
const userSchema = new mongoose.Schema({
 
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
 
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
 
  password: {
    type: String,
    required: true,
    select: false
  },
 
  mobile: {
    type: String,
    trim: true,
    default: ""
  },
 
  isEmailVerified: {
    type: Boolean,
    default: false
  },
 
  emailVerificationOTP: {
    type: String,
    select: false
  },
 
  emailVerificationOTPExpiry: {
    type: Date,
    select: false
  }
 
}, { timestamps: true });
 
module.exports = mongoose.model("User", userSchema);