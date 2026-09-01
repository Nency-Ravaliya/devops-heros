import mongoose from "mongoose";

const Event = mongoose.model(
  "Event",
  new mongoose.Schema(
    {
      name: { type: String, required: true },
      startDate: { type: Date, required: true },
      endDate: {type: Date, required: true},
      description: { type: String },
      monastery: { type: mongoose.Schema.Types.ObjectId, ref: "Monastery" },
      bookings: [{ type: mongoose.Schema.Types.ObjectId, ref: "Booking" }],
    },
    { timestamps: true }
  )
);

export default Event;
