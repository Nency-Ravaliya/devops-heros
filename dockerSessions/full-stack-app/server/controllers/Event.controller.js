import Event from "../models/Event.model.js";
import Monastery from "../models/Monastery.model.js";

export const post_event = async (req, res) => {
  try {
    const event = await Event.create(req.body);
    const monastery = await Monastery.findById(event.monastery).populate(
      "events"
    );
    monastery.events.push(event._id);
    await monastery.save();
    const populated_event = await Event.findById(event._id).populate("monastery", "_id name featured")
    res.status(201).json(populated_event);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const get_events = async (req, res) => {
  const events = await Event.find({}).populate("monastery", "_id name featured");
  res.status(200).send(events);
};

export const get_event = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id).populate("monastery", "_id name featured");
    if (!event) return res.status(404).json({ error: "Not found" });
    res.status(200).json(event);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const update_event = async (req, res) => {
  try {
    const event = await Event.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
    });
    if (!event) return res.status(404).json({ error: "Not found" });
    res.json(event);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const delete_event = async (req, res) => {
  try {
    const event = await Event.findByIdAndDelete(req.params.id);
    if (!event) return res.status(404).json({ error: "Not found" });
    res.json({ message: "Deleted successfully" });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};
