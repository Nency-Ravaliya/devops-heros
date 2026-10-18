import { ArrowDown, ArrowRight, ArrowUpRight, TriangleAlert } from 'lucide-react';
import { statuses } from '../tickets';

function initials(name) {
  return (name || '?')
    .split(/[ .@]+/)
    .slice(0, 2)
    .map((n) => n[0])
    .join('')
    .toUpperCase();
}
function formatDate(date) {
  return new Date(date).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

export default function TicketTable({ tickets, onSelect }) {
  return (
    <div className="table-scroll">
      <table>
        <thead>
          <tr>
            <th>Ticket</th>
            <th>Requester</th>
            <th>Status</th>
            <th>Priority</th>
            <th>Assignee</th>
            <th>Created</th>
            <th>
              <span className="sr-only">Details</span>
            </th>
          </tr>
        </thead>
        <tbody>
          {tickets.map((ticket) => (
            <tr key={ticket.id}>
              <td>
                <button className="ticket-link" onClick={() => onSelect(ticket)}>
                  <span className="ticket-id">QD-{String(ticket.id).padStart(4, '0')}</span>
                  <strong>{ticket.title}</strong>
                </button>
              </td>
              <td>
                <div className="requester">
                  <span className={`person-avatar avatar-${ticket.id % 4}`}>
                    {initials(ticket.requester)}
                  </span>
                  <span>{ticket.requester}</span>
                </div>
              </td>
              <td>
                <span className={`status-badge ${ticket.status}`}>
                  <span />
                  {statuses[ticket.status]}
                </span>
              </td>
              <td>
                <span className={`priority ${ticket.priority}`}>
                  {ticket.priority === 'urgent' ? (
                    <TriangleAlert size={13} />
                  ) : ticket.priority === 'high' ? (
                    <ArrowUpRight size={14} />
                  ) : (
                    <ArrowDown size={13} />
                  )}
                  {ticket.priority}
                </span>
              </td>
              <td>{ticket.assignee || <span className="muted">Unassigned</span>}</td>
              <td className="date-cell">{formatDate(ticket.created_at)}</td>
              <td>
                <button
                  className="icon-button"
                  aria-label={`View ticket ${ticket.id}`}
                  onClick={() => onSelect(ticket)}
                >
                  <ArrowRight size={16} />
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
