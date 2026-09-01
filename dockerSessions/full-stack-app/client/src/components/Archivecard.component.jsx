import React from "react";

function Archivecard({ archive }) {
  return (
    <a
      href={archive.fileUrl}
      target="_blank"
      rel="noopener noreferrer"
      className="block"
    >
      <div className="bg-white shadow-md rounded-2xl overflow-hidden hover:shadow-xl transition-shadow duration-300">
        {archive.filetype.startsWith("image") ? (
          <img
            src={archive.fileUrl}
            alt={archive.title}
            className="w-full h-48 object-cover rounded-t-2xl"
          />
        ) : (
          <div className="h-48 flex items-center justify-center bg-green-100 text-green-800 text-xl font-semibold rounded-t-2xl">
            PDF Document
          </div>
        )}
        <div className="p-4">
          <h3 className="text-lg font-semibold text-green-900">{archive.title}</h3>
          <p className="text-sm text-green-800 mt-1">
            Tags: {archive.tags.length > 0 ? archive.tags.join(", ") : "None"}
          </p>
        </div>
      </div>
    </a>
  );
}

export default Archivecard;
