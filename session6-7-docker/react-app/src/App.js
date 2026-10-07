import React from "react";

function App() {
  const styles = {
    page: {
      fontFamily: "system-ui, sans-serif",
      background: "#0f172a",
      color: "#f1f5f9",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      height: "100vh",
      margin: 0,
    },
    card: {
      textAlign: "center",
      padding: "3rem",
      background: "#1e293b",
      borderRadius: "12px",
    },
    title: { color: "#61dafb", margin: "0 0 .5rem" },
    sub: { color: "#94a3b8", margin: ".25rem 0" },
  };

  return (
    <div style={styles.page}>
      <div style={styles.card}>
        <h1 style={styles.title}>Hello World from React + Docker!</h1>
        <p style={styles.sub}>Built with a multi-stage Dockerfile, served by Nginx</p>
        <p style={styles.sub}>Chhavi Ahlawat &mdash; 24BCS10201</p>
      </div>
    </div>
  );
}

export default App;
