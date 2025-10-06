const fs = require("fs"), path = require("path");
const POSTS_DIR = "site/blog/posts";
const BASE = "https://www.beeplanetconnection.org";
const OUT_JSON = "site/blog/posts.json";
const OUT_RSS  = "site/blog/rss.xml";

const posts = fs.readdirSync(POSTS_DIR)
  .filter(f=>f.endsWith(".html"))
  .map(f=>{
    const p = path.join(POSTS_DIR,f);
    const html = fs.readFileSync(p,"utf8");
    const t = (html.match(/<h1[^>]*>([\s\S]*?)<\/h1>/i)||[,f])[1].trim();
    const d = (html.match(/<p[^>]*>([\s\S]*?)<\/p>/i)||[, ""])[1].replace(/<[^>]+>/g,"").trim();
    const date = (html.match(/data-date="([^"]+)"/)||[, ""])[1];
    const url = `/blog/posts/${f}`;
    return { title:t, excerpt:d, date, url };
  })
  .sort((a,b)=> (a.date < b.date ? 1 : -1));

fs.writeFileSync(OUT_JSON, JSON.stringify(posts,null,2));

// RSS
function esc(s){return s.replace(/&/g,"&amp;").replace(/</g,"&lt;");}
let rss = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"><channel>
<title>Bee Planet Connection — Blog</title>
<link>${BASE}/blog/</link>
<description>Updates and thought leadership from Bee Planet Connection.</description>`;
for (const p of posts) {
  rss += `
  <item>
    <title>${esc(p.title)}</title>
    <link>${BASE}${p.url}</link>
    <pubDate>${new Date(p.date).toUTCString()}</pubDate>
    <description>${esc(p.excerpt)}</description>
    <guid>${BASE}${p.url}</guid>
  </item>`;
}
rss += `</channel></rss>`;
fs.writeFileSync(OUT_RSS, rss);
console.log(`Wrote ${posts.length} posts → ${OUT_JSON}, ${OUT_RSS}`);
