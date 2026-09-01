import React from "react";
import NavbarComponent from "../components/Navbar.component.jsx";
import Monasterycardcomponent from "../components/Monasterycard.component.jsx";
import { useSelector } from "react-redux";
import useMonasteryData from "../hooks/useMonasteryData.js";

function HomePage() {
  const { monasteries } = useSelector((state) => state.monastery);
  const featuredMonasteries = monasteries.filter((mon) => mon.featured) || [];

  return (
    <div className="min-h-screen bg-gradient-to-b from-green-50 to-green-100 p-4 sm:p-6">
      <header className="mb-8 sm:mb-12 text-center px-4">
        <h1 className="text-3xl sm:text-5xl font-extrabold text-green-900 mb-3 tracking-wide">
          Welcome to Monastery360
        </h1>
        <p className="text-green-800 text-base sm:text-lg max-w-xl mx-auto">
          Explore the serene and historic monasteries of Sikkim, and book events
          that immerse you in spiritual experiences.
        </p>
      </header>

      <section className="mb-12">
        <h2 className="text-3xl font-semibold mb-6 text-green-900 border-b-2 border-green-300 inline-block pb-2">
          Featured Monasteries
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-8">
          {featuredMonasteries.map((monastery) => (
            <Monasterycardcomponent monastery={monastery} />
          ))}
        </div>
      </section>

      <NavbarComponent />
    </div>
  );
}

export default HomePage;
