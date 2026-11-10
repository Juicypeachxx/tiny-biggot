#!/bin/bash
# usage: cprobe.sh <projdir> <home> [args after --]  -> one rendered run of the cache probe with the given HOME
S=/tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad
G=$S/godot/Godot_v4.6.1-stable_linux.x86_64
D=$1; H=$2; shift 2
mkdir -p $H
( cd $S/$D && HOME=$H XDG_DATA_HOME=$H/data XDG_CACHE_HOME=$H/cache xvfb-run -a -s "-screen 0 1344x864x24" timeout 120 $G --path . --rendering-driver opengl3 --audio-driver Dummy --quit-after 400 res://tests/cache_probe.tscn -- --perf "$@" 2>&1 | grep -E "^\[probe\]|^\[perf\] sprite|ERROR|WARNING|SCRIPT" | grep -v "V-Sync" )
