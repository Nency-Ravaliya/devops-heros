import { useCallback, useEffect, useState } from 'react'
import { api } from './api.js'

const STATUSES = ['planned', 'in_progress', 'done']
const LABEL = { planned: 'Planned', in_progress: 'In progress', done: 'Done' }
const EMPTY = { subject: '', topic: '', minutes: 30, status: 'planned', notes: '' }

export default function App() {
  const [entries, setEntries] = useState([])
  const [summary, setSummary] = useState(null)
  const [form, setForm] = useState(EMPTY)
  const [filter, setFilter] = useState('all')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  const refresh = useCallback(async () => {
    try {
      const [e, s] = await Promise.all([api.list(), api.summary()])
      setEntries(e)
      setSummary(s)
      setError('')
    } catch (err) {
      setError(`Backend unreachable: ${err.message}`)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    refresh()
  }, [refresh])

  async function submit(ev) {
    ev.preventDefault()
    try {
      await api.create({ ...form, minutes: Number(form.minutes) })
      setForm(EMPTY)
      await refresh()
    } catch (err) {
      setError(err.message)
    }
  }

  async function setStatus(entry, status) {
    try {
      await api.update(entry.id, { status })
      await refresh()
    } catch (err) {
      setError(err.message)
    }
  }

  async function remove(entry) {
    try {
      await api.remove(entry.id)
      await refresh()
    } catch (err) {
      setError(err.message)
    }
  }

  const visible = filter === 'all' ? entries : entries.filter((e) => e.status === filter)
  const pct = summary ? Math.min(100, Math.round((summary.done_minutes / summary.daily_goal_minutes) * 100)) : 0

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="brand">StudyTrack</div>
        <p className="muted">Log what you studied, see where the hours go.</p>
        {summary && (
          <div className="goal">
            <div className="goal-head">
              <span>Daily goal</span>
              <strong>
                {summary.done_minutes} / {summary.daily_goal_minutes} min
              </strong>
            </div>
            <div className="bar">
              <div className={`bar-fill ${summary.goal_reached ? 'ok' : ''}`} style={{ width: `${pct}%` }} />
            </div>
            <small className="muted">{summary.goal_reached ? 'Goal reached today.' : `${pct}% of today's goal done.`}</small>
          </div>
        )}
        {summary && summary.by_subject.length > 0 && (
          <div className="subjects">
            <h4>By subject</h4>
            {summary.by_subject.map((s) => (
              <div className="subject-row" key={s.subject}>
                <span>{s.subject}</span>
                <span className="muted">
                  {s.minutes} min · {s.entries}
                </span>
              </div>
            ))}
          </div>
        )}
      </aside>

      <main className="content">
        <header className="topbar">
          <h1>Study log</h1>
          <div className="kpis">
            <div className="kpi">
              <span className="muted">Entries</span>
              <strong>{summary ? summary.total_entries : '–'}</strong>
            </div>
            <div className="kpi">
              <span className="muted">Minutes</span>
              <strong>{summary ? summary.total_minutes : '–'}</strong>
            </div>
            <div className="kpi">
              <span className="muted">Done</span>
              <strong>{summary ? summary.by_status.done || 0 : '–'}</strong>
            </div>
          </div>
        </header>

        {error && <div className="alert">{error}</div>}

        <form className="card form" onSubmit={submit}>
          <input
            required
            placeholder="Subject (e.g. Operating Systems)"
            value={form.subject}
            onChange={(e) => setForm({ ...form, subject: e.target.value })}
          />
          <input
            required
            placeholder="Topic"
            value={form.topic}
            onChange={(e) => setForm({ ...form, topic: e.target.value })}
          />
          <input
            type="number"
            min="1"
            max="600"
            value={form.minutes}
            onChange={(e) => setForm({ ...form, minutes: e.target.value })}
          />
          <select value={form.status} onChange={(e) => setForm({ ...form, status: e.target.value })}>
            {STATUSES.map((s) => (
              <option key={s} value={s}>
                {LABEL[s]}
              </option>
            ))}
          </select>
          <button type="submit">Add entry</button>
        </form>

        <div className="filters">
          {['all', ...STATUSES].map((f) => (
            <button key={f} className={filter === f ? 'chip active' : 'chip'} onClick={() => setFilter(f)}>
              {f === 'all' ? 'All' : LABEL[f]}
            </button>
          ))}
        </div>

        <div className="card">
          {loading ? (
            <p className="muted">Loading…</p>
          ) : visible.length === 0 ? (
            <p className="muted">No entries yet. Add your first study block above.</p>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Subject</th>
                  <th>Topic</th>
                  <th>Minutes</th>
                  <th>Status</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {visible.map((e) => (
                  <tr key={e.id}>
                    <td>{e.subject}</td>
                    <td>{e.topic}</td>
                    <td>{e.minutes}</td>
                    <td>
                      <span className={`badge ${e.status}`}>{LABEL[e.status]}</span>
                    </td>
                    <td className="actions">
                      {e.status !== 'done' && (
                        <button className="link" onClick={() => setStatus(e, 'done')}>
                          mark done
                        </button>
                      )}
                      {e.status === 'planned' && (
                        <button className="link" onClick={() => setStatus(e, 'in_progress')}>
                          start
                        </button>
                      )}
                      <button className="link danger" onClick={() => remove(e)}>
                        delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </main>
    </div>
  )
}
