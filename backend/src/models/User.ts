import mongoose, { Schema, type Document, Types } from "mongoose";

export interface IUser extends Document {
  _id: Types.ObjectId;
  clerkId: string;
  name: string;
  email: string;
  avatar: string;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema = new Schema<IUser>(// a generic
  {
    clerkId: {
      type: String,
      required: true,
      unique: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    avatar: {
      type: String,
      default: "",
    },
  },
  {
    timestamps: true,
  }
);

export const User = mongoose.model("User", UserSchema);
