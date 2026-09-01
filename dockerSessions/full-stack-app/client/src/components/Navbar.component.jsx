import React from "react";
import { Link } from "react-router-dom";

function NavbarComponent() {
  return (
    <div>
      <h2 className="text-2xl font-semibold mb-4 text-green-900">
        Quick Navigation
      </h2>
      <ul className="flex gap-6 text-green-700">
        <li>
          <a href="/monasteries" className="hover:underline">
            All Monasteries
          </a>
        </li>
        <li>
          <a href="/gallery" className="hover:underline">
            Gallery
          </a>
        </li>
        <li>
          <a href="/map" className="hover:underline">
            Map View
          </a>
        </li>
        <li>
          <a href="/events" className="hover:underline">
            Events
          </a>
        </li>
        <li>
          <a href="/archives" className="hover:underline">
            Digital Archive
          </a>
        </li>
      </ul>
    </div>
  );
}

export default NavbarComponent;
