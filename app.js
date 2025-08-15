// script type="module" so we can use await
// Icon utilities: prefer Font Awesome if available, else inline SVG fallback
const Icon = (() => {
  // Add event listener for reload button
  window.addEventListener('DOMContentLoaded', () => {
    const reloadBtn = document.getElementById('btn-reload');
    if (reloadBtn) {
      reloadBtn.addEventListener('click', () => {
        window.ahk.global.reload();
      });
    }
  });
  let faLoaded = null;
  const hasFA = () => {
    if (faLoaded !== null) return faLoaded;
    try {
      const probe = document.createElement('i');
      probe.className = 'fa-solid fa-tag';
      probe.style.position = 'absolute';
      probe.style.left = '-9999px';
      document.body.appendChild(probe);
      const cs = getComputedStyle(probe, '::before');
      const content = cs && cs.content;
      faLoaded =
        !!content &&
        content !== 'none' &&
        content !== 'normal' &&
        content !== '""';
      probe.remove();
    } catch {
      faLoaded = false;
    }
    return faLoaded;
  };
  const svg = {
    trash:
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512" width="16" height="16" fill="currentColor"><path d="M160 400c0 8.8-7.2 16-16 16s-16-7.2-16-16V208c0-8.8 7.2-16 16-16s16 7.2 16 16V400zM240 416c8.8 0 16-7.2 16-16V208c0-8.8-7.2-16-16-16s-16 7.2-16 16V400c0 8.8 7.2 16 16 16zM336 400c0 8.8-7.2 16-16 16s-16-7.2-16-16V208c0-8.8 7.2-16 16-16s16 7.2 16 16V400zM432 80H312l-9.4-18.7C295.7 50.5 279.8 40 262.5 40h-77c-17.3 0-33.2 10.5-40.1 21.3L136 80H16C7.2 80 0 87.2 0 96s7.2 16 16 16H32l21.2 339.4C55.9 470.8 77.9 492 104.3 492h239.4c26.4 0 48.4-21.2 51.1-40.6L416 112h16c8.8 0 16-7.2 16-16s-7.2-16-16-16z"/></svg>',
    tag: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="16" height="16" fill="currentColor"><path d="M497.9 225.1L286.9 14.1C277.8 5 265.6 0 252.9 0H112C85.5 0 64 21.5 64 48v140.9c0 12.7 5 24.9 14.1 34l211 211c18.7 18.7 49.1 18.7 67.9 0l130.9-130.9c18.7-18.7 18.7-49.1 0-67.9zM112 96c-17.7 0-32 14.3-32 32s14.3 32 32 32s32-14.3 32-32s-14.3-32-32-32z"/></svg>',
    ban: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="16" height="16" fill="currentColor"><path d="M256 48C141.1 48 48 141.1 48 256s93.1 208 208 208s208-93.1 208-208S370.9 48 256 48zm130.5 93.5c15.3 15.3 27.5 33.1 36.1 52.5L194 422.6c-19.4-8.6-37.2-20.8-52.5-36.1s-27.5-33.1-36.1-52.5L389.9 141.5c19.4 8.6 37.2 20.8 52.6 36zM96 256c0-36.6 10.6-70.7 28.8-99.3L355.3 387.2C326.7 405.4 292.6 416 256 416 167.6 416 96 344.4 96 256z"/></svg>',
    search:
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="16" height="16" fill="currentColor"><path d="M416 208c0 45.9-14.9 88.3-40 122.7l86.6 86.6c12.5 12.5 12.5 32.8 0 45.3s-32.8 12.5-45.3 0l-86.6-86.6C296.3 401.1 253.9 416 208 416 93.1 416 0 322.9 0 208S93.1 0 208 0s208 93.1 208 208zM80 208c0 70.7 57.3 128 128 128s128-57.3 128-128S278.7 80 208 80 80 137.3 80 208z"/></svg>',
    folderMinus:
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="16" height="16" fill="currentColor"><path d="M464 128h-192l-64-64H48C21.5 64 0 85.5 0 112v288c0 26.5 21.5 48 48 48h416c26.5 0 48-21.5 48-48V176c0-26.5-21.5-48-48-48zM352 304H160c-8.8 0-16-7.2-16-16s7.2-16 16-16h192c8.8 0 16 7.2 16 16s-7.2 16-16 16z"/></svg>',
    avidemux:
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 576 512" width="16" height="16" fill="currentColor"><path d="M528 64H384l-48-56c-6.1-7.2-15.6-10.4-24.7-8.8L96 64C78.3 68.9 64 86.9 64 105.9V320c0 35.3 28.7 64 64 64h320c35.3 0 64-28.7 64-64V96c0-17-7.3-32.6-24-32zM96 176l64-40 48 40-64 40-48-40zm144 56l64-40 48 40-64 40-48-40zM512 352c0 35.3-28.7 64-64 64H96c-35.3 0-64-28.7-64-64v-16h64c35.3 0 64-28.7 64-64s28.7-64 64-64h128c35.3 0 64 28.7 64 64s28.7 64 64 64h64v16z"/></svg>',
    pwsh: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="16" height="16" fill="currentColor"><path d="M2 3h20v18H2V3zm2 2v14h16V5H4zm3.5 3 4.5 4-4.5 4V8z"/></svg>',
  };
  function setIcon(btn, name, title) {
    if (title) btn.title = title;
    if (hasFA()) {
      const map = {
        trash: 'fa-solid fa-trash',
        tag: 'fa-solid fa-tag',
        ban: 'fa-solid fa-ban',
        search: 'fa-solid fa-magnifying-glass',
        folderMinus: 'fa-solid fa-folder-minus',
        pwsh: 'fa-solid fa-terminal',
        avidemux: 'fa-solid fa-video',
      };
      const cls = map[name] || 'fa-solid fa-circle-question';
      btn.innerHTML = `<i class="${cls}"></i>`;
    } else {
      btn.innerHTML = svg[name] || svg.search;
    }
    btn.classList.add('icon-btn');
  }
  return { setIcon };
})();

