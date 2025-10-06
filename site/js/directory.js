(async function () {
  const q = document.getElementById("q");
  const list = document.getElementById("d");
  const res = await fetch("/data/directory.json", { cache: "no-store" });
  const all = await res.json();

  function render(items) {
    list.innerHTML = items.map(x => `
      <a class="card" href="${x.url}" target="_blank" rel="noopener">
        <strong>${x.name}</strong><br>
        <span class="badge">${x.type}</span>
        <span class="badge">${x.region}</span>
        ${x.country ? `<span class="badge">${x.country}</span>` : ""}
        <div style="margin-top:6px;color:#475569;font-size:.95rem;">
          ${x.tags?.slice(0,3).map(t=>`#${t}`).join(' ')}
        </div>
      </a>
    `).join("");
  }

  function filter(term) {
    const t = (term || "").trim().toLowerCase();
    if (!t) return all;
    return all.filter(x =>
      [x.name, x.type, x.region, x.country, ...(x.tags||[])].join(" ").toLowerCase().includes(t)
    );
  }

  render(all);
  q?.addEventListener("input", () => render(filter(q.value)));
})();
