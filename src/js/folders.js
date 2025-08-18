import { els } from './dom.js';
import { setIcon } from './icons.js';

function setExcludedStyle(btn, excluded) {
  if (excluded) {
    btn.classList.remove('btn-outline-danger');
    btn.classList.add('btn-danger');
  } else {
    btn.classList.add('btn-outline-danger');
    btn.classList.remove('btn-danger');
  }
}
async function isExcluded(folder) {
  const curr = await ahk.getControlText('Edit1', 'ahk_class EVERYTHING_(1.5a)');
  const excl = `!"${folder}"`;
  return !!curr && curr.includes(excl);
}

export async function renderFolderButtons(items) {
  if (!items?.length) {
    els.actions.innerHTML =
      '<div class="alert alert-info">No folder actions available</div>';
    // NOTE: Do not clear els.secondary here; it now hosts global query buttons (Exclude Folders / Clean Query)
    return;
  }

  const fileName = await ahk.global.SelectedFileName;
  els.actions.innerHTML = '';
  // Do NOT wipe els.secondary anymore; it's reserved for global secondary toolbar buttons.

  // Create a container for folders
  const list = document.createElement('div');
  list.className = 'd-flex flex-column gap-2';

  items.forEach(folder => {
    const row = document.createElement('div');
    row.className = 'folder-row';
    row.dataset.path = folder;

    const folderLabel = document.createElement('span');
    folderLabel.className = 'folder-item mono';
    folderLabel.textContent = folder;
    folderLabel.dataset.path = folder;
    folderLabel.addEventListener('click', e => {
      const prev = list.querySelector('.folder-item.selected');
      const existingToolbar = list.querySelector('.folder-toolbar-row');
      const isSame = prev === folderLabel;

      if (prev) prev.classList.remove('selected');
      if (existingToolbar) existingToolbar.remove();
      if (isSame) return; // deselect

      folderLabel.classList.add('selected');
      renderFolderToolbar(row, folder, fileName, list);
    });

    row.appendChild(folderLabel);
    list.appendChild(row);
  });

  // Place the list inside a container in file-actions div
  const actionsContainer =
    els.actions.querySelector('.file-actions-container') || els.actions;
  actionsContainer.appendChild(list);
}

async function renderFolderToolbar(row, folder, fileName, list) {
  const toolbar = document.createElement('div');
  toolbar.className = 'folder-toolbar-row';

  const lbl = document.createElement('div');
  lbl.className = 'mono-dim mb-2';
  lbl.textContent = `Folder: ${folder}`;

  const group = document.createElement('div');
  group.className = 'd-flex flex-wrap gap-2 align-items-center';

  const btnExclude = document.createElement('button');
  btnExclude.className = 'icon-btn btn btn-sm btn-outline-danger';
  btnExclude.title = `Toggle exclusion for ${folder}`;
  btnExclude.innerHTML = '<i class="fa-solid fa-ban me-1"></i> Exclude';

  (async () => setExcludedStyle(btnExclude, await isExcluded(folder)))();
  btnExclude.addEventListener('click', async () => {
    await ahk.global.ToggleExcludeFolder(folder);
    setExcludedStyle(btnExclude, await isExcluded(folder));
  });

  const btnOnly = document.createElement('button');
  btnOnly.className = 'icon-btn btn btn-sm btn-outline-primary';
  btnOnly.title = `Toggle search only in ${folder}`;
  btnOnly.innerHTML = '<i class="fa-solid fa-search me-1"></i> Search Only';
  btnOnly.dataset.active = 'false';

  function setOnlyStyleActive(active) {
    if (active) {
      btnOnly.classList.remove('btn-outline-primary');
      btnOnly.classList.add('btn-primary');
    } else {
      btnOnly.classList.add('btn-outline-primary');
      btnOnly.classList.remove('btn-primary');
    }
  }

  btnOnly.addEventListener('click', async () => {
    const isActive = btnOnly.dataset.active === 'true';
    btnOnly.dataset.active = (!isActive).toString();
    setOnlyStyleActive(!isActive);
    if (!isActive) {
      await ahk.global.SetSearchOnlyFolder?.(folder);
    } else {
      await ahk.global.ClearSearchOnlyFolder?.();
    }
  });
  setOnlyStyleActive(false);

  const btnPwsh = document.createElement('button');
  btnPwsh.className = 'icon-btn btn btn-sm btn-outline-secondary';
  btnPwsh.title = `Open PowerShell in ${folder}`;
  btnPwsh.innerHTML = '<i class="fa-solid fa-terminal me-1"></i> PowerShell';
  btnPwsh.addEventListener('click', async () => {
    try {
      if (window.ahk?.global?.OpenPwsh) {
        await ahk.global.OpenPwsh(folder, fileName);
      } else {
        window.open(`file://${encodeURIComponent(folder)}`);
      }
    } catch (e) {
      console.error('OpenPwsh failed', e);
    }
  });

  const btnOpen = document.createElement('button');
  btnOpen.className = 'icon-btn btn btn-sm btn-outline-secondary';
  btnOpen.title = `Open ${folder} in Explorer`;
  btnOpen.innerHTML = '<i class="fa-solid fa-folder-open me-1"></i> Explorer';
  btnOpen.addEventListener('click', async () => {
    try {
      if (window.ahk?.global?.OpenFolder) {
        await ahk.global.OpenFolder(folder);
      } else if (window.ahk?.global?.OpenPwsh) {
        await ahk.global.OpenPwsh(folder, fileName);
      } else {
        window.open(`file://${encodeURIComponent(folder)}`);
      }
    } catch (e) {
      console.error('Open folder failed', e);
    }
  });

  const btnOpenParentSelect = document.createElement('button');
  btnOpenParentSelect.className = 'icon-btn btn btn-sm btn-outline-secondary';
  btnOpenParentSelect.title = `Open parent folder and select ${folder}`;
  btnOpenParentSelect.innerHTML =
    '<i class="fa-solid fa-file-arrow-up me-1"></i> Parent';
  btnOpenParentSelect.addEventListener('click', async () => {
    try {
      if (window.ahk?.global?.OpenExplorerSelect) {
        await ahk.global.OpenExplorerSelect(folder);
      } else if (window.ahk?.global?.OpenFolder) {
        const parent = folder.replace(/\\[^\\]+$/, '');
        await ahk.global.OpenFolder(parent);
      } else {
        const parent = folder.replace(/\\[^\\]+$/, '');
        window.open(`file://${encodeURIComponent(parent)}`);
      }
    } catch (e) {
      console.error('Open parent select failed', e);
    }
  });

  const nodes = [btnExclude, btnOnly, btnPwsh, btnOpen, btnOpenParentSelect];
  nodes.forEach(n => group.appendChild(n));

  toolbar.appendChild(lbl);
  toolbar.appendChild(group);
  row.after(toolbar);

  const other = list.querySelectorAll('.folder-toolbar-row');
  if (other.length > 1)
    other.forEach((el, idx) => {
      if (idx < other.length - 1) el.remove();
    });
}
