/**
 * Expand <!--#include file="..."> directives into static HTML.
 * Works for root and nested pages (e.g. /wiki/).
 */
const fs = require("fs");
const path = require("path");

function expand(file, anchorDir) {
  let html = fs.readFileSync(file, "utf8");
  html = html.replace(/<!--#include file="(.*?)" -->/g, (m, p) => {
    const inc = path.resolve(anchorDir, p);
    return fs.existsSync(inc) ? fs.readFileSync(inc, "utf8") : m;
  });
  fs.writeFileSync(file, html);
}

function walk(dir) {
  for (const f of fs.readdirSync(dir)) {
    const p = path.join(dir, f);
    const st = fs.statSync(p);
    if (st.isDirectory()) {
      walk(p);
    } else if (p.endsWith(".html")) {
      // Pages under /wiki/ use ../partials/…, others use partials/…
      const anchor = p.includes(path.sep + "wiki" + path.sep) ? "site/wiki" : "site";
      expand(p, anchor);
    }
  }
}

walk("site");
console.log("Includes expanded.");
