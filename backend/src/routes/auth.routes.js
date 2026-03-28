const express = require("express");
const router = express.Router();

const authController = require("../controllers/auth.controller");

router.post("/register", authController.registerUser);
router.post("/login", authController.LoginUser);
router.post("/logout", authController.logout);

module.exports = router;