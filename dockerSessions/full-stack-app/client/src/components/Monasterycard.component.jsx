import React from "react";
import { useNavigate } from "react-router-dom";

function Monasterycardcomponent({ monastery }) {
  const navigate = useNavigate();
  return (
    <div className="bg-green-50 rounded-2xl shadow-md p-5 hover:shadow-lg transition flex flex-col h-full">
      <h3 className="text-xl font-bold text-green-900 mb-2">
        {monastery.name}
      </h3>
      <p className="text-sm text-green-700 mb-4">{monastery.location}</p>
      <button
        onClick={() => navigate(`/monastery/${monastery._id}`)}
        className="mt-auto px-4 py-2 bg-green-600 text-white font-semibold rounded-full shadow hover:bg-green-700 transition"
      >
        View Details
      </button>
    </div>
  );
}

export default Monasterycardcomponent;
