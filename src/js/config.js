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

// Map config labels to either ahk.global.* variables or functions
const CONFIG_ITEMS = [
  {
    key: 'EverythingWindowTitle',
    label: 'Everything Window',
    src: () => readValue('ahk.global.EverythingWindowTitle'),
    editable: true,
    type: 'text',
  },
  {
    key: 'AssistantWindowTitle',
    label: 'Assistant Window',
    src: () => readValue('ahk.global.AssistantWindowTitle'),
    editable: true,
    type: 'text',
  },
  {
    key: 'MainWidth',
    label: 'Main Width',
    src: () => readValue('ahk.global.MainWidth'),
    editable: true,
    type: 'number',
  },
  {
    key: 'FileTaggerPath',
    label: 'File Tagger Path',
    src: () => readValue('ahk.global.FileTaggerPath'),
    editable: true,
    type: 'file',
  },
  {
    key: 'ElectronSubPath',
    label: 'Electron SubPath',
    src: () => readValue('ahk.global.ElectronSubPath'),
    editable: true,
    type: 'text',
  },
  {
    key: 'AvidemuxPath',
    label: 'Avidemux Path',
    src: () => readValue('ahk.global.AvidemuxPath'),
    editable: true,
    type: 'file',
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

    // Create input element for editable fields
    const inputGroup = document.createElement('div');
    inputGroup.className = 'input-group input-group-sm mt-1';

    const input = document.createElement('input');
    input.type = item.type || 'text';
    input.className = 'form-control form-control-sm mono';
    input.placeholder = `Enter ${item.label}...`;
    input.dataset.originalValue = '';
    input.disabled = !item.editable;

    if (item.type === 'file') {
      const browseBtn = document.createElement('button');
      browseBtn.className = 'btn btn-outline-secondary';
      browseBtn.type = 'button';
      browseBtn.innerHTML = '<i class="fa-solid fa-folder-open"></i>';
      browseBtn.title = `Browse for ${item.label}`;
      browseBtn.onclick = async () => {
        try {
          // This assumes we have a method in AHK to open a file dialog
          if (window.ahk?.global?.BrowseForFile) {
            const path = await window.ahk.global.BrowseForFile();
            if (path) {
              input.value = path;
              input.dispatchEvent(new Event('change'));
            }
          }
        } catch (e) {
          console.error('Browse failed:', e);
        }
      };
      inputGroup.appendChild(browseBtn);
    }

    inputGroup.appendChild(input);
    row.appendChild(inputGroup);

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
      if (input.value !== input.dataset.originalValue) {
        status.textContent = 'Changed - needs saving';
        status.className = 'text-warning';
        status.style.display = 'block';
        window._configEdits[item.key] = input.value;
      } else {
        status.style.display = 'none';
        delete window._configEdits[item.key];
      }

      // Update save button state
      updateSaveButtonState();
    });

    container.appendChild(row);

    function assign(finalVal) {
      value = finalVal;
      const text = value == null || value === '' ? '' : String(value);
      input.value = text;
      input.dataset.originalValue = text;
      input.title = text;
    }

    if (raw && typeof raw.then === 'function') {
      raw.then(r => assign(r)).catch(() => assign(undefined));
    } else {
      assign(raw);
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
    // Check if we have a bulk update method or need to call individually
    if (window.ahk?.global?.UpdateConfigBulk) {
      const result = await window.ahk.global.UpdateConfigBulk(
        JSON.stringify(changes)
      );
      showToast(
        result ? 'Configuration saved!' : 'Failed to save configuration'
      );
    } else {
      // Fall back to individual updates
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
    }

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

  // Initialize refresh button
  btnRefresh?.addEventListener('click', () => renderConfigInto(list));

  // Initialize save button
  btnSave?.addEventListener('click', saveConfig);

  // Initial render
  renderConfigInto(list);

  // Initial button state
  window._configEdits = {};
  updateSaveButtonState();

  // Expose for AHK
  window.refreshConfigFromAhk = () => renderConfigInto(list);
}
