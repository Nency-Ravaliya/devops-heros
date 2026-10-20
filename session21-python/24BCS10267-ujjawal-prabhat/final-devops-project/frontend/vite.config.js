import { defineConfig } from "vite";

// `npm run dev` proxies /api to a backend started with uvicorn on :8000.
export default defineConfig({
  server: { port: 5173, proxy: { "/api": "http://localhost:8000" } },
});
