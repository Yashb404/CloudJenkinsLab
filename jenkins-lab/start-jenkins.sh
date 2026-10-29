#!/usr/bin/env bash
set -euo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
port="${1:-8080}"
[[ "$port" =~ ^[0-9]+$ ]] && ((port >= 1024 && port <= 65535)) || { echo "Invalid port." >&2; exit 2; }
command -v java >/dev/null
command -v javac >/dev/null
[[ -f "$here/downloads/jenkins.war" ]] || { echo "Run download-jenkins.sh first." >&2; exit 1; }
export JENKINS_HOME="$here/runtime/jenkins-home"
mkdir -p "$JENKINS_HOME"
echo "Open http://127.0.0.1:$port/ after startup. Keep this terminal open."
exec java -Xms128m -Xmx768m -jar "$here/downloads/jenkins.war" --httpListenAddress=127.0.0.1 --httpPort="$port"
