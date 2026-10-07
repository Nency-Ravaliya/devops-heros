/* ────────────────────────────────────────────────────────
   DevSecOps Dashboard – JavaScript
   ──────────────────────────────────────────────────────── */

// ── Helpers ────────────────────────────────────────────

function scrollTo(hash) {
  document.querySelector(hash)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function show(id)  { document.getElementById(id)?.classList.remove('hidden'); }
function hide(id)  { document.getElementById(id)?.classList.add('hidden'); }
function setHTML(id, html) { const el = document.getElementById(id); if (el) el.innerHTML = html; }

function showResult(id, content, isError = false) {
  const el = document.getElementById(id);
  if (!el) return;
  el.classList.remove('hidden', 'error');
  if (isError) el.classList.add('error');
  el.textContent = typeof content === 'string' ? content : JSON.stringify(content, null, 2);
}

function setLoading(btnId, loading) {
  const btn = document.getElementById(btnId);
  if (!btn) return;
  btn.disabled = loading;
  btn.textContent = loading ? '⏳ Loading…' : btn.dataset.label || btn.textContent;
}

// ── Health Check ───────────────────────────────────────

async function checkHealth() {
  try {
    const res = await fetch('/health');
    const data = await res.json();
    const label = document.getElementById('health-label');
    const dot   = document.querySelector('.pulse-dot');
    if (data.status === 'healthy') {
      if (label) label.textContent = 'Healthy';
      if (dot)   { dot.style.background = 'var(--success)'; }
    } else {
      if (label) label.textContent = 'Degraded';
      if (dot)   { dot.style.background = 'var(--warning)'; }
    }
  } catch {
    const label = document.getElementById('health-label');
    const dot   = document.querySelector('.pulse-dot');
    if (label) label.textContent = 'Offline';
    if (dot)   dot.style.background = 'var(--danger)';
  }
}

// ── Status Cards ───────────────────────────────────────

async function loadStatus() {
  const btn = document.getElementById('refresh-status-btn');
  if (btn) { btn.disabled = true; btn.textContent = '↻ Loading…'; }

  try {
    const res  = await fetch('/api/status');
    const data = await res.json();
    renderStatusCards(data);
  } catch (e) {
    setHTML('status-cards', `<div class="stat-card" style="color:var(--danger)">⚠️ Failed to load status</div>`);
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = '↻ Refresh'; }
  }
}

function renderStatusCards(data) {
  const cards = [
    { icon: '⚡', label: 'Status',         value: data.status?.toUpperCase() || '—',  sub: data.app || '' },
    { icon: '🐍', label: 'Python Version', value: data.python_version || '—',          sub: data.platform || '' },
    { icon: '⏱️', label: 'Uptime',         value: data.uptime || '—',                 sub: 'since last restart' },
    { icon: '📊', label: 'Total Requests', value: data.total_requests ?? '—',          sub: 'v' + (data.version || '?') },
  ];

  const html = cards.map((c, i) => `
    <div class="stat-card" style="animation-delay:${i * 0.07}s">
      <div class="stat-icon">${c.icon}</div>
      <div class="stat-label">${c.label}</div>
      <div class="stat-value">${c.value}</div>
      <div class="stat-sub">${c.sub}</div>
    </div>
  `).join('');

  setHTML('status-cards', html);
}

// ── Greet API ──────────────────────────────────────────

async function doGreet() {
  const input = document.getElementById('greet-input');
  const name  = input?.value.trim();

  if (!name) {
    input?.focus();
    showResult('greet-result', '⚠️ Please enter a name first!', true);
    return;
  }

  const btn = document.getElementById('greet-btn');
  if (btn) { btn.disabled = true; btn.textContent = '⏳'; }

  try {
    const res  = await fetch(`/api/greet/${encodeURIComponent(name)}`);
    const data = await res.json();
    showResult('greet-result', data.message || JSON.stringify(data, null, 2));
  } catch {
    showResult('greet-result', '⚠️ Network error — is the server running?', true);
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = 'Greet 👋'; }
  }
}

// Enter key support for greet
document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('greet-input')?.addEventListener('keydown', e => {
    if (e.key === 'Enter') doGreet();
  });
});

// ── Calculator API ─────────────────────────────────────

