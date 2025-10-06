/**
 * Injects basic SEO/OG meta tags into all /site/**/*.html
 */
const fs=require("fs"), path=require("path");
const ROOT="site";
const SITE="https://www.beeplanetconnection.org";
function walk(dir, out=[]){
  for(const f of fs.readdirSync(dir)){
    const p=path.join(dir,f), st=fs.statSync(p);
    if(st.isDirectory()) walk(p,out);
    else if(p.endsWith(".html")) out.push(p);
  } return out;
}
for (const file of walk(ROOT)) {
  let html = fs.readFileSync(file,"utf8");
  // only inject once
  if (!/og:title|name="description"|rel="canonical"/i.test(html)) {
    const title = (html.match(/<h1[^>]*>([\s\S]*?)<\/h1>/i)||[, "Bee Planet Connection"])[1]
      .replace(/<[^>]+>/g,"").trim();
    const firstP = (html.match(/<p[^>]*>([\s\S]*?)<\/p>/i)||[, ""])[1]
      .replace(/<[^>]+>/g,"").trim();
    const urlPath = file.replace(/^site[\/\\\\]?/,"");
    const canon = `${SITE}/${urlPath.replace(/\\\\/g,"/")}`.replace(/\/index\.html$/,"/");
    const block = `
<link rel="canonical" href="${canon}">
<meta name="description" content="${firstP.slice(0,160)}">
<meta property="og:title" content="${title}">
<meta property="og:description" content="${firstP.slice(0,200)}">
<meta property="og:type" content="website">
<meta property="og:url" content="${canon}">
`;
    html = html.replace(/(<meta\s+charset="[^"]*"\s*>)/i, `$1\n${block}`);
    fs.writeFileSync(file, html);
  }
}
console.log("SEO/OG meta injected.");
