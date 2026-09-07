#!/usr/bin/env python3

import argparse
import subprocess
import sys, copy
import math


def run(cmd, cwd=None):
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{result.stderr.strip()}")
    return result.stdout.strip()


def get_branches(cwd, include_remote=False):
    branches = run(
            ["git", "branch", "--format", "%(refname:short)"], 
            cwd=cwd
    )
    return branches


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

def update_tree(tree, new_branch, cwd):
    bhash1, name1, v1, phash1, dist1 = new_branch
    # print(f"updating tree with {new_branch=}")
    if bhash1 in tree:
        # print(f"> already exists")
        return tree
    tree[bhash1] = [name1, v1, phash1, dist1]
    # print(f"tree overwritten with {bhash1=} {name1=} {v1=} {phash1=}")
    new_branches = []

    for bhash2, (name2, v2, phash2, dist) in tree.items():
        if bhash1 == bhash2: continue
        phash = run(["git", "merge-base", bhash1, bhash2], cwd=cwd)
        dist1 = int(
            run(["git", "rev-list", "--count", phash, bhash1], cwd=cwd))
        dist2 = int(
            run(["git", "rev-list", "--count", phash, bhash2], cwd=cwd))
        # print(f"{phash=} for {bhash1=} and {bhash2=}")
        # print(f"\t{dist=1} {dist2=}")
        pbranch = [phash, f"p_{name1}_{name2}", "", None, math.inf]
        # if pbranch[0] in tree:
        #     pbranch = [phash, *tree[pbranch[0]]]
        if pbranch not in new_branches:
            if (dist1 < tree[bhash1][3] or bhash1[0] == bhash1[2]) and phash != tree[bhash1][2]:
                tree[bhash1][2] = phash
                tree[bhash1][3] = dist1
            if (dist2 < tree[bhash2][3] or bhash2[0] == bhash2[2]) and phash != tree[bhash2][2]:
                tree[bhash2][2] = phash
                tree[bhash2][3] = dist2
            new_branches.append(pbranch)

    for branch in new_branches:
        # tree[branch[0]] = [branch[1], branch[2], branch[3]]
        # if branch[0] not in tree:
        update_tree(tree, branch, cwd=cwd)

    return tree

def infer_tree(branches, cwd):
    tree = {}

    for branch in branches:
        update_tree(tree, branch, cwd=cwd)

    return tree

def get_max_version(tree, prefix_version):
    # print(f"get_max_version {prefix_version=}")
    max_version = 0
    for bhash, (name, v, phash, dist) in tree.items():
        if v.startswith(prefix_version) and v != "":
            # print(f"unstripped {v=}")
            v = v[len(prefix_version)+1:]
            if v.startswith("."): v = v[1:]
            dot = v.find('.')
            if dot >= 0:
                v = v[:dot]
            # print(f"stripped {v=}")
            if v != "" and int(v) > max_version:
                max_version = int(v)
    return max_version

def compute_branch_version(tree, bhash):
    name, v, phash, dist = tree[bhash]
    # print(f"computing branch version for {bhash=} {name=} {v=} {phash=}")
    if v != "":
        # print(f"> {v=} already exists")
        return
    _, pv, _, _ = tree[phash]

    if bhash == phash:
        if v == "":
            max_version = get_max_version(tree, v)
        else:
            # TODO prefix_version must be up until last . in v
            max_version = get_max_version(tree, v)
        # print(f"[parent] {v=} {max_version=}")
        tree[bhash][1] = f"{max_version+1}"
    else:
        _, pv, _, _ = tree[phash]
        # print(f"[child] {bhash=} {name=} {v=} {phash=} {pv=}")
        compute_branch_version(tree, phash)
        _, pv, _, _ = tree[phash]
        max_version = get_max_version(tree, pv)
        # print(f"[child] {bhash=} {v=} {max_version=}")
        tree[bhash][1] = f"{pv}.{max_version+1}"

def compute_versions(tree):
    for bhash, (name, v, phash, dist) in tree.items():
        compute_branch_version(tree, bhash)
    return tree

def main():
    parser = argparse.ArgumentParser(
            description="argument parser", 
            formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--repo", default=".", help="path to the git repo (default: current dir)")
    parser.add_argument("--remote", action="store_true", help="include remote-tracking branches too")
    parser.add_argument("--root", default=None, help="name of the branch known to have been created first")
    args = parser.parse_args()

    cwd = None
    branches = get_branches(args.repo, args.remote)
    branches = branches.split('\n')
    branches = [
        [run(["git", "rev-parse", branch], cwd=cwd), 
         branch, "", None, math.inf]
        for branch in branches
    ]

    if not branches:
        print("No branches found.", file=sys.stderr)
        sys.exit(1)

    result = infer_tree(branches, cwd=cwd)
    # result = infer_base_branches(args.repo, branches, root=args.root)
    # print(branches)
    compute_versions(result)
    # print(len(branches), len(result))
    for bhash, (name, v, phash, dist) in result.items():
        # print(f"{bhash=}: {name=} {v=} {phash=} {dist=}")
        print(f"{v}:{name}:{result[phash][1]}:{result[phash][0]}:{bhash}")


if __name__ == "__main__":
    main()
