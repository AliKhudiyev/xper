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

  /* ------------------------------------------------------------------ *
   * Fig. 2 - supervisional mode: the write key changing hands.
   * Verified end to end with two users against a shared remote.
   * ------------------------------------------------------------------ */
  var SEQ = [
    { who:"ali",  cmd:"xper new -sl -y",          note:"v2.1, in supervisional mode",  key:"",     ali:"lock" },
    { who:"ali",  cmd:'echo "hello world" > text', note:"nobody holds the key yet",     key:"",     ali:"lock", denied:1 },
    { who:"ali",  cmd:"xper acquire",              note:"Ali takes the key",            key:"Ali",  ali:"open" },
    { who:"anne", cmd:"xper update -g",            note:"pull every version",           key:"Ali",  anne:"lock" },
    { who:"anne", cmd:"xper jump v2.1 -u Ali",     note:"same branch, read-only",       key:"Ali",  anne:"lock" },
    { who:"anne", cmd:"xper acquire",              note:"Ali has not released it",      key:"Ali",  anne:"lock", denied:1 },
    { who:"ali",  cmd:'echo "hello world" > text', note:"fine, Ali holds the key",      key:"Ali",  ali:"open" },
    { who:"ali",  cmd:"xper backup",               note:"push the work",                key:"Ali",  ali:"open" },
    { who:"ali",  cmd:"xper release",              note:"the key goes back",            key:"",     ali:"lock" },
    { who:"ali",  cmd:'echo "hello" > text',       note:"locked again",                 key:"",     ali:"lock", denied:1 },
    { who:"anne", cmd:"xper acquire",              note:"now Anne can take it",         key:"Anne", anne:"open" },
    { who:"anne", cmd:'echo "bye" > text',         note:"Anne's turn",                  key:"Anne", anne:"open" },
    { who:"anne", cmd:"xper release",              note:"and hands it back",            key:"",     anne:"lock" }
  ];

  var seqFig = document.getElementById("seq-fig");
  if (seqFig) (function () {
    var bodies = { ali: document.getElementById("lane-ali-body"),
                   anne: document.getElementById("lane-anne-body") };
    var lanes  = { ali: document.getElementById("lane-ali"),
                   anne: document.getElementById("lane-anne") };
    var holder = document.getElementById("seq-holder");
    var keybar = document.getElementById("seq-keybar");
    var seqTimer = null;
    var rows = [];

    SEQ.forEach(function (st, i) {
      var el = document.createElement("span");
      el.className = "line" + (st.denied ? " denied" : "");
      el.setAttribute("data-on", "0");
      var c = document.createElement("span");
      c.className = "lc"; c.textContent = st.cmd; el.appendChild(c);
      if (st.note) {
        var n = document.createElement("span");
        n.className = "ln"; n.textContent = st.note; el.appendChild(n);
      }
      bodies[st.who].appendChild(el);
      rows.push(el);
    });

    function seqShow(idx) {
      var key = "", aliLock = "lock", anneLock = "lock", anneSeen = false;
      for (var j = 0; j <= idx; j++) {
        var st = SEQ[j];
        key = st.key;
        if (st.ali)  aliLock  = st.ali;
        if (st.anne) { anneLock = st.anne; anneSeen = true; }
        if (st.who === "anne") anneSeen = true;
      }
      rows.forEach(function (el, j) {
        el.setAttribute("data-on", j <= idx ? "1" : "0");
        el.setAttribute("data-current", j === idx ? "1" : "0");
      });
      lanes.ali.setAttribute("data-lock", aliLock);
      lanes.anne.setAttribute("data-lock", anneLock);
      if (anneSeen) lanes.anne.removeAttribute("data-absent");
      else lanes.anne.setAttribute("data-absent", "1");
      holder.textContent = key || "no one";
      holder.setAttribute("data-held", key ? "1" : "0");
      keybar.setAttribute("data-held", key ? "1" : "0");
    }

    function seqStop() { if (seqTimer) { clearInterval(seqTimer); seqTimer = null; } }
    function seqPlay() {
      seqStop();
      var i = 0; seqShow(0);
      seqTimer = setInterval(function () {
        i++;
        if (i >= SEQ.length) { seqStop(); return; }
        seqShow(i);
      }, 1000);
    }

    var sr = document.getElementById("seq-replay");
    if (sr) sr.addEventListener("click", seqPlay);
    seqShow(SEQ.length - 1);

    /* ---- mode switch ---- */
    var bN = document.getElementById("mode-normal-btn");
    var bS = document.getElementById("mode-seq-btn");
    var pN = document.getElementById("mode-normal");
    var pS = document.getElementById("mode-seq");
    var seqPlayed = false;

    function pick(seqMode) {
      bN.setAttribute("aria-pressed", seqMode ? "false" : "true");
      bS.setAttribute("aria-pressed", seqMode ? "true" : "false");
      pN.hidden = seqMode;
      pS.hidden = !seqMode;
      if (seqMode) {
        stop();
        if (!reduce && !seqPlayed) { seqPlayed = true; seqPlay(); }
      } else {
        seqStop();
      }
    }
    bN.addEventListener("click", function () { pick(false); });
    bS.addEventListener("click", function () { pick(true); });
  })();
})();
