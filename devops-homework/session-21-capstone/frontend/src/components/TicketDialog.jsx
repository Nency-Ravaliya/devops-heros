import { useEffect, useRef, useState } from 'react';
import { Check, LoaderCircle, Trash2, X } from 'lucide-react';
import { api } from '../api';
import { emptyTicket, statuses } from '../tickets';

export default function TicketDialog({ ticket, onClose, onSaved }) {
  const dialogRef = useRef(null);
  const [form, setForm] = useState(
    ticket ? Object.fromEntries(Object.keys(emptyTicket).map((k) => [k, ticket[k]])) : emptyTicket,
  );
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  useEffect(() => {
    dialogRef.current.showModal();
  }, []);
  const handleFieldChange = (e) => setForm((f) => ({ ...f, [e.target.name]: e.target.value }));
  async function handleSubmit(e) {
    e.preventDefault();
    setBusy(true);
    setError('');
    try {
      await api(`/tickets${ticket ? `/${ticket.id}` : ''}`, {
        method: ticket ? 'PUT' : 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });
      onSaved(ticket ? 'Ticket updated.' : 'Ticket created.');
    } catch (err) {
      setError(err.message);
      setBusy(false);
    }
  }
  async function handleDelete() {
    if (!window.confirm(`Delete ticket #${ticket.id}? This permanently removes the ticket.`))
      return;
    setBusy(true);
    setError('');
    try {
      await api(`/tickets/${ticket.id}`, { method: 'DELETE' });
      onSaved('Ticket deleted.');
    } catch (err) {
      setError(err.message);
      setBusy(false);
    }
  }
  return (
    <dialog
      ref={dialogRef}
      onCancel={(e) => {
        e.preventDefault();
        if (!busy) onClose();
      }}
      aria-labelledby="dialog-title"
    >
      <form onSubmit={handleSubmit}>
        <div className="dialog-heading">
          <div>
            <span className="eyebrow">
              {ticket ? `TICKET #${String(ticket.id).padStart(4, '0')}` : 'NEW TICKET'}
            </span>
            <h2 id="dialog-title">{ticket ? 'Ticket details' : 'Create a ticket'}</h2>
          </div>
          <button
            type="button"
            className="icon-button"
            aria-label="Close dialog"
            disabled={busy}
            onClick={onClose}
          >
            <X size={20} />
          </button>
        </div>
        <fieldset disabled={busy}>
          <label>
            Subject
            <input
              autoFocus
              name="title"
              required
              minLength={3}
              maxLength={160}
              placeholder="e.g. Unable to sign in"
              value={form.title}
              onChange={handleFieldChange}
            />
          </label>
          <label>
            Description
            <textarea
              name="description"
              maxLength={5000}
              rows={4}
              placeholder="What happened? Include any error message."
              value={form.description}
              onChange={handleFieldChange}
            />
          </label>
          <div className="form-row">
            <label>
              Requester email
              <input
                type="email"
                name="requester"
                required
                maxLength={160}
                placeholder="alex@example.com"
                value={form.requester}
                onChange={handleFieldChange}
              />
            </label>
            <label>
              Assigned to
              <input
                name="assignee"
                maxLength={80}
                placeholder="Unassigned"
                value={form.assignee}
                onChange={handleFieldChange}
              />
            </label>
          </div>
          <div className="form-row">
            <label>
              Priority
              <select name="priority" value={form.priority} onChange={handleFieldChange}>
                {['low', 'medium', 'high', 'urgent'].map((p) => (
                  <option key={p}>{p}</option>
                ))}
              </select>
            </label>
            <label>
              Status
              <select name="status" value={form.status} onChange={handleFieldChange}>
                {Object.entries(statuses).map(([k, v]) => (
                  <option value={k} key={k}>
                    {v}
                  </option>
                ))}
              </select>
            </label>
          </div>
        </fieldset>
        {error && (
          <p role="alert" className="form-error">
            {error}
          </p>
        )}
        <div className="dialog-footer">
          {ticket && (
            <button type="button" className="delete-button" disabled={busy} onClick={handleDelete}>
              <Trash2 size={16} /> Delete
            </button>
          )}
          <button type="button" className="secondary" disabled={busy} onClick={onClose}>
            Cancel
          </button>
          <button className="primary" disabled={busy}>
            {busy ? <LoaderCircle className="spin" size={16} /> : <Check size={16} />}
            {ticket ? 'Save changes' : 'Create ticket'}
          </button>
        </div>
      </form>
    </dialog>
  );
}
