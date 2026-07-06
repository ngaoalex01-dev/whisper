import { Router } from "express";
import {getChats, getorCreateChat} from "../controllers/chatController";
import { protectRoute } from "../middleware/auth";

const router = Router();

router.use(protectRoute);

router.get("/", getChats);
router.post("/with/:participantId", getorCreateChat);


export default router;
