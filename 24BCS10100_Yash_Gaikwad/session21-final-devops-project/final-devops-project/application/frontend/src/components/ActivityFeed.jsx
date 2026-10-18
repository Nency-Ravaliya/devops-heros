import { formatNumber, timeAgo } from "../utils.js";

export default function ActivityFeed({ movements }) {
  return (
    <section className="panel" aria-labelledby="activity-heading">
      <h2 id="activity-heading">Stock movements</h2>
      {movements.length === 0 ? (
        <p className="muted">No stock has moved yet.</p>
      ) : (
        <ul className="activity-list">
          {movements.map((movement) => (
            <li key={movement.id}>
              <span className={movement.delta > 0 ? "delta delta-in" : "delta delta-out"}>
                {movement.delta > 0 ? "+" : "−"}
                {formatNumber(Math.abs(movement.delta))}
              </span>
              <div>
                <p>
                  <strong>{movement.item_name}</strong>
                </p>
                <span className="muted">
                  {movement.reason || "Adjustment"} · {timeAgo(movement.created_at)}
                </span>
              </div>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