async function doCalc() {
  const a   = document.getElementById('calc-a')?.value;
  const b   = document.getElementById('calc-b')?.value;
  const op  = document.getElementById('calc-op')?.value;
  const btn = document.getElementById('calc-btn');

  if (a === '' || b === '') {
    showResult('calc-result', '⚠️ Please enter both values.', true);
    return;
  }

  if (btn) { btn.disabled = true; btn.textContent = '⏳ Calculating…'; }

  try {
    const res  = await fetch('/api/calculate', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify({ a: parseFloat(a), b: parseFloat(b), operation: op }),
    });
    const data = await res.json();

    if (data.error) {
      showResult('calc-result', `⚠️ ${data.error}`, true);
    } else {
      showResult('calc-result', `${data.expression}`);
    }
  } catch {
    showResult('calc-result', '⚠️ Network error.', true);
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = 'Calculate'; }
  }
}

// ── Pipeline Simulator ─────────────────────────────────

async function runPipeline() {
  const branch    = document.getElementById('pipe-branch')?.value || 'main';
  const failPct   = parseInt(document.getElementById('pipe-fail')?.value || '10', 10);
  const btn       = document.getElementById('pipe-btn');
  const container = document.getElementById('pipeline-result');

  if (btn) { btn.disabled = true; btn.textContent = '⏳ Running…'; }
  if (container) { container.classList.add('hidden'); container.innerHTML = ''; }

  try {
    const res  = await fetch('/api/pipeline/run', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify({ branch, fail_chance: failPct / 100 }),
    });
    const data = await res.json();
    await renderPipeline(data, container);
  } catch {
    if (container) {
      container.classList.remove('hidden');
      container.innerHTML = `<div style="color:var(--danger);padding:1rem">⚠️ Network error — is the server running?</div>`;
    }
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = '▶ Run Pipeline'; }
  }
}

async function renderPipeline(data, container) {
  if (!container) return;
  container.classList.remove('hidden');
  container.innerHTML = '';

  // Animate stages one by one
  for (const stage of data.stages) {
    await sleep(120);

    const statusClass = `badge-${stage.status}`;
    const durText     = stage.status !== 'skipped'
      ? `${stage.duration_s}s`
      : '—';

    const row = document.createElement('div');
    row.className = 'stage-row';
    row.style.opacity = '0';
    row.style.transform = 'translateX(-12px)';
    row.innerHTML = `
      <span class="stage-icon">${stage.icon}</span>
      <span class="stage-name">${stage.name}</span>
      <span class="stage-dur">${durText}</span>
      <span class="stage-badge ${statusClass}">${stage.status}</span>
    `;
    container.appendChild(row);

    // Trigger animation
    requestAnimationFrame(() => {
      row.style.transition = 'opacity .25s ease, transform .25s ease';
      row.style.opacity = '1';
      row.style.transform = 'translateX(0)';
    });
  }

  // Summary
  await sleep(150);
  const isPass     = data.overall_status === 'passed';
  const summaryEl  = document.createElement('div');
  summaryEl.className = `pipeline-summary ${isPass ? 'summary-passed' : 'summary-failed'}`;
  summaryEl.innerHTML = `
    <div class="summary-item">
      <span class="summary-key">Overall</span>
      <span class="summary-val" style="color:${isPass ? 'var(--success)' : 'var(--danger)'}">
        ${isPass ? '✅ PASSED' : '❌ FAILED'}
      </span>
    </div>
    <div class="summary-item">
      <span class="summary-key">Run ID</span>
      <span class="summary-val">${data.run_id}</span>
    </div>
    <div class="summary-item">
      <span class="summary-key">Branch</span>
      <span class="summary-val">${data.branch}</span>
    </div>
    <div class="summary-item">
      <span class="summary-key">Total Time</span>
      <span class="summary-val">${data.total_time_s}s</span>
    </div>
  `;
  container.appendChild(summaryEl);
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// ── Init ───────────────────────────────────────────────

window.addEventListener('DOMContentLoaded', () => {
  checkHealth();
  loadStatus();

  // Re-check health every 30 seconds
  setInterval(checkHealth, 30_000);

  // Scroll-spy: highlight nav on scroll
  const sections = document.querySelectorAll('section[id]');
  const navLinks  = document.querySelectorAll('.nav-link');

  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        navLinks.forEach(link => {
          link.style.color = link.getAttribute('href') === `#${entry.target.id}`
            ? 'var(--text)'
            : '';
        });
      }
    });
  }, { threshold: 0.4 });

  sections.forEach(s => observer.observe(s));

  // Navbar shrink on scroll
  window.addEventListener('scroll', () => {
    document.getElementById('navbar')?.classList.toggle('scrolled', window.scrollY > 40);
  }, { passive: true });
});
