import React, { useRef, useEffect, useState } from "react";
import { post_archive } from "../api/archivecalls.js";

function ArchiveModal({ setopenModal }) {
  const modal_ref = useRef(null);

  const [input, setinput] = useState({
    name: "",
    title: "",
    file: null,
    tags: "",
  });

  const handleChange = (e) => {
    const { name, value, files } = e.target;
    if (name === "file") {
      setinput({ ...input, file: files[0] });
    } else {
      setinput({ ...input, [name]: value });
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const formdata = new FormData();
      formdata.append("title", input.title);
      formdata.append("file", input.file);
      formdata.append("filetype", input.file.type);
      input.tags.split(" ").forEach((tag) => formdata.append("tags", tag));
      formdata.append("uploadedBy", input.name);

      const response = await post_archive(formdata);
      console.log(response);
      window.location.reload();
    } catch (e) {
      console.log(e);
    }
  };

  useEffect(() => {
    const detect_mouse_click = (e) => {
      if (modal_ref.current && !modal_ref.current.contains(e.target))
        setopenModal(false);
    };
    document.addEventListener("mousedown", detect_mouse_click);
    return () => document.removeEventListener("mousedown", detect_mouse_click);
  }, []);

  return (
    <div className="fixed inset-0 z-[50] bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 overflow-hidden">
      <div
        ref={modal_ref}
        className="w-[95%] lg:max-w-[60%] h-[600px] bg-white rounded-2xl px-8 py-6 flex flex-col justify-center items-center overflow-auto relative shadow-xl"
      >
        <h2 className="text-3xl font-extrabold text-green-900 mb-6 text-center">
          Upload Archive
        </h2>
        <form className="w-full flex flex-col gap-5" onSubmit={handleSubmit}>
          <input
            type="text"
            name="name"
            placeholder="Your Name"
            className="p-3 border border-green-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-green-400"
            value={input.name}
            onChange={handleChange}
            required
          />
          <input
            type="text"
            name="title"
            placeholder="Title"
            className="p-3 border border-green-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-green-400"
            value={input.title}
            onChange={handleChange}
            required
          />
          <input
            type="file"
            name="file"
            className="p-2 border border-green-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-green-400"
            onChange={handleChange}
            required
          />
          <input
            type="text"
            name="tags"
            placeholder="Tags (comma separated)"
            className="p-3 border border-green-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-green-400"
            value={input.tags}
            onChange={handleChange}
          />
          <button
            type="submit"
            className="px-6 py-3 bg-green-600 text-white font-semibold rounded-full shadow hover:bg-green-700 transition mt-2"
          >
            Upload
          </button>
        </form>
      </div>
    </div>
  );
}

export default ArchiveModal;
