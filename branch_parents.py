#!/usr/bin/env python3
"""
Infer the "base" (parent) branch for every branch in a git repo.

Sources of information, in order of trust:

1. REFLOG (exact, when available): git writes "branch: Created from X" to
   a branch's reflog when it's created -- this is exactly what
   `git checkout -b <new> <parent>` / `git switch -c <new> <parent>` records,
   so it's the ground truth answer to "which branch was this checked out
   from". Two wrinkles this script handles:
     - If no explicit parent was given (plain `git checkout -b feature`
       while sitting on the branch you meant to fork from), git records
       the literal word "HEAD" instead of the branch name. This script
       cross-references HEAD's own reflog (which separately logs
       "checkout: moving from <parent> to feature") to resolve it.
     - If the recorded source was a raw commit/tag, or a branch that's
       since been deleted or renamed, it's reported as such rather than
       silently guessed away.
   Reflog is local-only and expires (git gc, ~90 days by default), so it's
   often missing for old branches or ones that only exist on a remote.

2. KNOWN ROOT (--root): if you tell it which branch was created first,
   the rest are attached to the tree by growing outward from that root
   (and from anything reflog already confirmed) one branch at a time --
   always attaching a not-yet-placed branch to something already in the
   tree. This guarantees the result is a real tree with no cycles and no
   branch ever ending up as the parent of its own ancestor, which is a
   structural guarantee, not just a better guess.

3. MERGE-BASE HEURISTIC (fallback with no root given): guess each branch's
   parent independently by topological closeness. This has a real blind
   spot -- if a branch keeps committing after a child forks off it (very
   common), the graph alone can look identical whichever way the parent/
   child relationship actually runs, and no root anchor was provided to
   grow a cycle-free tree.

Even with a known root, one thing remains genuinely unsolvable from the
commit graph alone: if two branches fork from the *exact same commit* and
accumulate the *exact same number* of subsequent commits, nothing in the
graph distinguishes "sibling" from "parent of the other". Reflog is the
only way to resolve that; the script tries reflog before ever guessing.

Every result is tagged with its source ("reflog", "root", "heuristic", or
"none") so you know which entries to trust outright.

Usage:
    python branch_parents.py                        # local branches, no known root
    python branch_parents.py --root main             # anchor the tree at `main`
    python branch_parents.py --root main --remote    # include remote-tracking branches
    python branch_parents.py --repo /path/to/repo --root main
"""
import argparse
import subprocess
import sys


def run(cmd, cwd=None):
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{result.stderr.strip()}")
    return result.stdout.strip()


def get_branches(cwd, include_remote):
    refs = ["refs/heads/"]
    if include_remote:
        refs.append("refs/remotes/")
    out = run(["git", "for-each-ref", "--format=%(refname:short)", *refs], cwd=cwd)
    return [b for b in out.splitlines() if b and not b.endswith("/HEAD")]


def merge_base(cwd, b1, b2):
    try:
        return run(["git", "merge-base", b1, b2], cwd=cwd)
    except RuntimeError:
        return None  # no common ancestor (unrelated histories)


def commits_between(cwd, mb, tip):
    """Number of commits reachable from `tip` but not from `mb`. Topological,
    so unaffected by same-second commits, clock skew, or rewritten dates."""
    return int(run(["git", "rev-list", "--count", f"{mb}..{tip}"], cwd=cwd))


def get_tip(cwd, branch):
    return run(["git", "rev-parse", branch], cwd=cwd)


def resolve_head_checkout_source(cwd, branch, known_branches):
    """`git checkout -b feature` / `git switch -c feature` with NO explicit
    start point writes 'branch: Created from HEAD' to feature's own reflog
    -- literally the word HEAD, not the branch name you were actually on.
    To resolve it, HEAD's own reflog separately records
    'checkout: moving from <source> to feature' at the same moment, which
    does name the real source branch. Returns the resolved branch name, or
    None if it can't be resolved (HEAD's reflog missing/expired/rotated, or
    the recorded source isn't a currently-existing branch)."""
    try:
        out = run(["git", "reflog", "show", "HEAD"], cwd=cwd)
    except RuntimeError:
        return None
    prefix = "checkout: moving from "
    suffix = f" to {branch}"
    matches = []
    for line in out.splitlines():
        idx = line.find(prefix)
        if idx == -1:
            continue
        rest = line[idx + len(prefix):]
        if rest.endswith(suffix):
            matches.append(rest[: -len(suffix)])
    if not matches:
        return None
    oldest = matches[-1]  # reflog lists newest first; last = oldest = creation time
    return oldest if oldest in known_branches else None


