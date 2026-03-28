// routes/notification.routes.js
 
const express    = require("express");
const router     = express.Router();
const auth       = require("../middleware/auth.middleware");
const controller = require("../controllers/notification.controller");
 
router.get("/",              auth, controller.getNotifications);   // GET all
router.get("/unread-count",  auth, controller.getUnreadCount);     // GET unread count
router.patch("/read-all",    auth, controller.markAllAsRead);      // PATCH mark all read
router.patch("/:id/read",    auth, controller.markAsRead);         // PATCH mark one read
router.delete("/:id",        auth, controller.deleteNotification); // DELETE one
 
module.exports = router;