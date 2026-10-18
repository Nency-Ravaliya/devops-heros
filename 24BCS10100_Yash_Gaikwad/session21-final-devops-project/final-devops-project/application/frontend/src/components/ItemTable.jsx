import { STOCK_LABELS, formatMoney, formatNumber, stockPercent } from "../utils.js";

export default function ItemTable({ items, busyId, onAdjust, onEdit, onDelete }) {
  if (items.length === 0) {
    return (
      <div className="empty-state">
        <strong>No items match</strong>
        <p>Add an item or change the filters.</p>
      </div>
    );
  }

  return (
    <table className="item-table">
      <thead>
        <tr>
          <th>Item</th>
          <th>Stock</th>
          <th>Status</th>
          <th>Unit price</th>
          <th>Location</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        {items.map((item) => (
          <tr key={item.id} className={busyId === item.id ? "row-busy" : undefined}>
            <td data-label="Item">
              <span className="item-name">{item.name}</span>
              <span className="item-meta">
                <code>{item.sku}</code> · {item.category}
              </span>
            </td>
            <td data-label="Stock">
              <div className="stock-cell">
                <span className="stock-qty">{formatNumber(item.quantity)}</span>
                <span className="stock-bar" aria-hidden="true">
                  <span className={`stock-fill fill-${item.stock_status}`} style={{ width: `${stockPercent(item)}%` }} />
                </span>
                <span className="muted stock-reorder">reorder at {item.reorder_level}</span>
              </div>
            </td>
            <td data-label="Status">
              <span className={`badge badge-${item.stock_status}`}>{STOCK_LABELS[item.stock_status]}</span>
            </td>
            <td data-label="Unit price">{formatMoney(item.unit_price)}</td>
            <td data-label="Location" className="muted">
              {item.location || "—"}
            </td>
            <td className="actions-cell">
              <button className="mini-button" disabled={busyId === item.id} onClick={() => onAdjust(item, "receive")}>
                + Receive
              </button>
              <button className="mini-button" disabled={busyId === item.id || item.quantity === 0} onClick={() => onAdjust(item, "issue")}>
                − Issue
              </button>
              <button className="mini-button" disabled={busyId === item.id} onClick={() => onEdit(item)}>
                Edit
              </button>
              <button
                className="icon-button"
                disabled={busyId === item.id}
                onClick={() => onDelete(item)}
                aria-label={`Delete ${item.name}`}
                title="Delete item"
              >
                ✕
              </button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
