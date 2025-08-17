// DOM references (moved into lib)
function createTagsContainerIfNeeded() {
  const existing = document.querySelector('#tags-container');
  if (existing) return existing;

  const fileInfo = document.querySelector('#file-info');
  if (!fileInfo) return null;

  let tags = document.querySelector('#tags');
  if (!tags) {
    tags = document.createElement('div');
    tags.id = 'tags';
    tags.className = 'mt-2 d-flex gap-1 flex-wrap';
    fileInfo.appendChild(tags);
  }

  const wrap = document.createElement('div');
  wrap.id = 'tags-container';
  wrap.className = 'mt-3';

  const label = document.createElement('div');
  label.className = 'mono-dim mb-1 fw-semibold';
  label.textContent = 'Tags:';

  tags.replaceWith(wrap);
  wrap.appendChild(label);
  wrap.appendChild(tags);

  return wrap;
}

export const els = {
  summary: document.querySelector('#sel-summary'),
  name: document.querySelector('#sel-name'),
  path: document.querySelector('#sel-path'),
  duration: document.querySelector('#sel-duration'),
  actions: document.querySelector('#file-actions'),
  secondary: document.querySelector('#secondary-toolbar'),
  btnDelete: document.querySelector('#btn-delete'),
  btnTag: document.querySelector('#btn-tag'),
  btnAvidemux: document.querySelector('#btn-avidemux'),
  tagsContainer: createTagsContainerIfNeeded(),
  get tags() {
    return document.querySelector('#tags');
  },
  chaptersSection: document.querySelector('#chapters-section'),
  chaptersList: document.querySelector('#chapters-list'),
};
