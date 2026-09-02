/* Fig. 1 — the version tree.
   Steps a real xper session and reveals the matching node.
   Every command here is verified against the test suite on `main`. */
(function () {
  "use strict";

  var STEPS = [
    { cmd: "xper init",          note: "set up the experiment repo",        node: "base" },
    { cmd: "xper new --tag MLP", note: "v1",                                node: "v1"   },
    { edit: 1, cmd: "edit train.py", note: "try an idea" },
    { cmd: "xper new -y",        note: "v1.1 — build on v1",                node: "v11"  },
    { edit: 1, cmd: "edit train.py", note: "keep going" },
    { cmd: "xper new -y",        note: "v1.1.1 — build on that",            node: "v111" },
    { cmd: "xper jump v1.1",     note: "dead end, go back",                 node: "v11", jump: 1 },
    { edit: 1, cmd: "edit train.py", note: "a different idea" },
    { cmd: "xper new -y",        note: "v1.1.2 — same start, new direction", node: "v112" },
    { cmd: "xper new --scratch", note: "v2 — unrelated idea",              node: "v2"   }
  ];

  var list  = document.getElementById("tree-steps");
  var svg   = document.getElementById("tree-svg");
  var stage = document.getElementById("tree-fig");
  if (!list || !svg || !stage) return;

  var reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var timer = null;
  var items = [];

  /* build the step list */
  STEPS.forEach(function (s, i) {
    var li = document.createElement("li");
    if (s.edit) li.className = "is-edit";
    li.setAttribute("role", "button");
    li.setAttribute("tabindex", "0");

    var c = document.createElement("span");
    c.className = "s-cmd";
    c.textContent = s.cmd;
    li.appendChild(c);

    if (s.note) {
      var n = document.createElement("span");
      n.className = "s-note";
      n.textContent = s.note;
      li.appendChild(n);
    }

    function pick() { stop(); show(i); }
    li.addEventListener("click", pick);
    li.addEventListener("keydown", function (e) {
      if (e.key === "Enter" || e.key === " ") { e.preventDefault(); pick(); }
    });

    list.appendChild(li);
    items.push(li);
  });

  function show(idx) {
    var revealed = {};
    for (var j = 0; j <= idx; j++) {
      if (STEPS[j].node) revealed[STEPS[j].node] = 1;
    }
    var active = STEPS[idx].node;

    Array.prototype.forEach.call(svg.querySelectorAll(".node"), function (g) {
      var id = g.getAttribute("data-id");
      g.setAttribute("data-on", revealed[id] ? "1" : "0");
      g.setAttribute("data-active", id === active ? "1" : "0");
    });
    Array.prototype.forEach.call(svg.querySelectorAll(".edge"), function (e) {
      var id = e.getAttribute("data-to");
      e.setAttribute("data-on", revealed[id] ? "1" : "0");
    });

    items.forEach(function (li, j) {
      if (j <= idx) li.setAttribute("data-done", ""); else li.removeAttribute("data-done");
      if (j === idx) li.setAttribute("data-current", ""); else li.removeAttribute("data-current");
    });

    show.at = idx;
  }

  function stop() { if (timer) { clearInterval(timer); timer = null; } }

  function play() {
    stop();
    var i = 0;
    show(0);
    timer = setInterval(function () {
      i++;
      if (i >= STEPS.length) { stop(); return; }
      show(i);
    }, 950);
  }

  var replay = document.getElementById("tree-replay");
  if (replay) replay.addEventListener("click", play);

  /* final state up front for reduced motion; otherwise play once on first view */
  if (reduce) {
    show(STEPS.length - 1);
  } else {
    show(STEPS.length - 1);
    var seen = false;
    if ("IntersectionObserver" in window) {
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (en) {
          if (en.isIntersecting && !seen) { seen = true; play(); io.disconnect(); }
        });
      }, { threshold: 0.35 });
      io.observe(stage);
    }
  }
})();
