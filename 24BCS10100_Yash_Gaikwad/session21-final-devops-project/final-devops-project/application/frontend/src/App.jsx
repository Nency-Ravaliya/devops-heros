import { useCallback, useEffect, useMemo, useState } from "react";
import { adjustStock, createItem, deleteItem, getItems, getMovements, getStats, updateItem } from "./api.js";
import ActivityFeed from "./components/ActivityFeed.jsx";
import AdjustModal from "./components/AdjustModal.jsx";
import FilterBar from "./components/FilterBar.jsx";
import ItemModal from "./components/ItemModal.jsx";
import ItemTable from "./components/ItemTable.jsx";
import PipelineIndicator from "./components/PipelineIndicator.jsx";
import ReorderPanel from "./components/ReorderPanel.jsx";
import Sidebar from "./components/Sidebar.jsx";
import StatCards from "./components/StatCards.jsx";

export default function App() {
  const [items, setItems] = useState([]);
  const [stats, setStats] = useState(null);
  const [movements, setMovements] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState("");
  const [actionError, setActionError] = useState("");
  const [busyId, setBusyId] = useState(null);

  const [stockFilter, setStockFilter] = useState("all");
  const [category, setCategory] = useState("");
  const [search, setSearch] = useState("");

  const [itemModal, setItemModal] = useState(null); // { item } while open; item is undefined when creating
  const [adjustModal, setAdjustModal] = useState(null); // { item, mode }

  const load = useCallback(async () => {
    try {
      const [itemList, statList, movementList] = await Promise.all([getItems(), getStats(), getMovements(8)]);
      setItems(itemList);
      setStats(statList);
      setMovements(movementList);
      setLoadError("");
    } catch (err) {
      setLoadError(err.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const categories = useMemo(() => [...new Set(items.map((item) => item.category))].sort(), [items]);

  const counts = useMemo(
    () => ({
      all: items.length,
      in_stock: items.filter((i) => i.stock_status === "in_stock").length,
      low_stock: items.filter((i) => i.stock_status === "low_stock").length,
      out_of_stock: items.filter((i) => i.stock_status === "out_of_stock").length,
    }),
    [items],
  );

  const visibleItems = useMemo(() => {
    const needle = search.trim().toLowerCase();
    return items.filter(
      (item) =>
        (stockFilter === "all" || item.stock_status === stockFilter) &&
        (!category || item.category === category) &&
        (!needle || item.name.toLowerCase().includes(needle) || item.sku.toLowerCase().includes(needle)),
    );
  }, [items, stockFilter, category, search]);

  async function handleSaveItem(payload) {
    if (itemModal.item) await updateItem(itemModal.item.id, payload);
    else await createItem(payload);
    setItemModal(null);
    await load();
  }

  async function handleAdjust(delta, reason) {
    await adjustStock(adjustModal.item.id, delta, reason);
    setAdjustModal(null);
    await load();
  }

  async function handleDelete(item) {
    if (!window.confirm(`Delete “${item.name}” and its stock history?`)) return;
    setBusyId(item.id);
    setActionError("");
    try {
      await deleteItem(item.id);
      await load();
    } catch (err) {
      setActionError(`Could not delete “${item.name}”: ${err.message}`);
    } finally {
      setBusyId(null);
    }
  }

  return (
    <div className="app-shell">
      <Sidebar />

      <main className="main">
        <header className="page-header">
          <div>
            <h1>Inventory dashboard</h1>
            <p className="muted">Stock levels, reorder alerts and recent movements.</p>
          </div>
          <button className="button primary" onClick={() => setItemModal({})}>
            + New item
          </button>
        </header>

        {loading && (
          <div className="state-card" role="status">
            <span className="spinner" aria-hidden="true" />
            Loading inventory…
          </div>
        )}

        {!loading && loadError && (
          <div className="state-card error" role="alert">
            <strong>We couldn’t reach the StockPilot API.</strong>
            <p>{loadError}</p>
            <button className="button secondary" onClick={load}>
              Try again
            </button>
          </div>
        )}

        {!loading && !loadError && (
          <>
            <StatCards stats={stats} />

            {actionError && (
              <div className="banner error" role="alert">
                {actionError}
                <button className="icon-button" onClick={() => setActionError("")} aria-label="Dismiss">
                  ✕
                </button>
              </div>
            )}

            <div className="content-grid">
              <section className="panel table-panel" aria-labelledby="items-heading">
                <div className="panel-header">
                  <h2 id="items-heading">Items</h2>
                </div>
                <FilterBar
                  stock={stockFilter}
                  onStockChange={setStockFilter}
                  counts={counts}
                  search={search}
                  onSearchChange={setSearch}
                  category={category}
                  onCategoryChange={setCategory}
                  categories={categories}
                />
                <ItemTable
                  items={visibleItems}
                  busyId={busyId}
                  onAdjust={(item, mode) => setAdjustModal({ item, mode })}
                  onEdit={(item) => setItemModal({ item })}
                  onDelete={handleDelete}
                />
              </section>

              <div className="side-column">
                <ReorderPanel items={items} onReceive={(item, mode) => setAdjustModal({ item, mode })} />
                <ActivityFeed movements={movements} />
                <PipelineIndicator />
              </div>
            </div>
          </>
        )}
      </main>

      {itemModal && (
        <ItemModal
          item={itemModal.item}
          categories={categories}
          onClose={() => setItemModal(null)}
          onSubmit={handleSaveItem}
        />
      )}
      {adjustModal && (
        <AdjustModal
          item={adjustModal.item}
          mode={adjustModal.mode}
          onClose={() => setAdjustModal(null)}
          onSubmit={handleAdjust}
        />
      )}
    </div>
  );
}
