import { useState } from "react";

export default function App() {
  const [clicks, setClicks] = useState(0);

  return (
    <div style={{ fontFamily: "sans-serif", textAlign: "center", marginTop: 60 }}>
      <h1>Hello World from React in Docker!</h1>
      <p>Built with Vite, served by nginx</p>
      <button onClick={() => setClicks(clicks + 1)}>Clicked {clicks} times</button>
    </div>
  );
}
