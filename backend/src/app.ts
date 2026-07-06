import express from "express";

import { clerkMiddleware } from '@clerk/express'
import authRoutes from "./routes/authRoutes";
import chatRoutes from "./routes/chatRoutes";
import messageRoutes from "./routes/messageRoutes";
import userRoutes from "./routes/userRoutes";

import { errorHandler } from "./middleware/errorHandler";

const app = express();

app.use(express.json()); // middleware  that converts incoming JSON requests into Jvascript objects that can be easily accessed and manipulated within the application.

app.use(clerkMiddleware())// if user is logged in, clerkMiddleware will add the user object to the request, which can be accessed in the route handlers. If the user is not logged in, it will return a 401 Unauthorized response.

app.get("/health", (req,res) => {
  res.json({status:"ok", message: "server is running"})
});

app.use("/api/auth", authRoutes);// mounts a router on the /api/auth path. This means that any requests to /api/auth will be handled by the authRoutes router, which contains the route handlers for authentication-related endpoints.
app.use("/api/chats", chatRoutes);
app.use("/api/messages", messageRoutes);
app.use("/api/users", userRoutes);

app.use(errorHandler);

export default app;// the app object is exported  so that another file can import it and use it to start the server or perform other operations.
