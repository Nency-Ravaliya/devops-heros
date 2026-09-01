import { v2 as cloudinary } from "cloudinary";
import path from "path";
import fs from "fs";
import dotenv from "dotenv";

dotenv.config();

// Make sure CLOUDINARY_URL exists
if (!process.env.CLOUDINARY_URL) {
  throw new Error("Missing CLOUDINARY_URL in .env");
}

// Manually parse CLOUDINARY_URL
// Format: cloudinary://<api_key>:<api_secret>@<cloud_name>
const match = process.env.CLOUDINARY_URL.match(
  /^cloudinary:\/\/(?<api_key>[^:]+):(?<api_secret>[^@]+)@(?<cloud_name>.+)$/
);

if (!match?.groups) {
  throw new Error("Invalid CLOUDINARY_URL format");
}

// Pass credentials explicitly
cloudinary.config({
  cloud_name: match.groups.cloud_name,
  api_key: match.groups.api_key,
  api_secret: match.groups.api_secret,
});

console.log("Cloudinary config loaded:", {
  cloud_name: match.groups.cloud_name,
  api_key_present: !!match.groups.api_key,
  api_secret_present: !!match.groups.api_secret,
});

const upload_to_cloud = async (file, isPublic = false) => {
  try {
    const localPath = path.resolve(file.path);
    console.log(
      "Uploading file:",
      localPath,
      "exists:",
      fs.existsSync(localPath)
    );
    const response = await cloudinary.uploader.upload(localPath, {
      resource_type: "auto",
      type: isPublic ? "upload" : "authenticated",
    });
    console.log("Upload successful:", response.secure_url);
    return { fileUrl: response.secure_url, publicId: response.public_id };
  } catch (error) {
    console.error("Cloudinary upload error:", error);
    throw error;
  }
};

export default upload_to_cloud;