def reflog_created_from(cwd, branch, known_branches):
    """Exact parent from this branch's reflog. Returns (source, status):
      status "confirmed"  -- resolved to a currently-existing branch, trust it
      status "external"   -- reflog is exact but points at something that
                              isn't a current branch (a raw SHA, tag, or a
                              branch that's since been deleted/renamed)
      status "missing"    -- no usable reflog entry at all (expired, never
                              existed locally, or this is a fresh clone)
    `source` is None unless status is "confirmed"."""
    try:
        out = run(["git", "reflog", "show", branch], cwd=cwd)
    except RuntimeError:
        return None, "missing"
    marker = "branch: Created from "
    for line in out.splitlines():
        idx = line.find(marker)
        if idx == -1:
            continue
        source = line[idx + len(marker):].strip()
        if source == "HEAD":
            resolved = resolve_head_checkout_source(cwd, branch, known_branches)
            return (resolved, "confirmed") if resolved else (None, "external")
        if source in known_branches and source != branch:
            return source, "confirmed"
        return None, "external"  # a SHA, tag, or a branch no longer around
    return None, "missing"


def grow_tree(cwd, branches, tips, seed_tree):
    """Attach every branch not already in `seed_tree` by repeatedly finding
    the (tree_member, outsider) pair with the smallest topological distance
    and adding the outsider as that tree member's child -- classic Prim's/
    MST-style growth. Because edges only ever go from an already-placed
    node to a not-yet-placed one, the result can never contain a cycle or
    make an existing tree member the child of something outside the tree,
    regardless of how the raw distances are tied or biased."""

    def divergence(x, y):
        """How many commits y has made since diverging from x. None if no
        common history; 0 if y hasn't diverged (y is upstream of x, or
        identical to it)."""
        mb = merge_base(cwd, y, x)
        if mb is None:
            return None
        return commits_between(cwd, mb, y)

    tree = set(seed_tree)
    remaining = [b for b in branches if b not in tree]
    attached_via = {}

    while remaining:
        best = None  # (distance, tree_member, outsider)
        for y in remaining:
            for x in tree:
                d = divergence(x, y)
                if d is None:
                    continue
                if d == 0 and tips[x] != tips[y]:
                    # y hasn't diverged from x at all -- y is upstream of x,
                    # not the other way around. x can't be y's parent.
                    continue
                if best is None or d < best[0]:
                    best = (d, x, y)
        if best is None:
            for y in remaining:
                attached_via[y] = None
            break
        _, x, y = best
        attached_via[y] = x
        tree.add(y)
        remaining.remove(y)

    return attached_via


def infer_base_branches(cwd, branches, root=None):
    known = set(branches)
    tips = {b: get_tip(cwd, b) for b in branches}

    result = {}
    if root is not None:
        if root not in known:
            raise ValueError(f"--root {root!r} is not one of this repo's branches")
        result[root] = {"base": None, "source": "root"}

    for b in branches:
        if b == root:
            continue
        rp, status = reflog_created_from(cwd, b, known)
        if status == "confirmed":
            result[b] = {"base": rp, "source": "reflog"}
        elif status == "external":
            # Reflog is exact but names something outside our branch set
            # (a raw commit, a tag, or a branch since deleted/renamed) --
            # don't guess a currently-existing branch in its place.
            result[b] = {"base": None, "source": "reflog-external"}

    if root is not None:
        # Grow the rest of the tree outward from {root} + reflog-confirmed
        # branches, so every remaining guess is checked against as much
        # real ground truth as possible, and can't ever loop back on it.
        seed = set(result.keys())
        grown = grow_tree(cwd, branches, tips, seed)
        for b, base in grown.items():
            result[b] = {"base": base, "source": "heuristic" if base else "none"}
    else:
        # No known root -- fall back to guessing everyone independently
        # (plain nearest-neighbor guess per branch). Can still produce
        # reversed edges for the reasons explained in the module docstring.
        for b in branches:
            if b in result:
                continue
            best_c, best_d = None, None
            for c in branches:
                if c == b:
                    continue
                mb = merge_base(cwd, b, c)
                if mb is None:
                    continue
                d = commits_between(cwd, mb, b)
                if d == 0 and tips[c] != tips[b]:
                    continue
                if best_d is None or d < best_d:
                    best_d, best_c = d, c
            result[b] = {"base": best_c, "source": "heuristic" if best_c else "none"}

    return result


