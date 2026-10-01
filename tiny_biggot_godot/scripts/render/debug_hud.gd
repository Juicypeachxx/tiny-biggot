extends Node2D
## TEMPORARY status overlay for play-testing stages 1-4. The real HUD
## (hearts, minimap, prompts, banners, boss bar) is ported in stage 6 and
## replaces this file.

func _draw() -> void:
	var p := G.player
	if p == null:
		return
	var need := GameData.xp_needed(p.level)
	var line := "HP %d/%d  ARMOR %d  POTIONS %d/%d  BOMBS %d  KEYS %d  GOLD %d  LV %d (%d/%d)" % [
		p.hp, p.max_hp, p.armor, p.potions, p.max_potions, p.bombs, p.keys, p.gold, p.level, p.xp, need]
	draw_rect(Rect2(0, 0, TB.SW, 9), Color(0.05, 0.04, 0.07, 0.7))
	Gfx.text(self, line, 3, 2, "white")
	var fl: Dictionary = GameData.FLOORS[G.floor_index]
	var info := "%s  ROOM %d/%d  %s  %s" % [fl["name"], G.floor_d.get("depth", 0) + 1, G.floor_d.get("total", 0),
		String(G.room.type).to_upper() if G.room != null else "", p.weapon["name"] if p.weapon != null else ""]
	Gfx.text(self, info, 3, 11, fl["accent"])
	if G.boss != null and G.boss.hp > 0:
		var w := 220.0
		var bx := (TB.SW - w) / 2
		var by := TB.SH - 12.0
		Gfx.panel(self, bx - 2, by - 2, w + 4, 8, "#8a2a33")
		draw_rect(Rect2(bx, by, w, 4), TB.c("#4e4a5e"))
		draw_rect(Rect2(bx, by, ceilf(w * G.boss.hp / G.boss.max_hp), 4), TB.c("#d8443c"))
		Gfx.text(self, G.boss.d["name"], TB.SW / 2, by - 9, "red", 1, 0.5)
	if not G.banner.is_empty():
		var a := clampf(G.banner["t"] * 2, 0.0, 1.0)
		Gfx.text(self, G.banner["text"], TB.SW / 2, 100, "gold", 2, 0.5, true, a)
		Gfx.text(self, G.banner["sub"], TB.SW / 2, 116, "bone", 1, 0.5, true, a)
	if not G.msg.is_empty():
		Gfx.text(self, G.msg["text"], TB.SW / 2, 245, G.msg["col"], 1, 0.5)
	match G.state:
		&"pause":
			draw_rect(Rect2(0, 0, TB.SW, TB.SH), Color(0.05, 0.04, 0.07, 0.8))
			Gfx.text(self, "PAUSED", TB.SW / 2, 120, "white", 2, 0.5)
			Gfx.text(self, "PRESS MENU OR USE TO RESUME", TB.SW / 2, 140, "grey", 1, 0.5)
		&"dead", &"win":
			draw_rect(Rect2(0, 0, TB.SW, TB.SH), Color(0.05, 0.04, 0.07, 0.85))
			Gfx.text(self, "VICTORY" if G.state == &"win" else "YOU DIED", TB.SW / 2, 100, "red" if G.state == &"dead" else "gold", 3, 0.5)
			if G.state == &"dead":
				Gfx.text(self, "SLAIN BY " + G.death_by, TB.SW / 2, 124, "bone", 1, 0.5)
			Gfx.text(self, "EMBERS EARNED: %d" % G.award.get("total", 0), TB.SW / 2, 138, "orange", 1, 0.5)
			if G.state_t > 1:
				Gfx.text(self, "PRESS USE TO START A NEW RUN", TB.SW / 2, 160, "grey", 1, 0.5)
