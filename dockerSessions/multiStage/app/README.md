# Biolume Web Application

A modern, minimalistic landing page & API service for **Biolume** — deep-sea nocturnal diving platform exploring oceanic phobias under bioluminescent illumination.

Designed as a clean, modular foundation for DevOps practices (multi-stage Docker builds, container orchestration, CI/CD).

---

## 🗂️ Project Structure

```text
./app/
├── backend/
│   ├── src/
│   │   ├── controllers/
│   │   │   └── message.controller.js
│   │   ├── routes/
│   │   │   └── api.routes.js
│   │   ├── app.js
│   │   └── server.js
│   ├── .env.example
│   ├── .gitignore
│   └── package.json
│
└── frontend/
    ├── public/
    │   └── favicon.svg
    ├── src/
    │   ├── components/
    │   │   ├── Contact.jsx
    │   │   ├── Footer.jsx
    │   │   ├── Hero.jsx
    │   │   ├── Icons.jsx
    │   │   ├── Navbar.jsx
    │   │   └── Reviews.jsx
    │   ├── App.jsx
    │   ├── index.css
    │   └── main.jsx
    ├── index.html
    ├── postcss.config.js
    ├── tailwind.config.js
    ├── vite.config.js
    ├── .env.example
    ├── .gitignore
    └── package.json
```

---

## 🛠️ Tech Stack

- **Frontend**: React 18, Vite 5, Tailwind CSS 3 (Dark aesthetic, glowing cyan accents, soft contrast, custom SVGs).
- **Backend**: Node.js, Express (Modular MVC-ready routing & controller architecture, CORS enabled).
- **Database**: None required.

---

## 🚀 Running Locally

### 1. Backend Service
```bash
cd app/backend
npm install
npm run dev # or npm start
```
- API Server: `http://localhost:5000`
- Health check: `http://localhost:5000/api/health`
- Hello endpoint: `http://localhost:5000/api/hello`

### 2. Frontend Application
```bash
cd app/frontend
npm install
npm run dev
```
- Web Application: `http://localhost:5173`
