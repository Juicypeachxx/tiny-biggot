#!/usr/bin/env bash
# The Windows build (his word, 12 Oct; WINDOWS_BUILD.md). Run from the top of the repo on a Linux
# machine, on the branch windows-build. Imports the project, plays 20 s without a screen, exports
# TinyBiggot.exe (64-bit, the game inside), packs build/TinyBiggot-<V>-<Name>-Windows.zip with its
# README and publishes it as the releases win-<V> (kept) and win-latest (needs GH_TOKEN; PUBLISH=0
# skips it). Godot and its Windows template are fetched into ~/godot and
# ~/.local/share/godot/export_templates when missing (the workflows keep them in a cache).
# Used by .github/workflows/build-windows.yml (a push to windows-build) and by the iPad build on
# claude/dev (build-ipa.yml: every iPad build is taken into windows-build and built here).
set -euo pipefail
PROJECT=tiny_biggot_godot
GODOT_RELEASE=4.6.1-stable
TEMPLATES=4.6.1.stable
G="$HOME/godot/godot"
T="$HOME/.local/share/godot/export_templates/$TEMPLATES"

# The version (the file VERSION) and its name (scripts/data/versions.gd).
V=$(tr -d '[:space:]' < VERSION)
NAME=$(bash "$PROJECT/tools/versions.sh" name "$V")
if [ -z "$NAME" ] || [ "$(bash "$PROJECT/tools/versions.sh" newest)" != "$V" ]; then
  echo "::error::Version $V needs its line (number|Name|tweak; tweak) at the top of scripts/data/versions.gd"
  exit 1
fi
# (not called ZIP: zip reads a variable of that name as its own options)
PACKAGE="TinyBiggot-$V-$(printf '%s' "$NAME" | tr -cs 'A-Za-z0-9' '-')-Windows.zip"
SHA=$(git rev-parse HEAD)
echo "Version $V: $NAME, commit $SHA"
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "PACKAGE=$PACKAGE" >> "$GITHUB_ENV"
fi

# Godot and the Windows export template.
if [ ! -x "$G" ]; then
  BASE="https://github.com/godotengine/godot/releases/download/$GODOT_RELEASE"
  mkdir -p "$HOME/godot"
  curl -fsSL --retry 3 -o "$HOME/godot/godot.zip" "$BASE/Godot_v${GODOT_RELEASE}_linux.x86_64.zip"
  unzip -q -o "$HOME/godot/godot.zip" -d "$HOME/godot"
  mv "$HOME/godot/Godot_v${GODOT_RELEASE}_linux.x86_64" "$G"
  rm "$HOME/godot/godot.zip"
fi
if [ ! -s "$T/windows_release_x86_64.exe" ]; then
  BASE="https://github.com/godotengine/godot/releases/download/$GODOT_RELEASE"
  mkdir -p "$T"
  curl -fsSL --retry 3 -o "$HOME/godot/templates.tpz" "$BASE/Godot_v${GODOT_RELEASE}_export_templates.tpz"
  unzip -q -o -j "$HOME/godot/templates.tpz" templates/windows_release_x86_64.exe templates/version.txt -d "$T"
  rm "$HOME/godot/templates.tpz"
fi
"$G" --version

# Import, the sprite atlas from this import, twenty seconds of play without a screen.
mkdir -p build/win
"$G" --headless --path "$PROJECT" --import > build/import.log 2>&1 || true
"$G" --headless --path "$PROJECT" --import >> build/import.log 2>&1
tail -n 3 build/import.log
GODOT="$G" bash "$PROJECT/tools/bake_atlas.sh"
"$G" --headless --path "$PROJECT" --fixed-fps 60 --quit-after 1200 -- --no-save --bot --smart-bot --god --seed=6 --hero=2 --room=elite > build/smoke.log 2>&1 || true
grep "\[bot\]" build/smoke.log | tail -n 1
if grep -E "SCRIPT ERROR|Parse Error|ERROR:" build/smoke.log; then exit 1; fi

# Export: one .exe with the game inside (the preset "Windows" in export_presets.cfg).
"$G" --headless --path "$PROJECT" --export-release "Windows" "$PWD/build/win/TinyBiggot.exe" > build/export.log 2>&1 || true
grep -E "ERROR|WARNING" build/export.log | sort | uniq -c | head -n 20 || true
test -s build/win/TinyBiggot.exe
file build/win/TinyBiggot.exe

# The package: the game and its README.
sed -e "s|@VERSION@|$V|" -e "s|@NAME@|$NAME|" WINDOWS_README.txt > build/win/README.txt
zip -q -9 -j "$PWD/build/$PACKAGE" build/win/TinyBiggot.exe build/win/README.txt
ls -la "build/$PACKAGE"
unzip -l "build/$PACKAGE"

if [ "${PUBLISH:-1}" != 1 ]; then
  exit 0
fi
# Two releases: win-latest (always the newest) and win-<V> (kept). A rebuild of the same version
# replaces it. The tags are moved, never deleted (as the iPad build does).
BODY="$(bash "$PROJECT/tools/versions.sh" notes "$V")

On Windows only: couch CO-OP for up to 4 players (CO-OP on the title screen; keyboard and mouse or a controller each; how to play together is in README.txt in the zip).

Version $V: $NAME, for Windows (64-bit). Built from commit $SHA. Unzip it and double-click TinyBiggot.exe. Windows may say it protected your PC, because the game is not signed: press More info, then Run anyway."
publish() {
  local tag="$1" title="$2"
  gh release delete "$tag" --yes || true
  git tag -f "$tag" "$SHA"
  git push -f origin "refs/tags/$tag"
  gh release create "$tag" "build/$PACKAGE" --verify-tag --prerelease --title "$title" --notes "$BODY"
  sleep 5
  if [ "$(gh release view "$tag" --json isDraft -q .isDraft)" != "false" ]; then
    gh release edit "$tag" --draft=false
  fi
  gh release view "$tag" --json tagName,isDraft,assets -q '.tagName + " draft=" + (.isDraft|tostring) + " " + (.assets|map(.name)|join(","))'
}
publish "win-$V" "Tiny Biggot Rogues $V: $NAME (Windows)"
publish win-latest "Tiny Biggot Rogues: latest Windows build ($V: $NAME)"
