import React from 'react';

function App() {
  return (
    <div style={{
      fontFamily: 'system-ui, -apple-system, sans-serif',
      background: 'linear-gradient(135deg, #0f172a 0%, #1e1b4b 100%)',
      color: '#f8fafc',
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      height: '100vh',
      margin: 0
    }}>
      <div style={{
        background: 'rgba(30, 41, 59, 0.8)',
        backdropFilter: 'blur(10px)',
        padding: '3rem',
        borderRadius: '1.5rem',
        boxShadow: '0 20px 40px rgba(0,0,0,0.5)',
        textAlign: 'center',
        border: '1px solid rgba(255,255,255,0.1)'
      }}>
        <h1 style={{ color: '#61dafb', margin: '0 0 1rem 0' }}>
          Hello World from React!
        </h1>
        <p style={{ color: '#94a3b8', fontSize: '1.2rem', margin: 0 }}>
          Containerized with Multi-Stage Docker & Nginx
        </p>
      </div>
    </div>
  );
}

export default App;
