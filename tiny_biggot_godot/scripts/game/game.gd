extends Node
## Game state and run flow (port of Game.rb CCGame). Autoload name: G.
## Stage 1: only the boot state; later stages fill in the run.

var state: StringName = &"title"
var time := 0.0

func update(dt: float) -> void:
	time += dt
