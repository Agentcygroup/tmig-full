fetch("/taxonomy.json").then(r => r.json()).then(d => {
  document.getElementById("status").textContent =
    `${d.count} tasks across ${d.families} families`;
}).catch(() => {
  document.getElementById("status").textContent = "taxonomy unavailable";
});
