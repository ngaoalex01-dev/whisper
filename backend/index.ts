
import "dotenv/config";
import app from "./src/app";
import { connectDB } from "./src/config/database";

const PORT = process.env.PORT;

connectDB().then(() => {
  app.listen(PORT, () => {// start the express server
    console.log("✅Server is running on PORT:", PORT);
  });
})
.catch((error) => {
  console.error("failed to start server", error);
  process.exit(1);
});
