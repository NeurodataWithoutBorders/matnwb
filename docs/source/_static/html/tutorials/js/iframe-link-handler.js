// iframe-link-handler.js
(() => {
  if (window.self === window.top) return;

  const STATIC_PREFIX = "/_static/html/";
  const PAGES_PREFIX  = "/pages/";

  function rewriteLinks(root = document) {
    root.querySelectorAll("a[href]").forEach(a => {
      const href = a.getAttribute("href");

      if (href.startsWith("https:") || href.endsWith(".html")) {
        a.setAttribute("target", "_top");
      }

      const isRelativeHtml = href.endsWith(".html") && !/^[a-z]+:\/\//i.test(href);
      if (isRelativeHtml) {
        const here = window.location.pathname;
        const base = here
          .replace(STATIC_PREFIX, PAGES_PREFIX)
          .replace(/[^/]+$/, "");
        a.href = base + href.replace(/^\.\//, "");
      }
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", rewriteLinks());
  } else {
    rewriteLinks();
  }
})();
