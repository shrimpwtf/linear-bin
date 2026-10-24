#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

feed=$(curl -fsSL https://releases.linear.app/latest.yml)
latest=$(sed -n 's/^version: *//p' <<<"$feed" | head -n1)
[[ $latest =~ ^[0-9]+(\.[0-9]+)+$ ]] || { echo "unexpected version in feed: '$latest'" >&2; exit 1; }

current=$(sed -n 's/^pkgver=//p' PKGBUILD)
if [[ $latest == "$current" ]]; then
  echo "up to date ($current)"
  exit 0
fi
if [[ $(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -n1) != "$latest" ]]; then
  echo "feed ($latest) is older than packaged ($current); nothing to do"
  exit 0
fi

installer="Linear-Setup-${latest}.exe"
expected=$(sed -n 's/^sha512: *//p' <<<"$feed" | head -n1)
curl -fSL -o "$installer" "https://releases.linear.app/Linear%20Setup%20${latest}.exe"
actual=$(openssl dgst -sha512 -binary "$installer" | base64 -w0)
[[ $actual == "$expected" ]] || { echo "installer sha512 does not match latest.yml" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
7z x -y -o"$work/nsis" "$installer" '$PLUGINSDIR/app-64.7z' >/dev/null
7z x -y -o"$work/app" "$work/nsis/\$PLUGINSDIR/app-64.7z" Linear.exe >/dev/null
strings -n8 "$work/app/Linear.exe" > "$work/strings.txt"
electron=$(grep -m1 -oE 'Electron/[0-9]+' "$work/strings.txt" | cut -d/ -f2)
[[ $electron =~ ^[0-9]+$ ]] || { echo "could not detect bundled Electron version" >&2; exit 1; }

sed -i -E "s/^pkgver=.*/pkgver=${latest}/; s/^pkgrel=.*/pkgrel=1/; s/^_electron=.*/_electron=electron${electron}/" PKGBUILD
updpkgsums
makepkg --printsrcinfo > .SRCINFO
echo "updated ${current} -> ${latest} (electron${electron})"
