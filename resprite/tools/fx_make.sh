# Every effect strip in his bright look (22 Oct), from the SpriteCook sheets in
# resprite/spritecook/fx/ into resprite/hd/. Run from the top of the repo: bash resprite/tools/fx_make.sh
# Each line: the sheet, the density (1: the game's own size, 2: double detail), --grey for the strips
# the game colours itself, --clip to keep today's form exactly, then the grid the reference was made
# with (fx_ref.py, the same arguments).
set -e
F=resprite/spritecook/fx
T="python3 resprite/tools/fx_fit.py"
$T $F/bright_fx01.png 1 3 4 fx_blast_m_fire:9
$T $F/bright_fx02.png 1 2 4 --fill 0.89 fx_blast_l_fire:10@0-3
$T $F/bright_fx03.png 1 2 4 --fill 0.89 fx_blast_l_fire:10@4-7
$T $F/bright_fx05.png 2 3 4 fx_blast_s_fire:8
$T $F/bright_fx06.png 2 3 4 --fill 0.54 fx_shatter:7
$T $F/bright_fx07.png 2 4 4 --fill 0.89 fx_zap:5 fx_crit:5 fx_smoke:6
$T $F/bright_fx08.png 1 --grey --clip 4 4 --fill 0.56 fx_cast:4 fx_hit:4 fx_flare:4 fx_muzzle:3 fx_plus:1
$T $F/bright_fx09.png 1 --grey --clip 3 4 swing_slash:4 swing_slash_edge:4
$T $F/bright_fx10.png 1 --grey 3 4 --fill 0.95 swing_thrust:3 swing_whip:3 - - -
$T $F/bright_fx11.png 1 4 4 --fill 0.67 fx_flame:8 fx_flame_s:8
$T $F/bright_fx12.png 2 --clip 6 4 --fill 0.74 eb_red:4 eb_bone:4 eb_water:4 eb_ice:4 eb_spore:4 eb_dark:4 eb_fire:4 eb_cyan:4 eb_page:4
$T $F/bright_fx13.png 1 --clip 4 4 --fill 0.67 eb_redBig:4 eb_darkBig:4 eb_fireBig:4 eb_iceBig:4
$T $F/bright_fx14.png 1 --clip 6 4 --fill 0.87 orb_red:1 orb_redBig:1 orb_bone:1 orb_water:1 orb_ice:1 orb_iceBig:1 orb_spore:1 orb_dark:1 orb_darkBig:1 orb_fire:1 orb_fireBig:1 orb_cyan:1 orb_page:1 orb_clod:1 orb_flask:1 orb_gold:1 orb_hex:1 orb_hexBig:1 orb_moon:1 fx_skull:1 fx_weak:1 fx_mark:1 fx_star:2 fx_frost:2 fx_bubble:4 - - - - - -
$T $F/bright_fx15.png 2 3 4 --fill 0.9 fx_dust:5 fx_pool:1 fx_scorch:1 fx_rock:1
$T $F/bright_fx16.png 1 --grey --clip --under 3 4 fx_cut:4 slash_arc:1 - - - -
# Your shots: one weapon family (pyre, #2) drawn, into resprite/spritecook/fx/base/.
$T $F/bright_fx17.png 2 --clip 3 4 shot_hexBig:4#2 shot_whirl:2#2 shot_flask:1#2 shot_pellet:2#2
$T $F/bright_fx18.png 2 --clip 4 4 --fill 0.78 shot_hex:4#2 shot_pulse:4#2 shot_spark:4#2 shot_fire:4#2
$T $F/bright_fx19.png 2 --clip 2 4 shot_rail:2#2 shot_bolt:2#2
# The other colours of the explosions, the big one's last two frames, the bubble's first.
python3 resprite/tools/fx_recolour.py
# The dark rims of the foes' shots (35.3), round the new ones.
python3 resprite/tools/fx_rims.py
# Your shots in all seventeen weapon families.
python3 resprite/tools/fx_shots.py
