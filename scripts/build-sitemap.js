const fs = require("fs");
const path = require("path");

const ROOT = "site";
const BASE = "https://www.beeplanetconnection.org";
const OUT_SITEMAP = path.join(ROOT, "sitemap.xml");
const ROBOTS = path.join(ROOT, "robots.txt");

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

function toUrl(p) {
  // /site/index.html → /
  // /site/wiki/index.html → /wiki/
  // /site/foo/bar.html → /foo/bar.html
  const rel = p.replace(/^site[\/\\]?/, "").replace(/\\/g, "/");
  return BASE + "/" + rel.replace(/^index\.html$/, "").replace(/\/index\.html$/, "/");
}

const pages = walk(ROOT)
  .filter(p => !/partials|404|draft|test/i.test(p))
  .map(p => {
    const st = fs.statSync(p);
    return { url: toUrl(p), lastmod: st.mtime.toISOString() };
  })
  // Sort newest first (not required, but nice)
  .sort((a, b) => (a.lastmod < b.lastmod ? 1 : -1));

const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="https://www.sitemaps.org/schemas/sitemap/0.9">
${pages
  .map(
    (u) => `  <url>
    <loc>${u.url}</loc>
    <lastmod>${u.lastmod}</lastmod>
  </url>`
  )
  .join("\n")}
</urlset>`;

fs.writeFileSync(OUT_SITEMAP, xml);
console.log(`✅ sitemap.xml written (${pages.length} URLs) → ${OUT_SITEMAP}`);

// --- Ensure robots.txt has a single Sitemap: line
const sitemapLine = `Sitemap: ${BASE}/sitemap.xml`;
let robots = "";
if (fs.existsSync(ROBOTS)) {
  robots = fs.readFileSync(ROBOTS, "utf8");
  // remove any existing Sitemap lines (dedupe/refresh)
  robots = robots.replace(/^\s*Sitemap:\s*.*$/gmi, "").trim();
  robots = (robots ? robots + "\n" : "") + sitemapLine + "\n";
} else {
  robots = `User-agent: *\nAllow: /\n${sitemapLine}\n`;
}
fs.writeFileSync(ROBOTS, robots);
console.log("✅ robots.txt updated with Sitemap:");
console.log(`   ${sitemapLine}`);
