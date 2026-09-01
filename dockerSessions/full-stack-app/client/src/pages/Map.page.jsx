import React from "react";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import { useSelector } from "react-redux";
import RedirectHome from "../components/RedirectHome.component";

const MapPage = () => {
  const { monasteries } = useSelector((state) => state.monastery);

  return (
    <div className="flex flex-col items-center justify-start min-h-screen bg-gradient-to-b from-green-50 to-green-100 py-12 px-6">
      <RedirectHome />

      <h1 className="text-4xl sm:text-5xl font-extrabold text-green-900 mb-10 text-center tracking-wide">
        🏯 Monastery Locations
      </h1>

      <div className="w-full max-w-6xl rounded-2xl shadow-xl overflow-hidden bg-white border border-green-200">
        <MapContainer
          center={[27.3389, 88.6065]}
          zoom={10}
          scrollWheelZoom
          className="h-96 md:h-[600px] w-full"
        >
          <TileLayer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution='&copy; <a href="https://openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          />
          {monasteries.map(({ id, name, geo }) => (
            <Marker key={id} position={[geo.lat, geo.lng]}>
              <Popup>
                <span className="font-semibold text-green-900">{name}</span>
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      </div>

      {/* Optional: Footer / Legend */}
      <div className="mt-6 text-green-700 text-sm text-center">
        Map data © OpenStreetMap contributors
      </div>
    </div>
  );
};

export default MapPage;
