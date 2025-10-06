/**
 * Adds Google Tag Manager across /site/**/*.html (idempotent)
 */
const fs=require("fs"), path=require("path");
const ROOT="site";
const GTM_ID="GTM-NDKQRC3N";
const RE_JS = new RegExp(`googletagmanager\\.com\\/gtm\\.js\\?id=${GTM_ID}`);
const RE_IFR= new RegExp(`googletagmanager\\.com\\/ns\\.html\\?id=${GTM_ID}`);
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
function walk(dir, out=[]){
  for(const f of fs.readdirSync(dir)){
    const p=path.join(dir,f), st=fs.statSync(p);
    if(st.isDirectory()) walk(p,out);
    else if(p.endsWith(".html")) out.push(p);
  } return out;
}
for (const file of walk(ROOT)) {
  let html = fs.readFileSync(file,"utf8"), changed=false;
  if(!RE_JS.test(html)){
    html = html.replace(/(<meta\s+charset="[^"]*">\s*)/i, `$1${JS_SNIPPET}\n`);
    changed=true;
  }
  if(!RE_IFR.test(html)){
    if(html.includes('<!--#include file="partials/header.html" -->')){
      html = html.replace('<!--#include file="partials/header.html" -->',
        `<!--#include file="partials/header.html" -->\n${IFR_SNIPPET}\n`);
    } else {
      html = html.replace(/(<main[^>]*>)/i, `${IFR_SNIPPET}\n$1`);
    }
    changed=true;
  }
  if(changed) fs.writeFileSync(file, html);
}
console.log("GTM injected where missing.");
