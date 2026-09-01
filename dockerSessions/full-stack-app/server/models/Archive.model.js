import mongoose from "mongoose";

const ArchiveSchema = new mongoose.Schema({
  title: { type: String, required: true },
  fileUrl: { type: String, required: true }, // Cloudinary URL
  publicId: { type: String, required: true }, // Cloudinary public ID
  filetype: { type: String, required: true },
  tags: [String],
  uploadedBy: { type: String, required: true },
  uploadDate: { type: Date, default: Date.now() },
});
ArchiveSchema.index({ title: "text", tags: "text" });

const Archive = mongoose.model("Archive", ArchiveSchema);

export default Archive;
