# The Windows build

His word, 12 Oct: "i want to setup windows build in windows-build". The branch `windows-build` is his
Windows build branch, next to `ios-build` (IPA 53 "Souls") and `claude/dev` (where the work happens).

- **Every push to `windows-build` builds the game for Windows** on one of GitHub's Linux machines
  (`.github/workflows/build-windows.yml`) and publishes it as two releases: `win-<version>` (kept) and
  `win-latest`. The download is `TinyBiggot-<version>-<Name>-Windows.zip`: `TinyBiggot.exe` (one file,
  the game inside) and a short `README.txt` (`WINDOWS_README.txt`).
- **To bring it up to date:** merge `claude/dev` into `windows-build` and push. The version and its name
  come from `VERSION` and `scripts/data/versions.gd`, as for the IPA.
- The export preset is "Windows" in `tiny_biggot_godot/export_presets.cfg` (64-bit, the game embedded
  in the .exe, the icon `windows_icon.ico` made from `ios_icon_1024.png`, its name in the file's
  details). The renderer is GL Compatibility, the same as on the iPad.
- To build it by hand: the Windows export template (`windows_release_x86_64.exe` from the 4.6.1
  templates) in `~/.local/share/godot/export_templates/4.6.1.stable/`, then
  `godot --headless --path tiny_biggot_godot --export-release "Windows" /tmp/TinyBiggot.exe`.
- Not tested by Claude: the game running on Windows (the cloud has no Windows machine). The export
  itself is checked: a 64-bit Windows program with the game's name and icon in it.
