# The iPad app built with Xcode

This pass prepared the project for the app you will build with Xcode. It does
three things: it removes stalls an exported app has, it sets the export up
for speed and for signing, and it gives the build steps. The rules of the game
are untouched and every picture is the same as in the previous build, pixel
for pixel.

Most of it should help in Xogot as well. The rows about graphics programs,
sounds and the shot count apply there for certain. Whether the read-back rows
did depends on how Xogot runs the game, which I cannot see from here.

## What caused stalls, and what was done

| What you would see | Why | Now |
|---|---|---|
| A hitch the first time a sprite flashes white or is tinted (a hit, a chill) | The white silhouette was made by reading the whole sprite atlas back from the graphics chip. On a tablet that call waits until the chip has finished everything it was given | The silhouettes come ready-made in a file. Nothing is read back from the chip during play |
| The same the first time a piece of gear shows on the hero | Its colours were read from the atlas in the same way | Read from a copy kept in memory |
| A hitch at the first shot, the first ring, the first lightning bolt, the first glow | The graphics driver builds a program for each kind of drawing the first time that kind is drawn | Every kind is drawn once, invisibly, in the first two frames after launch (`scripts/render/warmup.gd`) |
| A hitch when the number of shots on screen reaches a value it has not had before | The count was part of how the shot batch was handed to the driver, so each new count could mean new set-up work. The software renderer used for the tests stalled at every new count; a graphics chip's driver may or may not | The batch always hands over the same number; the ones not in use are parked off screen |
| A small hiccup the first time each sound plays | Its file was opened at that moment | All 28 sounds and 7 music tracks are loaded at launch |
| A slow launch | At every launch each of the 837 small graphics was decoded, handed to the graphics chip and, on a tablet, read back from it, to pack the sprite atlas | The atlas is loaded ready-made (`assets/atlas/sprites.tbatlas`). The graphics' own files are still read, but only to check that the atlas was made from them; they are small (0.2 MB in all) |
| Godot's logo at launch | | A black screen until the title appears |

## Measured

On the machine the game is tested on: a release export, a software renderer
instead of a graphics chip, and an empty shader cache, which is what a first
launch is. The previous build against this one.

| | Before | Now |
|---|---|---|
| 25 s of play from a first launch: frames that took 40 ms or more | 11-12 in each of 3 runs (worst 142-163 ms) | none in 5 runs of 6; one frame of 42 ms in the sixth |
| Time lost to those stalls | 0.8 s | 0-0.03 s |
| 60 s with a new weapon every second: frames of 40 ms or more | 23 in each of 2 runs (worst 108-116 ms) | none in 4 runs of 5; one frame of 70 ms in the fifth |
| Time lost to those stalls | 1.3-1.5 s | 0-0.05 s |
| Graphics programs built in the middle of play | 1-2 | none |
| Atlas read back from the graphics chip during play (25 s / 60 s) | 8 / 19 times | never |
| Sounds opened in the middle of play (25 s / 60 s) | 16 / 21 | none |
| Loading the graphics at launch | 100-150 ms | about 50 ms |

The two stray frames in the new build came at a different moment in each run
and went with no drawing call that was slow. I take them for the test machine
(two processor cores, a software renderer), but I cannot rule out more.

45 more scenes were run the same way with every graphics call timed: 11
guardian fights, 8 rift worlds, the heavy fight, the title and 17 menu
screens, the touch controls, FAST DRAWING off, FANCY EFFECTS off, classic
mode, the Gaolbird, a melee fight and a normal run. After the third frame no
call that draws sprites, lines or shapes took over 12 ms in the new build. In
the previous build the three guardian fights I timed the same way had 2 to 6
such calls each, of 30 to 170 ms.

What the numbers do not say: how long each stall is on the iPad. Its graphics
chip is much faster than a software renderer at some of this and has its own
costs for the rest. The causes are the engine's and the driver's, so they are
there on the iPad too; their size there is not measured.

