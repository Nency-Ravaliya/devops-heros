import React, { useRef, useEffect, useState } from "react";
import { post_booking } from "../api/bookingcalls.js";

function BookingModal({ setopenModal, event }) {
  const modal_ref = useRef(null);

  const [input, setinput] = useState({
    name: "",
    email: "",
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setinput({ ...input, [name]: value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const formdata = new FormData();
      formdata.append("event", event._id);
      formdata.append("name", input.name);
      formdata.append("email", input.email);

      const response = await post_booking(formdata);
      console.log(response);
      window.location.reload();
    } catch (e) {
      console.log(e);
    }
  };

  useEffect(() => {
    const detect_mouse_click = (e) => {
      if (modal_ref.current && !modal_ref.current.contains(e.target))
        setopenModal(false);
    };
    document.addEventListener("mousedown", detect_mouse_click);
    return () => document.removeEventListener("mousedown", detect_mouse_click);
  }, []);

  return (
    <div className="fixed inset-0 z-[50] bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 overflow-hidden">
      <div
        ref={modal_ref}
        className="w-[95%] lg:max-w-[40%] bg-white rounded-2xl px-8 py-6 flex flex-col justify-center items-center overflow-auto shadow-xl"
      >
        <h2 className="text-3xl font-extrabold text-green-900 mb-2 text-center">
          Make Booking
        </h2>
        <h4 className="text-green-800 mb-6 text-center">{`for: ${event.name}`}</h4>

        <form className="w-full flex flex-col gap-5" onSubmit={handleSubmit}>
          <input
            type="text"
            name="name"
            placeholder="Your Name"
            className="p-3 border border-green-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-green-400"
            value={input.name}
            onChange={handleChange}
            required
          />
          <input
            type="text"
            name="email"
            placeholder="example@email.com"
            className="p-3 border border-green-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-green-400"
            value={input.email}
            onChange={handleChange}
            required
          />
          <button
            type="submit"
            className="px-6 py-3 bg-green-600 text-white font-semibold rounded-full shadow hover:bg-green-700 transition mt-2"
          >
            Book
          </button>
        </form>
      </div>
    </div>
  );
}

export default BookingModal;
