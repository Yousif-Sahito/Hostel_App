import express from "express";
import {
  getRooms,
  createRoom,
  updateRoom,
  deleteRoom
} from "../controllers/room.controller.js";
import { protect } from "../middleware/auth.middleware.js";
import { allowRoles } from "../middleware/role.middleware.js";

const router = express.Router();

router.get("/", protect, getRooms);
router.post("/", protect, allowRoles("ADMIN"), createRoom);
router.put("/:id", protect, allowRoles("ADMIN"), updateRoom);
router.delete("/:id", protect, allowRoles("ADMIN"), deleteRoom);

export default router;