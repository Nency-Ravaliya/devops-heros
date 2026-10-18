import { useEffect, useRef, useState } from "react";
import Modal from "./Modal.jsx";

export default function AdjustModal({ item, mode, onClose, onSubmit }) {
  const receiving = mode === "receive";
  const [amount, setAmount] = useState("");
  const [reason, setReason] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const amountRef = useRef(null);

  useEffect(() => {
    amountRef.current?.focus();
  }, []);

  const quantity = Number(amount) || 0;
  const delta = receiving ? quantity : -quantity;
  const nextQuantity = item.quantity + delta;
  const invalid = quantity < 1 || nextQuantity < 0;

  async function handleSubmit(event) {
    event.preventDefault();
    setSaving(true);
    setError("");
    try {
      await onSubmit(delta, reason.trim());
    } catch (err) {
      setError(err.message);
      setSaving(false);
    }
  }

  return (
    <Modal
      title={`${receiving ? "Receive" : "Issue"} stock`}
      titleId="adjust-modal-title"
      onClose={onClose}
      onSubmit={handleSubmit}
    >
      <p className="muted">
        <strong>{item.name}</strong> ({item.sku}) · {item.quantity} in stock
      </p>

      <label>
        {receiving ? "Quantity received" : "Quantity issued"}
        <input
          ref={amountRef}
          type="number"
          min="1"
          step="1"
          value={amount}
          onChange={(event) => setAmount(event.target.value)}
          required
        />
      </label>

      <label>
        Reason
        <input
          value={reason}
          onChange={(event) => setReason(event.target.value)}
          maxLength={200}
          placeholder={receiving ? "e.g. Purchase order PO-311" : "e.g. Shipped order #1042"}
        />
      </label>

      <p className={nextQuantity < 0 ? "form-error" : "muted"}>
        {nextQuantity < 0
          ? `Not enough stock: only ${item.quantity} available.`
          : `New quantity: ${nextQuantity}`}
      </p>

      {error && (
        <p className="form-error" role="alert">
          {error}
        </p>
      )}

      <div className="modal-actions">
        <button type="button" className="button secondary" onClick={onClose}>
          Cancel
        </button>
        <button type="submit" className="button primary" disabled={saving || invalid}>
          {saving ? "Saving…" : receiving ? "Receive stock" : "Issue stock"}
        </button>
      </div>
    </Modal>
  );
}
