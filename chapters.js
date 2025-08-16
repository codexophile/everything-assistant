import { els } from './dom.js';

export function renderChapters(chaptersJson) {
  if (!els.chaptersSection || !els.chaptersList) return;
  if (!chaptersJson) {
    els.chaptersSection.style.display = 'none';
    els.chaptersList.innerHTML = '';
    return;
  }
  let chapters = [];
  try {
    chapters = JSON.parse(chaptersJson);
  } catch {
    chapters = [];
  }
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
    if (ch.thumbnail && ch.thumbnail.trim() !== '') {
      const img = document.createElement('img');
      img.loading = 'lazy';
      img.src = ch.thumbnail;
      img.alt = ch.title || `Chapter ${idx + 1}`;
      img.onerror = function () {
        this.style.display = 'none';
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
