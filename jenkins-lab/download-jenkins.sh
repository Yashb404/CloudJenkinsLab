#!/usr/bin/env bash
set -euo pipefail
version="${1:-2.580.1}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Use an LTS version." >&2; exit 2; }
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$here/downloads"
base="https://get.jenkins.io/war-stable/$version"
curl --fail --location "$base/jenkins.war.sha256" -o "$here/downloads/jenkins.war.sha256"
curl --fail --location "$base/jenkins.war" -o "$here/downloads/jenkins.war.download"
expected="$(awk '{print $1}' "$here/downloads/jenkins.war.sha256" | tr -d '\r\n')"
[[ "$expected" =~ ^[0-9a-fA-F]{64}$ ]] || { echo "Invalid checksum response." >&2; exit 1; }
if command -v sha256sum >/dev/null; then
    actual="$(sha256sum "$here/downloads/jenkins.war.download" | awk '{print $1}')"
else
    actual="$(shasum -a 256 "$here/downloads/jenkins.war.download" | awk '{print $1}')"
fi
[[ "$actual" == "$expected" ]] || { echo "Checksum mismatch; do not run this download." >&2; exit 1; }
mv "$here/downloads/jenkins.war.download" "$here/downloads/jenkins.war"
printf '%s\n' "$version" > "$here/downloads/jenkins-version.txt"
echo "Downloaded and SHA-256 verified Jenkins LTS $version."
