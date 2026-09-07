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
