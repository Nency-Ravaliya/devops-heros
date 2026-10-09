import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";

const API = "/api";
const STATUSES = ["PLANNED", "RUNNING", "COMPLETED"];

function App() {
  const [labs, setLabs] = useState([]);
  const [stats, setStats] = useState({ total: 0, planned: 0, running: 0, completed: 0 });
  const [filter, setFilter] = useState("ALL");
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = async () => {
    try {
      setError("");
      const [labsResponse, statsResponse] = await Promise.all([
        fetch(`${API}/labs`),
        fetch(`${API}/labs/stats`),
      ]);
      if (!labsResponse.ok || !statsResponse.ok) throw new Error("The API is not available");
      setLabs(await labsResponse.json());
      setStats(await statsResponse.json());
    } catch (requestError) {
      setError(requestError.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const visibleLabs = filter === "ALL" ? labs : labs.filter((lab) => lab.status === filter);

  const advanceStatus = async (lab) => {
    const currentIndex = STATUSES.indexOf(lab.status);
    const nextStatus = STATUSES[(currentIndex + 1) % STATUSES.length];
    await fetch(`${API}/labs/${lab.id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: nextStatus }),
    });
    await load();
  };

  const removeLab = async (lab) => {
    await fetch(`${API}/labs/${lab.id}`, { method: "DELETE" });
    await load();
  };

  const createLab = async (event) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    await fetch(`${API}/labs`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        title: form.get("title"),
        objective: form.get("objective"),
        tool: form.get("tool"),
        difficulty: form.get("difficulty"),
        owner: form.get("owner"),
        status: "PLANNED",
      }),
    });
    event.currentTarget.reset();
    setShowForm(false);
    await load();
  };

  return (
    <div className="app">
      <aside className="sidebar">
        <div className="brand">
          <span className="brand-mark">L</span>
          <div><b>LabTrack</b><small>DevOps practice journal</small></div>
        </div>
        <nav>
          <a className="active">▦ <span>Lab overview</span></a>
          <a>◇ <span>Learning paths</span></a>
          <a>↗ <span>Pipeline runs</span></a>
          <a>◌ <span>Observability</span></a>
        </nav>
        <div className="side-bottom">
          <div className="upgrade">
            <strong>Learn by building.</strong>
            <p>Plan a lab, run it, record the result, and keep the next experiment clear.</p>
          </div>
          <div className="profile">
            <div className="avatar">AK</div>
            <div><b>Anshal Kumar</b><small>DevOps learner</small></div>
            <span>⋮</span>
          </div>
        </div>
      </aside>

      <main className="main">
        <header>
          <div>
            <p className="eyebrow">MY DEVOPS LAB / THIS WEEK</p>
            <h1>Build, test, and write down what worked.</h1>
            <p className="muted">A small journal for practical Docker, Kubernetes, CI/CD, and monitoring labs.</p>
          </div>
          <button className="primary" onClick={() => setShowForm(true)}>＋ Plan a lab</button>
        </header>

        {error && <div className="alert">⚠ {error}. Start the local stack and refresh this page.</div>}

        <section className="stats">
          <Stat label="All labs" value={stats.total} icon="▦" />
          <Stat label="Planned" value={stats.planned} icon="○" />
          <Stat label="Running" value={stats.running} icon="◔" />
          <Stat label="Completed" value={stats.completed} icon="✓" />
        </section>

        <section className="content-grid">
          <div className="panel tasks-panel">
            <div className="panel-head">
              <div><h2>Practice labs</h2><p className="muted">Move each lab forward as you work through it.</p></div>
              <div className="filters">
                {["ALL", ...STATUSES].map((status) => (
                  <button className={filter === status ? "selected" : ""} onClick={() => setFilter(status)} key={status}>
                    {status === "ALL" ? "All" : status}
                  </button>
                ))}
              </div>
            </div>

            {loading ? <div className="empty">Loading labs…</div> : (
              <div className="table-wrap">
                <table>
                  <thead><tr><th>Lab</th><th>Tool</th><th>Difficulty</th><th>Status</th><th>Actions</th></tr></thead>
                  <tbody>
                    {visibleLabs.map((lab) => (
                      <tr key={lab.id}>
                        <td><div className="task-title"><span className={`dot ${lab.status.toLowerCase()}`}></span><div><b>{lab.title}</b><small>{lab.objective}</small></div></div></td>
                        <td>{lab.tool}</td>
                        <td><span className={`priority ${lab.difficulty.toLowerCase()}`}>{lab.difficulty}</span></td>
                        <td><span className={`status ${lab.status.toLowerCase()}`}>{lab.status}</span></td>
                        <td className="actions"><button className="icon-btn" onClick={() => advanceStatus(lab)} title="Advance status">↻</button><button className="icon-btn danger" onClick={() => removeLab(lab)} title="Delete lab">×</button></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                {!visibleLabs.length && <div className="empty">No labs in this view yet.</div>}
              </div>
            )}
          </div>

          <aside className="panel activity">
            <div className="panel-head"><div><h2>Current learning path</h2><p className="muted">The route I am following.</p></div></div>
            <Activity icon="1" text="Containerize the application" detail="Docker" />
            <Activity icon="2" text="Automate tests and scans" detail="GitHub Actions" />
            <Activity icon="3" text="Package the deployment" detail="Helm + Kubernetes" />
            <Activity icon="4" text="Measure the live service" detail="Prometheus + Grafana" />
            <div className="pipeline"><span>CODE</span><i></i><span>TEST</span><i></i><span>SHIP</span><i></i><span>WATCH</span></div>
          </aside>
        </section>

        {showForm && (
          <div className="modal-backdrop">
            <form className="modal" onSubmit={createLab}>
              <div className="modal-head"><div><p className="eyebrow">NEW PRACTICE LAB</p><h2>What will you learn?</h2></div><button type="button" className="close" onClick={() => setShowForm(false)}>×</button></div>
              <label>Lab title<input name="title" required placeholder="e.g. Troubleshoot a broken Service" /></label>
              <label>Objective<textarea name="objective" placeholder="What should be working when the lab is complete?" /></label>
              <div className="form-row">
                <label>Tool<select name="tool"><option>Docker</option><option>Kubernetes</option><option>Terraform</option><option>CI/CD</option><option>Monitoring</option></select></label>
                <label>Difficulty<select name="difficulty"><option>BEGINNER</option><option>INTERMEDIATE</option><option>ADVANCED</option></select></label>
              </div>
              <label>Owner<input name="owner" defaultValue="Anshal Kumar" /></label>
              <button className="primary full">Add lab</button>
            </form>
          </div>
        )}
      </main>
    </div>
  );
}

function Stat({ label, value, icon }) {
  return <div className="stat"><div className="stat-icon">{icon}</div><div><small>{label}</small><strong>{value}</strong><span>Live from PostgreSQL</span></div></div>;
}

function Activity({ icon, text, detail }) {
  return <div className="activity-row"><span className="activity-icon">{icon}</span><div><b>{text}</b><small>{detail}</small></div></div>;
}

createRoot(document.getElementById("root")).render(<App />);
