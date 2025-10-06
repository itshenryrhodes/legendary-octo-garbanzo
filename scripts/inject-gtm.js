/**
 * inject-gtm.js — Adds Google Tag Manager to all /site/**/*.html
 * - <script> goes right after <meta charset="...">
 * - <noscript> iframe goes right after the header include (best body-adjacent spot in this layout)
 * Idempotent (won’t double-insert).
 */
const fs=require("fs"), path=require("path");
const ROOT="site";
const GTM_ID="GTM-NDKQRC3N";
const RE_JS = new RegExp(`googletagmanager\\.com\\/gtm\\.js\\?id=${GTM_ID.replace(/-/g,"-")}`);
const RE_IFR= new RegExp(`googletagmanager\\.com\\/ns\\.html\\?id=${GTM_ID.replace(/-/g,"-")}`);

const JS_SNIPPET = `<!-- Google Tag Manager -->
<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
})(window,document,'script','dataLayer','${GTM_ID}');</script>
<!-- End Google Tag Manager -->`;

const IFR_SNIPPET = `<!-- Google Tag Manager (noscript) -->
<noscript><iframe src="https://www.googletagmanager.com/ns.html?id=${GTM_ID}"
height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
<!-- End Google Tag Manager (noscript) -->`;

function walk(dir, files=[]){
  for(const f of fs.readdirSync(dir)){
    const p=path.join(dir,f);
    const st=fs.statSync(p);
    if(st.isDirectory()) walk(p, files);
    else if(p.endsWith(".html")) files.push(p);
  }
  return files;
}

for(const file of walk(ROOT)){
  let html=fs.readFileSync(file,"utf8"), changed=false;

  // Inject <script> in "head" area (right after <meta charset="...">)
  if(!RE_JS.test(html)){
    html = html.replace(/(<meta\s+charset="[^"]*">\s*)/i, `$1${JS_SNIPPET}\n`);
    if (html !== fs.readFileSync(file,"utf8")) changed=true;
  }

  // Inject noscript right after the header include (closest common body spot)
  if(!RE_IFR.test(html)){
    if(html.includes('<!--#include file="partials/header.html" -->')){
      html = html.replace('<!--#include file="partials/header.html" -->',
        `<!--#include file="partials/header.html" -->\n${IFR_SNIPPET}\n`);
      changed = true;
    } else {
      // Fallback: before first <main>
      html = html.replace(/(<main[^>]*>)/i, `${IFR_SNIPPET}\n$1`);
      changed = true;
    }
  }

  if(changed) fs.writeFileSync(file, html);
}
console.log("GTM injected where missing.");
