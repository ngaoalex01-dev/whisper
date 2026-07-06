import type { NextFunction, Request, Response } from "express";// this line  doesnt exist at runtime, it is only used for type checking during development. It helps developers catch type-related errors and provides better autocompletion and documentation in IDEs.
import type { AuthRequest } from "../middleware/auth";
import { User } from "../models/User";
import { clerkClient, getAuth } from "@clerk/express";
//clerkClient helps my backend communicate with Clerk's API to perform operations like fetching user details, creating users, etc. getAuth extracts the authentication information from the request object, allowing us to access the authenticated user's ID and other details.
export async function getMe(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.userId;

    const user = await User.findById(userId);

    if (!user) {
      res.status(404).json({ message: "User not found" });
      return;
    }

    res.status(200).json(user);
  } catch (error) {
    res.status(500);
    next(error);
  }
}

export async function authCallback(req: Request, res: Response, next: NextFunction) {
  try {
    const { userId: clerkId } = getAuth(req);

    if (!clerkId) {
      res.status(401).json({ message: "Unauthorized" });
      return;
    }

    let user = await User.findOne({ clerkId });

    if (!user) {
      // get user info from clerk and save to db
      const clerkUser = await clerkClient.users.getUser(clerkId);

      user = await User.create({
        clerkId,
        name: clerkUser.firstName
          ? `${clerkUser.firstName} ${clerkUser.lastName || ""}`.trim()
          : clerkUser.emailAddresses[0]?.emailAddress?.split("@")[0],
        email: clerkUser.emailAddresses[0]?.emailAddress,
        avatar: clerkUser.imageUrl,
      });
    }

    res.json(user);
  } catch (error) {
    res.status(500);
    next(error);
  }
}
