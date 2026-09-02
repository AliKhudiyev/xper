# xper — website

This branch holds the project site published at
<https://alikhudiyev.github.io/xper/> via GitHub Pages
(Settings → Pages → Deploy from a branch → `web` → `/ (root)`).

**The xper source code lives on [`main`](https://github.com/AliKhudiyev/xper/tree/main).**

## Layout

    index.html                     the whole page
    assets/style.css               all styling, light + dark
    assets/tree.js                 the Fig. 1 version-tree stepper
    assets/asciinema-player.*      vendored player, v3.8.0
    casts/                         .cast recordings (see below)

No build step and no dependencies — edit the files and push.

## Adding a demo recording

    asciinema rec casts/tree.cast

The page looks for `casts/tree.cast`, `casts/sort.cast` and `casts/finish.cast`.
Each demo shows a static transcript until its `.cast` file exists, then swaps in
the player automatically. Nothing else to wire up.

## Working on both branches at once

The two branches share no files, so switching with `git checkout` churns the whole
tree. Use a worktree instead:

    git worktree add ../xper-web web

## Local preview

    python3 -m http.server 8000
