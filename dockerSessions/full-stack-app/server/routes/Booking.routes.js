import express from "express";
import {
  get_bookings,
  post_booking,
} from "../controllers/Booking.controller.js";

const booking_routes = express.Router();

booking_routes.get("/", get_bookings);
booking_routes.post("/", post_booking);

export default booking_routes;
