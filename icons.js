// Icon utilities: prefer Font Awesome if available, else inline SVG fallback
// Export setIcon(btn, name, title?)

let faLoadedCache = null;

function hasFA() {
  if (faLoadedCache !== null) return faLoadedCache;
  try {
    const probe = document.createElement('i');
    probe.className = 'fa-solid fa-tag';
    probe.style.position = 'absolute';
    probe.style.left = '-9999px';
    document.body.appendChild(probe);
    const cs = getComputedStyle(probe, '::before');
    const content = cs && cs.content;
    faLoadedCache = !!content && content !== 'none' && content !== 'normal' && content !== '""';
    probe.remove();
  } catch {
    faLoadedCache = false;
  }
  return faLoadedCache;
}

const svg = {
  trash: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512" width="16" height="16" fill="currentColor"><path d="M160 400c0 8.8-7.2 16-16 16s-16-7.2-16-16V208c0-8.8 7.2-16 16-16s16 7.2 16 16V400zM240 416c8.8 0 16-7.2 16-16V208c0-8.8-7.2-16-16-16s-16 7.2-16 16V400c0 8.8 7.2 16 16 16zM336 400c0 8.8-7.2 16-16 16s-16-7.2-16-16V208c0-8.8 7.2-16 16-16s16 7.2 16 16V400zM432 80H312l-9.4-18.7C295.7 50.5 279.8 40 262.5 40h-77c-17.3 0-33.2 10.5-40.1 21.3L136 80H16C7.2 80 0 87.2 0 96s7.2 16 16 16H32l21.2 339.4C55.9 470.8 77.9 492 104.3 492h239.4c26.4 0 48.4-21.2 51.1-40.6L416 112h16c8.8 0 16-7.2 16-16s-7.2-16-16-16z"/></svg>',
  tag: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="16" height="16" fill="currentColor"><path d="M497.9 225.1L286.9 14.1C277.8 5 265.6 0 252.9 0H112C85.5 0 64 21.5 64 48v140.9c0 12.7 5 24.9 14.1 34l211 211c18.7 18.7 49.1 18.7 67.9 0l130.9-130.9c18.7-18.7 18.7-49.1 0-67.9zM112 96c-17.7 0-32 14.3-32 32s14.3 32 32 32s32-14.3 32-32s-14.3-32-32-32z"/></svg>',
  ban: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="16" height="16" fill="currentColor"><path d="M256 48C141.1 48 48 141.1 48 256s93.1 208 208 208s208-93.1 208-208S370.9 48 256 48zm130.5 93.5c15.3 15.3 27.5 33.1 36.1 52.5L194 422.6c-19.4-8.6-37.2-20.8-52.5-36.1s-27.5-33.1-36.1-52.5L389.9 141.5c19.4 8.6 37.2 20.8 52.6 36zM96 256c0-36.6 10.6-70.7 28.8-99.3L355.3 387.2C326.7 405.4 292.6 416 256 416 167.6 416 96 344.4 96 256z"/></svg>',
  search: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="16" height="16" fill="currentColor"><path d="M416 208c0 45.9-14.9 88.3-40 122.7l86.6 86.6c12.5 12.5 12.5 32.8 0 45.3s-32.8 12.5-45.3 0l-86.6-86.6C296.3 401.1 253.9 416 208 416 93.1 416 0 322.9 0 208S93.1 0 208 0s208 93.1 208 208zM80 208c0 70.7 57.3 128 128 128s128-57.3 128-128S278.7 80 208 80 80 137.3 80 208z"/></svg>',
  folderMinus: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="16" height="16" fill="currentColor"><path d="M464 128h-192l-64-64H48C21.5 64 0 85.5 0 112v288c0 26.5 21.5 48 48 48h416c26.5 0 48-21.5 48-48V176c0-26.5-21.5-48-48-48zM352 304H160c-8.8 0-16-7.2-16-16s7.2-16 16-16h192c8.8 0 16 7.2 16 16s-7.2 16-16 16z"/></svg>',
  avidemux: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 576 512" width="16" height="16" fill="currentColor"><path d="M528 64H384l-48-56c-6.1-7.2-15.6-10.4-24.7-8.8L96 64C78.3 68.9 64 86.9 64 105.9V320c0 35.3 28.7 64 64 64h320c35.3 0 64-28.7 64-64V96c0-17-7.3-32.6-24-32zM96 176l64-40 48 40-64 40-48-40zm144 56l64-40 48 40-64 40-48-40zM512 352c0 35.3-28.7 64-64 64H96c-35.3 0-64-28.7-64-64v-16h64c35.3 0 64-28.7 64-64s28.7-64 64-64h128c35.3 0 64 28.7 64 64s28.7 64 64 64h64v16z"/></svg>',
  pwsh: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="16" height="16" fill="currentColor"><path d="M2 3h20v18H2V3zm2 2v14h16V5H4zm3.5 3 4.5 4-4.5 4V8z"/></svg>'
};

export function setIcon(btn, name, title) {
  if (title) btn.title = title;
  if (hasFA()) {
    const map = {
      trash: 'fa-solid fa-trash',
      tag: 'fa-solid fa-tag',
      ban: 'fa-solid fa-ban',
      search: 'fa-solid fa-magnifying-glass',
      folderMinus: 'fa-solid fa-folder-minus',
      pwsh: 'fa-solid fa-terminal',
      avidemux: 'fa-solid fa-video'
    };
    const cls = map[name] || 'fa-solid fa-circle-question';
    btn.innerHTML = `<i class="${cls}"></i>`;
  } else {
    btn.innerHTML = svg[name] || svg.search;
  }
  btn.classList.add('icon-btn');
}
