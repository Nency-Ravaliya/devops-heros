import React, { useState } from "react";
export default function App() {
  const [clicks, setClicks] = useState(0);
  return (
    <main style={{ fontFamily: "system-ui", textAlign: "center", marginTop: "15vh" }}>
      <h1>Hello World</h1>
      <p>
        from <strong>React {React.version}</strong> built with Vite and served by Nginx in Docker
      </p>
      <button onClick={() => setClicks(clicks + 1)}>clicked {clicks} times</button>
    </main>
  );
}
