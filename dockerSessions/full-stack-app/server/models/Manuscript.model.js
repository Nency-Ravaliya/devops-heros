import mongoose from "mongoose";

const Manuscript = mongoose.model(
  "Manuscript",
  new mongoose.Schema(
    {
      title: { type: String, required: true },
      fileUrl: { type: String, required: true },
      description: { type: String },
      monastery: { type: mongoose.Schema.Types.ObjectId, ref: "Monastery" },
    },
    { timestamps: true }
  )
);

export default Manuscript