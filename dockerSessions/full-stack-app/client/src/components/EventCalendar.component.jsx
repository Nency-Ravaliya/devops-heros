// src/components/EventCalendar.jsx
import React from "react";
import { Calendar, momentLocalizer } from "react-big-calendar";
import moment from "moment";
import "react-big-calendar/lib/css/react-big-calendar.css";
import { parseISO } from "date-fns";

const localizer = momentLocalizer(moment);

const EventCalendar = ({ events }) => {
  // Convert string dates to Date objects
  const parsedEvents = events.map((e) => ({
    ...e,
    start: e.startDate instanceof Date ? e.startDate : parseISO(e.startDate),
    end: e.endDate instanceof Date ? e.endDate : parseISO(e.endDate),
    title: e.title || "(No title)",
  }));

  return (
    <div className="bg-green-50 rounded-2xl p-4 shadow-inner">
      <Calendar
        localizer={localizer}
        events={parsedEvents}
        startAccessor="start"
        endAccessor="end"
        style={{ height: 500 }}
        views={["month", "week", "day"]}
        popup
        dayPropGetter={() => ({
          className:
            "bg-green-50 hover:bg-green-100 transition-colors rounded-lg",
        })}
        eventPropGetter={() => ({
          className:
            "bg-green-600 text-white px-2 py-1 rounded-md text-sm shadow hover:bg-green-700 transition",
        })}
        components={{
          event: ({ event }) => (
            <span className="text-white font-medium">{event.title}</span>
          ),
          toolbar: (toolbar) => (
            <div className="flex justify-between items-center mb-4">
              <button
                onClick={() => toolbar.onNavigate("PREV")}
                className="px-3 py-1 bg-green-200 rounded-md hover:bg-green-300 transition"
              >
                Prev
              </button>
              <span className="text-green-900 font-semibold">
                {toolbar.label}
              </span>
              <button
                onClick={() => toolbar.onNavigate("NEXT")}
                className="px-3 py-1 bg-green-200 rounded-md hover:bg-green-300 transition"
              >
                Next
              </button>
            </div>
          ),
        }}
      />
    </div>
  );
};

export default EventCalendar;