// DOM refs
const els = {
  summary: document.querySelector('#sel-summary'),
  name: document.querySelector('#sel-name'),
  path: document.querySelector('#sel-path'),
  actions: document.querySelector('#file-actions'),
  secondary: document.querySelector('#secondary-toolbar'),
  btnDelete: document.querySelector('#btn-delete'),
  btnTag: document.querySelector('#btn-tag'),
  btnAvidemux: document.querySelector('#btn-avidemux'),
  tagsContainer: (() => {
    // create Tags section dynamically so we don't disturb layout too much
    const fileInfo = document.querySelector('#file-info');
    const wrap = document.createElement('div');
    wrap.id = 'tags-container';
    const label = document.createElement('div');
    label.className = 'mono-dim';
    label.textContent = 'Tags:';
    const tags = document.createElement('div');
    tags.id = 'tags';
    wrap.appendChild(label);
    wrap.appendChild(tags);
    fileInfo.after(wrap);
    return wrap;
  })(),
  tags: null,
};
els.tags = document.querySelector('#tags');
els.chaptersSection = document.querySelector('#chapters-section');
els.chaptersList = document.querySelector('#chapters-list');

// Helpers
const setExcludedStyle = (btn, excluded) => {
  btn.classList.toggle('excluded', !!excluded);
};

async function isExcluded(folder) {
  const curr = await ahk.getControlText('Edit1', 'ahk_class EVERYTHING_(1.5a)');
  // Everything exclusion syntax for a path: !"C:\\Path"
  const excl = `!"${folder}"`;
  return !!curr && curr.includes(excl);
}

