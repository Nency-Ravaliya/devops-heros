import React, { useState, useEffect } from "react";
import { get_archive, get_archives } from "../api/archivecalls.js";
import Archivecard from "../components/Archivecard.component.jsx";
import { useDispatch } from "react-redux";
import { setarchives } from "../redux/archiveslice.js";
import ArchiveModal from "../components/ArchiveModal.component.jsx";
import RedirectHome from "../components/RedirectHome.component.jsx";

function ArchivesPage() {
  const dispatch = useDispatch();
  const [searchTerm, setSearchTerm] = useState("");
  const [filteredArchives, setfilteredArchives] = useState([]);
  const [openModal, setopenModal] = useState(false);

  useEffect(() => {
    try {
      const make_get_archives_call = async () => {
        const data = await get_archives();
        setfilteredArchives(data);
        dispatch(setarchives(data));
      };
      make_get_archives_call();
    } catch (e) {
      console.log(e);
    }
  }, []);

  const make_get_archive_call = async (e) => {
    e.preventDefault();
    if (searchTerm === "") return;
    try {
      const data = await get_archive(searchTerm);
      setfilteredArchives(data);
    } catch (e) {
      console.log(e);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-green-50 to-green-100 py-8 sm:py-12 px-4 sm:px-6">
      <RedirectHome />

      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl sm:text-5xl font-extrabold text-green-900 mb-6 sm:mb-8 text-center tracking-wide">
          Digital Archive
        </h1>

        <div className="mb-6 sm:mb-8 flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
          <form className="flex-1 flex flex-col sm:flex-row gap-2" onSubmit={make_get_archive_call}>
            <input
              type="text"
              placeholder="Search archives..."
              className="flex-1 p-3 border border-green-300 rounded-xl shadow-sm focus:outline-none focus:ring-2 focus:ring-green-400"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            <button
              type="submit"
              className="px-6 py-3 bg-green-600 text-white font-semibold rounded-xl shadow hover:bg-green-700 transition"
            >
              Search
            </button>
          </form>

          <button
            onClick={() => setopenModal(true)}
            className="px-6 py-3 bg-green-600 text-white font-semibold rounded-xl shadow hover:bg-green-700 transition"
          >
            Add Archive
          </button>
        </div>

        {filteredArchives.length > 0 ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 sm:gap-8">
            {filteredArchives.map((archive) => (
              <Archivecard key={archive._id} archive={archive} />
            ))}
          </div>
        ) : (
          <p className="text-green-800 text-center text-lg mt-10">
            No archives found.
          </p>
        )}

        {openModal && <ArchiveModal setopenModal={setopenModal} />}
      </div>
    </div>
  );
}

export default ArchivesPage;
