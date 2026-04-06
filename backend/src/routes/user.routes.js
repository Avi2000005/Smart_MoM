// routes/user.routes.js

const express    = require("express");
const router     = express.Router();
const auth       = require("../middleware/auth.middleware");
const controller = require("../controllers/user.controller");

router.get("/",          controller.getUsers);           // GET all verified users
router.get("/search",    auth, controller.searchUsers);  // GET search?q=john
router.get("/me",        auth, controller.getCurrentUser);
router.patch("/password",auth, controller.changePassword);

module.exports = router;