import { createSlice } from "@reduxjs/toolkit";

const monasteryslice = createSlice({
  name: "monastery",
  initialState: { monasteries: [] },
  reducers: {
    setmonasteries: (state, action) => {
      state.monasteries = action.payload;
    },
  },
});

export const { setmonasteries } = monasteryslice.actions;
export default monasteryslice.reducer;
