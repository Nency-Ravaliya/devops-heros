import express from "express";
import {
  delete_monastery,
  get_monasteries,
  get_monastery,
  post_monastery,
  update_monastery,
} from "../controllers/Monastery.controller.js";

const monastery_routes = express.Router();

monastery_routes.get("/", get_monasteries);
monastery_routes.get("/:id", get_monastery);
monastery_routes.post("/", post_monastery);
monastery_routes.put("/:id", update_monastery);
monastery_routes.delete("/:id", delete_monastery);

export default monastery_routes;
