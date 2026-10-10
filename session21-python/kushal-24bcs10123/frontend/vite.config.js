import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// In `npm run dev` the /api calls are proxied to the local backend.
// In the container nginx does the same job (see nginx.conf.template).
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: { '/api': 'http://localhost:8000' },
  },
})
