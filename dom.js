// DOM references & dynamic structural adjustments
// Central place to query & create needed elements.

function createTagsContainerIfNeeded() {
  const existing = document.querySelector('#tags-container');
  if (existing) return existing;
  const fileInfo = document.querySelector('#file-info');
  if (!fileInfo) return null;
  // Reuse existing #tags element instead of creating duplicate id
  let tags = document.querySelector('#tags');
  if (!tags) {
    tags = document.createElement('div');
    tags.id = 'tags';
    fileInfo.appendChild(tags);
  }
  const wrap = document.createElement('div');
  wrap.id = 'tags-container';
  const label = document.createElement('div');
  label.className = 'mono-dim';
  label.textContent = 'Tags:';
  tags.replaceWith(wrap); // move location after label inside container
  wrap.appendChild(label);
  wrap.appendChild(tags);
  fileInfo.after(wrap);
  return wrap;
}

export const els = {
  summary: document.querySelector('#sel-summary'),
  name: document.querySelector('#sel-name'),
  path: document.querySelector('#sel-path'),
  actions: document.querySelector('#file-actions'),
  secondary: document.querySelector('#secondary-toolbar'),
  btnDelete: document.querySelector('#btn-delete'),
  btnTag: document.querySelector('#btn-tag'),
  btnAvidemux: document.querySelector('#btn-avidemux'),
  tagsContainer: createTagsContainerIfNeeded(),
  get tags() { return document.querySelector('#tags'); },
  chaptersSection: document.querySelector('#chapters-section'),
  chaptersList: document.querySelector('#chapters-list')
};
