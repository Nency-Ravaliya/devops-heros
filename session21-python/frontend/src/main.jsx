import React, { useEffect, useMemo, useState } from 'react';
import { createRoot } from 'react-dom/client';
import './styles.css';

const API = '/api';
const GROUPS = ['CHEST', 'BACK', 'SHOULDERS', 'BICEPS', 'TRICEPS', 'QUADS', 'HAMSTRINGS', 'GLUTES', 'CALVES', 'CORE', 'FULL_BODY'];
const EQUIPMENT = ['BARBELL', 'DUMBBELL', 'MACHINE', 'CABLE', 'BODYWEIGHT', 'KETTLEBELL', 'OTHER'];
const VIEWS = [['dashboard', '◉', 'Dashboard'], ['log', '＋', 'Log workout'], ['history', '☰', 'History'], ['exercises', '⚑', 'Exercises'], ['progress', '↗', 'Progress']];

const pretty = (s) => s.charAt(0) + s.slice(1).toLowerCase().replace('_', ' ');
const kg = (n) => `${Math.round(n).toLocaleString()} kg`;
const day = (d) => new Date(d).toLocaleDateString(undefined, { weekday: 'short', day: 'numeric', month: 'short' });

async function api(path, options = {}) {
  const res = await fetch(`${API}${path}`, { headers: { 'Content-Type': 'application/json' }, ...options });
  if (!res.ok) throw new Error((await res.json().catch(() => ({}))).detail || `Request failed (${res.status})`);
  return res.status === 204 ? null : res.json();
}

function App() {
  const [view, setView] = useState('dashboard');
  const [exercises, setExercises] = useState([]);
  const [workouts, setWorkouts] = useState([]);
  const [stats, setStats] = useState(null);
  const [error, setError] = useState('');

  const load = async () => {
    try {
      setError('');
      const [e, w, s] = await Promise.all([api('/exercises'), api('/workouts'), api('/stats')]);
      setExercises(e); setWorkouts(w); setStats(s);
    } catch (err) { setError(err.message); }
  };
  useEffect(() => { load(); }, []);

  return (
    <div className="app">
      <aside className="sidebar">
        <div className="brand"><span className="brand-mark">LL</span><div><b>LiftLog</b><small>Train · Track · Progress</small></div></div>
        <nav>{VIEWS.map(([id, icon, label]) => (
          <a key={id} className={view === id ? 'active' : ''} onClick={() => setView(id)}>{icon} <span>{label}</span></a>
        ))}</nav>
        <div className="pro-card"><span className="pro-badge">PRO</span><strong>Premium analytics</strong><p>Estimated 1RM, PR tracking and muscle-group volume.</p></div>
      </aside>
      <main className="main">
        {error && <div className="alert">⚠ {error}. Is the API running?</div>}
        {view === 'dashboard' && <Dashboard stats={stats} workouts={workouts} go={setView} />}
        {view === 'log' && <LogWorkout exercises={exercises} onSaved={() => { load(); setView('history'); }} />}
        {view === 'history' && <History workouts={workouts} onChange={load} />}
        {view === 'exercises' && <Exercises exercises={exercises} onChange={load} />}
        {view === 'progress' && <Progress exercises={exercises} workouts={workouts} />}
      </main>
    </div>
  );
}

function Header({ eyebrow, title, subtitle, action }) {
  return <header><div><p className="eyebrow">{eyebrow}</p><h1>{title}</h1>{subtitle && <p className="muted">{subtitle}</p>}</div>{action}</header>;
}

