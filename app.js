// App orchestrator (moved into lib)
import { setIcon } from './src/js/icons.js';
import { els } from './src/js/dom.js';
import { fullUpdate } from './src/js/selection.js';

function initSecondaryToolbar() {
  const btnExclude = document.createElement('button');
  btnExclude.id = 'btn-exclude-folders';
  btnExclude.title = 'Exclude folders (!folder:)';
  setIcon(btnExclude, 'folderMinus', 'Exclude folders (!folder:)');
  els.secondary.appendChild(btnExclude);
  btnExclude.addEventListener('click', async () => {
    try {
      await ahk.global.ExcludeFolders();
    } catch (e) {
      console.error('ExcludeFolders failed', e);
    }
  });

  const btnCleanQuery = document.createElement('button');
  btnCleanQuery.id = 'btn-clean-query';
  btnCleanQuery.title = 'Clean query';
  setIcon(btnCleanQuery, 'ban', 'Clean query');
  els.secondary.appendChild(btnCleanQuery);
  btnCleanQuery.addEventListener('click', async () => {
    await ahk.global.CleanQuery();
  });
}

function initPrimaryToolbar() {
  setIcon(els.btnDelete, 'trash', 'Delete selected files');
  setIcon(els.btnTag, 'tag', 'Tag selected files');
  setIcon(els.btnAvidemux, 'avidemux', 'Send to Avidemux');

  els.btnDelete.addEventListener('click', async () => {
    try {
      await ahk.global.DeleteSelected();
    } catch (e) {
      console.error('DeleteSelected failed', e);
    }
  });
  els.btnTag.addEventListener('click', async () => {
    try {
      const count = Number(await ahk.global.SelectedCount) || 0;
      if (count > 1) {
        const paths = await ahk.global.GetMultipleSelectedFilePaths();
        await ahk.global.SendToFileTagger(paths || '');
      } else {
        const path = await ahk.global.GetSingleSelectedFilePath();
        await ahk.global.SendToFileTagger(path || '');
      }
    } catch (e) {
      console.error('Tag action failed', e);
    }
  });
  els.btnAvidemux.addEventListener('click', async () => {
    const count = Number(await ahk.global.SelectedCount) || 0;
    if (count !== 1) return;
    const path = await ahk.global.GetSingleSelectedFilePath();
    if (window.ahk?.global?.SendToAvidemux)
      await ahk.global.SendToAvidemux(path || '');
    else alert('SendToAvidemux function not implemented in AHK.');
  });
}

function initReloadButton() {
  window.addEventListener('DOMContentLoaded', () => {
    const reloadBtn = document.getElementById('btn-reload');
    if (reloadBtn)
      reloadBtn.addEventListener('click', () => {
        window.ahk.global.reload();
      });
  });
}

async function init() {
  initReloadButton();
  initPrimaryToolbar();
  initSecondaryToolbar();
  await fullUpdate();
  window.updateSelectedFromAhk = fullUpdate;
}

await init();
