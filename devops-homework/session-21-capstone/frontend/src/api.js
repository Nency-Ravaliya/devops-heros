export async function api(path, options) {
  const response = await fetch(`/api${path}`, options);
  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    const detail =
      typeof data.detail === 'string' ? data.detail : data.detail?.map((e) => e.msg).join('. ');
    throw new Error(detail || `The request failed (${response.status}). Please try again.`);
  }
  return response.status === 204 ? null : response.json();
}
