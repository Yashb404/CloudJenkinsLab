#!/usr/bin/env bash
set -euo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
port="${1:-8080}"
[[ "$port" =~ ^[0-9]+$ ]] && ((port >= 1024 && port <= 65535)) || { echo "Invalid port." >&2; exit 2; }
command -v java >/dev/null
command -v javac >/dev/null
url="http://127.0.0.1:$port/"
umask 077
mkdir -p "$here/runtime/agent-private" "$here/runtime/agent-work"
curl --fail --location "${url}jnlpJars/agent.jar" -o "$here/runtime/agent.jar"
secret_file="$(mktemp "$here/runtime/agent-private/secret.XXXXXX")"
trap 'rm -f -- "$secret_file"' EXIT
read -r -s -p "Paste the student-laptop node secret (input hidden): " secret
printf '\n'
[[ -n "$secret" ]] || { echo "Secret cannot be empty." >&2; exit 2; }
printf '%s' "$secret" > "$secret_file"
unset secret
echo "Connecting student-laptop agent. Keep this terminal open."
java -Xmx512m -jar "$here/runtime/agent.jar" -url "$url" -secret "@$secret_file" \
    -name student-laptop -webSocket -workDir "$here/runtime/agent-work"
