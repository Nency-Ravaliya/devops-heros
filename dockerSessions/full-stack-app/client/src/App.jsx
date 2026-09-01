import "./App.css";
import { Navigate, Route, Routes } from "react-router-dom";
import HomePage from "./pages/Home.page.jsx";
import MonasteryPage from "./pages/Monastery.page.jsx";
import GalleryPage from "./pages/Gallery.page.jsx";
import MapPage from "./pages/Map.page.jsx";
import useMonasteryData from "./hooks/useMonasteryData.js";
import useEventData from "./hooks/useEventData.js";
import useImageData from "./hooks/useImageData.js";
import MonasteriesPage from "./pages/Monasteries.page.jsx";
import EventsPage from "./pages/Events.page.jsx";
import ArchivesPage from "./pages/Archives.page.jsx";
import EventPage from "./pages/Event.page.jsx";

function App() {
  useMonasteryData();
  useEventData();
  useImageData();
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/home" />} />
      <Route path="/home" element={<HomePage />} />
      <Route path="/monasteries" element={<MonasteriesPage />} />
      <Route path="/monastery/:id" element={<MonasteryPage />} />
      <Route path="/gallery" element={<GalleryPage />} />
      <Route path="/map" element={<MapPage />} />
      <Route path="/events" element={<EventsPage />} />
      <Route path="/event/:id" element={<EventPage />} />
      <Route path="/archives" element={<ArchivesPage />} />
    </Routes>
  );
}

export default App;
