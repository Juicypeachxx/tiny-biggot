#!/usr/bin/env bash
# Reads the version list, scripts/data/versions.gd (one version a line: "number|Name|tweak; tweak").
#   tools/versions.sh name 27     the name (Mythic Armory)
#   tools/versions.sh notes 27    the tweaks, a "- " line each
#   tools/versions.sh newest      the number of the first line (it must be the one in VERSION)
#   tools/versions.sh all         every number, newest first
# The IPA build uses it for the release's title and notes and the IPA's file name. Plain POSIX awk:
# the Mac's awk is not GNU's.
set -euo pipefail
FILE="$(cd "$(dirname "$0")/.." && pwd)/scripts/data/versions.gd"
awk -v cmd="${1:-all}" -v want="${2:-}" '
	match($0, /^[ \t]*"[^"]*"/) {
		s = substr($0, RSTART, RLENGTH)
		sub(/^[ \t]*"/, "", s)
		sub(/"$/, "", s)
		if (split(s, f, "|") != 3) next
		if (cmd == "all") { print f[1]; next }
		if (cmd == "newest") { print f[1]; exit }
		if (f[1] != want) next
		if (cmd == "name") print f[2]
		else if (cmd == "notes") { n = split(f[3], t, "; "); for (i = 1; i <= n; i++) print "- " t[i] }
		exit
	}' "$FILE"
