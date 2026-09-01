import express from "express";
import { get_images, post_image } from "../controllers/Image.controller.js";
import upload from "../middlewares/Multer.js"

const image_routes = express.Router();

image_routes.post("/", upload.single("file"), post_image);
image_routes.get("/", get_images);

export default image_routes;