The price is at launch. The first frames now do the work that used to
interrupt the fights, while the screen is still black:

| Launch, from engine start to the third frame | Before | Now |
|---|---|---|
| First launch (empty shader cache) | 0.25-0.5 s | 1.0-1.1 s |
| Later launches | 0.13-0.27 s | 0.24-0.49 s |

That is with the software renderer, which is slow at exactly this work; a
graphics chip should need a fraction of it. "Later launches" are quicker
because this machine's driver keeps what it built. If the iPad's does not,
every launch there is like the first.

A release export also runs the game's scripts faster than Xogot can on the
same hardware. Xogot runs the game in an editor build of the engine. On this
desktop, in the heavy fight: 0.57 ms of rules a tick in the editor build,
0.43 ms in the release export (a quarter less), and 0.67 against 0.54 ms for
the script side of drawing.

## Building it

### On GitHub (what is used now)

The repository builds the IPA itself, on one of GitHub's Macs
(`.github/workflows/build-ipa.yml`). A build starts when a commit is pushed
whose message contains `[ipa]`, and takes about a minute and a half. The
result is `TinyBiggot.ipa` under Releases > "Tiny Biggot Rogues: latest iPad
build". It is not signed: SideStore signs it with your Apple ID when it
installs it.

The build imports the project, makes the sprite atlas from that import and
tests it, plays 20 seconds without a screen, exports the Xcode project with
the release engine, and builds it with Xcode.

### By hand on a Mac

Not tested: these are the usual steps for Godot 4.6 and Xcode.

1. On the Mac, install **Godot 4.6.1** (the standard build, the same version
   the project is made for) and Xcode. In Godot: Editor > Manage Export
   Templates > Download and Install. Needed once.
2. Open the project in Godot and wait for the import to finish.
3. Project > Export. The **iOS** preset is already in the project. You can
   change the bundle identifier. The team ID in it is a placeholder; the real
   one is chosen in Xcode in step 5.
4. Press **Export Project**, choose an empty folder, and switch **Export With
   Debug off** in the save dialog. Godot writes an Xcode project and stops
   there.
5. Open `TinyBiggot.xcodeproj` in Xcode. Select the TinyBiggot target >
   Signing & Capabilities. "Automatically manage signing" is already ticked;
   pick your team (the personal team of your Apple ID will do).
6. To try it straight away: connect the iPad, choose it at the top of the
   Xcode window and press Run. (The iPad needs Developer Mode on, as it does
   for SideStore.)
7. For an IPA for SideStore: choose "Any iOS Device (arm64)" as the
   destination, then Product > Archive. In the Organizer window right-click
   the archive > Show in Finder, right-click the `.xcarchive` > Show Package
   Contents, and open Products > Applications. Make a folder named `Payload`,
   copy `TinyBiggot.app` into it, compress the folder, and rename
   `Payload.zip` to `TinyBiggot.ipa`. SideStore signs it again with your
   Apple ID when it installs it.

Signing: Godot's own setting for a release export is the signing identity
"Apple Distribution", which only a paid developer account has, and Xcode then
refuses to sign automatically ("conflicting provisioning settings"). The
preset in this project asks for "Apple Development" instead, which is what a
free Apple ID and SideStore use. If Xcode still complains about the identity:
Build Settings > Signing > Code Signing Identity > Apple Development.

Godot prints one warning during the export, about `boot_splash/fullsize`. It
is the engine's own and harmless.

