# rog-control-center-x11-installer

A small helper script that builds and installs **ROG Control Center** (from
[asusctl](https://github.com/OpenGamingCollective/asusctl)) with **X11 support
enabled**, for use on X11-based desktop environments (e.g. XFCE) where the
officially packaged binary (built for Wayland) fails to launch.

This repo contains two scripts:

- `install-rog-control-center-x11.sh` — builds and installs everything.
- `uninstall-rog-control-center-x11.sh` — cleanly removes what the install
  script created (see [Uninstall](#uninstall) below).

Tested on **CachyOS + XFCE (X11)**. Should work on other Arch-based
distributions with minor adjustments to the package manager calls.

## What it does

1. Removes any previously installed `rog-control-center` / `rog-control-center-x11` packages.
2. Installs the required build dependencies (`base-devel`, `cmake`, `clang`, Slint/GUI libs, etc.).
3. Ensures a recent Rust toolchain via `rustup`.
4. Clones (or updates) the upstream source from
   [OpenGamingCollective/asusctl](https://github.com/OpenGamingCollective/asusctl).
5. Builds `rog-control-center` with `--features "rog-control-center/x11"`.
6. Installs the resulting binary to `/usr/local/bin/rog-control-center`.
7. Adds a `.desktop` entry so it shows up in your application menu.
8. Enables/restarts the `asusd` service and creates `/etc/asusd` if missing.
9. Launches the GUI briefly to verify it starts without crashing.

## Requirements

- An Arch-based distribution with `pacman` (developed/tested on CachyOS).
- `asusd`/`asusctl` daemon available in your repos.
- An ASUS ROG laptop supported by asusctl.
- Internet access (for `git clone`, `rustup`, and package downloads).

## Usage

```bash
chmod +x install-rog-control-center-x11.sh
./install-rog-control-center-x11.sh
```

The script will prompt for `sudo` when needed. Build logs are saved to
`~/rog-control-center-build.log` for troubleshooting.

## Uninstall

A companion script, `uninstall-rog-control-center-x11.sh`, removes everything
the install script created:

```bash
chmod +x uninstall-rog-control-center-x11.sh
./uninstall-rog-control-center-x11.sh
```

It removes:

- the installed binary (`/usr/local/bin/rog-control-center`)
- the icon (`/usr/share/icons/hicolor/512x512/apps/rog-control-center.png`)
- the `.desktop` menu entry
- the local source/build directory (`~/build-asusctl`)
- the build log file

It **deliberately leaves untouched**:

- the `asusd` service and the `asusctl`/`rog-control-center` distro
  packages, since these provide the actual hardware control (fans, power
  profiles, RGB, etc.) — removing them affects more than just this X11 GUI
  build. Instructions to remove them manually are printed at the end of
  the script if you want to go further.
- `rustup`/`cargo`, since it may be used by other projects on your system.
- build dependencies (`cmake`, `clang`, `mesa`, etc.), since they are
  commonly shared with other packages and removing them automatically
  could break unrelated software.

## Troubleshooting

If the build fails, check the log file and re-run with:

```bash
journalctl -u asusd -n 50 --no-pager
rog-control-center 2>&1 | head -n 50
```

Common issues are missing GUI/Slint dependencies or an outdated system Rust
compiler — both are handled by the script, but partial/interrupted runs can
sometimes leave things in an inconsistent state. Re-running the script is
generally safe (it cleans and re-clones the source directory).

## Disclaimer

- **X11 is officially unsupported by upstream asusctl/ROG Control Center.**
  The upstream project explicitly states that X11 integration is
  community-maintained and that they do not provide support for issues
  specific to X11. This script simply automates the documented
  `--features "rog-control-center/x11"` build flag — it does not add any
  functionality beyond what upstream already exposes.
- This script is provided **as-is, with no warranty of any kind**. It
  modifies system packages, installs software system-wide, and interacts
  with `systemd` services on your machine. Review the script before running
  it, especially if you are unfamiliar with shell scripts.
- The author(s) of this script are **not affiliated with** the asusctl /
  ROG Control Center / asus-linux project, ASUS, or OpenGamingCollective.
- Use at your own risk. Always make sure you have backups / a way to
  recover your system before running scripts that install software with
  root privileges.
- For anything related to hardware control bugs, kernel modules, or core
  `asusctl`/`asusd` functionality, please refer to the
  [upstream project](https://github.com/OpenGamingCollective/asusctl) —
  this repo only concerns the build/install convenience script for the
  X11 GUI variant.

## License

This script is released under the MIT License. See upstream
[asusctl](https://github.com/OpenGamingCollective/asusctl) for the license
of the software it builds.
