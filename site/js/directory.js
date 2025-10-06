(async function () {
  const q = document.getElementById("q");
  const list = document.getElementById("d");
  const selType = document.getElementById("f-type");
  const selRegion = document.getElementById("f-region");
  const res = await fetch("/data/directory.json", { cache: "no-store" });
  const all = await res.json();

  const uniq = (arr) => [...new Set(arr)].sort();

  function renderOptions() {
    const types = uniq(all.map(x=>x.type).filter(Boolean));
    const regs  = uniq(all.map(x=>x.region).filter(Boolean));
    selType.innerHTML  += types.map(t=>`<option>${t}</option>`).join("");
    selRegion.innerHTML+= regs.map(r=>`<option>${r}</option>`).join("");
  }

  function card(x) {
    return `
      <a class="card" href="${x.url}" target="_blank" rel="noopener">
        <strong>${x.name}</strong><br>
        <span class="badge">${x.type}</span>
        <span class="badge">${x.region}</span>
        ${x.country ? `<span class="badge">${x.country}</span>` : ""}
        <div style="margin-top:6px;color:#475569;font-size:.95rem;">
          ${(x.tags||[]).slice(0,3).map(t=>`#${t}`).join(" ")}
        </div>
      </a>`;
  }

  function applyFilters(items, term, type, region) {
    const t = (term||"").toLowerCase();
    return items.filter(x => {
      const inText = !t || [x.name,x.type,x.region,x.country,(x.tags||[]).join(" ")].join(" ").toLowerCase().includes(t);
      const okType = !type || x.type === type;
      const okReg  = !region || x.region === region;
      return inText && okType && okReg;
    });
  }

  function render(items) { list.innerHTML = items.map(card).join(""); }

  renderOptions();
  render(all);

  function update() { render(applyFilters(all, q?.value, selType?.value, selRegion?.value)); }

  q?.addEventListener("input", update);
  selType?.addEventListener("change", update);
  selRegion?.addEventListener("change", update);
})();
