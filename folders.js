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
  if (!items?.length) {
    els.actions.innerHTML = '';
    return;
  }
  const fileName = await ahk.global.SelectedFileName;
  els.actions.innerHTML = '';
  const btns = document.createElement('div');
  btns.style.display = 'flex';
  btns.style.flexDirection = 'column';
  btns.style.gap = '2px';
  items.forEach(folder => {
    const row = document.createElement('div');
    row.style.display = 'flex';
    row.style.alignItems = 'center';
    row.style.gap = '8px';

    const folderLabel = document.createElement('span');
    folderLabel.className = 'mono';
    folderLabel.textContent = folder;
    row.appendChild(folderLabel);

    const btnGroup = document.createElement('span');
    btnGroup.style.display = 'flex';
    btnGroup.style.gap = '4px';

    const btnExclude = document.createElement('button');
    btnExclude.className = 'folder-btn';
    setIcon(btnExclude, 'ban', `Toggle exclusion for ${folder}`);
    (async () => setExcludedStyle(btnExclude, await isExcluded(folder)))();
    btnExclude.addEventListener('click', async () => {
      await ahk.global.ToggleExcludeFolder(folder);
      setExcludedStyle(btnExclude, await isExcluded(folder));
    });

    const btnOnly = document.createElement('button');
    btnOnly.className = 'folder-btn only';
    setIcon(btnOnly, 'search', `Toggle search only in ${folder}`);
    btnOnly.dataset.active = 'false';
    function setOnlyStyle(active) {
      btnOnly.style.background = active ? '#dfd' : '';
    }
    btnOnly.addEventListener('click', async () => {
      const isActive = btnOnly.dataset.active === 'true';
      btnOnly.dataset.active = (!isActive).toString();
      setOnlyStyle(!isActive);
      if (!isActive) {
        await ahk.global.SetSearchOnlyFolder?.(folder);
      } else {
        await ahk.global.ClearSearchOnlyFolder?.();
      }
    });
    setOnlyStyle(false);

    const btnPwsh = document.createElement('button');
    btnPwsh.className = 'folder-btn pwsh';
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

    btnGroup.appendChild(btnExclude);
    btnGroup.appendChild(btnOnly);
    btnGroup.appendChild(btnPwsh);
    row.appendChild(btnGroup);
    btns.appendChild(row);
  });
  els.actions.appendChild(btns);
}
