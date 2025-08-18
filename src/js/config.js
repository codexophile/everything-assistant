// Configuration section renderer
// Assumes certain AHK globals or callable functions are exposed. We try to read
// them defensively; if not present we show placeholders.
function readValue(path) {
  try {
    const parts = path.split('.');
    let ctx = window;
    for (const p of parts) {
      if (ctx == null) return undefined;
      ctx = ctx[p];
    }
    return ctx;
  } catch {
    return undefined;
  }
}

// Map config labels to either ahk.global.* variables or functions
const CONFIG_ITEMS = [
  { key: 'EverythingWindowTitle', label: 'Everything Window', src: () => readValue('ahk.global.EverythingWindowTitle') },
  { key: 'AssistantWindowTitle', label: 'Assistant Window', src: () => readValue('ahk.global.AssistantWindowTitle') },
  { key: 'MainWidth', label: 'Main Width', src: () => readValue('ahk.global.MainWidth') },
  { key: 'FileTaggerPath', label: 'File Tagger Path', src: () => readValue('ahk.global.FileTaggerPath') },
  { key: 'ElectronSubPath', label: 'Electron SubPath', src: () => readValue('ahk.global.ElectronSubPath') },
  { key: 'AvidemuxPath', label: 'Avidemux Path', src: () => readValue('ahk.global.AvidemuxPath') },
];

export function renderConfigInto(container) {
  if (!container) return;
  container.innerHTML = '';
  CONFIG_ITEMS.forEach(item => {
    const value = item.src();
    const row = document.createElement('div');
    row.className = 'd-flex flex-column';
    const label = document.createElement('div');
    label.className = 'fw-semibold mono-dim';
    label.textContent = item.label;
    const val = document.createElement('div');
    val.className = 'truncate-1';
    val.textContent = value == null || value === '' ? '(not set)' : String(value);
    val.title = val.textContent;
    row.appendChild(label);
    row.appendChild(val);
    container.appendChild(row);
  });
}

export function initStandaloneConfigPage() {
  const list = document.querySelector('#config-list');
  const btnRefresh = document.querySelector('#btn-refresh-config');
  btnRefresh?.addEventListener('click', () => renderConfigInto(list));
  renderConfigInto(list);
  // Expose for AHK
  window.refreshConfigFromAhk = () => renderConfigInto(list);
}
