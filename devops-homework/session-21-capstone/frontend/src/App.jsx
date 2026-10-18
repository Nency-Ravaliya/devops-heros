import { useEffect, useState } from 'react';
import {
  Check,
  CheckCheck,
  ChevronLeft,
  ChevronRight,
  CircleHelp,
  Clock3,
  Inbox,
  Layers3,
  LifeBuoy,
  LoaderCircle,
  Plus,
  RefreshCw,
  Search,
  Ticket,
  TriangleAlert,
} from 'lucide-react';
import { api } from './api';
import { statuses } from './tickets';
import TicketDialog from './components/TicketDialog';
import TicketTable from './components/TicketTable';

const pageSize = 20;

export default function App() {
  const [filter, setFilter] = useState('');
  const [priority, setPriority] = useState('');
  const [search, setSearch] = useState('');
  const [query, setQuery] = useState('');
  const [offset, setOffset] = useState(0);
  const [tickets, setTickets] = useState([]);
  const [total, setTotal] = useState(0);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [revision, setRevision] = useState(0);
  const [dialog, setDialog] = useState(null);
  const [notice, setNotice] = useState('');
  useEffect(() => {
    const timer = setTimeout(() => {
      setQuery(search);
      setOffset(0);
    }, 250);
    return () => clearTimeout(timer);
  }, [search]);
  useEffect(() => {
    let active = true;
    setLoading(true);
    setError('');
    const params = new URLSearchParams({
      limit: pageSize,
      offset,
      ...(filter && { status: filter }),
      ...(priority && { priority }),
      ...(query && { q: query }),
    });
    Promise.all([api(`/tickets?${params}`), api('/tickets/stats')])
      .then(([list, counts]) => {
        if (active) {
          if (offset && !list.items.length) {
            setOffset(Math.max(0, offset - pageSize));
            return;
          }
          setTickets(list.items);
          setTotal(list.total);
          setStats(counts);
        }
      })
      .catch((err) => {
        if (active) setError(err.message);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [filter, priority, query, offset, revision]);
  useEffect(() => {
    if (notice) {
      const t = setTimeout(() => setNotice(''), 4500);
      return () => clearTimeout(t);
    }
  }, [notice]);
  const chooseFilter = (value) => {
    setFilter(value);
    setOffset(0);
  };
  const refresh = () => setRevision((n) => n + 1);
  const cards = [
    {
      key: 'open',
      label: 'Open tickets',
      icon: Inbox,
      text: 'Waiting for a response',
      color: 'green',
    },
    {
      key: 'in_progress',
      label: 'In progress',
      icon: Clock3,
      text: 'Currently being worked on',
      color: 'blue',
    },
    {
      key: 'resolved',
      label: 'Resolved',
      icon: CheckCheck,
      text: 'Marked as completed',
      color: 'purple',
    },
    {
      key: 'urgent',
      label: 'Needs attention',
      icon: TriangleAlert,
      text: 'Urgent and unresolved',
      color: 'orange',
    },
  ];
  return (
    <div className="app-shell">
      <aside className="sidebar">
        <a className="brand" href="/" aria-label="QueueDesk home">
          <span className="brand-mark">
            <Layers3 size={23} />
          </span>
          queue<span>desk</span>
          <span className="brand-dot">.</span>
        </a>
        <div className="workspace">
          <span className="workspace-avatar">Q</span>
          <div>
            <strong>Support workspace</strong>
            <small>Ticket management</small>
          </div>
          <span className="workspace-dot" />
        </div>
        <div className="nav-caption">WORKSPACE</div>
        <nav aria-label="Ticket views">
          <button
            className={filter === '' ? 'nav-item active' : 'nav-item'}
            onClick={() => chooseFilter('')}
          >
            <Inbox size={18} /> All tickets<span className="nav-count">{stats?.total ?? '–'}</span>
          </button>
          {Object.entries(statuses).map(([key, label]) => (
            <button
              key={key}
              className={filter === key ? 'nav-item active' : 'nav-item'}
              onClick={() => chooseFilter(key)}
            >
              {key === 'resolved' ? (
                <CheckCheck size={18} />
              ) : key === 'open' ? (
                <Ticket size={18} />
              ) : (
                <Clock3 size={18} />
              )}
              {label}
              <span className="nav-count">{stats?.[key] ?? '–'}</span>
            </button>
          ))}
        </nav>
        <div className="sidebar-note">
          <LifeBuoy size={23} />
          <strong>Ticket workflow</strong>
          <p>
            Assign a ticket when you start working on it. Mark it resolved once the issue is fixed.
          </p>
          <span>OPEN → IN PROGRESS → RESOLVED</span>
        </div>
        <div className="sidebar-footer">
          <span className="profile-avatar">ST</span>
          <div>
            <strong>Support team</strong>
            <small>QueueDesk workspace</small>
          </div>
          <span className="online-dot" />
        </div>
      </aside>
      <main>
        <header className="topbar">
          <div className="breadcrumb">
            Workspace <ChevronRight size={14} />
            <span>Support overview</span>
          </div>
          <div className="topbar-right">
            <span className="team-status">
              <span className="online-dot" /> Team workspace
            </span>
            <span className="topbar-avatar">ST</span>
          </div>
        </header>
        <div className="main-content">
          <section className="page-heading">
            <div>
              <div className="eyebrow">QUEUEDESK</div>
              <h1>Support tickets</h1>
              <p>Track requests, assign work, and update ticket status.</p>
            </div>
            <button className="primary create-main" onClick={() => setDialog({ ticket: null })}>
              <Plus size={18} /> New ticket
            </button>
          </section>
          <section className="stat-grid" aria-label="Ticket statistics">
            {cards.map(({ key, label, icon: Icon, text, color }) => (
              <article className="stat-card" key={key}>
                <div className="stat-top">
                  <span>{label}</span>
                  <span className={`stat-icon ${color}`}>
                    <Icon size={17} />
                  </span>
                </div>
                <strong className="stat-number">{error ? '–' : (stats?.[key] ?? '–')}</strong>
                <p>
                  <span className={`mini-dot ${color}`} />
                  {text}
                </p>
              </article>
            ))}
          </section>
          <section className="queue-panel" aria-labelledby="queue-title">
            <div className="queue-heading">
              <div>
                <h2 id="queue-title">
                  Tickets <span>{error ? '–' : total}</span>
                </h2>
                <p>Select a ticket to view its details or make changes.</p>
              </div>
              <button
                className="icon-button refresh-button"
                onClick={refresh}
                aria-label="Refresh tickets"
                disabled={loading}
              >
                <RefreshCw size={17} className={loading ? 'spin' : ''} />
              </button>
            </div>
            <div className="queue-tools">
              <div className="tabs" role="group" aria-label="Filter by status">
                {[['', 'All tickets'], ...Object.entries(statuses)].map(([key, label]) => (
                  <button
                    key={key}
                    aria-pressed={filter === key}
                    className={filter === key ? 'tab selected' : 'tab'}
                    onClick={() => chooseFilter(key)}
                  >
                    {label}
                  </button>
                ))}
              </div>
              <div className="search-tools">
                <label className="search-box">
                  <Search size={16} />
                  <input
                    aria-label="Search ticket subjects"
                    placeholder="Search tickets…"
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                  />
                </label>
                <select
                  className="priority-filter"
                  aria-label="Filter by priority"
                  value={priority}
                  onChange={(e) => {
                    setPriority(e.target.value);
                    setOffset(0);
                  }}
                >
                  <option value="">All priorities</option>
                  {['urgent', 'high', 'medium', 'low'].map((p) => (
                    <option key={p}>{p}</option>
                  ))}
                </select>
              </div>
            </div>
            {error ? (
              <div className="empty-state" role="alert">
                <TriangleAlert size={32} />
                <h3>Could not load tickets</h3>
                <p>{error}</p>
                <button className="secondary" onClick={refresh}>
                  <RefreshCw size={15} /> Try again
                </button>
              </div>
            ) : loading ? (
              <div className="empty-state" role="status">
                <LoaderCircle className="spin" size={30} />
                <p>Loading tickets…</p>
              </div>
            ) : !tickets.length ? (
              <div className="empty-state">
                <span className="empty-icon">
                  <Inbox size={32} />
                </span>
                <h3>{query || filter || priority ? 'No matching tickets' : 'No tickets yet'}</h3>
                <p>
                  {query || filter || priority
                    ? 'Try a different search or clear the filters.'
                    : 'Create a ticket to start tracking a request.'}
                </p>
                <button className="secondary" onClick={() => setDialog({ ticket: null })}>
                  <Plus size={16} /> Create a ticket
                </button>
              </div>
            ) : (
              <TicketTable tickets={tickets} onSelect={(ticket) => setDialog({ ticket })} />
            )}
            <div className="table-footer">
              <span>
                {total && !error
                  ? `Showing ${offset + 1}–${Math.min(offset + pageSize, total)} of ${total} tickets`
                  : 'No tickets to show.'}
              </span>
              <div>
                <button
                  className="icon-button"
                  aria-label="Previous page"
                  disabled={loading || offset === 0}
                  onClick={() => setOffset((n) => Math.max(0, n - pageSize))}
                >
                  <ChevronLeft size={16} />
                </button>
                <button
                  className="icon-button"
                  aria-label="Next page"
                  disabled={loading || offset + pageSize >= total}
                  onClick={() => setOffset((n) => n + pageSize)}
                >
                  <ChevronRight size={16} />
                </button>
              </div>
            </div>
          </section>
          <div className="bottom-note">
            <span>
              <CircleHelp size={15} /> Summary counts include all tickets. Filters apply to the
              table.
            </span>
            <span>QueueDesk · Support tracker</span>
          </div>
        </div>
      </main>
      {dialog && (
        <TicketDialog
          ticket={dialog.ticket}
          onClose={() => setDialog(null)}
          onSaved={(message) => {
            setDialog(null);
            setNotice(message);
            refresh();
          }}
        />
      )}
      {notice && (
        <div className="toast" role="status">
          <Check size={17} />
          {notice}
        </div>
      )}
    </div>
  );
}
