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

// Attempt to update a configuration value through AHK
async function updateConfigValue(key, value) {
  try {
    if (window.ahk?.global?.UpdateConfig) {
      return await window.ahk.global.UpdateConfig(key, String(value));
    }
    return false;
  } catch (e) {
    console.error('Failed to update config:', e);
    return false;
  }
}

// Configuration items now reduced to a single option.
// Boolean option rendered as a checkbox (Bootstrap switch style).
const CONFIG_ITEMS = [
  {
    key: 'OpenDevToolsAtStartup',
    label: 'Open dev tools at startup',
    // Prefer dedicated getter function (more reliable across bridges), fallback to raw var
    src: () =>
      readValue('ahk.global.GetOpenDevToolsAtStartup') ??
      readValue('ahk.global.OpenDevToolsAtStartup'),
    editable: true,
    type: 'boolean',
  },
];

export function renderConfigInto(container) {
  if (!container) return;
  container.innerHTML = '';

  // Store edited values for save operation
  if (!window._configEdits) window._configEdits = {};

  CONFIG_ITEMS.forEach(item => {
    let value;
    let raw;
    try {
      raw = item.src();
      if (typeof raw === 'function') {
        raw = raw(); // attempt invoke
      }
    } catch (e) {
      raw = undefined;
    }

    const row = document.createElement('div');
    row.className = 'd-flex flex-column mb-3';
    row.dataset.configKey = item.key;

    const labelRow = document.createElement('div');
    labelRow.className = 'd-flex justify-content-between align-items-center';

    const label = document.createElement('div');
    label.className = 'fw-semibold mono-dim';
    label.textContent = item.label;
    labelRow.appendChild(label);

    row.appendChild(labelRow);

    let input; // reference used later

    if (item.type === 'boolean') {
      // Use a form-switch for boolean
      const formCheck = document.createElement('div');
      formCheck.className = 'form-check form-switch mt-1';
      input = document.createElement('input');
      input.type = 'checkbox';
      input.className = 'form-check-input';
      input.id = `cfg-${item.key}`;
      input.disabled = !item.editable;
      const switchLabel = document.createElement('label');
      switchLabel.className = 'form-check-label small';
      switchLabel.setAttribute('for', input.id);
      switchLabel.textContent = 'Enabled';
      formCheck.appendChild(input);
      formCheck.appendChild(switchLabel);
      row.appendChild(formCheck);
    } else {
      // Fallback (not currently used) - keeps previous behavior
      const inputGroup = document.createElement('div');
      inputGroup.className = 'input-group input-group-sm mt-1';
      input = document.createElement('input');
      input.type = item.type || 'text';
      input.className = 'form-control form-control-sm mono';
      input.placeholder = `Enter ${item.label}...`;
      input.dataset.originalValue = '';
      input.disabled = !item.editable;
      inputGroup.appendChild(input);
      row.appendChild(inputGroup);
    }

    // Status indicator for changes
    const statusRow = document.createElement('div');
    statusRow.className = 'mt-1 d-flex justify-content-end';

    const status = document.createElement('small');
    status.className = 'text-muted';
    status.style.display = 'none';
    statusRow.appendChild(status);
    row.appendChild(statusRow);

    // Track changes
    input.addEventListener('change', () => {
      const currentValue =
        item.type === 'boolean' ? String(input.checked) : input.value;
      if (currentValue !== input.dataset.originalValue) {
        status.textContent = 'Changed - needs saving';
        status.className = 'text-warning';
        status.style.display = 'block';
        window._configEdits[item.key] = currentValue;
      } else {
        status.style.display = 'none';
        delete window._configEdits[item.key];
      }
      updateSaveButtonState();
    });

    container.appendChild(row);

    function assign(finalVal) {
      value = finalVal;
      if (item.type === 'boolean') {
        const boolVal = !!(
          value === true ||
          value === 'true' ||
          value === 1 ||
          value === '1'
        );
        input.checked = boolVal;
        input.dataset.originalValue = String(boolVal);
        input.title = boolVal ? 'Enabled' : 'Disabled';
      } else {
        const text = value == null || value === '' ? '' : String(value);
        input.value = text;
        input.dataset.originalValue = text;
        input.title = text;
      }
    }

    if (raw && typeof raw.then === 'function') {
      raw.then(r => assign(r)).catch(() => assign(undefined));
    } else {
      assign(raw);
    }

    // If the value was undefined (likely because the AHK bridge hadn't yet populated
    // globals when this script ran), schedule a single retry shortly after. This helps
    // the UI reflect values loaded very early on the AHK side (e.g., from config.ini)
    // without requiring a manual refresh.
    if (raw === undefined) {
      setTimeout(() => {
        try {
          const later = item.src();
          if (later === undefined) return; // still nothing
          if (later && typeof later.then === 'function') {
            later.then(v => assign(v)).catch(() => {});
          } else {
            assign(later);
          }
        } catch {
          /* ignore */
        }
      }, 300);
    }
  });
}

// Updates save button state based on whether changes exist
function updateSaveButtonState() {
  const saveBtn = document.querySelector('#btn-save-config');
  if (!saveBtn) return;

  const hasChanges =
    window._configEdits && Object.keys(window._configEdits).length > 0;

  if (hasChanges) {
    saveBtn.classList.remove('btn-outline-success');
    saveBtn.classList.add('btn-success');
    saveBtn.disabled = false;
  } else {
    saveBtn.classList.add('btn-outline-success');
    saveBtn.classList.remove('btn-success');
    saveBtn.disabled = true;
  }
}