function Dashboard({ stats, workouts, go }) {
  if (!stats) return <div className="empty">Loading…</div>;
  const groups = Object.entries(stats.volume_by_muscle_group_30d);
  const max = Math.max(1, ...groups.map(([, v]) => v));
  return (<>
    <Header eyebrow="OVERVIEW" title="Ready to train? 💪" subtitle="Your training at a glance." action={<button className="primary" onClick={() => go('log')}>＋ Log workout</button>} />
    <section className="stats">
      <Stat label="Workouts (7 days)" value={stats.workouts_last_7_days} icon="📅" />
      <Stat label="Volume (7 days)" value={kg(stats.volume_last_7_days_kg)} icon="🏋" />
      <Stat label="Total workouts" value={stats.total_workouts} icon="✓" />
      <Stat label="Personal records" value={stats.personal_records.length} icon="🏆" />
    </section>
    <section className="grid-2">
      <div className="panel">
        <div className="panel-head"><h2>Muscle-group volume</h2><span className="pro-badge">PRO</span></div>
        <p className="muted">Total kg lifted per muscle group, last 30 days.</p>
        {groups.length ? groups.map(([g, v]) => (
          <div className="bar-row" key={g}><span>{pretty(g)}</span><div className="bar"><i style={{ width: `${(v / max) * 100}%` }} /></div><b>{kg(v)}</b></div>
        )) : <div className="empty">Log a workout to see your volume split.</div>}
      </div>
      <div className="panel">
        <div className="panel-head"><h2>Personal records</h2><span className="pro-badge">PRO</span></div>
        <p className="muted">Best set per exercise, ranked by estimated 1RM (Epley).</p>
        <table><thead><tr><th>Exercise</th><th>Best set</th><th>Est. 1RM</th></tr></thead>
          <tbody>{stats.personal_records.slice(0, 8).map(r => (
            <tr key={r.exercise_id}><td><b>{r.exercise}</b><small>{pretty(r.muscle_group)}</small></td><td>{r.best_set}</td><td className="accent">{r.est_1rm_kg} kg</td></tr>
          ))}</tbody></table>
        {!stats.personal_records.length && <div className="empty">No records yet.</div>}
      </div>
    </section>
    <section className="panel">
      <div className="panel-head"><h2>Recent workouts</h2><button className="link" onClick={() => go('history')}>View all →</button></div>
      <div className="cards">{workouts.slice(0, 3).map(w => <WorkoutCard key={w.id} w={w} compact />)}</div>
      {!workouts.length && <div className="empty">No workouts logged yet.</div>}
    </section>
  </>);
}

function Stat({ label, value, icon }) {
  return <div className="stat"><div className="stat-icon">{icon}</div><div><small>{label}</small><strong>{value}</strong></div></div>;
}