def simple_dict(result):
    """Collapse the annotated result down to the plain {branch: base} dict."""
    return {b: v["base"] for b, v in result.items()}


def get_last_modified(cwd, branch):
    """Committer timestamp of the branch's tip commit -- always available
    (no reflog needed), used to order siblings for version numbering."""
    return int(run(["git", "log", "-1", "--format=%ct", branch], cwd=cwd))


def compute_versions(cwd, parent_of, root):
    """Assign a version string to every branch reachable from `root` via
    `parent_of` (the {branch: base_branch} dict), following:
      - root itself has no version (None).
      - root's direct children get bare integers: "1", "2", "3", ...
      - every other branch gets f"{version_of(parent)}.{subversion}".
      - within a sibling group, subversion order follows the branch's tip
        commit recency: oldest tip = subversion 1, most recently modified
        tip = the highest subversion number. Ties broken alphabetically for
        determinism.

    Returns (versions, unplaced):
      versions: {branch: version_str_or_None}, only for branches actually
                reachable from root (root itself included, mapped to None).
      unplaced: branches that have a `parent_of` entry but no path back to
                root (a dangling/external source, or -- in principle only,
                since the tree-growing construction shouldn't produce this
                -- a cycle).
    """
    children = {}
    for b, p in parent_of.items():
        if b == root or p is None:
            continue
        children.setdefault(p, []).append(b)

    tip_time_cache = {}

    def tip_time(b):
        if b not in tip_time_cache:
            tip_time_cache[b] = get_last_modified(cwd, b)
        return tip_time_cache[b]

    versions = {root: None}

    def assign(parent, ancestors):
        for i, kid in enumerate(sorted(children.get(parent, []), key=lambda b: (tip_time(b), b)), start=1):
            if kid in ancestors:
                continue  # defensive cycle guard; shouldn't occur in practice
            versions[kid] = str(i) if parent == root else f"{versions[parent]}.{i}"
            assign(kid, ancestors | {kid})

    assign(root, {root})

    unplaced = [b for b in parent_of if b not in versions]
    return versions, unplaced


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--repo", default=".", help="path to the git repo (default: current dir)")
    parser.add_argument("--remote", action="store_true", help="include remote-tracking branches too")
    parser.add_argument("--root", default=None, help="name of the branch known to have been created first")
    args = parser.parse_args()

    branches = get_branches(args.repo, args.remote)
    if not branches:
        print("No branches found.", file=sys.stderr)
        sys.exit(1)

    result = infer_base_branches(args.repo, branches, root=args.root)

    if args.root is None:
        # No known root -- version numbers aren't well-defined (nothing to
        # anchor "1, 2, 3..." at), so fall back to the diagnostic view.
        for branch, info in result.items():
            tag = {
                "reflog": "[confirmed]",
                "root": "[root]",
                "heuristic": "[guess]",
                "none": "[unknown]",
                "reflog-external": "[created from a commit/tag/deleted branch -- see reflog]",
            }[info["source"]]
            print(f"{branch!r}: {info['base']!r:35} {tag}")
        return

    parent_of = simple_dict(result)
    versions, unplaced = compute_versions(args.repo, parent_of, args.root)

    # Diagnostics go to stderr so stdout stays exactly in the requested
    # branch:parent_branch:branch_version format.
    guesses = [b for b in branches if result[b]["source"] == "heuristic"]
    if guesses:
        print(f"Note: parent was guessed (not confirmed by reflog) for: {', '.join(guesses)}", file=sys.stderr)
    if unplaced:
        print(f"Note: no path back to root, left unversioned: {', '.join(unplaced)}", file=sys.stderr)

    for branch in branches:
        parent = parent_of.get(branch) or ""
        version = versions.get(branch) or ""
        print(f"{branch}:{parent}:{version}")


if __name__ == "__main__":
    main()
