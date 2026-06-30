import mongoose from "mongoose";

export const connectDB = async () => {

  try {

    const mongoUri = process.env.MONGODB_URI;
    if (!mongoUri) {
      throw new Error("MONGODB_URI environment variable  is not defined");
    }

    await mongoose.connect(mongoUri);
    console.log("✅ MongoDb connected Successfully");
  } catch (error) {
    console.error("❌ MongoDB connection error", error);
    process.exit(1); // 1 means failure
  }
};
