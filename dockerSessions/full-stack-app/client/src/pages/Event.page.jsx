import React, { useState, useEffect } from "react";
import { useParams } from "react-router-dom";
import { get_event } from "../api/eventcalls";
import BookingModal from "../components/BookingModal.component";
import RedirectHome from "../components/RedirectHome.component";

const EventPage = () => {
  const id = useParams().id;
  const [event, setevent] = useState(null);
  const [openModal, setopenModal] = useState(false);

  useEffect(() => {
    const fetchEvent = async () => {
      try {
        const response = await get_event(id);
        setevent(response);
      } catch (e) {
        console.log(e);
      }
    };
    fetchEvent();
  }, [id]);

  if (!event) {
    return (
      <div className="text-center mt-10 text-green-800 font-semibold">
        Loading event...
      </div>
    );
  }

  const valid_period = (startDate) => Date.now().toLocaleString() < (new Date(startDate)).toLocaleString();

  return (
    <div className="min-h-screen bg-gradient-to-b from-green-50 to-green-100 flex items-center justify-center p-6">
      <RedirectHome />

      <div className="max-w-2xl w-full bg-white rounded-2xl shadow-lg overflow-hidden border border-green-200">
        {/* Event Banner */}
        <div className="bg-gradient-to-r from-green-400 via-green-500 to-green-600 h-40 flex items-center justify-center">
          <h1 className="text-3xl sm:text-4xl font-extrabold text-white text-center px-4">
            {event.name || "Untitled Event"}
          </h1>
        </div>

        {/* Event Details */}
        <div className="p-6 space-y-5">
          {/* Dates */}
          <div className="flex items-center justify-between text-green-800 font-medium">
            <span className="flex flex-col">
              <span className="font-semibold text-green-900">Start:</span>
              {event.startDate
                ? new Date(event.startDate).toLocaleDateString()
                : "N/A"}
            </span>
            <span className="flex flex-col">
              <span className="font-semibold text-green-900">End:</span>
              {event.endDate
                ? new Date(event.endDate).toLocaleDateString()
                : "N/A"}
            </span>
          </div>

          {/* Description */}
          <div className="bg-green-50 p-4 rounded-xl border border-green-200 min-h-[80px]">
            <h2 className="font-semibold text-green-900 mb-1">Description</h2>
            <p className="text-green-800">
              {event.description || "No description provided for this event."}
            </p>
          </div>

          {/* Monastery */}
          <div className="bg-green-100 p-4 rounded-xl border border-green-200">
            <h2 className="font-semibold text-green-900 mb-1">Monastery</h2>
            <p className="text-green-800">
              {event.monastery?.name || "No monastery linked."}
            </p>
          </div>

          {/* Bookings */}
          <div className="bg-green-50 p-4 rounded-xl border border-green-200">
            <h2 className="font-semibold text-green-900 mb-1">Bookings</h2>
            <p className="text-green-800">
              {event.bookings && event.bookings.length > 0
                ? `${event.bookings.length} booking(s) registered`
                : "No bookings yet."}
            </p>
          </div>

          {/* Action Button */}
          <div className="text-center mt-4">
            <button
              onClick={() =>
                setopenModal(valid_period(event.startDate) && true)
              }
              className={`px-6 py-2 font-semibold rounded-full shadow transition ${
                valid_period(event.startDate)
                  ? "bg-green-600 text-white hover:bg-green-700"
                  : "bg-gray-400 text-gray-200 cursor-not-allowed"
              }`}
            >
              {valid_period(event.startDate)
                ? "Register"
                : "Booking Period ended!"}
            </button>
          </div>

          {openModal && (
            <BookingModal setopenModal={setopenModal} event={event} />
          )}
        </div>
      </div>
    </div>
  );
};

export default EventPage;
