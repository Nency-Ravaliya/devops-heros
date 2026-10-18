import { useEffect, useRef, useState } from "react";
import Modal from "./Modal.jsx";

const EMPTY_FORM = {
  sku: "",
  name: "",
  category: "General",
  quantity: "0",
  reorder_level: "10",
  unit_price: "0.00",
  supplier: "",
  location: "",
  description: "",
};

function toForm(item) {
  return {
    sku: item.sku,
    name: item.name,
    category: item.category,
    quantity: String(item.quantity),
    reorder_level: String(item.reorder_level),
    unit_price: item.unit_price.toFixed(2),
    supplier: item.supplier ?? "",
    location: item.location ?? "",
    description: item.description,
  };
}

export default function ItemModal({ item, categories, onClose, onSubmit }) {
  const editing = Boolean(item);
  const [form, setForm] = useState(item ? toForm(item) : EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const firstFieldRef = useRef(null);

  useEffect(() => {
    firstFieldRef.current?.focus();
  }, []);

  const setField = (name) => (event) => setForm({ ...form, [name]: event.target.value });

  async function handleSubmit(event) {
    event.preventDefault();
    setSaving(true);
    setError("");
    try {
      await onSubmit({
        sku: form.sku.trim(),
        name: form.name.trim(),
        category: form.category.trim() || "General",
        quantity: Number(form.quantity) || 0,
        reorder_level: Number(form.reorder_level) || 0,
        unit_price: form.unit_price || "0",
        supplier: form.supplier.trim() || null,
        location: form.location.trim() || null,
        description: form.description,
      });
    } catch (err) {
      setError(err.message);
      setSaving(false);
    }
  }

  return (
    <Modal title={editing ? "Edit item" : "New item"} titleId="item-modal-title" onClose={onClose} onSubmit={handleSubmit}>
      <div className="form-row">
        <label>
          SKU
          <input ref={firstFieldRef} value={form.sku} onChange={setField("sku")} maxLength={40} required placeholder="EL-1001" />
        </label>
        <label>
          Category
          <input value={form.category} onChange={setField("category")} maxLength={60} list="category-options" required />
          <datalist id="category-options">
            {categories.map((name) => (
              <option key={name} value={name} />
            ))}
          </datalist>
        </label>
      </div>

      <label>
        Name
        <input value={form.name} onChange={setField("name")} maxLength={200} required />
      </label>

      <div className="form-row">
        <label>
          Quantity
          <input type="number" min="0" step="1" value={form.quantity} onChange={setField("quantity")} required />
        </label>
        <label>
          Reorder level
          <input type="number" min="0" step="1" value={form.reorder_level} onChange={setField("reorder_level")} required />
        </label>
      </div>

      <div className="form-row">
        <label>
          Unit price (USD)
          <input type="number" min="0" step="0.01" value={form.unit_price} onChange={setField("unit_price")} required />
        </label>
        <label>
          Location
          <input value={form.location} onChange={setField("location")} maxLength={50} placeholder="A-01" />
        </label>
      </div>

      <label>
        Supplier
        <input value={form.supplier} onChange={setField("supplier")} maxLength={100} placeholder="Optional" />
      </label>

      <label>
        Description
        <textarea value={form.description} onChange={setField("description")} rows={2} maxLength={2000} />
      </label>

      {error && (
        <p className="form-error" role="alert">
          {error}
        </p>
      )}

      <div className="modal-actions">
        <button type="button" className="button secondary" onClick={onClose}>
          Cancel
        </button>
        <button type="submit" className="button primary" disabled={saving || !form.sku.trim() || !form.name.trim()}>
          {saving ? "Saving…" : editing ? "Save changes" : "Create item"}
        </button>
      </div>
    </Modal>
  );
}