function LogWorkout({ exercises, onSaved }) {
  const today = new Date().toISOString().slice(0, 16);
  const [title, setTitle] = useState('Push Day');
  const [performedAt, setPerformedAt] = useState(today);
  const [duration, setDuration] = useState(60);
  const [notes, setNotes] = useState('');
  const [blocks, setBlocks] = useState([{ exercise_id: '', sets: [{ reps: 8, weight_kg: 60, rpe: '' }] }]);
  const [error, setError] = useState('');

  const patch = (i, fn) => setBlocks(b => b.map((x, j) => (j === i ? fn(structuredClone(x)) : x)));
  const submit = async (e) => {
    e.preventDefault();
    const sets = blocks.filter(b => b.exercise_id).flatMap(b => b.sets.map(s => ({
      exercise_id: Number(b.exercise_id), reps: Number(s.reps), weight_kg: Number(s.weight_kg), rpe: s.rpe === '' ? null : Number(s.rpe),
    })));
    if (!sets.length) return setError('Add at least one exercise with a set.');
    try {
      await api('/workouts', { method: 'POST', body: JSON.stringify({ title, notes, duration_min: Number(duration), performed_at: new Date(performedAt).toISOString(), sets }) });
      onSaved();
    } catch (err) { setError(err.message); }
  };

  return (<>
    <Header eyebrow="NEW SESSION" title="Log a workout" subtitle="Add exercises and the sets you performed." />
    <form className="panel log-form" onSubmit={submit}>
      <div className="form-row">
        <label>Workout name<input value={title} onChange={e => setTitle(e.target.value)} required /></label>
        <label>Date & time<input type="datetime-local" value={performedAt} onChange={e => setPerformedAt(e.target.value)} /></label>
        <label>Duration (min)<input type="number" min="1" value={duration} onChange={e => setDuration(e.target.value)} /></label>
      </div>
      {blocks.map((b, i) => (
        <div className="exercise-block" key={i}>
          <div className="block-head">
            <select value={b.exercise_id} onChange={e => patch(i, x => ({ ...x, exercise_id: e.target.value }))}>
              <option value="">Choose exercise…</option>
              {GROUPS.map(g => {
                const list = exercises.filter(x => x.muscle_group === g);
                return list.length ? <optgroup key={g} label={pretty(g)}>{list.map(x => <option key={x.id} value={x.id}>{x.name}</option>)}</optgroup> : null;
              })}
            </select>
            <button type="button" className="icon-btn" onClick={() => setBlocks(bs => bs.filter((_, j) => j !== i))} title="Remove exercise">✕</button>
          </div>
          <table className="sets"><thead><tr><th>Set</th><th>kg</th><th>Reps</th><th>RPE</th><th></th></tr></thead><tbody>
            {b.sets.map((s, k) => (
              <tr key={k}>
                <td>{k + 1}</td>
                {['weight_kg', 'reps', 'rpe'].map(f => (
                  <td key={f}><input type="number" step={f === 'reps' ? 1 : 0.5} min="0" value={s[f]} placeholder={f === 'rpe' ? '–' : ''}
                    onChange={e => patch(i, x => { x.sets[k][f] = e.target.value; return x; })} /></td>
                ))}
                <td><button type="button" className="icon-btn" onClick={() => patch(i, x => { x.sets.splice(k, 1); return x; })}>−</button></td>
              </tr>
            ))}
          </tbody></table>
          <button type="button" className="ghost" onClick={() => patch(i, x => { x.sets.push({ ...x.sets[x.sets.length - 1] || { reps: 8, weight_kg: 60, rpe: '' } }); return x; })}>＋ Add set</button>
        </div>
      ))}
      <button type="button" className="ghost wide" onClick={() => setBlocks(b => [...b, { exercise_id: '', sets: [{ reps: 8, weight_kg: 40, rpe: '' }] }])}>＋ Add exercise</button>
      <label>Notes<textarea value={notes} onChange={e => setNotes(e.target.value)} placeholder="How did it feel?" /></label>
      {error && <div className="alert">{error}</div>}
      <button className="primary full">Save workout</button>
    </form>
  </>);
}

function WorkoutCard({ w, compact, onDelete }) {
  const byExercise = useMemo(() => {
    const m = new Map();
    w.sets.forEach(s => m.set(s.exercise_name, [...(m.get(s.exercise_name) || []), s]));
    return [...m.entries()];
  }, [w]);
  return (
    <div className="workout-card">
      <div className="workout-head"><div><b>{w.title}</b><small>{day(w.performed_at)} · {w.duration_min} min</small></div>
        <div className="chips"><span>{w.total_sets} sets</span><span>{kg(w.volume_kg)}</span>{onDelete && <button className="icon-btn" onClick={onDelete} title="Delete workout">🗑</button>}</div></div>
      {byExercise.slice(0, compact ? 3 : undefined).map(([name, sets]) => (
        <div className="set-line" key={name}><span>{name}</span><small>{sets.map(s => `${s.weight_kg}×${s.reps}`).join('  ·  ')}</small></div>
      ))}
      {!compact && w.notes && <p className="muted notes">“{w.notes}”</p>}
    </div>
  );
}

function History({ workouts, onChange }) {
  const remove = async (id) => { await api(`/workouts/${id}`, { method: 'DELETE' }); onChange(); };
  return (<>
    <Header eyebrow="HISTORY" title="Workout history" subtitle={`${workouts.length} workouts logged`} />
    <div className="cards">{workouts.map(w => <WorkoutCard key={w.id} w={w} onDelete={() => remove(w.id)} />)}</div>
    {!workouts.length && <div className="empty">Nothing here yet — log your first workout.</div>}
  </>);
}

