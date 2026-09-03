#!/usr/bin/env bash
# ~/.local/bin/xper
set -euo pipefail
XPER_LIBEXEC="${XPER_LIBEXEC:-$HOME/.local/share/xper/libexec}"
PATH="$XPER_LIBEXEC:$PATH"
export PATH
exec xper.sh "$@"
