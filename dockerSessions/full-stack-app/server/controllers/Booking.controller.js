import Booking from "../models/Booking.model.js";
import Event from "../models/Event.model.js";

export const get_bookings = async (req, res) => {
    try {
        const bookings = await Booking.find({}).populate("event", "_id name startDate endDate")
        res.status(200).send(bookings)
    } catch (e) {
        res.status(404).send(e)       
    }
}

export const post_booking = async (req, res) => {
    try {
        const booking = await Booking.create(req.body)
        const event = await Event.findById(booking.event).populate("bookings")
        event.bookings.push(booking._id)
        await event.save()
        const populated_booking = await Booking.findById(booking._id).populate("event", "_id name startDate endDate")
        res.status(201).send(populated_booking)
    } catch (e) {
        res.status(400).send(e)
    }
}