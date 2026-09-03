#!/usr/bin/env bash
#
# xper installer
#
#   ./install.sh                 install to ~/.local
#   ./install.sh --prefix DIR    install to DIR (DIR/bin, DIR/share)
#   ./install.sh --uninstall     remove a previous install
#
# No sudo. Nothing is written outside the prefix.
#
# Deliberately written for bash 3.2 so it runs on stock macOS.

set -eu

PROG="xper"
MIN_GIT="2.22"          # git branch --show-current

# ---------------------------------------------------------------- helpers

say()  { printf '%s\n' "$*"; }
warn() { printf '%s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

# version_ge A B -> true if A >= B, comparing dot-separated numbers.
# Avoids sort -V, which does not exist on macOS.
version_ge() {
    a_major=${1%%.*}; a_rest=${1#*.}; a_minor=${a_rest%%.*}
    b_major=${2%%.*}; b_rest=${2#*.}; b_minor=${b_rest%%.*}
    [ "$a_major" -gt "$b_major" ] && return 0
    [ "$a_major" -lt "$b_major" ] && return 1
    [ "$a_minor" -ge "$b_minor" ]
}

on_path() {
    case ":${PATH}:" in
        *":$1:"*) return 0 ;;
        *)        return 1 ;;
    esac
}

rc_file_hint() {
    case "${SHELL:-}" in
        */zsh)  printf '%s' "$HOME/.zshrc" ;;
        */bash) printf '%s' "$HOME/.bashrc" ;;
        *)      printf '%s' "$HOME/.profile" ;;
    esac
}

# ---------------------------------------------------------------- arguments

PREFIX="${XPER_PREFIX:-$HOME/.local}"
UNINSTALL=0

while [ $# -gt 0 ]; do
    case "$1" in
        --prefix)
            [ $# -ge 2 ] || die "--prefix needs a directory"
            PREFIX="$2"; shift 2 ;;
        --prefix=*)
            PREFIX="${1#--prefix=}"; shift ;;
        --uninstall)
            UNINSTALL=1; shift ;;
        -h|--help)
            sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)
            die "unknown option: $1 (try --help)" ;;
    esac
done

BIN_DIR="$PREFIX/bin"
LIBEXEC="$PREFIX/share/$PROG/libexec"
WRAPPER="$BIN_DIR/$PROG"

# ---------------------------------------------------------------- uninstall

if [ "$UNINSTALL" -eq 1 ]; then
    removed=0
    if [ -e "$WRAPPER" ]; then rm -f "$WRAPPER"; say "removed $WRAPPER"; removed=1; fi
    if [ -d "$PREFIX/share/$PROG" ]; then
        rm -rf "$PREFIX/share/$PROG"
        say "removed $PREFIX/share/$PROG"
        removed=1
    fi
    [ "$removed" -eq 0 ] && say "nothing to uninstall under $PREFIX"
    say "your experiment repos are untouched."
    exit 0
fi

# ---------------------------------------------------------------- source dir

# Resolve the directory holding this script, without readlink -f
# (GNU-only flag; missing on older macOS).
SRC_DIR=$(cd "$(dirname "$0")" && pwd)

# ---------------------------------------------------------------- preflight

# bash
bash_major=${BASH_VERSINFO[0]}
if [ "$bash_major" -lt 4 ]; then
    warn "note: this system's bash is ${BASH_VERSION%%(*} (macOS ships 3.2)."
    warn "      xper will run, but if you hit odd errors try: brew install bash"
fi

# git
command -v git >/dev/null 2>&1 || die "git is required but was not found on PATH."

git_version=$(git --version | awk '{print $3}')
if ! version_ge "$git_version" "$MIN_GIT"; then
    die "git $git_version found, but xper needs $MIN_GIT or newer."
fi

# git identity: xper derives branch names from it, so an empty value
# produces a broken repo at init time rather than a clear error.
git_user=$(git config --global user.name 2>/dev/null || true)
if [ -z "$git_user" ]; then
    die "git has no global user.name set. Fix with:
    git config --global user.name \"Your Name\""
fi

case "$git_user" in
    *[:~^?*\[\\]*)
        die "git user.name (\"$git_user\") contains characters that are not
       legal in a git branch name. xper builds branch names from it." ;;
esac

# ---------------------------------------------------------------- manifest

# Every helper xper.sh and its siblings invoke by bare name. A missing one
# does not fail at install time -- it fails mid-command, possibly after a
# commit has already been made. So check up front.
REQUIRED="
xper.sh
xper_acquire.sh
xper_backup.sh
xper_children.sh
xper_clean.sh
xper_ctx.sh
xper_delete.sh
xper_diff.sh
xper_finish.sh
xper_goto.sh
xper_goto_rel.sh
xper_index.sh
xper_init.sh
xper_locked.sh
xper_logfp.sh
xper_modify.sh
xper_new.sh
xper_owner.sh
xper_parent.sh
xper_release.sh
xper_remote.sh
xper_rootdir.sh
xper_save.sh
xper_sort.sh
xper_track.sh
xper_untrack.sh
xper_update.sh
xper_user.sh
xper_version.sh
"

missing=""
for f in $REQUIRED; do
    [ -f "$SRC_DIR/$f" ] || missing="$missing $f"
done

if [ -n "$missing" ]; then
    warn "error: these scripts are referenced by xper but not present in"
    warn "       $SRC_DIR:"
    for f in $missing; do warn "         $f"; done
    exit 1
fi

# ---------------------------------------------------------------- install

mkdir -p "$BIN_DIR" "$LIBEXEC"

# Clear the old libexec so helpers deleted upstream do not linger.
rm -rf "${LIBEXEC:?}"/*

count=0
for f in "$SRC_DIR"/xper*.sh; do
    [ -f "$f" ] || continue
    cp "$f" "$LIBEXEC/"
    chmod 0755 "$LIBEXEC/$(basename "$f")"
    count=$((count + 1))
done

# The wrapper is the only thing on PATH. It prepends libexec so that the
# helpers can keep calling each other by bare name, then hands off.
cat > "$WRAPPER" <<EOF
#!/usr/bin/env bash
# Generated by xper install.sh -- do not edit; re-run the installer instead.
set -euo pipefail

XPER_LIBEXEC="\${XPER_LIBEXEC:-$LIBEXEC}"

if [ ! -d "\$XPER_LIBEXEC" ]; then
    printf 'xper: library directory not found: %s\n' "\$XPER_LIBEXEC" >&2
    printf 'xper: reinstall, or set XPER_LIBEXEC to the right path.\n' >&2
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    printf 'xper: git is required but was not found on PATH.\n' >&2
    exit 1
fi

if [ -z "\$(git config --global user.name 2>/dev/null || true)" ]; then
    printf 'xper: git has no global user.name set.\n' >&2
    printf 'xper: xper names branches after you -- set one with:\n' >&2
    printf '        git config --global user.name "Your Name"\n' >&2
    exit 1
fi

PATH="\$XPER_LIBEXEC:\$PATH"
export PATH
exec xper.sh "\$@"
EOF

chmod 0755 "$WRAPPER"

# ---------------------------------------------------------------- report

say "installed $PROG ($count scripts)"
say "  command:  $WRAPPER"
say "  library:  $LIBEXEC"

if ! on_path "$BIN_DIR"; then
    say ""
    warn "$BIN_DIR is not on your PATH. Add it with:"
    warn ""
    warn "    echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> $(rc_file_hint)"
    warn ""
    warn "then open a new shell."
else
    say ""
    say "try:  xper help"
fi
