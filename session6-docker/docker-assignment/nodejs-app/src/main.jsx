import React from 'react';
import ReactDOM from 'react-dom/client';

function App() {
  return (
    <div style={{ fontFamily: 'sans-serif', textAlign: 'center', marginTop: '50px' }}>
      <h1>Hello World from React & Docker!</h1>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
