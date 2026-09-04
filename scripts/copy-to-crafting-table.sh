#!/usr/bin/env bash
# Copy the staged build (./dist of this manager) into a frontend slot of
# the motoko-crafting-table, replacing whatever the slot held before.
#
# Usage: scripts/copy-to-crafting-table.sh [slot]     (default: frontend3)
#
# The slot must be an "assets" canister in the crafting table's dfx.json,
# so a typo can never wipe a backend slot or an unrelated directory.
set -euo pipefail

SLOT="${1:-frontend3}"
CRAFTING_TABLE="${MOTOKO_CRAFTING_TABLE:-$HOME/motoko-crafting-table}"
MANAGER_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$MANAGER_DIR/dist"
DEST="$CRAFTING_TABLE/$SLOT"

fail() { echo "copy-to-crafting-table: $*" >&2; exit 1; }

case "$SLOT" in
    *[!A-Za-z0-9_-]*) fail "bad slot name '$SLOT'" ;;
esac

[ -f "$SRC/index.html" ] || fail "$SRC/index.html not found — copy the web project's dist here first"
[ -f "$CRAFTING_TABLE/dfx.json" ] || fail "crafting table not found at $CRAFTING_TABLE"

node -e '
    const canister = require(process.argv[1]).canisters[process.argv[2]];
    process.exit(canister && canister.type === "assets" ? 0 : 1);
' "$CRAFTING_TABLE/dfx.json" "$SLOT" \
    || fail "'$SLOT' is not an assets canister in $CRAFTING_TABLE/dfx.json"

rm -rf "$DEST"
cp -r "$SRC" "$DEST"
echo "copy-to-crafting-table: dist -> $DEST"
