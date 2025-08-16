import { els } from './dom.js';
import { renderFolderButtons } from './folders.js';
import { extractTagsFromNamesList, renderTags } from './tags.js';
import { renderChapters } from './chapters.js';

export async function renderSelection() {
  try {
    const [fileName, filePath, namesAll, countRaw, folderChain, chaptersJson] = await Promise.all([
      ahk.global.SelectedFileName,
      ahk.global.SelectedFilePath,
      ahk.global.SelectedNames,
      ahk.global.SelectedCount,
      ahk.global.SelectedFolderPaths,
      ahk.global.SelectedChaptersJson
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
    els.summary.innerText = '(none)';
    els.name.style.display = 'none';
    els.name.innerText = '';
    els.path.innerText = '(no path)';
    els.actions.innerHTML = '';
    renderTags([]);
    renderChapters(null);
  } catch {
    // ignore if globals not yet available
  }
}

export async function updateDeleteState() {
  try {
    const [countRaw, filePath] = await Promise.all([
      ahk.global.SelectedCount,
      ahk.global.SelectedFilePath
    ]);
    const count = Number(countRaw) || 0;
    els.btnDelete.disabled = !(count > 0 || (filePath && filePath.trim()));
  } catch {}
}

export async function updateTagState() {
  try {
    const [countRaw, filePath] = await Promise.all([
      ahk.global.SelectedCount,
      ahk.global.SelectedFilePath
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
