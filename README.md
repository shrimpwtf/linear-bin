# linear-bin

[Linear](https://linear.app)'s desktop client for Arch Linux, packaged for the AUR.

Linear publishes no Linux build, but its Electron app is pure JavaScript. This package takes
`app.asar` from the official Windows installer and runs it on the system `electronNN` package,
so Electron/Chromium security fixes arrive through pacman.

```
yay -S linear-bin        # or: git clone https://aur.archlinux.org/linear-bin.git && makepkg -si
```

## What it changes

- The native titlebar is removed on Linux and replaced by minimize/maximize/close controls
  styled to match Linear (`linear-chrome.*.js`, appended to the app at build time).
- The window is matched to `linear.desktop`, so shells show Linear's icon.
- The launcher reads extra Electron flags from `~/.config/linear-flags.conf` and sends a
  notification when a newer release exists than the one installed.

## Updates

A GitHub Actions workflow runs every three hours. When `releases.linear.app/latest.yml`
announces a newer version it verifies the installer against the published sha512, detects
the Electron major bundled in the release, bumps `PKGBUILD`, test-builds the package in an
Arch container, commits the bump here and pushes it to the AUR. A failed build publishes
nothing.

The workflow needs one repository secret, `AUR_SSH_KEY`: a private SSH key whose public half
is on the AUR account that maintains the package.

Linear is proprietary software. Nothing from Linear is redistributed here; the installer is
downloaded from Linear at build time.
