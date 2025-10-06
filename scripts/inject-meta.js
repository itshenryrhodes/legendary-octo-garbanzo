/**
 * Injects basic SEO/OG meta tags into all /site/**/*.html
 */
const fs = require("fs");
const path = require("path");

function walk(dir, out=[]) {
  for (const f of fs.readdirSync(dir)) {
    const p = path.join(dir,f);
    const st = fs.statSync(p);
    if (st.isDirectory()) walk(p,out);
    else if (p.endsWith(".html")) out.push(p);
  }
  return out;
}

function extract(html){
  const get = re => (html.match(re)||[,""])[1].trim();
  let title = get(/<h1[^>]*>([\s\S]*?)<\/h1>/i) || get(/<title[^>]*>([\s\S]*?)<\/title>/i) || "Bee Planet Connection";
  let desc  = get(/<p[^>]*>([\s\S]*?)<\/p>/i).replace(/<[^>]+>/g,"");
  if (desc.length > 155) desc = desc.slice(0,152)+"…";
  return { title, desc };
}

function inject(html, url) {
  const { title, desc } = extract(html);
  const meta = `
  <meta name="description" content="${desc}">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${desc}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://www.beeplanetconnection.org${url}">
  <meta name="twitter:card" content="summary">`;
  return html.replace(/(<meta charset="[^"]*">\s*)/i, `$1${meta}\n`);
}

function relUrl(fp){
  return fp.replace(path.resolve("site"),"").replace(/\\/g,"/").replace(/\/index\.html$/,"/");
}

for (const file of walk("site")) {
  let html = fs.readFileSync(file,"utf8");
  if (!/og:title/.test(html)) {
    html = inject(html, relUrl(file));
    fs.writeFileSync(file, html);
  }
}
console.log("Meta injected.");
