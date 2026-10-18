import { STOCK_LABELS } from "../utils.js";

const TABS = [{ id: "all", label: "All" }, ...Object.entries(STOCK_LABELS).map(([id, label]) => ({ id, label }))];

export default function FilterBar({ stock, onStockChange, counts, search, onSearchChange, category, onCategoryChange, categories }) {
  return (
    <div className="filters">
      <div className="filter-bar" role="tablist" aria-label="Filter by stock level">
        {TABS.map((tab) => (
          <button
            key={tab.id}
            role="tab"
            aria-selected={stock === tab.id}
            className={stock === tab.id ? "filter active" : "filter"}
            onClick={() => onStockChange(tab.id)}
          >
            {tab.label}
            <span className="filter-count">{counts[tab.id] ?? 0}</span>
          </button>
        ))}
      </div>

      <div className="filter-inputs">
        <input
          type="search"
          className="search-input"
          placeholder="Search name or SKU"
          aria-label="Search items"
          value={search}
          onChange={(event) => onSearchChange(event.target.value)}
        />
        <select
          className="select-input"
          aria-label="Filter by category"
          value={category}
          onChange={(event) => onCategoryChange(event.target.value)}
        >
          <option value="">All categories</option>
          {categories.map((name) => (
            <option key={name} value={name}>
              {name}
            </option>
          ))}
        </select>
      </div>
    </div>
  );
}
