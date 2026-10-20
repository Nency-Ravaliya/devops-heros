import "./style.css";

const $ = (id) => document.getElementById(id);
async function load() {
  try {
    const [info, sum, items] = await Promise.all(["/api/info", "/api/summary", "/api/items"].map(u => fetch(u).then(r => r.json())));
    $("env").textContent = `${info.env} - v${info.version}`;
    $("k-items").textContent = sum.total_items;
    $("k-units").textContent = sum.total_units;
    $("k-low").textContent = sum.low_stock_items;
    $("k-value").textContent = "Rs " + (sum.inventory_value_paise / 100).toFixed(2);
    $("rows").replaceChildren(...items.map(i => {
      const tr = document.createElement("tr");
      [i.sku, i.name, i.location, i.quantity].forEach(v => { const td = document.createElement("td"); td.textContent = v; tr.appendChild(td); });
      const flag = document.createElement("td");
      if (i.low_stock) { const s = document.createElement("span"); s.className = "low"; s.textContent = "reorder"; flag.appendChild(s); }
      tr.appendChild(flag);
      return tr;
    }));
  } catch (e) { $("err").textContent = "Backend unavailable: " + e; }
}
$("f").addEventListener("submit", async (ev) => {
  ev.preventDefault();
  const d = Object.fromEntries(new FormData(ev.target));
  d.quantity = Number(d.quantity); d.unit_price_paise = Number(d.unit_price_paise || 0);
  const r = await fetch("/api/items", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(d) });
  $("err").textContent = r.ok ? "" : (await r.json()).detail;
  if (r.ok) ev.target.reset();
  load();
});
load();
