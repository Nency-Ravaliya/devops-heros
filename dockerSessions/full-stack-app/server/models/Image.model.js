import mongoose from "mongoose";

const Image = mongoose.model(
  "Image",
  new mongoose.Schema(
    {
      fileUrl: { type: String, required: true }, // Cloudinary URL
      publicId: { type: String, required: true }, // Cloudinary public ID
      caption: { type: String },
      monastery: { type: mongoose.Schema.Types.ObjectId, ref: "Monastery" },
    },
    { timestamps: true }
  )
);

export default Image;
