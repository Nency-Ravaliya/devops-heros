import { useEffect } from "react";
import React from "react";
import { useDispatch } from "react-redux";
import { get_monasteries } from "../api/monasterycalls.js";
import { setmonasteries } from "../redux/monasteryslice.js";

function useMonasteryData() {
  const dispatch = useDispatch();
  useEffect(() => {
    try {
      const make_get_monasteries_call = async () => {
        const monasteries = await get_monasteries();
        dispatch(setmonasteries(monasteries));
      };
      make_get_monasteries_call();
    } catch (e) {
      console.log(e);
    }
  }, []);
}

export default useMonasteryData;
