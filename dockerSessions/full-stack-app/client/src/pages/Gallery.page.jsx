import React, { useEffect, useState } from "react";
import { get_images } from "../api/imagecalls.js";
import { useSelector } from "react-redux";
import useImageData from "../hooks/useImageData.js";
import ImageCard from "../components/Gallerycard.component.jsx";
import RedirectHome from "../components/RedirectHome.component.jsx";

const GalleryPage = () => {
  const { images } = useSelector((state) => state.image);

  return (
    <div className="min-h-screen bg-gradient-to-b from-green-50 to-green-100 py-8 sm:py-12 px-4 sm:px-6">
      <RedirectHome />

      <div className="max-w-6xl mx-auto bg-white rounded-2xl shadow-lg p-4 sm:p-8">
        <h1 className="text-3xl sm:text-5xl font-extrabold text-green-900 mb-6 sm:mb-8 text-center tracking-wide">
          Monastery Image Gallery
        </h1>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 sm:gap-8">
          {images.map((img) => (
            <ImageCard image={img} />
          ))}
        </div>
      </div>
    </div>
  );
};

export default GalleryPage;
