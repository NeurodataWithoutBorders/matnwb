/**
 * Auto-resize <iframe> elements with class "autoresize".
 *
 * Goal: keep each iframe’s height in sync with the embedded document’s total height
 * to avoid inner scrollbars.
 *
 * Behavior:
 * - Runs on pages that contain <iframe class="autoresize"> (no-op otherwise).
 * - Measures the inner document’s scroll height and sets iframe.style.height.
 * - Recomputes on content/layout changes (e.g., images, fonts, responsive reflow).
 *
 * Usage: <iframe class="autoresize" src="..."></iframe>
 */

(function () {
  function wire(iframe) {
    function resize() {
      const doc = iframe.contentDocument || iframe.contentWindow?.document;
      if (!doc) return;
      const h = Math.max(doc.documentElement.scrollHeight, doc.body?.scrollHeight || 0);
      if (iframe.__lastH !== h) {
        iframe.style.height = h + 'px';
        iframe.__lastH = h;
      }
    }
    const rafResize = () => requestAnimationFrame(resize);

    iframe.addEventListener('load', () => {
      resize();
      const doc = iframe.contentDocument || iframe.contentWindow?.document;
      if (!doc) return;

      if ('ResizeObserver' in window) {
        const roInner = new ResizeObserver(rafResize);
        roInner.observe(doc.documentElement);
        iframe.__roInner = roInner;
      }
      doc.fonts?.ready?.then(resize);
      for (const img of doc.images || []) {
        if (!img.complete) img.addEventListener('load', rafResize);
      }
    });

    if ('ResizeObserver' in window) {
      const roOuter = new ResizeObserver(rafResize);
      roOuter.observe(iframe);
      iframe.__roOuter = roOuter;
    } else {
      window.addEventListener('resize', rafResize);
      setTimeout(resize, 500);
      setTimeout(resize, 1500);
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('iframe.autoresize').forEach(wire);
  });
})();
