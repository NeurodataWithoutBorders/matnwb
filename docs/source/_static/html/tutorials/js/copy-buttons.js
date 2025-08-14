// copy-buttons.js
(() => {
  let uid = 0;  // unique id per block

  function addCopyButtons(root = document) {
    root.querySelectorAll('.CodeBlock').forEach(block => {
      if (block.dataset.copyReady) return;
      block.dataset.copyReady = 'y';

      const targetId = `codecell${uid++}`;
      block.setAttribute('id', targetId);

      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'copybtn o-tooltip--left';
      btn.dataset.tooltip = 'Copy';
      btn.setAttribute('aria-label', 'Copy code');
      btn.innerHTML = `
        <!-- copy icon -->
        <svg class="icon-copy icon icon-tabler icon-tabler-copy" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
          <rect x="8" y="8" width="12" height="12" rx="2"/>
          <path d="M16 8v-2a2 2 0 0 0 -2 -2h-8
                   a2 2 0 0 0 -2 2v8
                   a2 2 0 0 0 2 2h2"/>
        </svg>
        <!-- check icon -->
        <svg class="icon-check icon icon-tabler icon-tabler-check" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
          <path d="M5 12l5 5l10 -10" stroke-width="2"
                stroke-linecap="round" stroke-linejoin="round" fill="none"/>
        </svg>`;
      block.appendChild(btn);

      // lock position on scroll
      btn.style.transform = 'translateX(0)';
      block.addEventListener('scroll', () => {
        btn.style.transform = `translateX(${block.scrollLeft}px)`;
      }, { passive: true });

      // copy click handler
      btn.addEventListener('click', async () => {
        const lines = [];
        let outputsNode = null;

        block.childNodes.forEach(node => {
          if (node.nodeType !== 1) return;
          if (node.classList.contains('outputs')) {
            outputsNode = node;
            return;
          }
          if (node !== btn) {
            // use textContent to keep line breaks exactly as in the DOM
            lines.push(node.textContent || '');
          }
        });

        if (outputsNode) {
          const firstOut = (outputsNode.textContent || '')
            .split(/\r?\n/)
            .find(Boolean) || '';
          lines.push(firstOut);
        }

        // join with \n to preserve multi-node breaks
        const payload = lines.join('\n').replace(/\s+$/, '');

        try {
          await navigator.clipboard.writeText(payload);
          btn.classList.add('copied');
        } finally {
          setTimeout(() => btn.classList.remove('copied'), 1200);
        }
      });
    });
  }

  // run on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => addCopyButtons());
  } else {
    addCopyButtons();
  }
})();
