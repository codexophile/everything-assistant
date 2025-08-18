// App orchestrator (moved into lib)
import { setIcon } from './src/js/icons.js';
import { els } from './src/js/dom.js';
import { fullUpdate } from './src/js/selection.js';

// Simple logger (namespaced) to help diagnose why secondary toolbar might not render
function log(...args) {
  if (typeof console !== 'undefined') console.log('[EA]', ...args);
}

log('script loaded, beginning init sequence');

let secondaryInitialised = false;
let secondaryAttempts = 0;
function initSecondaryToolbar() {
  if (secondaryInitialised) return;
  secondaryAttempts++;
  // Re-query each attempt
  const container = document.querySelector('#secondary-toolbar');
  if (!container) {
    log(`attempt ${secondaryAttempts}: secondary toolbar container not found`);
    return;
  }
  try {
    log('secondary toolbar container found, building buttons');
    const btnExclude = document.createElement('button');
    btnExclude.id = 'btn-exclude-folders';
    btnExclude.className = 'icon-btn btn btn-outline-secondary';
    btnExclude.title = 'Exclude folders (!folder:)';
    btnExclude.innerHTML =
      '<i class="fa-solid fa-folder-minus me-1"></i> Exclude Folders';
    container.appendChild(btnExclude);
    btnExclude.addEventListener('click', async () => {
      try {
        await ahk.global.ExcludeFolders();
      } catch (e) {
        console.error('ExcludeFolders failed', e);
      }
    });

    const btnCleanQuery = document.createElement('button');
    btnCleanQuery.id = 'btn-clean-query';
    btnCleanQuery.className = 'icon-btn btn btn-outline-secondary';
    btnCleanQuery.title = 'Clean query';
    btnCleanQuery.innerHTML =
      '<i class="fa-solid fa-ban me-1"></i> Clean Query';
    container.appendChild(btnCleanQuery);
    btnCleanQuery.addEventListener('click', async () => {
      try {
        await ahk.global.CleanQuery();
      } catch (e) {
        console.error('CleanQuery failed', e);
      }
    });
    secondaryInitialised = true;
    log('secondary toolbar initialised after', secondaryAttempts, 'attempt(s)');
    // Immediate diagnostics
    try {
      const rect = container.getBoundingClientRect();
      log(
        'secondary toolbar rect',
        JSON.stringify({ x: rect.x, y: rect.y, w: rect.width, h: rect.height })
      );
      [...container.children].forEach((c, i) => {
        const r = c.getBoundingClientRect();
        log(
          `btn${i} tag=${c.tagName} id=${c.id} classes=${c.className} rect=`,
          JSON.stringify({ x: r.x, y: r.y, w: r.width, h: r.height })
        );
      });
      setTimeout(() => {
        const rect2 = container.getBoundingClientRect();
        log(
          'secondary toolbar rect (500ms later)',
          JSON.stringify({
            x: rect2.x,
            y: rect2.y,
            w: rect2.width,
            h: rect2.height,
          })
        );
      }, 500);
    } catch (e) {
      /* ignore */
    }
  } catch (err) {
    console.error('Failed initialising secondary toolbar:', err);
  }
}

// Repeated attempts (covers race conditions & dynamic injection scenarios)
const secondaryRetryInterval = setInterval(() => {
  if (secondaryInitialised || secondaryAttempts > 20) {
    clearInterval(secondaryRetryInterval);
    if (!secondaryInitialised) log('stopped retrying secondary toolbar init');
    return;
  }
  initSecondaryToolbar();
}, 100);

// Also run once on DOMContentLoaded for good measure
window.addEventListener('DOMContentLoaded', initSecondaryToolbar, {
  once: true,
});

function initPrimaryToolbar() {
  // Using Bootstrap styling instead of setIcon
  els.btnDelete.innerHTML = '<i class="fa-solid fa-trash me-1"></i> Delete';
  els.btnTag.innerHTML = '<i class="fa-solid fa-tag me-1"></i> Tag';
  els.btnAvidemux.innerHTML = '<i class="fa-solid fa-video me-1"></i> Avidemux';

  els.btnDelete.addEventListener('click', async () => {
    await ahk.global.DeleteSelected();
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
