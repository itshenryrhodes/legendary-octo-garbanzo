(function(){
  const TAX_URL = "/wiki/_meta/taxonomy-full.json";
  async function pickFeaturedUrl(){
    try{
      const res = await fetch(TAX_URL, {cache:"no-cache"});
      if(!res.ok) throw new Error("HTTP " + res.status);
      const all = await res.json();
      const pool = (Array.isArray(all) ? all : []).filter(x =>
        x && Array.isArray(x.tags) && x.tags.map(String.toLowerCase).includes("featured") && typeof x.url === "string"
      );
      if(!pool.length) throw new Error("No featured items");
      const pick = pool[Math.floor(Math.random()*pool.length)];
      return pick.url;
    }catch(e){
      console.warn("[surprise] fallback due to:", e);
      return "/wiki/"; // safe fallback
    }
  }

  async function handleClick(ev){
    ev.preventDefault();
    const href = await pickFeaturedUrl();
    window.location.assign(href);
  }

  function wire(){
    const els = Array.from(document.querySelectorAll('[data-action="surprise"], #surprise'));
    els.forEach(el => {
      // If it's a link, leave href stable, we just intercept click
      el.addEventListener("click", handleClick, {passive:false});
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", wire);
  } else {
    wire();
  }
})();
