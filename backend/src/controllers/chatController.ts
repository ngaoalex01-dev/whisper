import type { Response, NextFunction } from "express";
import type { AuthRequest } from "../middleware/auth";
import { Chat } from "../models/Chat";
import { Types } from "mongoose";

export async function getChats(req: AuthRequest, res: Response, next: NextFunction) {

  try {
    const userId = req.userId;

    if (!userId) {
      res.status(401).json({ message: "Unauthorized" });
      return;
    }

    const chats = await Chat.find({ participants: userId }).populate("participants", "name email avatar").populate("lastMessage").sort({ lastMessageAt: -1 });

    const formattedChats = chats.map((chat) => {
      const otherParticipant = chat.participants.find((participant) => participant._id.toString() !== userId);

      return {
        _id: chat._id,
        participant: otherParticipant,
        lastMessage: chat.lastMessage,
        lastMessageAt: chat.lastMessageAt,
        createdAt: chat.createdAt,
      };
    });

      res.json(formattedChats);

  } catch (error) {
    res.status(500);
    next(error);
  }
}

export async function getorCreateChat(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.userId;

    if (!userId) {
      res.status(401).json({ message: "Unauthorized" });
      return;
    }

    const participantIdParam = req.params.participantId;
    const participantId = Array.isArray(participantIdParam) ? participantIdParam[0] : participantIdParam;

    if (typeof participantId !== "string" || participantId.trim() === "") {
      res.status(400).json({ message: "Participant ID is required" });
      return;
    }

    if(!Types.ObjectId.isValid(participantId)) {
      res.status(400).json({ message: "Invalid participant ID" });
      return;
    }

    if (userId === participantId) {
      res.status(400).json({ message: "Cannot create a chat with yourself" });
      return;
    }

    //check if the chat already exists
    let chat = await Chat.findOne({
      participants: { $all: [userId, participantId] },
    }).populate("participants", "name email avatar").populate("lastMessage");

    if (!chat) {
      //create a new chat
      const newChat = new Chat({
        participants: [userId, participantId],
      });
      await newChat.save();
      chat = await newChat.populate("participants", "name email avatar");
    }

    const otherParticipant = chat.participants.find((participant) => participant._id.toString() !== userId);

      res.json({
        _id: chat._id,
        participant: otherParticipant ?? null,
        lastMessage: chat.lastMessage,
        lastMessageAt: chat.lastMessageAt,
        createdAt: chat.createdAt,
      });

  } catch (error) {
    res.status(500);
    next(error);
  }
};
