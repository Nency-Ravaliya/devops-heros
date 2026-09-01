// src/components/ImageCard.jsx
import React from "react";
import { useNavigate } from "react-router-dom";

const ImageCard = ({ image }) => {
  const navigate = useNavigate();
  return (
    <div
      onClick={() => navigate(`/monastery/${image.monastery._id}`)}
      key={image._id}
      className="bg-green-50 rounded-2xl shadow-md overflow-hidden hover:shadow-lg transition cursor-pointer"
    >
      <img
        src={image.fileUrl}
        alt={image.caption}
        className="w-full h-56 object-cover rounded-t-2xl"
      />
      <div className="p-4 flex flex-col gap-1">
        <h3 className="text-lg font-bold text-green-900">{image.caption}</h3>
        <p className="text-green-800 text-sm">🏯 {image.monastery.name}</p>
        <p className="text-green-700 text-sm">{image.monastery.location}</p>
      </div>
    </div>
  );
};

export default ImageCard;
