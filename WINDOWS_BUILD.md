# The Windows build

His word, 12 Oct: "i want to setup windows build in windows-build", and "i want separate thing ios
and windows to work, soo if i work on multiplayer addon on windows it wont be pushed on ios".

## The three branches

- **`claude/dev`**: where the Claudes work, as before. The iPad builds are made from it (`[ipa]`).
- **`ios-build`**: the iOS line. Every iPad build moves it up to the version it was made from.
- **`windows-build`** (this branch): the Windows line. Everything from `claude/dev` comes here, and
  Windows-only work (say, multiplayer) is done here too. **It goes one way only: never merge
  `windows-build` into `claude/dev` or `ios-build`.**

## How it builds

- **Every iPad build also builds Windows.** After an iPad build on `claude/dev` succeeds, the same
  run (`build-ipa.yml` there, the job "windows") moves `ios-build` up to that commit, merges it into
  `windows-build`, pushes it and builds the Windows game from the result. If the merge clashes with
  Windows-only work, that job stops and says so: a Claude merges `claude/dev` into `windows-build` by
  hand and pushes.
- **Every push to `windows-build` builds Windows too** (`.github/workflows/build-windows.yml`), for
  Windows-only work.
- Both use `tiny_biggot_godot/tools/build_windows.sh`: import, the sprite atlas, 20 s of play without
  a screen, the export and the package, then two releases: `win-<version>` (kept) and `win-latest`.
  The download is `TinyBiggot-<version>-<Name>-Windows.zip`: `TinyBiggot.exe` (one file, the game
  inside) and a short `README.txt` (`WINDOWS_README.txt`). The version and its name come from
  `VERSION` and `scripts/data/versions.gd`, as for the IPA.
- The export preset is "Windows" in `tiny_biggot_godot/export_presets.cfg` (64-bit, the game embedded
  in the .exe, the icon `windows_icon.ico` made from `ios_icon_1024.png`, its name in the file's
  details). The renderer is GL Compatibility, the same as on the iPad. It lives only on this branch.
- To build by hand: `PUBLISH=0 bash tiny_biggot_godot/tools/build_windows.sh` from the top of the
  repo (Godot in `~/godot/godot` and the Windows template are fetched when missing).
- Couch co-op for up to 4 players lives only here: COOP_PLAN.md (CO-OP on the title).
- The automatic way was first used for IPA 55 (12 Oct): the iPad build, then `ios-build` moved up,
  `windows-build` took in Stage 55 and Windows 55 was published, all in one run.
- Not tested by Claude: the game running on Windows (the cloud has no Windows machine). The export
  itself is checked: a 64-bit Windows program with the game's name and icon in it.
