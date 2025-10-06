/**
 * build-sitemap.js — auto-generates sitemap.xml from /site
 * Includes .html pages (excludes partials, hidden, 404, draft/test pages)
 */
const fs = require("fs"), path = require("path");
const ROOT = "site";
const BASE = "https://www.beeplanetconnection.org";
const OUT = "site/sitemap.xml";

function walk(dir) {
  let results = [];
  for (const f of fs.readdirSync(dir)) {
    const p = path.join(dir, f);
    const st = fs.statSync(p);
    if (st.isDirectory()) results = results.concat(walk(p));
    else if (f.endsWith(".html")) results.push(p);
  }
  return results;
}

const pages = walk(ROOT)
  .filter(p => !/partials|404|draft|test/i.test(p))
  .map(p => {
    const url = p.replace(/^site[\/\\]?/, "/").replace(/\\/g, "/");
    return `${BASE}${url.replace(/index\.html$/, "")}`;
  });

const now = new Date().toISOString();
const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="https://www.sitemaps.org/schemas/sitemap/0.9">
${pages.map(u=>`  <url><loc>${u}</loc><lastmod>${now}</lastmod></url>`).join("\n")}
</urlset>`;

fs.writeFileSync(OUT, xml);
console.log(`✅ sitemap.xml written (${pages.length} URLs) → ${OUT}`);
