import React from "react";
import { createRoot } from "react-dom/client";

function App() {
    return <h1>Hello World from React!</h1>;
}

createRoot(document.getElementById("root")).render(<App />);