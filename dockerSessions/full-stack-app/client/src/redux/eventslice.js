import { createSlice } from "@reduxjs/toolkit";

const eventslice = createSlice({
  name: "event",
  initialState: { events: [] },
  reducers: {
    setevents: (state, action) => {
      state.events = action.payload;
    },
  },
});

export const { setevents } = eventslice.actions;
export default eventslice.reducer;
