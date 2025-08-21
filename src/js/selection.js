import { els } from './dom.js';
import { renderFolderButtons } from './folders.js';
import { extractTagsFromNamesList, renderTags } from './tags.js';
import { renderChapters } from './chapters.js';

export async function renderSelection() {
  try {
    const [
      fileName,
      filePath,
      namesAll,
      countRaw,
      folderChain,
      chaptersJson,
      duration,
    ] = await Promise.all([
      ahk.global.SelectedFileName,
      ahk.global.SelectedFilePath,
      ahk.global.SelectedNames,
      ahk.global.SelectedCount,
      ahk.global.SelectedFolderPaths,
      ahk.global.SelectedChaptersJson,
      ahk.global.SelectedFileDuration,
    ]);
    const count = Number(countRaw) || 0;

    // Clear the alert message when files are selected
    const actionsContainer = document.querySelector('.file-actions-container');
    if (actionsContainer && count > 0) {
      actionsContainer.innerHTML = '';
    }

    if (count > 1) {
      els.summary.innerHTML = `<span class="badge bg-primary">${count} items selected</span>`;
      els.name.style.display = '';
      els.name.classList.add('truncate-1');
      els.name.title = (namesAll || '').split('\n').slice(0, 10).join(', ');
      els.name.innerText = (namesAll || '').split('\n').slice(0, 10).join(', ');
      els.path.classList.add('truncate-1');
      els.path.title = '(multiple paths)';
      els.path.innerText = '(multiple paths)';
      els.duration.style.display = 'none';
      els.actions.innerHTML = '';
      const allNames = (namesAll || '').split('\n').filter(Boolean);
      renderTags(extractTagsFromNamesList(allNames));
      renderChapters(null);
      return;
    }
    if (count === 1 || (fileName && fileName.trim())) {
      els.summary.innerHTML =
        '<span class="badge bg-success">1 item selected</span>';
      els.name.style.display = '';
      els.name.classList.add('truncate-1');
      els.name.title = fileName || '';
      els.name.innerText = fileName || '';
      els.path.classList.add('truncate-1');
      els.path.title = filePath && filePath.trim() ? filePath : '(no path)';
      els.path.innerText = filePath && filePath.trim() ? filePath : '(no path)';

      if (duration && duration.trim()) {
        if (duration === '__PENDING__') {
          els.duration.style.display = '';
          els.duration.innerHTML =
            '<i class="fa-solid fa-spinner fa-spin me-1"></i> Getting duration...';
        } else {
          els.duration.style.display = '';
          els.duration.innerHTML = `<i class="fa-regular fa-clock me-1"></i> ${duration}`;
        }
      } else {
        els.duration.style.display = 'none';
        els.duration.innerText = '';
      }

      const items = folderChain ? folderChain.split('\n') : [];
      renderFolderButtons(items);
      renderTags(extractTagsFromNamesList([fileName || '']));
      renderChapters(chaptersJson);
      return;
    }
    els.summary.innerHTML =
      '<span class="badge bg-secondary">No selection</span>';
    els.name.style.display = 'none';
    els.name.innerText = '';
    els.path.innerText = '(no path)';
    els.duration.style.display = 'none';
    els.duration.innerText = '';
    els.actions.innerHTML = '';
    renderTags([]);
    renderChapters(null);
  } catch {}
}

export async function updateDeleteState() {
  try {
    const [countRaw, filePath] = await Promise.all([
      ahk.global.SelectedCount,
      ahk.global.SelectedFilePath,
    ]);
    const count = Number(countRaw) || 0;
    els.btnDelete.disabled = !(count > 0 || (filePath && filePath.trim()));
  } catch {}
}

export async function updateTagState() {
  try {
    const [countRaw, filePath] = await Promise.all([
      ahk.global.SelectedCount,
      ahk.global.SelectedFilePath,
    ]);
    const count = Number(countRaw) || 0;
    els.btnTag.disabled = !(count > 0 || (filePath && filePath.trim()));
  } catch {}
}

export async function updateAvidemuxState() {
  const count = Number(await ahk.global.SelectedCount) || 0;
  els.btnAvidemux.disabled = count !== 1;
}

export async function fullUpdate() {
  await renderSelection();
  await updateDeleteState();
  await updateTagState();
  await updateAvidemuxState();
}
