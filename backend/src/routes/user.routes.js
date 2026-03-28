const express = require("express");
const router = express.Router();

const userController = require("../controllers/user.controller");
const auth = require("../middleware/auth.middleware");


// GET ALL USERS
router.get("/", userController.getUsers);

// GET CURRENT USER
router.get("/me", auth, userController.getCurrentUser);

// CHANGE PASSWORD
router.patch("/password", auth, userController.changePassword);

module.exports = router;