async function renderFolderButtons(items) {
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

    // Folder path label
    const folderLabel = document.createElement('span');
    folderLabel.className = 'mono';
    folderLabel.textContent = folder;
    row.appendChild(folderLabel);

    // Buttons container
    const btnGroup = document.createElement('span');
    btnGroup.style.display = 'flex';
    btnGroup.style.gap = '4px';

    // Exclude button
    const btnExclude = document.createElement('button');
    btnExclude.className = 'folder-btn';
    Icon.setIcon(btnExclude, 'ban', `Toggle exclusion for ${folder}`);
    btnExclude.title = `Toggle exclusion for ${folder}`;
    (async () => setExcludedStyle(btnExclude, await isExcluded(folder)))();
    btnExclude.addEventListener('click', async () => {
      await ahk.global.ToggleExcludeFolder(folder);
      setExcludedStyle(btnExclude, await isExcluded(folder));
    });

    // Search-only button
    const btnOnly = document.createElement('button');
    btnOnly.className = 'folder-btn only';
    Icon.setIcon(btnOnly, 'search', `Toggle search only in ${folder}`);
    btnOnly.title = `Toggle search only in ${folder}`;
    btnOnly.dataset.active = 'false';
    function setOnlyStyle(active) {
      btnOnly.style.background = active ? '#dfd' : '';
    }
    btnOnly.addEventListener('click', async () => {
      const isActive = btnOnly.dataset.active === 'true';
      btnOnly.dataset.active = (!isActive).toString();
      setOnlyStyle(!isActive);
      if (!isActive) {
        if (window.ahk?.global?.SetSearchOnlyFolder) {
          await ahk.global.SetSearchOnlyFolder(folder);
        }
      } else {
        if (window.ahk?.global?.ClearSearchOnlyFolder) {
          await ahk.global.ClearSearchOnlyFolder(folder);
        }
      }
    });
    setOnlyStyle(false);

    btnGroup.appendChild(btnExclude);
    btnGroup.appendChild(btnOnly);
    // Open PowerShell button
    const btnPwsh = document.createElement('button');
    btnPwsh.className = 'folder-btn pwsh';
    Icon.setIcon(btnPwsh, 'pwsh', `Open PowerShell in ${folder}`);
    btnPwsh.title = `Open PowerShell in ${folder}`;
    btnPwsh.addEventListener('click', async () => {
      try {
        if (window.ahk?.global?.OpenPwsh) {
          await ahk.global.OpenPwsh(folder, fileName);
        } else {
          // Fallback: try to open via shell: will likely be ignored in WebView context
          window.open(`file://${encodeURIComponent(folder)}`);
        }
      } catch (e) {
        console.error('OpenPwsh failed', e);
      }
    });
    btnGroup.appendChild(btnPwsh);
    row.appendChild(btnGroup);
    btns.appendChild(row);
  });
  els.actions.appendChild(btns);
}

// Tag extraction and rendering
function extractTagsFromName(name) {
  if (!name) return [];
  const matches = [...name.matchAll(/\[(.+?)\]/g)];
  const tags = matches.map(match => match[1]);
  return tags;
}
function extractTagsFromNamesList(namesList) {
  const counts = new Map();
  for (const nm of namesList) {
    for (const t of extractTagsFromName(nm)) {
      counts.set(t, (counts.get(t) || 0) + 1);
    }
  }
  // Return unique tags sorted alphabetically
  const output = Array.from(counts.keys()).sort((a, b) => a.localeCompare(b));
  return output;
}
function renderTags(tags) {
  if (tags && tags.length) {
    els.tags.innerHTML = '';
    for (const t of tags) {
      const chip = document.createElement('span');
      chip.className = 'tag-chip';
      chip.textContent = t;
      chip.title = `Search for tag: ${t}`;
      chip.style.cursor = 'pointer';
      chip.addEventListener('click', () => {
        window.open(`es:${encodeURIComponent(`[${t}]`)}`, '_blank');
      });
      els.tags.appendChild(chip);
    }
    els.tagsContainer.style.display = '';
  } else {
    els.tags.innerHTML = '';
    els.tagsContainer.style.display = 'none';
  }
}

