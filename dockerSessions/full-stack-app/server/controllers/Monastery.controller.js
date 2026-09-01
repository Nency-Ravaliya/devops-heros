import Monastery from "../models/Monastery.model.js";

export const post_monastery = async (req, res) => {
  try {
    const monastery = await Monastery.create(req.body);
    res.status(201).json(monastery);
  } catch (e) {
    res.status(400).send({ error: e.message ? e.message : e });
  }
};

export const get_monasteries = async (req, res) => {
  try {
    const monasteries = await Monastery.find({});
    res.status(200).json(monasteries);
  } catch (e) {
    res.status(404).send({ error: e.message ? e.message : e });
  }
};

export const get_monastery = async (req, res) => {
  try {
    const monastery = await Monastery.findById(req.params.id);
    res.status(200).json(monastery);
  } catch (e) {
    res.status(404).send({ error: e.message ? e.message : e });
  }
};

export const update_monastery = async (req, res) => {
  try {
    const monastery = await Monastery.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    if (!monastery) return res.status(404).json({ error: "Not found" });
    res.json(monastery);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
};

export const delete_monastery = async (req, res) => {
  try {
    const monastery = await Monastery.findByIdAndDelete(req.params.id);
    if (!monastery) return res.status(404).json({ error: "Not found" });
    res.json({ message: "Deleted successfully" });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
};
