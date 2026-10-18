// All calls use relative URLs: Vite (dev), Nginx (container) or the Ingress (Kubernetes)
// forwards /api to the backend, so the browser never needs the backend hostname.
const ITEMS_URL = "/api/items";

async function request(url, options = {}) {
  let response;
  try {
    response = await fetch(url, {
      headers: { "Content-Type": "application/json" },
      ...options,
    });
  } catch {
    throw new Error("The server did not respond. Check that the backend is running.");
  }

  if (!response.ok) {
    let detail = `Request failed (${response.status})`;
    try {
      const body = await response.json();
      if (typeof body.detail === "string") detail = body.detail;
      else if (Array.isArray(body.detail)) detail = body.detail.map((d) => d.msg).join(", ");
    } catch {
      // response had no JSON body (e.g. a 502 from the proxy) - keep the generic message
    }
    throw new Error(detail);
  }

  return response.status === 204 ? null : response.json();
}

export const getItems = () => request(ITEMS_URL);
export const getStats = () => request(`${ITEMS_URL}/stats`);
export const getMovements = (limit = 8) => request(`/api/movements?limit=${limit}`);
export const createItem = (item) => request(ITEMS_URL, { method: "POST", body: JSON.stringify(item) });
export const updateItem = (id, changes) =>
  request(`${ITEMS_URL}/${id}`, { method: "PUT", body: JSON.stringify(changes) });
export const adjustStock = (id, delta, reason) =>
  request(`${ITEMS_URL}/${id}/adjust`, { method: "POST", body: JSON.stringify({ delta, reason }) });
export const deleteItem = (id) => request(`${ITEMS_URL}/${id}`, { method: "DELETE" });