// Render current selection from AHK globals
async function renderSelection() {
  try {
    const [fileName, filePath, namesAll, countRaw, folderChain, chaptersJson] =
      await Promise.all([
        ahk.global.SelectedFileName,
        ahk.global.SelectedFilePath,
        ahk.global.SelectedNames,
        ahk.global.SelectedCount,
        ahk.global.SelectedFolderPaths,
        ahk.global.SelectedChaptersJson,
      ]);
    const count = Number(countRaw) || 0;
    if (count > 1) {
      els.summary.innerText = `${count} items selected`;
      els.name.style.display = '';
      els.name.innerText = (namesAll || '').split('\n').slice(0, 10).join('\n');
      els.path.innerText = '(multiple paths)';
      els.actions.innerHTML = '';
      const allNames = (namesAll || '').split('\n').filter(Boolean);
      renderTags(extractTagsFromNamesList(allNames));
      renderChapters(null);
      return;
    }
    if (count === 1 || (fileName && fileName.trim())) {
      els.summary.innerText = '1 item selected';
      els.name.style.display = '';
      els.name.innerText = fileName || '';
      els.path.innerText = filePath && filePath.trim() ? filePath : '(no path)';
      const items = folderChain ? folderChain.split('\n') : [];
      renderFolderButtons(items);
      renderTags(extractTagsFromNamesList([fileName || '']));
      renderChapters(chaptersJson);
      return;
    }
    // none selected
    els.summary.innerText = '(none)';
    els.name.style.display = 'none';
    els.name.innerText = '';
    els.path.innerText = '(no path)';
    els.actions.innerHTML = '';
    renderTags([]);
    renderChapters(null);
  } catch {
    /* ignore if globals not yet available */
  }
}

// Secondary toolbar: Exclude Folders toggle (!folder:)
const btnExclude = document.createElement('button');
btnExclude.id = 'btn-exclude-folders';
btnExclude.title = 'Exclude folders (!folder:)';
Icon.setIcon(btnExclude, 'folderMinus', 'Exclude folders (!folder:)');
els.secondary.appendChild(btnExclude);
btnExclude.addEventListener('click', async () => {
  try {
    await ahk.global.ExcludeFolders();
  } catch (e) {
    console.error('ExcludeFolders failed', e);
  }
});

// Secondary toolbar: Remove ampersands and commas from search query
const btnCleanQuery = document.createElement('button');
btnCleanQuery.id = 'btn-clean-query';
btnCleanQuery.title = 'Clean query';
Icon.setIcon(btnCleanQuery, 'ban', 'Clean query');
els.secondary.appendChild(btnCleanQuery);
btnCleanQuery.addEventListener('click', async () => {
  await ahk.global.CleanQuery();
});

// Delete button state and action
async function updateDeleteState() {
  try {
    const [countRaw, filePath] = await Promise.all([
      ahk.global.SelectedCount,
      ahk.global.SelectedFilePath,
    ]);
    const count = Number(countRaw) || 0;
    els.btnDelete.disabled = !(count > 0 || (filePath && filePath.trim()));
  } catch {
    /* ignore */
  }
}
els.btnDelete.addEventListener('click', async () => {
  try {
    await ahk.global.DeleteSelected();
  } catch (e) {
    console.error('DeleteSelected failed', e);
  }
});

// Tag button state and action
async function updateTagState() {
  try {
    const [countRaw, filePath] = await Promise.all([
      ahk.global.SelectedCount,
      ahk.global.SelectedFilePath,
    ]);
    const count = Number(countRaw) || 0;
    els.btnTag.disabled = !(count > 0 || (filePath && filePath.trim()));
  } catch {
    /* ignore */
  }
}
els.btnTag.addEventListener('click', async () => {
  try {
    const count = Number(await ahk.global.SelectedCount) || 0;
    if (count > 1) {
      const paths = await ahk.global.GetMultipleSelectedFilePaths();
      // Use existing AHK function to display a MsgBox
      await ahk.global.SendToFileTagger(paths || '');
    } else {
      const path = await ahk.global.GetSingleSelectedFilePath();
      await ahk.global.SendToFileTagger(path || '');
    }
  } catch (e) {
    console.error('Tag action failed', e);
  }
});

