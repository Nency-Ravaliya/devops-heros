import React, { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { get_monastery } from "../api/monasterycalls.js";
import { useSelector } from "react-redux";
import RedirectHome from "../components/RedirectHome.component.jsx";

const MonasteryPage = () => {
  const navigate = useNavigate();
  const monastery_id = useParams().id;
  const [monasteryInfo, setmonasteryInfo] = useState(null);
  const make_get_monastery_call = async () => {
    try {
      const monastery = await get_monastery(monastery_id);
      setmonasteryInfo(monastery);
    } catch (e) {
      console.log(e);
    }
  };
  make_get_monastery_call();

  const { events } = useSelector((state) => state.event);
  const { images } = useSelector((state) => state.image);

  return (
    <div className="max-w-5xl mx-auto mb-40 p-8 bg-green-50 rounded-xl shadow-lg">
      <RedirectHome />

      {/* Monastery Info */}
      <h1 className="text-4xl sm:text-5xl font-extrabold text-green-900 mb-2">
        {monasteryInfo?.name}
      </h1>
      <h2 className="text-xl text-green-800 mb-4">{monasteryInfo?.location}</h2>
      <p className="text-green-700 mb-8 leading-relaxed">
        {monasteryInfo?.description}
      </p>

      {/* Gallery */}
      <section className="mb-10">
        <h3 className="text-2xl font-semibold mb-4 text-green-900 border-b border-green-300 pb-2">
          Gallery
        </h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
          {monasteryInfo?.images.map((img, index) => {
            const im = images.find((i) => i._id === img);
            return (
              <img
                key={index}
                src={im.fileUrl}
                alt={`Image ${index + 1} of ${im.monastery.name}`}
                className="rounded-xl shadow-md hover:scale-105 transition-transform duration-300"
              />
            );
          })}
        </div>
      </section>

      {/* Upcoming Events */}
      <section className="mb-10">
        <h3 className="text-2xl font-semibold mb-4 text-green-900 border-b border-green-300 pb-2">
          Upcoming Events
        </h3>
        <ul className="space-y-4">
          {monasteryInfo?.events.map((event) => {
            const ev = events.find((e) => e._id === event);
            return (
              <li
                key={ev._id}
                className="flex flex-col p-4 bg-white rounded-xl shadow hover:shadow-lg cursor-pointer transition-shadow duration-300"
                onClick={() => navigate(`/event/${ev._id}`)}
              >
                <span className="font-semibold text-green-900 text-lg">
                  {ev.name}
                </span>
                <span className="flex gap-2 text-green-700 mt-1 text-sm">
                  <time>{new Date(ev.startDate).toLocaleString()}</time>-
                  <time>{new Date(ev.endDate).toLocaleString()}</time>
                </span>
              </li>
            );
          })}
        </ul>
      </section>
    </div>
  );
};

export default MonasteryPage;
