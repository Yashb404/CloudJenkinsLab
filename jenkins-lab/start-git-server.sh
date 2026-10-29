#!/usr/bin/env bash
set -euo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd -- "${1:-$here/../festpass-java}" && pwd)"
port="${2:-9418}"
[[ "$port" =~ ^[0-9]+$ ]] && ((port >= 1024 && port <= 65535)) || { echo "Invalid port." >&2; exit 2; }
[[ -d "$repo/.git" ]] || { echo "Initialize the repository first." >&2; exit 1; }
git -C "$repo" rev-parse --verify HEAD
touch "$repo/.git/git-daemon-export-ok"
parent="$(dirname "$repo")"
name="$(basename "$repo")"
echo "Read-only repository URL: git://127.0.0.1:$port/$name"
echo "Keep this terminal open. Service binds only to this laptop."
exec git daemon --reuseaddr --verbose --listen=127.0.0.1 --port="$port" --base-path="$parent" "$repo"
