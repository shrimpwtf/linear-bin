#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -z ${AUR_SSH_KEY:-} ]]; then
  echo "AUR_SSH_KEY is not set; skipping AUR publish" >&2
  exit 0
fi

pinned='SHA256:RFzBCUItH9LZS0cKB5UE6ceAYhBD5C8GeOBip8Z11+4'
ssh_dir=$(mktemp -d)
work=$(mktemp -d)
trap 'rm -rf "$ssh_dir" "$work"' EXIT

umask 077
printf '%s\n' "$AUR_SSH_KEY" > "$ssh_dir/key"
ssh-keyscan -t ed25519 aur.archlinux.org > "$ssh_dir/known_hosts" 2>/dev/null
[[ $(ssh-keygen -lf "$ssh_dir/known_hosts" | cut -d' ' -f2) == "$pinned" ]] \
  || { echo "AUR host key fingerprint mismatch" >&2; exit 1; }
export GIT_SSH_COMMAND="ssh -i $ssh_dir/key -o IdentitiesOnly=yes -o UserKnownHostsFile=$ssh_dir/known_hosts -o StrictHostKeyChecking=yes"

git clone ssh://aur@aur.archlinux.org/linear-bin.git "$work/aur"
cp PKGBUILD .SRCINFO linear-desktop linear.desktop linear-chrome.main.js linear-chrome.preload.js "$work/aur/"

cd "$work/aur"
git add -A
if git diff --cached --quiet; then
  echo "AUR is already up to date"
  exit 0
fi
version=$(sed -n 's/^pkgver=//p' PKGBUILD)-$(sed -n 's/^pkgrel=//p' PKGBUILD)
git -c user.name="shrimp" -c user.email="james@shrimp.wtf" commit -m "Update to ${version}"
git push origin HEAD:master
