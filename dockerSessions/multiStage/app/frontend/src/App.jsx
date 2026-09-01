import React, { useState, useEffect, useCallback } from 'react';
import { Navbar } from './components/Navbar';
import { Hero } from './components/Hero';
import { Reviews } from './components/Reviews';
import { Contact } from './components/Contact';
import { Footer } from './components/Footer';

export function App() {
  const [backendData, setBackendData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [backendStatus, setBackendStatus] = useState({ connected: false });

  const fetchBackendData = useCallback(async () => {
    setLoading(true);
    const backendBaseUrl = import.meta.env.VITE_BACKEND_URL || '';
    const endpoint = backendBaseUrl ? `${backendBaseUrl}/api/hello` : '/api/hello';

    try {
      const response = await fetch(endpoint, {
        headers: { 'Accept': 'application/json' }
      });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      const data = await response.json();
      setBackendData(data);
      setBackendStatus({ connected: true });
    } catch (err) {
      console.warn('Backend connection offline or pending:', err.message);
      // Fallback try localhost:5000 directly if proxy fails in some dev modes
      if (!backendBaseUrl) {
        try {
          const directResp = await fetch('http://localhost:5000/api/hello');
          if (directResp.ok) {
            const data = await directResp.json();
            setBackendData(data);
            setBackendStatus({ connected: true });
            setLoading(false);
            return;
          }
        } catch (_) {}
      }
      setBackendStatus({ connected: false });
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchBackendData();
  }, [fetchBackendData]);

  return (
    <div className="min-h-screen bg-abyss-950 text-soft-white deep-sea-mesh flex flex-col justify-between">
      <Navbar backendStatus={backendStatus} />
      
      <main className="flex-grow">
        <Hero 
          backendData={backendData} 
          loading={loading} 
          onRefreshBackend={fetchBackendData} 
        />
        <Reviews />
        <Contact />
      </main>

      <Footer />
    </div>
  );
}

export default App;
