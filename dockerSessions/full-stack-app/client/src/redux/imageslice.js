import { createSlice } from "@reduxjs/toolkit";

const imageslice = createSlice({
  name: "image",
  initialState: { images: [] },
  reducers: {
    setimages: (state, action) => {
      state.images = action.payload;
    },
  },
});

export const { setimages } = imageslice.actions;
export default imageslice.reducer;
