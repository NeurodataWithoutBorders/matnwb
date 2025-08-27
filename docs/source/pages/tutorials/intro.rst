Getting Started with MatNWB
===========================

.. image:: https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg
   :target: https://matlab.mathworks.com/open/github/v1?repo=NeurodataWithoutBorders/matnwb&file=tutorials/intro.mlx
   :alt: Open in MATLAB Online
.. image:: https://img.shields.io/badge/View-Full_Page-blue
   :target: ../../_static/html/tutorials/intro.html
   :alt: View full page

.. raw:: html

   <iframe id="tutorialIframe"
           src="../../_static/html/tutorials/intro.html"
           style="width: 100%; border: none; overflow: hidden;"></iframe>
   <script>
     (function () {
       const iframe = document.getElementById('tutorialIframe');

       function setIframeHeight() {
         if (!iframe.contentWindow) return;
         const doc = iframe.contentDocument || iframe.contentWindow.document;
         if (!doc) return;

         // Inject CSS to disable inner scrolling (prevents 2nd scrollbar)
         if (!doc.__noScrollInjected) {
           const style = doc.createElement('style');
           style.textContent = 'html,body{margin:0;overflow:hidden !important;}';
           (doc.head || doc.documentElement).appendChild(style);
           doc.__noScrollInjected = true;
         }

         // Compute a robust height (Chrome can differ between body vs documentElement)
         const h = Math.max(
           doc.documentElement.scrollHeight,
           doc.body ? doc.body.scrollHeight : 0,
           doc.documentElement.offsetHeight,
           doc.body ? doc.body.offsetHeight : 0
         );
         iframe.style.height = h + 'px';
       }

       function setupObservers() {
         const doc = iframe.contentDocument || iframe.contentWindow.document;
         if (!doc) return;

         // Recalculate after images/fonts load
         Array.from(doc.images || []).forEach(img => {
           if (!img.complete) img.addEventListener('load', setIframeHeight, {once:false});
         });

         // Observe size changes inside the iframe (layout shifts)
         if ('ResizeObserver' in window) {
           const ro = new ResizeObserver(setIframeHeight);
           ro.observe(doc.documentElement);
           // Keep a reference so it’s not GC’d
           iframe.__ro = ro;
         } else {
           // Fallback: poll briefly for late layout changes
           let n = 0;
           const id = setInterval(() => {
             setIframeHeight();
             if (++n > 50) clearInterval(id); // ~5s if 100ms interval
           }, 100);
         }

         // Extra: recalc on DOM mutations (e.g., MathJax typesets later)
         if ('MutationObserver' in window) {
           const mo = new MutationObserver(setIframeHeight);
           mo.observe(doc.documentElement, {subtree: true, childList: true, attributes: true, characterData: true});
           iframe.__mo = mo;
         }

         // Initial and next-tick recalcs
         setIframeHeight();
         requestAnimationFrame(setIframeHeight);
       }

       iframe.addEventListener('load', () => {
         // Give the inner page a tick to finish initial layout, then wire up observers
         requestAnimationFrame(() => {
           setIframeHeight();
           setupObservers();
         });
       });
     })();
   </script>
