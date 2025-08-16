import { els } from './dom.js';
import { setIcon } from './icons.js';

function setExcludedStyle(btn, excluded) {
  btn.classList.toggle('excluded', !!excluded);
}

async function isExcluded(folder) {
  const curr = await ahk.getControlText('Edit1', 'ahk_class EVERYTHING_(1.5a)');
  const excl = `!"${folder}"`;
  return !!curr && curr.includes(excl);
}

export async function renderFolderButtons(items) {
  // If no folders, clear any actions and secondary toolbar
  if (!items?.length) {
    els.actions.innerHTML = '';
    els.secondary.innerHTML = '';
    return;
  }

  const fileName = await ahk.global.SelectedFileName;
  els.actions.innerHTML = '';
  els.secondary.innerHTML = '';

  const list = document.createElement('div');
  list.style.display = 'flex';
  list.style.flexDirection = 'column';
  list.style.gap = '6px';

  items.forEach(folder => {
    const row = document.createElement('div');
    row.className = 'folder-row';
    row.dataset.path = folder;
    row.style.display = 'flex';
    row.style.alignItems = 'center';
    row.style.gap = '8px';

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
      if (isSame) {
        // deselect -> toolbar removed above
        return;
      }
      // select new
      folderLabel.classList.add('selected');
      renderFolderToolbar(row, folder, fileName, list);
    });

    row.appendChild(folderLabel);
    list.appendChild(row);
  });

  els.actions.appendChild(list);
}

async function renderFolderToolbar(row, folder, fileName, list) {
  // create a toolbar row inserted after the clicked folder row
  const toolbar = document.createElement('div');
  toolbar.className = 'folder-toolbar-row';
  toolbar.style.display = 'flex';
  toolbar.style.flexDirection = 'column';
  toolbar.style.gap = '6px';

  const lbl = document.createElement('div');
  lbl.className = 'mono-dim';
  lbl.textContent = `Folder: ${folder}`;

  const group = document.createElement('div');
  group.style.display = 'flex';
  group.style.gap = '6px';
  group.style.alignItems = 'center';

  const btnExclude = document.createElement('button');
  btnExclude.className = 'icon-btn';
  setIcon(btnExclude, 'ban', `Toggle exclusion for ${folder}`);
  (async () => setExcludedStyle(btnExclude, await isExcluded(folder)))();
  btnExclude.addEventListener('click', async () => {
    await ahk.global.ToggleExcludeFolder(folder);
    setExcludedStyle(btnExclude, await isExcluded(folder));
  });

  const btnOnly = document.createElement('button');
  btnOnly.className = 'icon-btn';
  setIcon(btnOnly, 'search', `Toggle search only in ${folder}`);
  btnOnly.dataset.active = 'false';
  function setOnlyStyleActive(active) {
    btnOnly.style.background = active ? '#dfd' : '';
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
  btnPwsh.className = 'icon-btn';
  setIcon(btnPwsh, 'pwsh', `Open PowerShell in ${folder}`);
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

  group.appendChild(btnExclude);
  group.appendChild(btnOnly);
  group.appendChild(btnPwsh);

  toolbar.appendChild(lbl);
  toolbar.appendChild(group);

  // insert after the folder row
  row.after(toolbar);

  // ensure only one toolbar exists at a time
  const other = list.querySelectorAll('.folder-toolbar-row');
  if (other.length > 1) {
    other.forEach((el, idx) => {
      if (idx < other.length - 1) el.remove();
    });
  }
}
