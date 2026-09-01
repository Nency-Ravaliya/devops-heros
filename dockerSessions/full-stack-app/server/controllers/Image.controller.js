import fs from "fs";
import Image from "../models/Image.model.js";
import Monastery from "../models/Monastery.model.js";
import upload_to_cloud from "../config/Cloudinary.js";

export const post_image = async (req, res) => {
  try {
    console.log("req.file:", req.file);
    console.log("req.file.path:", req.file?.path);
    console.log(
      "file exists:",
      req.file ? fs.existsSync(req.file.path) : false
    );
    console.log("Content-Type header:", req.headers["content-type"]);
    const { caption, monastery } = req.body;
    let cloud_response;
    if (req.file) cloud_response = await upload_to_cloud(req.file);
    else return res.status(404).json({ message: "No Media File Detected" });

    console.log("cloud_response:", cloud_response);
    if (!cloud_response || !cloud_response.fileUrl) {
      return res
        .status(500)
        .json({ message: "Cloud upload returned no URL", cloud_response });
    }
    const { fileUrl, publicId } = cloud_response;
    const image = await Image.create({
      fileUrl,
      publicId,
      caption,
      monastery,
    });
    const populated_monastery = await Monastery.findById(
      image.monastery
    ).populate("images");
    populated_monastery.images.push(image._id);
    await populated_monastery.save();
    const populated_image = await Image.findById(image._id).populate(
      "monastery",
      "_id name location"
    );
    res.status(201).send(populated_image);
  } catch (e) {
    res.status(400).send(e);
  }
};

export const get_images = async (req, res) => {
  try {
    const images = await Image.find({}).populate("monastery", "_id name location");
    res.status(200).send(images);
  } catch (e) {
    res.status(404).send(e);
  }
};