Optional, before step 3: `GODOT=/Applications/Godot.app/Contents/MacOS/Godot
tools/bake_atlas.sh` in Terminal, in the project folder. It remakes the
ready-made sprite atlas from the graphics as the Mac imported them (see "The
ready-made sprite atlas" below). Without it the app still shows the right
pictures; only its very first launch may be slower.

I can also export the Xcode project here and send it, so that only steps 5
to 7 are left. It is about 100 MB zipped. Say when you want it.

## What matters for speed

- **Export With Debug off** (step 4). This, not Xcode's build configuration,
  decides which engine goes into the app: Godot copies either its debug or its
  release engine library into the Xcode project. A debug export ran the
  rules about a quarter slower here.
- **Judge the speed with the app started from the Home Screen.** Started with
  Xcode's Run button the app has the debugger attached, which slows it down.
- The scheme in the exported project already uses the Release configuration
  for Run and for Archive (checked in the project exported here).
- **Game Mode.** The preset adds three lines to the app's Info.plist
  (`LSSupportsGameMode`, `GCSupportsGameMode`, and the app category "games").
  On iPadOS 18 and later the system then turns Game Mode on while the game is
  in front: it holds back background activity so that frames come more evenly.
  Older systems ignore the lines.
- **Low Power Mode off** when you judge the speed. It can slow the processor.

Left as it was: the Compatibility renderer (OpenGL ES 3). It is what the
game has been checked on in Xogot, and all the picture comparisons were made
with it.

## Seeing it on the iPad

OPTIONS > SHOW FPS has a new number at the end of its line: **WORST**, the
longest frame of the last second in milliseconds. 17 is a steady 60 frames a
second. 33 means one frame was missed. 50 and more is a hitch you can see.
The frame rate beside it is an average and hides single stalls; WORST does
not. (On an iPad with a 120 Hz screen the steady value can be 8. The iPad
Air's screen is 60 Hz.)

To compare with the previous build: start the game fresh, play the first
rooms, and watch WORST in the first seconds of each fight and at the first
use of each kind of weapon.

## The ready-made sprite atlas

`assets/atlas/sprites.tbatlas` holds the sprite atlas and the white
silhouettes. You do not have to look after it:

- It carries a fingerprint of the graphics it was made from: every graphic's
  name and the bytes of the file the engine imported it into. Every time the
  game starts it works the fingerprint out again and uses the file only if
  it fits. So a picture that is out of date is not shown.
- A file that is damaged or was cut short (an interrupted copy, a full disk)
  is turned down too. The file begins with a checksum of everything else in
  it, and the game uses nothing from it until that has been found right. It
  then carries on as if the file did not fit.
- If it does not fit (you added or redrew a graphic, or the iPad or the Mac
  stores imported graphics differently from my machine), the game packs the
  atlas from the separate graphics as it always did, and writes a fitting
  file for itself in its own data folder. That one start is slower than
  starts used to be: by 0.3 s on this desktop, and I expect about a second
  in Xogot, where scripts run about 4.5 times slower. The starts after it
  are quick again. This works the same in Xogot and in the app.
- `tools/bake_atlas.sh` remakes the file in the project. I run it before
  every delivery, and `tools/check.sh` fails if it is out of date.

Keeping the atlas's pixels in memory costs 16 MB of RAM.

## What I could not test

- **The iPad's graphics chip.** Everything above was measured with a software
  renderer. How long the launch warm-up takes on the iPad, and how much of
  each stall the iPad had, I do not know.
- **Installing with SideStore and running on the iPad.** The IPA is built
  and I have opened it: the app is for arm64 with the release engine, the
  Game Mode lines are in its Info.plist, and its resource pack runs in a
  desktop player with the same pictures. Whether SideStore installs it and
  the iPad runs it, I have not seen.
- **Signing in Xcode by hand.** The preset asks for "Apple Development".
  That Xcode accepts it with a free Apple ID is what its documentation and
  other people's reports say. The GitHub build does not sign at all.
- **Whether the atlas file fits in Xogot at once.** Xogot imports the
  graphics itself when it first opens the project. If it stores them
  differently from this machine, the first start there takes longer once (see
  above). On GitHub's Mac the import came out byte for byte the same as here,
  and the app's atlas is made from that import, so the app is not affected.
- **Game Mode.** The lines are the ones Apple documents. I have not seen the
  system react to them.
