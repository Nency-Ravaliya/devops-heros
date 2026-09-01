import fs from "fs";
import upload_to_cloud from "../config/Cloudinary.js";
import Archive from "../models/Archive.model.js";

export const post_archive = async (req, res) => {
  try {
    console.log("req.file:", req.file);
    console.log("req.file.path:", req.file?.path);
    console.log(
      "file exists:",
      req.file ? fs.existsSync(req.file.path) : false
    );
    console.log("Content-Type header:", req.headers["content-type"]);
    const { title, filetype, tags, uploadedBy } = req.body;
    let cloud_response;
    if (req.file) cloud_response = await upload_to_cloud(req.file, true);
    else return res.status(404).json({ message: "No Media File Detected" });

    console.log("cloud_response:", cloud_response);
    if (!cloud_response || !cloud_response.fileUrl) {
      return res
        .status(500)
        .json({ message: "Cloud upload returned no URL", cloud_response });
    }
    const { fileUrl, publicId } = cloud_response;
    const archive = await Archive.create({
      title,
      fileUrl,
      publicId,
      filetype,
      tags,
      uploadedBy,
    });
    res.status(201).send(archive);
  } catch (err) {
    res.status(500).json({ error: "File upload failed", details: err });
  }
};

export const get_archives = async (req, res) => {
  try {
    const archives = await Archive.find({});
    res.status(200).send(archives);
  } catch (e) {
    res.status(404).send(e);
  }
};

export const get_archive = async (req, res) => {
  try {
    const query = req.query.q;
    const results = await Archive.find({ $text: { $search: query } });
    res.status(200).json(results);
  } catch (e) {
    res.status(404).send(e);
  }
};
