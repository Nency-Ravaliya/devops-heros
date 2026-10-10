// All calls are relative, so the browser only ever talks to the host that served the page.
// nginx (compose) or the Ingress (Kubernetes) forwards /api to the backend.
async function request(path, options = {}) {
  const res = await fetch(path, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  })
  if (res.status === 204) return null
  const body = await res.json().catch(() => null)
  if (!res.ok) {
    const detail = body && body.detail ? JSON.stringify(body.detail) : res.statusText
    throw new Error(`${res.status} ${detail}`)
  }
  return body
}

export const api = {
  list: () => request('/api/entries'),
  summary: () => request('/api/entries/summary'),
  create: (data) => request('/api/entries', { method: 'POST', body: JSON.stringify(data) }),
  update: (id, data) => request(`/api/entries/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  remove: (id) => request(`/api/entries/${id}`, { method: 'DELETE' }),
}