function Exercises({ exercises, onChange }) {
  const [error, setError] = useState('');
  const create = async (e) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    try {
      await api('/exercises', { method: 'POST', body: JSON.stringify({ name: f.get('name'), muscle_group: f.get('group'), equipment: f.get('equipment') }) });
      e.currentTarget.reset(); setError(''); onChange();
    } catch (err) { setError(err.message); }
  };
  const remove = async (id) => { try { await api(`/exercises/${id}`, { method: 'DELETE' }); onChange(); } catch (err) { setError(err.message); } };
  return (<>
    <Header eyebrow="LIBRARY" title="Exercises" subtitle={`${exercises.length} exercises`} />
    <form className="panel form-row inline" onSubmit={create}>
      <label>Name<input name="name" required placeholder="e.g. Bulgarian Split Squat" /></label>
      <label>Muscle group<select name="group">{GROUPS.map(g => <option key={g} value={g}>{pretty(g)}</option>)}</select></label>
      <label>Equipment<select name="equipment">{EQUIPMENT.map(g => <option key={g} value={g}>{pretty(g)}</option>)}</select></label>
      <button className="primary">Add</button>
    </form>
    {error && <div className="alert">{error}</div>}
    <div className="panel"><table><thead><tr><th>Exercise</th><th>Muscle group</th><th>Equipment</th><th></th></tr></thead>
      <tbody>{exercises.map(x => (
        <tr key={x.id}><td><b>{x.name}</b></td><td><span className="tag">{pretty(x.muscle_group)}</span></td><td>{pretty(x.equipment)}</td>
          <td><button className="icon-btn" onClick={() => remove(x.id)} title="Delete">🗑</button></td></tr>
      ))}</tbody></table></div>
  </>);
}

function Progress({ exercises, workouts }) {
  const used = exercises.filter(x => workouts.some(w => w.sets.some(s => s.exercise_id === x.id)));
  const [id, setId] = useState('');
  const [points, setPoints] = useState([]);
  const selected = id || (used[0] && String(used[0].id)) || '';
  useEffect(() => { if (selected) api(`/exercises/${selected}/progress`).then(setPoints).catch(() => setPoints([])); }, [selected, workouts]);
  return (<>
    <Header eyebrow="PRO · PROGRESS" title="Strength progress" subtitle="Estimated one-rep max and top set over time." />
    <div className="panel">
      <select value={selected} onChange={e => setId(e.target.value)}>
        {used.map(x => <option key={x.id} value={x.id}>{x.name}</option>)}
        {!used.length && <option>No logged exercises yet</option>}
      </select>
      {points.length > 0 && <Chart points={points} />}
      <table><thead><tr><th>Date</th><th>Top set</th><th>Est. 1RM</th><th>Volume</th></tr></thead>
        <tbody>{[...points].reverse().map(p => <tr key={p.workout_id}><td>{day(p.performed_at)}</td><td>{p.top_weight_kg} kg</td><td className="accent">{p.best_est_1rm_kg} kg</td><td>{kg(p.volume_kg)}</td></tr>)}</tbody></table>
    </div>
  </>);
}

function Chart({ points }) {
  const W = 640, H = 220, P = 32;
  const ys = points.flatMap(p => [p.best_est_1rm_kg, p.top_weight_kg]);
  const lo = Math.min(...ys) * 0.95, hi = Math.max(...ys) * 1.05;
  const x = (i) => P + (points.length === 1 ? (W - 2 * P) / 2 : (i * (W - 2 * P)) / (points.length - 1));
  const y = (v) => H - P - ((v - lo) / (hi - lo || 1)) * (H - 2 * P);
  const line = (key) => points.map((p, i) => `${i ? 'L' : 'M'}${x(i)},${y(p[key])}`).join(' ');
  return (
    <svg className="chart" viewBox={`0 0 ${W} ${H}`} role="img" aria-label="Progress chart">
      {[0, 0.5, 1].map(t => <line key={t} x1={P} x2={W - P} y1={P + t * (H - 2 * P)} y2={P + t * (H - 2 * P)} className="grid" />)}
      <path d={line('top_weight_kg')} className="series top" />
      <path d={line('best_est_1rm_kg')} className="series e1rm" />
      {points.map((p, i) => <circle key={i} cx={x(i)} cy={y(p.best_est_1rm_kg)} r="4" className="dot" />)}
      <text x={P} y={18} className="legend e1rm">● Est. 1RM</text><text x={P + 110} y={18} className="legend top">● Top set</text>
    </svg>
  );
}

createRoot(document.getElementById('root')).render(<App />);
