import mongoose from "mongoose";

const Booking = mongoose.model(
  "Booking",
  new mongoose.Schema(
    {
      event: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Event",
        required: true,
      },
      name: { type: String, required: true },
      email: { type: String, required: true },
      participants: { type: Number, default: 1 },
    },
    { timestamps: true }
  )
);

export default Booking;
