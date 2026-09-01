import e from "express";
import upload from "../middlewares/Multer.js";
import {
  post_archive,
  get_archives,
  get_archive,
} from "../controllers/Archive.controller.js";

const archive_routes = e.Router();

archive_routes.post("/", upload.single("file"), post_archive);
archive_routes.get("/", get_archives);
archive_routes.get("/search", get_archive);

export default archive_routes;
