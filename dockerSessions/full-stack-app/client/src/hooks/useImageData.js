import React, { useEffect } from "react";
import { useDispatch } from "react-redux";
import { setimages } from "../redux/imageslice.js";
import { get_images } from "../api/imagecalls.js";

function useImageData() {
  const dispatch = useDispatch();
  useEffect(() => {
    try {
      const make_get_images_call = async () => {
        const images = await get_images();
        dispatch(setimages(images));
      };
      make_get_images_call();
    } catch (e) {
      console.log(e);
    }
  }, []);
}

export default useImageData;
