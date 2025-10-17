function(){
  try{
    var here = location.pathname.toLowerCase();
    var links = document.querySelectorAll('nav.nav a');
    links.forEach(function(a){
      var href = a.getAttribute('href')||'';
      if(!href) return;
      // normalize
      var p = href.toLowerCase();
      if (p.length>1 && p.endsWith('/')) p = p.slice(0,-1);
      var h = here; if (h.length>1 && h.endsWith('/')) h = h.slice(0,-1);
      if (p && p !== '/' && h.startsWith(p)) a.classList.add('is-active');
      if (p==='/' && h==='/') a.classList.add('is-active');
    });
  }catch(e){}
})();