import React, { useEffect, useState } from "react";
import Monasterycardcomponent from "../components/Monasterycard.component.jsx";
import { useSelector } from "react-redux";
import RedirectHome from "../components/RedirectHome.component.jsx";

function MonasteriesPage() {
  const { monasteries } = useSelector((state) => state.monastery);

  return (
    <div className="min-h-screen bg-gradient-to-b from-green-50 to-green-100 py-8 sm:py-12 px-4 sm:px-6">
      <RedirectHome />
      <div className="max-w-7xl mx-auto">
        {/* Page Title */}
        <h1 className="text-3xl sm:text-5xl font-extrabold text-center text-green-900 mb-8 sm:mb-12 tracking-wide">
          Monasteries
        </h1>

        {/* Grid of Monastery Cards */}
        {monasteries.length > 0 ? (
          <div className="grid gap-4 sm:gap-8 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {monasteries.map((monastery) => (
              <Monasterycardcomponent
                key={monastery._id}
                monastery={monastery}
              />
            ))}
          </div>
        ) : (
          <div className="text-center text-green-800 text-lg">
            No monasteries found.
          </div>
        )}
      </div>
    </div>
  );
}

export default MonasteriesPage;
