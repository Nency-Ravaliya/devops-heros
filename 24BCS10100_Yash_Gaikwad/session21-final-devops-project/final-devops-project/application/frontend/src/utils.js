export const STOCK_LABELS = {
  in_stock: "In stock",
  low_stock: "Low stock",
  out_of_stock: "Out of stock",
};

const money = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" });
const compactMoney = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "USD",
  notation: "compact",
  maximumFractionDigits: 1,
});

export const formatMoney = (value) => money.format(value);
export const formatCompactMoney = (value) => compactMoney.format(value);
export const formatNumber = (value) => new Intl.NumberFormat("en-US").format(value);

export function timeAgo(isoString) {
  const seconds = Math.max(0, Math.round((Date.now() - new Date(isoString).getTime()) / 1000));
  if (seconds < 60) return "just now";
  const minutes = Math.round(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.round(hours / 24)}d ago`;
}

// Width of the stock bar: full at three times the reorder level.
export function stockPercent(item) {
  const full = Math.max(item.reorder_level * 3, 1);
  return Math.min(100, Math.round((item.quantity / full) * 100));
}
