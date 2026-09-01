import React, { useEffect, useState } from "react";
import { useSelector } from "react-redux";
import EventCard from "../components/Eventcard.component.jsx";
import useEventData from "../hooks/useEventData.js";
import EventCalendar from "../components/EventCalendar.component.jsx";
import RedirectHome from "../components/RedirectHome.component.jsx";

function EventsPage() {
  const { events } = useSelector((state) => state.event);

  return (
    <div className="min-h-screen bg-gradient-to-b from-green-50 to-green-100 py-8 sm:py-12 px-4 sm:px-6">
      <RedirectHome />

      <div className="max-w-7xl mx-auto">
        {/* Page Title */}
        <h1 className="text-3xl sm:text-5xl font-extrabold text-center text-green-900 mb-8 sm:mb-12 tracking-wide">
          Upcoming Events
        </h1>

        {/* Event calendar */}
        <div className="mb-8 sm:mb-12 bg-white p-4 sm:p-6 rounded-2xl shadow-lg">
          <EventCalendar events={events} />
        </div>

        {/* Events Grid */}
        {events.length > 0 ? (
          <div className="grid gap-4 sm:gap-8 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {events.map((event) => (
              <EventCard key={event._id} event={event} />
            ))}
          </div>
        ) : (
          <div className="text-center text-green-800 text-lg">
            No events found.
          </div>
        )}
      </div>
    </div>
  );
}

export default EventsPage;