// Initial render and expose updater for AHK to call

// Initialize toolbar icons (works with FA or SVG fallback)
Icon.setIcon(els.btnDelete, 'trash', 'Delete selected files');
Icon.setIcon(els.btnTag, 'tag', 'Tag selected files');
Icon.setIcon(els.btnAvidemux, 'avidemux', 'Send to Avidemux');

// Enable/disable Avidemux button based on selection
async function updateAvidemuxState() {
  const count = Number(await ahk.global.SelectedCount) || 0;
  els.btnAvidemux.disabled = count !== 1;
}

// Handle click: send to Avidemux if single file selected
els.btnAvidemux.addEventListener('click', async () => {
  const count = Number(await ahk.global.SelectedCount) || 0;
  if (count !== 1) return;
  const path = await ahk.global.GetSingleSelectedFilePath();
  // You may want to call an AHK function to send to Avidemux
  if (window.ahk?.global?.SendToAvidemux) {
    await ahk.global.SendToAvidemux(path || '');
  } else {
    alert('SendToAvidemux function not implemented in AHK.');
  }
});

await renderSelection();
await updateDeleteState();
await updateTagState();
await updateAvidemuxState();
const oldUpdater = renderSelection;
window.updateSelectedFromAhk = async () => {
  await oldUpdater();
  await updateDeleteState();
  await updateTagState();
  await updateAvidemuxState();
};

// Chapters rendering
function renderChapters(chaptersJson) {
  if (!els.chaptersSection || !els.chaptersList) return;
  if (!chaptersJson) {
    els.chaptersSection.style.display = 'none';
    els.chaptersList.innerHTML = '';
    return;
  }
  let chapters = [];
  try {
    chapters = JSON.parse(chaptersJson);
  } catch (err) {
    console.log(err);
    chapters = [];
  }
  console.log('Chapters data:', chapters);
  if (!Array.isArray(chapters) || !chapters.length) {
    els.chaptersSection.style.display = 'none';
    els.chaptersList.innerHTML = '';
    return;
  }
  els.chaptersSection.style.display = '';
  els.chaptersList.innerHTML = '';
  chapters.forEach((ch, idx) => {
    const row = document.createElement('div');
    row.className = 'chapter-row';
    console.log(
      `Chapter ${idx + 1} thumbnail:`,
      ch.thumbnail ? `${ch.thumbnail.substring(0, 50)}...` : 'none'
    );
    if (ch.thumbnail && ch.thumbnail.trim() !== '') {
      const img = document.createElement('img');
      img.loading = 'lazy';
      img.src = ch.thumbnail; // Now contains base64 data URL
      img.alt = ch.title || `Chapter ${idx + 1}`;
      // Add error handling for failed image loads
      img.onerror = function () {
        console.warn(
          'Failed to load thumbnail for chapter:',
          ch.title || `Chapter ${idx + 1}`
        );
        console.warn(
          'Thumbnail data starts with:',
          ch.thumbnail ? ch.thumbnail.substring(0, 100) : 'empty'
        );
        this.style.display = 'none';
      };
      img.onload = function () {
        console.log(
          'Successfully loaded thumbnail for chapter:',
          ch.title || `Chapter ${idx + 1}`
        );
      };
      row.appendChild(img);
    }
    const txt = document.createElement('div');
    txt.className = 'chap-text';
    const title = document.createElement('div');
    title.textContent = ch.title || `Chapter ${idx + 1}`;
    const time = document.createElement('div');
    time.style.color = '#555';
    time.textContent = `${ch.startTimecode || ''} - ${ch.endTimecode || ''}`;
    txt.appendChild(title);
    txt.appendChild(time);
    row.appendChild(txt);
    els.chaptersList.appendChild(row);
  });
}
