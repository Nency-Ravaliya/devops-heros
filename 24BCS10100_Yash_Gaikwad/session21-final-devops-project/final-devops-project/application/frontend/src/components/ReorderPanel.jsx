import { STOCK_LABELS } from "../utils.js";

export default function ReorderPanel({ items, onReceive }) {
  const needsStock = items
    .filter((item) => item.stock_status !== "in_stock")
    .sort((a, b) => a.quantity - b.quantity)
    .slice(0, 6);

  return (
    <section className="panel" aria-labelledby="reorder-heading">
      <h2 id="reorder-heading">Reorder list</h2>
      {needsStock.length === 0 ? (
        <p className="muted">Everything is above its reorder level.</p>
      ) : (
        <ul className="reorder-list">
          {needsStock.map((item) => (
            <li key={item.id}>
              <div>
                <strong>{item.name}</strong>
                <span className="muted">
                  {item.quantity} left · {STOCK_LABELS[item.stock_status].toLowerCase()}
                  {item.supplier ? ` · ${item.supplier}` : ""}
                </span>
              </div>
              <button className="mini-button" onClick={() => onReceive(item, "receive")}>
                Receive
              </button>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
