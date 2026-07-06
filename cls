warning: in the working copy of 'web/.gitignore', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'web/bun.lock', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'web/package.json', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'web/src/App.jsx', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'web/src/main.jsx', LF will be replaced by CRLF the next time Git touches it
[1mdiff --git a/backend/src/app.ts b/backend/src/app.ts[m
[1mindex 2d4c2f4..706402b 100644[m
[1m--- a/backend/src/app.ts[m
[1m+++ b/backend/src/app.ts[m
[36m@@ -1,14 +1,19 @@[m
 import express from "express";[m
 [m
[32m+[m[32mimport { clerkMiddleware } from '@clerk/express'[m
 import authRoutes from "./routes/authRoutes";[m
 import chatRoutes from "./routes/chatRoutes";[m
 import messageRoutes from "./routes/messageRoutes";[m
 import userRoutes from "./routes/userRoutes";[m
 [m
[32m+[m[32mimport { errorHandler } from "./middleware/errorHandler";[m
[32m+[m
 const app = express();[m
 [m
 app.use(express.json()); // parse incoming JSON bodies  and make them available as req.body in your Route Handlers[m
 [m
[32m+[m[32mapp.use(clerkMiddleware())[m
[32m+[m
 app.get("/health", (req,res) => {[m
   res.json({status:"ok", message: "server is running"})[m
 });[m
[36m@@ -18,4 +23,6 @@[m [mapp.use("/api/chats", chatRoutes);[m
 app.use("/api/messages", messageRoutes);[m
 app.use("/api/users", userRoutes);[m
 [m
[32m+[m[32mapp.use(errorHandler);[m
[32m+[m
 export default app;[m
[1mdiff --git a/backend/src/controllers/authController.ts b/backend/src/controllers/authController.ts[m
[1mindex e69de29..f1af39b 100644[m
[1m--- a/backend/src/controllers/authController.ts[m
[1m+++ b/backend/src/controllers/authController.ts[m
[36m@@ -0,0 +1,54 @@[m
[32m+[m[32mimport type { NextFunction, Request, Response } from "express";[m
[32m+[m[32mimport type { AuthRequest } from "../middleware/auth";[m
[32m+[m[32mimport { User } from "../models/User";[m
[32m+[m[32mimport { clerkClient, getAuth } from "@clerk/express";[m
[32m+[m
[32m+[m[32mexport async function getMe(req: AuthRequest, res: Response, next: NextFunction) {[m
[32m+[m[32m  try {[m
[32m+[m[32m    const userId = req.userId;[m
[32m+[m
[32m+[m[32m    const user = await User.findById(userId);[m
[32m+[m
[32m+[m[32m    if (!user) {[m
[32m+[m[32m      res.status(404).json({ message: "User not found" });[m
[32m+[m[32m      return;[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    res.status(200).json(user);[m
[32m+[m[32m  } catch (error) {[m
[32m+[m[32m    res.status(500);[m
[32m+[m[32m    next(error);[m
[32m+[m[32m  }[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mexport async function authCallback(req: Request, res: Response, next: NextFunction) {[m
[32m+[m[32m  try {[m
[32m+[m[32m    const { userId: clerkId } = getAuth(req);[m
[32m+[m
[32m+[m[32m    if (!clerkId) {[m
[32m+[m[32m      res.status(401).json({ message: "Unauthorized" });[m
[32m+[m[32m      return;[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    let user = await User.findOne({ clerkId });[m
[32m+[m
[32m+[m[32m    if (!user) {[m
[32m+[m[32m      // get user info from clerk and save to db[m
[32m+[m[32m      const clerkUser = await clerkClient.users.getUser(clerkId);[m
[32m+[m
[32m+[m[32m      user = await User.create({[m
[32m+[m[32m        clerkId,[m
[32m+[m[32m        name: clerkUser.firstName[m
[32m+[m[32m          ? `${clerkUser.firstName} ${clerkUser.lastName || ""}`.trim()[m
[32m+[m[32m          : clerkUser.emailAddresses[0]?.emailAddress?.split("@")[0],[m
[32m+[m[32m        email: clerkUser.emailAddresses[0]?.emailAddress,[m
[32m+[m[32m        avatar: clerkUser.imageUrl,[m
[32m+[m[32m      });[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    res.json(user);[m
[32m+[m[32m  } catch (error) {[m
[32m+[m[32m    res.status(500);[m
[32m+[m[32m    next(error);[m
[32m+[m[32m  }[m
[32m+[m[32m}[m
[1mdiff --git a/backend/src/middleware/auth.ts b/backend/src/middleware/auth.ts[m
[1mindex e69de29..4860fba 100644[m
[1m--- a/backend/src/middleware/auth.ts[m
[1m+++ b/backend/src/middleware/auth.ts[m
[36m@@ -0,0 +1,29 @@[m
[32m+[m[32mimport type { Request, Response, NextFunction } from "express";[m
[32m+[m[32mimport { getAuth } from "@clerk/express";[m
[32m+[m[32mimport { User } from "../models/User";[m
[32m+[m[32mimport { requireAuth } from "@clerk/express";[m
[32m+[m
[32m+[m[32mexport type AuthRequest = Request & {[m
[32m+[m[32m  userId?: string;[m
[32m+[m[32m};[m
[32m+[m
[32m+[m[32mexport const protectRoute = [[m
[32m+[m[32m  requireAuth(),[m
[32m+[m[32m  async (req: AuthRequest, res: Response, next: NextFunction) => {[m
[32m+[m[32m    try {[m
[32m+[m[32m      const { userId: clerkId } = getAuth(req);[m
[32m+[m[32m      // since we call requireAuth() this if check is not necessary[m
[32m+[m[32m      // if (!clerkId) return res.status(401).json({ message: "Unauthorized - invalid token" });[m
[32m+[m
[32m+[m[32m      const user = await User.findOne({ clerkId });[m
[32m+[m[32m      if (!user) return res.status(404).json({ message: "User not found" });[m
[32m+[m
[32m+[m[32m      req.userId = user._id.toString();[m
[32m+[m
[32m+[m[32m      next();[m
[32m+[m[32m    } catch (error) {[m
[32m+[m[32m      res.status(500);[m
[32m+[m[32m      next(error);[m
[32m+[m[32m    }[m
[32m+[m[32m  },[m
[32m+[m[32m];[m
[1mdiff --git a/backend/src/middleware/errorHandler.ts b/backend/src/middleware/errorHandler.ts[m
[1mindex e69de29..81763f2 100644[m
[1m--- a/backend/src/middleware/errorHandler.ts[m
[1m+++ b/backend/src/middleware/errorHandler.ts[m
[36m@@ -0,0 +1,15 @@[m
[32m+[m[32mimport type { Request, Response, NextFunction } from "express";[m
[32m+[m
[32m+[m[32mexport const errorHandler = (err: Error, _req: Request, res: Response, _next: NextFunction) => {[m
[32m+[m[32m  console.log("Error:", err.message);[m
[32m+[m
[32m+[m[32m  const statusCode = res.statusCode !== 200 ? res.statusCode : 500;[m
[32m+[m
[32m+[m[32m  res.status(statusCode).json({[m
[32m+[m[32m    message: err.message || "Internal Server Error",[m
[32m+[m[32m    ...(process.env.NODE_ENV === "development" && { stack: err.stack }),[m
[32m+[m[32m  });[m
[32m+[m[32m};[m
[32m+[m
[32m+[m[32m// if status code is 200 and we still hit the error handler that means it's an internal error[m
[32m+[m[32m// so we set the status code as 500[m
[1mdiff --git a/backend/src/models/User.ts b/backend/src/models/User.ts[m
[1mindex afe17a2..e59dbf5 100644[m
[1m--- a/backend/src/models/User.ts[m
[1m+++ b/backend/src/models/User.ts[m
[36m@@ -1,6 +1,7 @@[m
[31m-import mongoose, { Schema, type Document } from "mongoose";[m
[32m+[m[32mimport mongoose, { Schema, type Document, Types } from "mongoose";[m
 [m
 export interface IUser extends Document {[m
[32m+[m[32m  _id: Types.ObjectId;[m
   clerkId: string;[m
   name: string;[m
   email: string;[m
[1mdiff --git a/backend/src/routes/authRoutes.ts b/backend/src/routes/authRoutes.ts[m
[1mindex 41250a3..a08c175 100644[m
[1m--- a/backend/src/routes/authRoutes.ts[m
[1m+++ b/backend/src/routes/authRoutes.ts[m
[36m@@ -1,5 +1,11 @@[m
 import { Router } from "express";[m
[32m+[m[32mimport { protectRoute } from "../middleware/auth";[m
[32m+[m[32mimport { authCallback, getMe } from "../controllers/authController";[m
[32m+[m
 [m
 const router = Router();[m
 [m
[32m+[m[32mrouter.get("/me", protectRoute, getMe);[m
[32m+[m[32mrouter.post("/callback",   authCallback);[m
[32m+[m
 export default router;[m
[1mdiff --git a/web/.gitignore b/web/.gitignore[m
[1mindex a547bf3..26a3ac4 100644[m
[1m--- a/web/.gitignore[m
[1m+++ b/web/.gitignore[m
[36m@@ -7,6 +7,8 @@[m [myarn-error.log*[m
 pnpm-debug.log*[m
 lerna-debug.