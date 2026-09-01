import { createSlice } from "@reduxjs/toolkit";

const archiveslice = createSlice({
  name: "event",
  initialState: { archives: [] },
  reducers: {
    setarchives: (state, action) => {
      state.archives = action.payload;
    },
  },
});

export const { setarchives } = archiveslice.actions;
export default archiveslice.reducer;
