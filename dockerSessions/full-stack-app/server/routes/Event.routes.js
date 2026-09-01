import express from "express";
import {
  delete_event,
  get_event,
  get_events,
  post_event,
  update_event,
} from "../controllers/Event.controller.js";

const event_routes = express.Router();

event_routes.get("/", get_events);
event_routes.get("/:id", get_event);
event_routes.post("/", post_event);
event_routes.put("/:id", update_event);
event_routes.delete("/:id", delete_event);

export default event_routes;
