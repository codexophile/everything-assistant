import { els } from './dom.js';
export function extractTagsFromName(name) {
  if (!name) return [];
  const matches = [...name.matchAll(/\[(.+?)\]/g)];
  return matches.map(m => m[1]);
}
export function extractTagsFromNamesList(namesList) {
  const counts = new Map();
  for (const nm of namesList) {
    for (const t of extractTagsFromName(nm)) {
      counts.set(t, (counts.get(t) || 0) + 1);
    }
  }
  return Array.from(counts.keys()).sort((a, b) => a.localeCompare(b));
}
export function renderTags(tags) {
  const tagsEl = els.tags;
  if (!tagsEl || !els.tagsContainer) return;
  if (tags && tags.length) {
    tagsEl.innerHTML = '';
    for (const t of tags) {
      const chip = document.createElement('span');
      chip.className = 'tag-chip';
      chip.textContent = t;
      chip.title = `Search for tag: ${t}`;
      chip.style.cursor = 'pointer';
      chip.addEventListener('click', () => {
        window.open(`es:${encodeURIComponent(`[${t}]`)}`, '_blank');
      });
      tagsEl.appendChild(chip);
    }
    els.tagsContainer.style.display = 'block';
  } else {
    tagsEl.innerHTML = '';
    els.tagsContainer.style.display = 'none';
  }
}
