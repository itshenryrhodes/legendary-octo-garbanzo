/**
 * inject-ld.js — adds Organization JSON-LD to /site/index.html and /site/about/index.html
 */
const fs=require("fs"), path=require("path");
const targets=["site/index.html","site/about/index.html"].filter(p=>fs.existsSync(p));
const ld = {
  "@context":"https://schema.org",
  "@type":"Organization",
  "name":"Bee Planet Connection",
  "url":"https://www.beeplanetconnection.org",
  "logo":"https://www.beeplanetconnection.org/img/logo.png",
  "sameAs":[
    "https://github.com/itshenryrhodes/legendary-octo-garbanzo"
  ]
};
for (const f of targets){
  let html=fs.readFileSync(f,"utf8");
  if(!/application\/ld\+json/.test(html)){
    const block = `\n<script type="application/ld+json">${JSON.stringify(ld)}</script>\n`;
    html = html.replace(/<\/head>/i, block + "</head>");
    fs.writeFileSync(f, html);
  }
}
console.log("Injected JSON-LD into", targets.join(", "));