// Save changes to configuration
async function saveConfig() {
  const saveBtn = document.querySelector('#btn-save-config');
  const changes = window._configEdits || {};
  const keys = Object.keys(changes);

  if (keys.length === 0) return;

  // Show saving state
  const origText = saveBtn.innerHTML;
  saveBtn.innerHTML =
    '<i class="fa-solid fa-spinner fa-spin me-1"></i> Saving...';
  saveBtn.disabled = true;

  try {
    // Always perform per-key updates (bulk path caused COM enumeration issues)
    let allSuccess = true;
    for (const key of keys) {
      const value = changes[key];
      const success = await updateConfigValue(key, value);
      if (!success) {
        allSuccess = false;
        console.error(`Failed to update ${key}`);
      }
    }
    showToast(
      allSuccess ? 'Configuration saved!' : 'Some settings failed to save'
    );

    // Clear changes and refresh
    window._configEdits = {};
    updateSaveButtonState();
    renderConfigInto(document.querySelector('#config-list'));
  } catch (e) {
    console.error('Save failed:', e);
    showToast('Error saving configuration');
  } finally {
    saveBtn.innerHTML = origText;
    saveBtn.disabled = false;
  }
}

// Create and show a toast message
function showToast(message, type = 'success') {
  // Check if toast container exists, create if not
  let toastContainer = document.querySelector('.toast-container');
  if (!toastContainer) {
    toastContainer = document.createElement('div');
    toastContainer.className =
      'toast-container position-fixed bottom-0 end-0 p-3';
    document.body.appendChild(toastContainer);
  }

  const toast = document.createElement('div');
  toast.className = `toast align-items-center text-white bg-${type} border-0`;
  toast.setAttribute('role', 'alert');
  toast.setAttribute('aria-live', 'assertive');
  toast.setAttribute('aria-atomic', 'true');

  const toastContent = document.createElement('div');
  toastContent.className = 'd-flex';

  const toastBody = document.createElement('div');
  toastBody.className = 'toast-body';
  toastBody.textContent = message;

  const closeBtn = document.createElement('button');
  closeBtn.type = 'button';
  closeBtn.className = 'btn-close btn-close-white me-2 m-auto';
  closeBtn.setAttribute('data-bs-dismiss', 'toast');
  closeBtn.setAttribute('aria-label', 'Close');

  toastContent.appendChild(toastBody);
  toastContent.appendChild(closeBtn);
  toast.appendChild(toastContent);
  toastContainer.appendChild(toast);

  // Use Bootstrap's toast API
  const bsToast = new bootstrap.Toast(toast);
  bsToast.show();

  // Auto-remove after shown
  toast.addEventListener('hidden.bs.toast', () => {
    toast.remove();
  });
}

export function initStandaloneConfigPage() {
  const list = document.querySelector('#config-list');
  const btnRefresh = document.querySelector('#btn-refresh-config');
  const btnSave = document.querySelector('#btn-save-config');
  // Inject a small diagnostics footer
  let diag = document.getElementById('config-diagnostics');
  if (!diag) {
    diag = document.createElement('div');
    diag.id = 'config-diagnostics';
    diag.className = 'mt-3 small text-muted';
    diag.innerHTML =
      '<div><strong>Diagnostics:</strong> <span id="cfg-diag-open"></span></div>' +
      '<div class="mt-1">(If blank/?? then window.ahk.global not ready when rendered)</div>';
    list?.parentElement?.appendChild(diag);
  }

  function updateDiagnostics() {
    const span = document.getElementById('cfg-diag-open');
    if (!span) return;
    let val = undefined;
    try {
      let getter = readValue('ahk.global.GetOpenDevToolsAtStartup');
      if (typeof getter === 'function') {
        try {
          val = getter();
        } catch (e) {
          // some bridges require async call pattern
          val = undefined;
        }
      }
      if (val === undefined) {
        val = readValue('ahk.global.OpenDevToolsAtStartup');
      }
      if (val && typeof val.then === 'function') {
        // async promise
        val
          .then(r => {
            span.textContent = 'OpenDevToolsAtStartup=' + JSON.stringify(r);
          })
          .catch(() => {
            span.textContent = 'OpenDevToolsAtStartup=?';
          });
        return;
      }
    } catch {
      val = undefined;
    }
    let display;
    if (val === undefined) display = '??';
    else if (val === true || val === false) display = val ? 'true' : 'false';
    else display = JSON.stringify(val);
    span.textContent = 'OpenDevToolsAtStartup=' + display;
  }

  // Initialize refresh button
  btnRefresh?.addEventListener('click', () => renderConfigInto(list));

  // Initialize save button
  btnSave?.addEventListener('click', saveConfig);

  // Initial render
  renderConfigInto(list);
  updateDiagnostics();

  // Initial button state
  window._configEdits = {};
  updateSaveButtonState();

  // Expose for AHK
  window.refreshConfigFromAhk = () => renderConfigInto(list);
  // Periodic diag update for first second
  let attempts = 0;
  const iv = setInterval(() => {
    attempts++;
    updateDiagnostics();
    if (attempts > 8) clearInterval(iv);
  }, 150);
}
