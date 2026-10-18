import { formatCompactMoney, formatNumber } from "../utils.js";

export default function StatCards({ stats }) {
  const cards = [
    { label: "Total SKUs", value: stats && formatNumber(stats.total_items), hint: stats && `${stats.categories} categories`, tone: "neutral" },
    { label: "Units in stock", value: stats && formatNumber(stats.total_units), hint: "across all locations", tone: "info" },
    { label: "Stock value", value: stats && formatCompactMoney(stats.total_value), hint: "at unit price", tone: "success" },
    {
      label: "Needs attention",
      value: stats && formatNumber(stats.low_stock + stats.out_of_stock),
      hint: stats && `${stats.low_stock} low · ${stats.out_of_stock} out`,
      tone: "danger",
    },
  ];

  return (
    <section className="kpi-grid" aria-label="Key numbers">
      {cards.map((card) => (
        <article key={card.label} className={`kpi-card kpi-${card.tone}`}>
          <span className="kpi-label">{card.label}</span>
          <strong className="kpi-value">{card.value ?? "–"}</strong>
          <span className="kpi-hint">{card.hint ?? " "}</span>
        </article>
      ))}
    </section>
  );
}
