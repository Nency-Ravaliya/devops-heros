import React, { useEffect } from "react";
import { useDispatch } from "react-redux";
import { get_events } from "../api/eventcalls.js";
import { setevents } from "../redux/eventslice.js";

function useEventData() {
  const dispatch = useDispatch();
  useEffect(() => {
    try {
      const make_get_events_call = async () => {
        const events = await get_events();
        dispatch(setevents(events));
      };
      make_get_events_call();
    } catch (e) {
      console.log(e);
    }
  }, []);
}

export default useEventData;
