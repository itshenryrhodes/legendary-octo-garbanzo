/**
 * build-search.js
 * Scans /site/wiki for .html pages and emits /site/search-index.json
 * Fields: { url, title, excerpt }
 */
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve("site/wiki");
const OUT  = path.resolve("site/search-index.json");

function walk(dir, out=[]) {
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    const st = fs.statSync(p);
    if (st.isDirectory()) walk(p, out);
    else if (name.endsWith(".html")) out.push(p);
  }
  return out;
}

function relUrl(absPath) {
  const rel = absPath.replace(path.resolve("site"), "").replace(/\\/g,"/");
  return rel.replace(/\/index\.html$/,"/"); // pretty URLs
}

function extract(html) {
  const get = (re) => (html.match(re) || [,""])[1].trim();
  let title = get(/<h1[^>]*>([\s\S]*?)<\/h1>/i);
  if (!title) title = get(/<title[^>]*>([\s\S]*?)<\/title>/i);
  const para = get(/<p[^>]*>([\s\S]*?)<\/p>/i).replace(/<[^>]+>/g,"");
  return { title, excerpt: para };
}

const files = walk(ROOT);
const docs = files.map(p => {
  const html = fs.readFileSync(p,"utf8");
  const { title, excerpt } = extract(html);
  return { url: relUrl(p), title, excerpt };
}).filter(d => d.title);

fs.writeFileSync(OUT, JSON.stringify(docs, null, 2));
console.log(`Wrote ${docs.length} docs → ${OUT}`);
