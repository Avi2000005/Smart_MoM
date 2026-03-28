const express = require("express");
const router = express.Router();

const auth = require("../middleware/auth.middleware");
const taskController = require("../controllers/task.controller");


router.get("/", auth, taskController.getTasks);
router.post("/", auth, taskController.createTask);
router.patch("/:taskId", auth, taskController.toggleTask);
router.delete("/:taskId", auth, taskController.deleteTask);


module.exports = router;