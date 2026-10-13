# Cinder Crypt - rendering with RGSS sprites (world, HUD, menus).

ROOM_COL = { "boss" => "#d8443c", "treasure" => "#f2c94c", "shop" => "#63b84f", "shrine" => "#a35bd6", "combat" => "#8b8f9c", "elite" => "#d8443c", "rest" => "#e8873a",
             "vault" => "#e8873a", "secret" => "#e86fb4", "challenge" => "#6fd3e0" }

class SpritePool
  def initialize(vp, z = 0, blend = 0)
    @vp = vp; @z = z; @blend = blend; @list = []; @n = 0
  end
  def start; @n = 0; end
  def get(bmp, x = 0, y = 0)
    s = @list[@n]
    unless s
      s = Sprite.new(@vp)
      s.blend_type = @blend
      @list << s
    end
    @n += 1
    s.bitmap = bmp
    s.visible = true; s.opacity = 255; s.zoom_x = 1.0; s.zoom_y = 1.0; s.mirror = false; s.angle = 0
    s.color.set(0, 0, 0, 0); s.ox = 0; s.oy = 0; s.z = @z
    s.x = x.round; s.y = y.round
    s
  end
  def finish; (@n...@list.size).each { |i| @list[i].visible = false }; end
  def hide_all; start; finish; end
end

class Renderer
  def initialize
    @vw = Viewport.new(0, 0, SW, SH); @vw.z = 0
    @vh = Viewport.new(0, 0, SW, SH); @vh.z = 100
    @vt = Viewport.new(0, 0, SW, SH); @vt.z = 200
    @bg = Sprite.new(@vw); @bg.z = 0
    @dyn = Sprite.new(@vw); @dyn.z = 1; @dyn.bitmap = Bitmap.new(SW, SH)
    @vig = Sprite.new(@vw); @vig.z = 2500; @vig.bitmap = Img["vignette"]
    @torch = [0, 1].map { |i| s = Sprite.new(@vw); s.bitmap = Img["torch"]; s.z = 2; s.x = [6, 21][i] * TS + 5; s.y = TS + 1; s }
    @tglow = [0, 1].map { |i| s = Sprite.new(@vw); s.bitmap = Img["glow_torch"]; s.blend_type = 1; s.z = 1900; s.x = [6, 21][i] * TS + 8 - 36; s.y = TS + 4 - 36; s }
    @shadows = SpritePool.new(@vw, 4)
    @objs = SpritePool.new(@vw, 6)
    @ents = SpritePool.new(@vw, 100)
    @fx = SpritePool.new(@vw, 1800)
    @bul = SpritePool.new(@vw, 2000)
    @glow = SpritePool.new(@vw, 1900, 1)
    @txt = SpritePool.new(@vw, 3000)
    @hud = Sprite.new(@vh); @hud.bitmap = Bitmap.new(SW, SH)
    @banner = Sprite.new(@vh); @banner.z = 50; @banner.bitmap = Bitmap.new(SW, 40); @banner.y = 96
    @touch = SpritePool.new(@vh, 60)
    @over = Sprite.new(@vt); @over.bitmap = Bitmap.new(SW, SH)
    @menu = SpritePool.new(@vt, 10)
    @menu_glow = SpritePool.new(@vt, 5, 1)
    @hud_sig = nil; @banner_sig = nil
    @c_white = Color.new(255, 255, 255, 255)
    @c_ice = Color.new(111, 211, 224, 130)
    @dark = hex_color("#0d0a12")
  end

  def room_changed; @hud_sig = nil; end

  def draw
    g = $G
    world = [:play, :pause, :relics, :choice, :traits, :traitlist, :gearpage].include?(g.state) || (g.state == :options && g.opt_from == :pause)
    world = false if g.room.nil?
    if world then draw_world; draw_hud else hide_world end
    draw_overlay(world)
    a = 0
    if g.fade then a = g.fade[:phase] == :out ? g.fade[:t] : 1 - g.fade[:t] end
    Graphics.brightness = (255 * (1 - clampf(a, 0, 1))).round
  end

  def hide_world
    [@bg, @dyn, @vig, @hud, @banner].each { |s| s.visible = false }
    (@torch + @tglow).each { |s| s.visible = false }
    [@shadows, @objs, @ents, @fx, @bul, @glow, @txt, @touch].each { |p| p.hide_all }
  end

  # ---------- World ----------
  def draw_world
    g = $G; room = g.room; p = g.player; t = g.time
    [@bg, @dyn, @vig, @hud].each { |s| s.visible = true }
    (@torch + @tglow).each { |s| s.visible = true }
    sh = g.shake
    @vw.ox = sh > 0 ? ((rnd - 0.5) * sh).round : 0
    @vw.oy = sh > 0 ? ((rnd - 0.5) * sh).round : 0
    @bg.bitmap = room[:bg]
    redraw_dyn if g.dyn_dirty
    @tglow.each_with_index { |s, i| s.opacity = (200 + Math.sin(t * 9 + i * 7) * 25 + Math.sin(t * 23 + i) * 15).round }
    [@shadows, @objs, @ents, @fx, @bul, @glow, @txt].each { |pl| pl.start }

    # Room objects.
    room[:objects].each do |o|
      next if o[:gone]
      bob = (Math.sin(t * 3 + o[:x]) * 1.5).round
      case o[:kind]
      when :chest
        shadow(o[:x], o[:y] + 4, 12)
        sp(@objs, o[:opened] ? "chestOpen" : "chest", o[:x], o[:y] + 4)
        unless o[:opened] then s = @glow.get(Img["glow_white"], o[:x] - 24, o[:y] - 24) end
      when :ichest
        shadow(o[:x], o[:y] + 4, 12)
        sp(@objs, o[:opened] ? "chestIronOpen" : "chestIron", o[:x], o[:y] + 4)
        @glow.get(Img["glow_white"], o[:x] - 24, o[:y] - 24) unless o[:opened]
      when :cchest
        shadow(o[:x], o[:y] + 4, 12)
        sp(@objs, o[:opened] ? "chestCursedOpen" : "chestCursed", o[:x], o[:y] + 4)
        @glow.get(Img["glow_purple"], o[:x] - 30, o[:y] - 30) unless o[:opened]
      when :pedestal
        b = @objs.get(Img.px("#4e4a5e", 1), o[:x] - 9, o[:y] + 2); b.zoom_x = 18; b.zoom_y = 6
        b = @objs.get(Img.px("#8b8f9c", 1), o[:x] - 9, o[:y] + 2); b.zoom_x = 18; b.z = 7
        unless o[:opened] || o[:relic].nil?
          s = sp(@objs, "relic_" + o[:relic][:id], o[:x], o[:y] + bob); s.zoom_x = 2.0; s.zoom_y = 2.0; s.z = 8
          @glow.get(Img["glow_white"], o[:x] - 24, o[:y] - 30)
        end
      when :idol
        shadow(o[:x], o[:y] + 4, 14); sp(@objs, "idol", o[:x], o[:y] + 4)
      when :campfire
        shadow(o[:x], o[:y] + 4, 14); sp(@objs, "campfire", o[:x], o[:y] + 4)
        @glow.get(Img["glow_torch"], o[:x] - 36, o[:y] - 40).opacity = o[:used] ? 120 : 220
      when :bell
        shadow(o[:x], o[:y] + 4, 10); s = sp(@objs, "bell", o[:x], o[:y] + 4)
        s.angle = o[:used] ? Math.sin(t * 10) * 8 : 0
      when :lockdoor
        s = sp(@objs, "lock", o[:x], o[:y] + 4 + bob) unless o[:used]
      when :item
        it = o[:item]
        icon = (it[:item] == :weapon ? "w_" : "g_") + it[:id]
        shadow(o[:x], o[:y] + 6, 10)
        gw = @glow.get(Img["glow_white"], o[:x] - 24, o[:y] - 26); gw.color.set(*rarity_rgb(it[:rarity])); gw.opacity = 200
        s = sp(@objs, icon, o[:x], o[:y] + 2 + bob); s.zoom_x = s.zoom_y = 1.5; s.z = 8
      when :shop
        b = @objs.get(Img.px("#4e4a5e", 1), o[:x] - 9, o[:y] + 2); b.zoom_x = 18; b.zoom_y = 6
        b = @objs.get(Img.px("#8b8f9c", 1), o[:x] - 9, o[:y] + 2); b.zoom_x = 18; b.z = 7
        name = o[:item] == :relic ? "relic_" + o[:relic][:id] : (o[:thing] ? (o[:item] == :weapon ? "w_" : "g_") + o[:thing][:id] : { potion: "potion", heart: "heartPick", bomb: "bomb", key: "key", armor: "armor" }[o[:item]])
        s = sp(@objs, name, o[:x], o[:y] + bob); s.zoom_x = 2.0; s.zoom_y = 2.0; s.z = 8
        str = "#{o[:price]}G"
        tb = TextCache.get(str, p[:gold] >= o[:price] ? "gold" : "red")
        s = @objs.get(tb, o[:x] - text_w(str) / 2, o[:y] + 11); s.z = 8
      when :altar
        shadow(o[:x], o[:y] + 4, 14); sp(@objs, "altar", o[:x], o[:y] + 4)
        @glow.get(Img["glow_red"], o[:x] - 30, o[:y] - 34) unless o[:used]
      when :fountain
        shadow(o[:x], o[:y] + 4, 14); sp(@objs, "fountain", o[:x], o[:y] + 4)
      when :portal
        s = sp(@objs, "portal", o[:x], o[:y] + 6); s.zoom_x = s.zoom_y = 1 + Math.sin(t * 4) * 0.05
        @glow.get(Img["glow_purple"], o[:x] - 30, o[:y] - 30)
        particle(o[:x] + rint(-5, 5), o[:y] + rint(-5, 5), 0, -20, 0.5, "#a35bd6") if rnd < 0.4 && g.state == :play
      end
    end
    # Exit signs: what room and what reward waits behind each door.
    unless g.locked
      room[:exits].each do |d, c|
        x, y = door_center(d)
        sx = x + ({ "w" => 30, "e" => -30 }[d] || 0); sy = y + ({ "n" => 30 }[d] || -2)
        kind = ROOM_KINDS[c[:type]]
        bob = (Math.sin(t * 3 + sx) * 1.5).round
        s = sp(@objs, kind[:icon], sx - (c[:reward] ? 7 : 0), sy + bob); s.z = 8
        if c[:reward]
          s2 = sp(@objs, REWARDS[c[:reward]][:icon], sx + 7, sy + bob); s2.z = 8
        end
        lb = TextCache.get(kind[:name], kind[:col])
        q = @objs.get(lb, sx - lb.width / 2, sy + 3); q.z = 8
      end
    end
    # Zones (fire, poison, smoke).
    g.zones.each do |z|
      case z[:kind]
      when :fire
        if rnd < 0.5 then q = @fx.get(Img.px(pick(["#e8873a", "#f2c94c", "#d8443c"]), 2), z[:x] + rint(-z[:r], z[:r]) * 0.7, z[:y] + rint(-3, 3)); q.z = 5 end
        @glow.get(Img["glow_small"], z[:x] - 12, z[:y] - 12).opacity = 120
      when :poison
        3.times { q = @fx.get(Img.px(pick(["#b8e05a", "#63b84f"]), 1), z[:x] + Math.cos(t * 2 + q.object_id) * z[:r] * rnd, z[:y] + Math.sin(t * 3 + rnd * 6) * z[:r] * 0.6); q.z = 5; q.opacity = 160 }
      when :smoke
        g2 = @glow.get(Img["glow_white"], z[:x] - 24, z[:y] - 24); g2.opacity = (90 * [1, z[:t]].min).round
      end
    end
    # Start room hint.
    if room[:type] == "start" && g.floor_index == 0
      ["CLEAR THE ROOMS. SLAY THE GUARDIAN.",
       $opts[:autofire] ? "YOU FIRE AT THE NEAREST FOE BY ITSELF" : "AIM WITH THE AIM BUTTONS TO FIRE",
       "PRESS ROLL TO DODGE THROUGH SHOTS"].each_with_index do |l, i|
        s = @objs.get(TextCache.get(l, "bone"), SW / 2 - text_w(l) / 2, 6 * TS + i * 10); s.opacity = 120; s.z = 3
      end
    end
    # Pickups and bombs.
    g.pickups.each do |k|
      shadow(k[:x], k[:y] + 2, 6)
      name = { coin: "coin", heart: "heartPick", potion: "potion", gem: "gem", bomb: "bomb", key: "key", armor: "armor", ember: "ember" }[k[:kind]]
      wob = k[:kind] == :coin ? 0 : (Math.sin(t * 4)).round
      @glow.get(Img["glow_small"], k[:x] - 12, k[:y] - 14 - k[:z]) if k[:kind] == :ember
      s = sp(@objs, name, k[:x], k[:y] + 3 - k[:z] - wob); s.z = 9
    end
    g.bombs.each do |b|
      s = sp(@objs, "bomb", b[:x], b[:y] + 4); s.z = 9
      s.zoom_x = s.zoom_y = 1.0 + (b[:t] < 0.35 ? 0.25 : 0)
      if (b[:t] * (b[:t] < 0.4 ? 20 : 8)).floor.odd? then s.color.set(255, 80, 60, 170) end
    end
    # Telegraphs.
    g.enemies.each do |e|
      if e[:type] == "knight" && e[:state] == :tele
        i = 10
        while i < 160
          q = @fx.get(Img.px("#d8443c", 2), e[:x] + Math.cos(e[:ca]) * i - 1, e[:y] + Math.sin(e[:ca]) * i - 1); q.opacity = 130
          i += 6
        end
      end
      if e[:telegraph]
        i = 16
        while i < 300
          q = @fx.get(Img.px("#e8873a", 3), e[:x] + Math.cos(e[:telegraph]) * i - 1, e[:y] + Math.sin(e[:telegraph]) * i - 1); q.opacity = 160
          i += 6
        end
      end
      if e[:beams] && !e[:beams].empty?
        active = e[:sub] == 2
        e[:beams].each do |ba|
          deg = -ba * 180 / Math::PI
          if active
            q = @fx.get(Img.px("#e8c8ff", 1), e[:x] + 5 * Math.sin(ba), e[:y] - 4 - 5 * Math.cos(ba)); q.zoom_x = 520; q.zoom_y = 10; q.angle = deg
            q2 = @fx.get(Img.px("#ffffff", 1), (e[:x] + 2 * Math.sin(ba)).round, (e[:y] - 4 - 2 * Math.cos(ba)).round); q2.zoom_x = 520; q2.zoom_y = 4; q2.angle = deg
          else
            q = @fx.get(Img.px("#a35bd6", 1), e[:x], e[:y] - 4); q.zoom_x = 520; q.zoom_y = 2; q.angle = deg
            q.opacity = (t * 16).floor.odd? ? 180 : 80
          end
        end
      end
    end
    # Entities, sorted by y.
    list = g.enemies + [p]
    list.sort_by { |e| e[:y] }.each do |e|
      if e.equal?(p) then draw_player(p, t) else draw_enemy(e, t) end
    end
    orbital_positions(p).each { |o| s = @bul.get(Img["orb_moon"], o[:x] - 5, o[:y] - 5) }
    (g.swings || []).each do |w|
      k = w[:t] / w[:max]
      tint = (TAG_COLS[w[:tag] || :core] || TAG_COLS[:core])[0]
      case w[:kind]
      when :slash
        arc = Img["slash_arc"]
        s = @fx.get(arc, w[:x], w[:y]); s.ox = 24; s.oy = 24; s.z = 2250
        s.zoom_x = s.zoom_y = w[:r] / 24.0 * (1.15 - 0.15 * k)
        s.angle = -w[:a] * 180 / Math::PI; s.opacity = (210 * k).round
        tc = hex_color(TAG_COLS[w[:tag] || :core][0]); s.color.set(tc.red, tc.green, tc.blue, 110)
        s.zoom_y *= w[:arc] / (140 * Math::PI / 180)
      when :thrust, :whip
        s = @fx.get(Img.px(w[:kind] == :whip ? "#d9d0b4" : "#f4ecd8", 1), w[:x], w[:y]); s.z = 2250
        s.zoom_x = w[:len] * (1.1 - 0.4 * k); s.zoom_y = [2, w[:width] * 0.5].max; s.angle = -w[:a] * 180 / Math::PI; s.opacity = (230 * k).round
        tx = w[:x] + Math.cos(w[:a]) * w[:len]; ty = w[:y] + Math.sin(w[:a]) * w[:len]
        q = @fx.get(Img.px("#ffffff", 3), tx - 1, ty - 1); q.z = 2251; q.opacity = (255 * k).round
      when :beam
        s = @fx.get(Img.px(tint, 1), w[:x], w[:y] - 1); s.z = 2250; s.zoom_x = w[:len]; s.zoom_y = 3; s.angle = -w[:a] * 180 / Math::PI
        s2 = @fx.get(Img.px("#ffffff", 1), w[:x], w[:y]); s2.z = 2251; s2.zoom_x = w[:len]; s2.zoom_y = 1; s2.angle = -w[:a] * 180 / Math::PI
      end
    end
    g.temp_fams.each do |f|
      s = sp(@ents, "familiar", f[:x], f[:y] + 4); s.z = 2000; s.color.set(160, 220, 255, 120); s.opacity = f[:t] < 1 ? (f[:t] * 255).round : 255
    end
    g.familiars.each_with_index do |f, i|
      next if i >= p[:familiars]
      s = sp(@ents, "familiar", f[:x], f[:y] + 4 + (Math.sin(t * 6 + i) * 1.5).round); s.z = 2000
      @glow.get(Img["glow_small"], f[:x] - 12, f[:y] - 12)
    end
    # Player shots.
    gl = 0
    g.pbullets.each do |b|
      case b[:kind]
      when "hex"
        big = b[:r] > 3.5
        bm = Img[big ? "orb_hexBig" : "orb_hex"]
        s = @bul.get(bm, b[:x], b[:y]); s.ox = bm.width / 2; s.oy = bm.height / 2
        s.zoom_x = s.zoom_y = b[:r] / (big ? 5.0 : 2.5) if b[:r] > 6
        if gl < 40 then gl += 1; @glow.get(Img["glow_small"], b[:x] - 12, b[:y] - 12) end
      when "lance"
        s = @bul.get(Img["orb_iceBig"], b[:x], b[:y]); s.ox = 6; s.oy = 6; s.zoom_x = 1.3; s.zoom_y = 0.8
        s.angle = -Math.atan2(b[:vy], b[:vx]) * 180 / Math::PI
      when "dart"
        s = @bul.get(Img["orb_spore"], b[:x], b[:y]); s.ox = 4; s.oy = 4
      when "clod", "flask", "spark"
        bm = Img[{ "clod" => "orb_clod", "flask" => "orb_flask", "spark" => "orb_cyan" }[b[:kind]]]
        s = @bul.get(bm, b[:x], b[:y]); s.ox = bm.width / 2; s.oy = bm.height / 2
        s.zoom_x = s.zoom_y = [1.0, b[:r] / 2.5].max if b[:kind] != "spark"
      when "boomer"
        bm = b[:icon] ? Img["w_" + b[:icon]] : Img["orb_gold"]
        s = @bul.get(bm, b[:x], b[:y]); s.ox = bm.width / 2; s.oy = bm.height / 2; s.zoom_x = s.zoom_y = [1.0, b[:r] / 3.0].max
        s.angle = (b[:rot] * 40) % 360 unless b[:icon] == "lantern" || b[:icon] == "sunlantern"
        if gl < 40 then gl += 1; @glow.get(Img["glow_small"], b[:x] - 12, b[:y] - 12) end
      when "bolt"
        s = @bul.get(Img["bolt"], b[:x], b[:y]); s.ox = 4; s.oy = 2
        s.angle = -Math.atan2(b[:vy], b[:vx]) * 180 / Math::PI
        s.zoom_x = s.zoom_y = 1.4 if b[:r] > 3.2
      when "fire"
        bm = Img["orb_fire"]
        s = @bul.get(bm, b[:x], b[:y]); s.ox = bm.width / 2; s.oy = bm.height / 2
        s.zoom_x = s.zoom_y = 0.6 + 0.8 * (1 - b[:life] / [b[:max_life], 0.01].max)
        s.opacity = (255 * clampf(b[:life] / [b[:max_life], 0.01].max * 1.5, 0, 1)).round
      when "pulse"
        bm = Img[{ pyre: "orb_fireBig", frost: "orb_iceBig", shadow: "orb_darkBig", venom: "orb_fireBig" }[b[:tag]] || "orb_hexBig"]
        s = @bul.get(bm, b[:x], b[:y]); s.ox = bm.width / 2; s.oy = bm.height / 2; s.zoom_x = s.zoom_y = b[:r] / 4.0
        s.color.set(184, 224, 90, 140) if b[:tag] == :venom
        g2 = @glow.get(Img["glow_small"], b[:x] - 12, b[:y] - 12); g2.zoom_x = g2.zoom_y = b[:r] / 3.0
      when "mine"
        bm = Img["w_" + b[:icon]]
        s = @bul.get(bm, b[:x], b[:y]); s.ox = bm.width / 2; s.oy = bm.height / 2; s.z = 6
        s.color.set(255, 80, 60, 150) if b[:arm] <= 0 && ($G.time * 6).floor.odd?
      when "rail"
        a = Math.atan2(b[:vy], b[:vx])
        s = @bul.get(Img.px("#ffffff", 1), b[:x] - Math.cos(a) * 14, b[:y] - Math.sin(a) * 14); s.zoom_x = 18; s.zoom_y = 2; s.angle = -a * 180 / Math::PI
        if gl < 40 then gl += 1; @glow.get(Img["glow_white"], b[:x] - 24, b[:y] - 24).opacity = 120 end
      else
        bm = b[:icon] && b[:kind] != "hatchet" ? Img["w_" + b[:icon]] : Img["hatchet"]
        s = @bul.get(bm, b[:x], b[:y]); s.ox = bm.width / 2; s.oy = bm.height / 2
        s.angle = (b[:rot] * 40) % 360
        s.zoom_x = s.zoom_y = [0.8, b[:r] / 4.0].max
      end
    end
    g.ebullets.each do |b|
      bm = Img["orb_" + b[:spr]]
      s = @bul.get(bm, b[:x] - bm.width / 2, b[:y] - bm.height / 2); s.z = 2100
    end
    g.particles.each do |q|
      sz = q[:size]
      s = @fx.get(Img.px(q[:col], sz), q[:x] - sz / 2, q[:y] - sz / 2); s.z = 2200
      s.opacity = (clampf(q[:life] / q[:max] * 1.5, 0, 1) * 255).round
    end
    g.texts.each do |tx|
      bm = TextCache.get(tx[:text], tx[:col])
      s = @txt.get(bm, tx[:x] - bm.width / 2, tx[:y]); s.opacity = (clampf(tx[:life] * 3, 0, 1) * 255).round
    end
    [@shadows, @objs, @ents, @fx, @bul, @glow, @txt].each { |pl| pl.finish }
  end

  def sp(pool, name, x, y)
    bm = Img[name]
    s = pool.get(bm, x, y)
    s.ox = bm.width / 2; s.oy = bm.height
    s
  end

  def shadow(x, y, w)
    ws = [6, 10, 12, 14, 16, 20, 24].min_by { |v| (v - w).abs }
    s = @shadows.get(Img["shadow#{ws}"], x - ws / 2, y - 1)
    s
  end

  def draw_player(p, t)
    name = p[:hero][:sprite]
    bm = Img[name]
    p[:trail].each do |tr|
      s = @ents.get(bm, tr[:x], tr[:y] + 6); s.ox = bm.width / 2; s.oy = bm.height; s.mirror = tr[:face] < 0
      s.color.set(255, 255, 255, 255); s.opacity = (tr[:life] * 2.5 * 255).round; s.z = 99
    end
    shadow(p[:x], p[:y] + 5, 10)
    return if p[:invuln] > 0 && (t * 20).floor.odd? && p[:dodge_t] <= 0
    bob = (p[:moving] && p[:dodge_t] <= 0 && (p[:walk_t] * 10).floor.odd?) ? -1 : 0
    s = @ents.get(bm, p[:x], p[:y] + 6 + bob); s.ox = bm.width / 2; s.oy = bm.height
    s.mirror = p[:face] < 0
    s.zoom_y = 0.85 if p[:dodge_t] > 0
    s.z = 100 + p[:y].round
    if p[:weapon] && p[:dodge_t] <= 0
      wb = Img["w_" + p[:weapon][:id]]
      hx = p[:x] + Math.cos(p[:aim_a]) * 6; hy = p[:y] - 1 + Math.sin(p[:aim_a]) * 4
      ws = @ents.get(wb, hx, hy); ws.ox = wb.width / 2; ws.oy = wb.height / 2
      left = Math.cos(p[:aim_a]) < 0
      ws.mirror = left
      ws.angle = left ? -(p[:aim_a] - Math::PI) * 180 / Math::PI + 45 : -p[:aim_a] * 180 / Math::PI + 45
      ws.angle = -ws.angle if left
      ws.z = 100 + p[:y].round + (Math.sin(p[:aim_a]) < -0.3 ? -1 : 1)
    end
    if $G.enemies_active? || Keys.aim
      ax = p[:x] + Math.cos(p[:aim_a]) * 16; ay = p[:y] - 2 + Math.sin(p[:aim_a]) * 16
      q = @fx.get(Img.px("#1a1423", 1), ax - 2, ay - 2); q.zoom_x = q.zoom_y = 4; q.z = 2300
      q = @fx.get(Img.px("#f4ecd8", 2), ax - 1, ay - 1); q.z = 2301
    end
  end

  def draw_enemy(e, t)
    if e[:spawn_t] > 0
      k = 1 - e[:spawn_t] / 0.75
      col = FLOORS[$G.floor_index][:accent_hex]
      r = 10 - k * 6
      8.times do |i|
        a = i / 8.0 * TAU + t * 3
        @fx.get(Img.px(col, 1), e[:x] + Math.cos(a) * r, e[:y] + Math.sin(a) * r * 0.6 + 4)
      end
      @fx.get(Img.px(col, 2), e[:x] - 1, e[:y] + 3) if (t * 12).floor.odd?
      return
    end
    boss = e[:type] == "boss"
    return if boss && e[:hidden]
    key = e[:d][:sprite]
    key = "bat2" if key == "bat" && (e[:anim] * 8).floor.odd?
    bm = Img[(e[:elite] && !boss) ? key + "_elite" : key]
    sc = e[:scale]
    foot = e[:y] + e[:r] + (boss ? 2 : 0)
    shadow(e[:x], foot, bm.width * sc * 0.75) unless e[:hidden]
    sx = 1.0; sy = 1.0
    if e[:d][:ai] == :slime
      if e[:state] == :hop then sx = 0.85; sy = 1.2
      else q = Math.sin(e[:anim] * 6) * 0.06; sx = 1 + q; sy = 1 - q
      end
    end
    bob = boss ? (Math.sin(t * 2) * 2).round : (e[:d][:fly] ? (Math.sin(e[:anim] * 5) * 2).round - 3 : 0)
    s = @ents.get(bm, e[:x], foot + bob - e[:z])
    s.ox = bm.width / 2; s.oy = bm.height
    s.zoom_x = sc * sx; s.zoom_y = sc * sy
    s.mirror = e[:face] < 0
    s.z = 100 + e[:y].round
    s.opacity = 46 if e[:hidden]
    flashing = e[:flash] > 0 || ([:aim, :tele, :puff].include?(e[:state]) && (t * 16).floor.odd?)
    if flashing then s.color.set(255, 255, 255, 255)
    elsif e[:chill_t] > 0 then s.color.set(111, 211, 224, 130)
    end
    if !boss && e[:hp] < e[:max_hp] && !e[:hidden]
      x = (e[:x] - 6).round; y = (foot + 2).round
      q = @fx.get(Img.px("#1a1423", 1), x - 1, y - 1); q.zoom_x = 14; q.zoom_y = 4; q.z = 2050
      q = @fx.get(Img.px("#4e4a5e", 1), x, y); q.zoom_x = 12; q.zoom_y = 2; q.z = 2051
      q = @fx.get(Img.px(e[:elite] ? "#f2c94c" : "#d8443c", 1), x, y); q.zoom_x = (12.0 * e[:hp] / e[:max_hp]).ceil; q.zoom_y = 2; q.z = 2052
    end
  end

  def redraw_dyn
    g = $G; room = g.room; b = @dyn.bitmap
    b.clear
    dark = hex_color("#0d0a12"); ol = hex_color("#140f1c")
    bars = lambda do |x0, y0, w, h, vertical|
      bc = hex_color("#5a5770"); hc = hex_color("#8b8f9c")
      if vertical
        i = 2; while i < w; b.fill_rect(x0 + i, y0, 2, h, bc); i += 5; end
        b.fill_rect(x0, y0 + h - 4, w, 2, hc)
      else
        i = 2; while i < h; b.fill_rect(x0, y0 + i, w, 2, bc); i += 5; end
        b.fill_rect(x0 + w - 4, y0, 2, h, hc)
      end
    end
    crack = Img["crack"]
    room[:secret_dirs].keys.each do |d|
      tiles = door_tiles(d)
      tiles.each_with_index do |(c, r), i|
        next if d == "n" && r == 0
        b.blt(c * TS, r * TS, crack, crack.rect, g.player[:reveal] ? 255 : 170)
      end
    end
    doors = room[:doors].keys
    doors += [room[:entrance]] if room[:entrance] && !doors.include?(room[:entrance])
    doors.each do |d|
      next if room[:secret_dirs][d]
      ex = room[:exits][d]
      fc = hex_color(ex ? (ROOM_COL[ex[:type]] || "#8b8f9c") : "#4e4a5e")
      shut = g.locked || room[:sealed][d] || d == room[:entrance]
      case d
      when "n"
        b.fill_rect(13 * TS - 3, 0, 2 * TS + 6, 2 * TS, ol)
        b.fill_rect(13 * TS - 2, 0, 2, 2 * TS, fc); b.fill_rect(15 * TS, 0, 2, 2 * TS, fc); b.fill_rect(13 * TS - 2, 0, 2 * TS + 4, 2, fc)
        b.fill_rect(13 * TS, 2, 2 * TS, 2 * TS - 2, dark)
        bars.call(13 * TS, 2, 2 * TS, 2 * TS - 2, true) if shut
      when "s"
        b.fill_rect(13 * TS - 3, 17 * TS, 2 * TS + 6, TS, ol)
        b.fill_rect(13 * TS - 2, 17 * TS, 2, TS, fc); b.fill_rect(15 * TS, 17 * TS, 2, TS, fc)
        b.fill_rect(13 * TS, 17 * TS, 2 * TS, TS, dark)
        bars.call(13 * TS, 17 * TS, 2 * TS, TS, true) if shut
      when "w"
        b.fill_rect(0, 8 * TS - 3, TS, 3 * TS + 6, ol)
        b.fill_rect(0, 8 * TS - 2, TS, 2, fc); b.fill_rect(0, 11 * TS, TS, 2, fc)
        b.fill_rect(0, 8 * TS, TS, 3 * TS, dark)
        bars.call(0, 8 * TS, TS, 3 * TS, false) if shut
      when "e"
        b.fill_rect(27 * TS, 8 * TS - 3, TS, 3 * TS + 6, ol)
        b.fill_rect(27 * TS, 8 * TS - 2, TS, 2, fc); b.fill_rect(27 * TS, 11 * TS, TS, 2, fc)
        b.fill_rect(27 * TS, 8 * TS, TS, 3 * TS, dark)
        bars.call(27 * TS, 8 * TS, TS, 3 * TS, false) if shut
      end
    end
    crate = Img["crate"]
    room[:crate_hp].each_key do |k|
      c, r = k
      next unless room[:grid][r][c] == T_CRATE
      b.fill_rect(c * TS + 2, r * TS + 12, 14, 5, Color.new(10, 6, 16, 90))
      b.blt(c * TS + 1, r * TS + 1, crate, crate.rect)
    end
    g.dyn_dirty = false
  end

  # ---------- HUD ----------
  def draw_hud
    g = $G; p = g.player; b = @hud.bitmap
    pr = g.prompt
    near_exit = nil
    unless g.locked
      g.room[:exits].each_key { |d| x, y = door_center(d); near_exit = d if Math.hypot(p[:x] - x, p[:y] - y) < 46 }
    end
    sig = [p[:weapon] ? p[:weapon][:id] : 0, p[:gear].values.compact.map { |gi| gi[:id] }.join, near_exit, p[:xp], p[:level], p[:hp], p[:max_hp], p[:armor], g.floor[:depth], g.room[:exits].size, g.locked, p[:bombs], p[:keys], p[:embers_found], g.msg ? g.msg[:text] : 0, p[:potions], p[:max_potions], p[:gold], p[:charges], p[:dodge_charges], (p[:charge_t] / p[:dodge_cd] * 5).floor,
           g.floor_index, g.room.object_id, p[:relics].size, g.boss ? (g.boss[:hp] / g.boss[:max_hp] * 110).ceil : -1,
           pr ? pr.object_id : 0, g.state].hash
    if sig != @hud_sig
      @hud_sig = sig
      b.clear
      (p[:max_hp] / 2).times do |i|
        v = p[:hp] - i * 2
        m = v >= 2 ? "full" : (v == 1 ? "half" : "empty")
        hb = Img["heart_" + m]; b.blt(5 + i * 9, 6, hb, hb.rect)
      end
      ax = 5 + (p[:max_hp] / 2) * 9
      p[:armor].times { |i| ab = Img["heart_armor"]; b.blt(ax + i * 9, 6, ab, ab.rect) }
      x = 5
      pot = Img["potion"]
      p[:max_potions].times { |i| b.blt(x + 1, 18, pot, pot.rect, i < p[:potions] ? 255 : 64); x += 9 }
      x += 4
      coin = Img["coin"]; b.blt(x + 1, 19, coin, coin.rect)
      ptext(b, p[:gold], x + 8, 18, "gold")
      x += 14 + text_w(p[:gold].to_s)
      p[:dodge_charges].times do |i|
        full = i < p[:charges]
        b.fill_rect(x - 1, 18, 7, 7, hex_color("#140f1c"))
        b.fill_rect(x, 19, 5, 5, hex_color(full ? "#6fd3e0" : "#4e4a5e"))
        if !full && i == p[:charges]
          h = (5 * p[:charge_t] / p[:dodge_cd]).round
          b.fill_rect(x, 24 - h, 5, h, hex_color("#4d9be6")) if h > 0
        end
        x += 8
      end
      x += 6
      [["bomb", p[:bombs]], ["key", p[:keys]]].each do |name, v|
        ic = Img[name]; b.blt(x, 25 - ic.height, ic, ic.rect); x += ic.width + 2
        x += ptext(b, v, x, 18, "white") + 6
      end
      if p[:embers_found] > 0
        ic = Img["ember"]; b.blt(x, 19, ic, ic.rect); x += 7
        ptext(b, p[:embers_found], x, 18, "orange")
      end
      if g.msg
        w = text_w(g.msg[:text]) + 10
        panel(b, (SW - w) / 2, 242, w, 11, "#4e4a5e")
        ptext(b, g.msg[:text], SW / 2, 245, g.msg[:col], 1, 0.5)
      end
      need = xp_needed(p[:level])
      b.fill_rect(5, 28, 82, 3, hex_color("#140f1c"))
      b.fill_rect(6, 29, (80.0 * p[:xp] / need).round, 1, hex_color("#b8e05a"))
      ptext(b, "LV #{p[:level]}", 90, 27, "lime")
      fl = FLOORS[g.floor_index]
      ptext(b, fl[:name], SW / 2, 4, fl[:accent], 1, 0.5)
      ptext(b, "#{g.floor_index + 1}/#{FLOORS.size}", SW / 2, 12, "grey", 1, 0.5)
      draw_minimap(b)
      p[:relics].last(24).each_with_index { |r, i| ic = Img["relic_" + r[:id]]; b.blt(4 + i * 11, SH - 13, ic, ic.rect, 220) }
      if p[:weapon]
        wi = Img["w_" + p[:weapon][:id]]
        panel(b, SW - 20, SH - 22, 16, 16, RARITY_HEX[p[:weapon][:rarity]])
        b.blt(SW - 18, SH - 20, wi, wi.rect)
        SLOTS.each_with_index do |sl, i|
          gp = p[:gear][sl]
          x = SW - 34 - (3 - i) * 12
          b.fill_rect(x, SH - 16, 11, 11, hex_color(gp ? RARITY_HEX[gp[:rarity]] : "#2a2838"))
          b.fill_rect(x + 1, SH - 15, 9, 9, hex_color("#17121e"))
          if gp then gi = Img["g_" + gp[:id]]; b.stretch_blt(Rect.new(x + 1, SH - 15, 9, 9), gi, gi.rect) end
        end
      end
      if g.boss && g.boss[:hp] > 0
        bo = g.boss; w = 220; bx = (SW - w) / 2; by = SH - 12
        panel(b, bx - 2, by - 2, w + 4, 8, "#8a2a33")
        b.fill_rect(bx, by, w, 4, hex_color("#4e4a5e"))
        fw = (w * bo[:hp] / bo[:max_hp]).ceil
        if fw > 0 then b.fill_rect(bx, by, fw, 4, hex_color("#d8443c")); b.fill_rect(bx, by, fw, 1, hex_color("#ff8a70")) end
        ptext(b, bo[:d][:name], SW / 2, by - 9, "white", 1, 0.5)
      end
      draw_prompt(b, pr) if pr && g.state == :play
      draw_exit_prompt(b) if !pr && g.state == :play && !g.locked
    end
    # Banner.
    bn = g.banner
    if bn
      if @banner_sig != bn.object_id
        @banner_sig = bn.object_id
        bb = @banner.bitmap; bb.clear
        bb.fill_rect(0, 0, SW, bn[:sub].empty? ? 26 : 36, Color.new(13, 10, 18, 190))
        ptext(bb, bn[:text], SW / 2, 5, "gold", 2, 0.5)
        ptext(bb, bn[:sub], SW / 2, 22, "white", 1, 0.5) unless bn[:sub].empty?
      end
      @banner.visible = true
      @banner.opacity = (clampf([bn[:t], 2.6 - bn[:t]].min * 4, 0, 1) * 255).round
    else
      @banner.visible = false
    end
  end

  def draw_minimap(b)
    f = $G.floor
    n = f[:total]
    w = 7
    ox = SW - 6 - (n + 1) * w; oy = 4
    (0..n).each do |i|
      x = ox + i * w
      if i == n
        ic = Img["icon_skull"]; b.blt(x, oy - 1, ic, ic.rect, i <= f[:depth] ? 255 : 150)
        next
      end
      col = i < f[:depth] ? "#5c5a78" : (i == f[:depth] ? "#f4ecd8" : "#2a2838")
      c = i > 0 && f[:path][i - 1] ? ROOM_COL[f[:path][i - 1][:type]] : nil
      col = c if c && i <= f[:depth]
      b.fill_rect(x, oy, w - 2, 5, hex_color("#140f1c"))
      b.fill_rect(x + 1, oy + 1, w - 4, 3, hex_color(col))
    end
    ptext(b, "ROOM #{f[:depth]}/#{n}", SW - 6, 12, "grey", 1, 1)
  end

  def draw_exit_prompt(b)
    g = $G; p = g.player
    best = nil; bd = 46
    g.room[:exits].each do |d, c|
      x, y = door_center(d)
      dd = Math.hypot(p[:x] - x, p[:y] - y)
      if dd < bd then bd = dd; best = [d, c, x, y] end
    end
    return unless best
    d, c, x, y = best
    kind = ROOM_KINDS[c[:type]]
    lines = [kind[:name]]
    lines << "REWARD: " + REWARDS[c[:reward]][:name] if c[:reward]
    lines << (g.room[:sealed][d] ? "LOCKED. USE A KEY ON THE LOCK" : "WALK THROUGH TO ENTER")
    w = lines.map { |l| text_w(l) }.max + 10; h = lines.size * 8 + 6
    px = clampf((x - w / 2).round, 4, SW - w - 4)
    py = d == "n" ? 40 : clampf((y - h - 18).round, 34, SH - h - 4)
    panel(b, px, py, w, h, ROOM_COL[c[:type]] || "#8b8f9c")
    lines.each_with_index { |l, i| ptext(b, l, px + w / 2, py + 4 + i * 8, i == 0 ? kind[:col] : (i == 1 && c[:reward] ? REWARDS[c[:reward]][:col] : "white"), 1, 0.5) }
  end

  def rarity_rgb(r)
    h = RARITY_HEX[r].sub("#", "")
    [h[0, 2].to_i(16), h[2, 2].to_i(16), h[4, 2].to_i(16), 120]
  end

  def item_lines(it)
    p = $G.player
    lines = []
    if it[:item] == :weapon
      lines << [it[:name], RARITY_COL[it[:rarity]]]
      lines << [RARITY_NAME[it[:rarity]] + " " + ARCH[it[:kind]][:name] + " - " + ARCH_DESC[it[:kind]], "grey"]
      cur = p[:weapon]
      dps = weapon_dps(it); cdps = weapon_dps(cur)
      diff = cdps > 0 ? ((dps / cdps - 1) * 100).round : 0
      dl = format("DAMAGE %s  RATE %.1f/S", it[:dmg] == it[:dmg].round ? it[:dmg].round.to_s : format("%.1f", it[:dmg]), it[:rate])
      dl += "  (#{diff >= 0 ? '+' : ''}#{diff}% BASE POWER)" unless it[:id] == cur[:id]
      lines << [dl, diff >= 0 ? "lime" : "red"]
      lines << ["TAGS: " + it[:tags].map { |t| FAMILIES[t][:name] }.join(", "), "tan"] unless it[:tags].empty?
    else
      lines << [it[:name], RARITY_COL[it[:rarity]]]
      lines << [RARITY_NAME[it[:rarity]] + " " + SLOT_NAME[it[:slot]] + (it[:tags].empty? ? "" : " - " + it[:tags].map { |t| FAMILIES[t][:name] }.join(", ")), "grey"]
      sl = it[:stats].map { |k, v| stat_line(k, v) }.compact
      lines << [sl.join("  "), "lime"] unless sl.empty?
      if it[:set]
        st = SETS[it[:set]]
        have = (p[:sets][it[:set]] || 0)
        lines << ["#{st[:name]} SET (#{have}/4): 2: #{st[:d2]}", "gold"]
        lines << ["4: #{st[:d4]}", "gold"]
      end
    end
    wrap_text(it[:desc], 220).each { |l| lines << [l, "white"] }
    lines
  end

  def draw_item_prompt(b, o, it, price = nil)
    p = $G.player
    lines = item_lines(it)
    if it[:item] == :gear && p[:gear][it[:slot]] && p[:gear][it[:slot]][:id] != it[:id]
      lines << ["REPLACES " + p[:gear][it[:slot]][:name], "dim"]
    elsif it[:item] == :weapon && p[:weapon][:id] != it[:id]
      lines << ["REPLACES " + p[:weapon][:name], "dim"]
    end
    lines << [price ? "BUY FOR #{price} GOLD" : "PRESS USE TO EQUIP", price ? "gold" : "grey"]
    w = [lines.map { |l, c| text_w(l) }.max + 10, SW - 8].min; h = lines.size * 8 + 6
    px = clampf((o[:x] - w / 2).round, 4, SW - w - 4)
    py = (o[:y] - 22 - h).round
    py = (o[:y] + 16).round if py < 32
    panel(b, px, py, w, h, RARITY_HEX[it[:rarity]])
    lines.each_with_index { |(l, c), i| ptext(b, l, px + w / 2, py + 4 + i * 8, c, 1, 0.5) }
  end

  def draw_prompt(b, o)
    return draw_item_prompt(b, o, o[:item]) if o[:kind] == :item
    return draw_item_prompt(b, o, o[:thing], o[:price]) if o[:kind] == :shop && o[:thing]
    title = ""; desc = ""; extra = ""
    case o[:kind]
    when :chest then title = o[:boss] ? "GUARDIAN'S HOARD" : "OLD CHEST"; desc = "CHOOSE A RELIC"
    when :ichest then title = "IRON CHEST"; desc = "RARER RELICS INSIDE"; extra = o[:free] ? "" : "OPEN WITH 1 KEY"
    when :cchest then title = "CURSED CHEST"; desc = "COSTS 1 MAX HEART. POWERFUL RELICS"
    when :pedestal then title = o[:relic] ? o[:relic][:name] : "EMPTY"; desc = o[:relic] ? o[:relic][:desc] : ""
    when :idol then title = "GREEDY IDOL"; desc = "FEED IT GOLD. IT MAY REWARD YOU"; extra = "PAY #{$G.price(15 + $G.floor_index * 3)} GOLD"
    when :bell then title = "CHALLENGE BELL"; desc = "RING IT FOR 3 HARD WAVES AND A PRIZE"
    when :campfire then title = "CAMPFIRE"; desc = "REST: HEAL HALF YOUR HEARTS, REFILL ROLLS"
    when :lockdoor then title = "LOCKED VAULT"; desc = "TREASURE LIES BEYOND"; extra = "OPEN WITH 1 KEY"
    when :shop
      if o[:item] == :relic then title = o[:relic][:name]; desc = o[:relic][:desc]
      else
        title, desc = { potion: ["RED POTION", "STORE IT. HEAL BUTTON HEALS 2 HEARTS"], heart: ["HEART", "HEALS 1 HEART"],
                        bomb: ["BOMB", "BLOWS UP FOES, CRATES AND CRACKED WALLS"], key: ["KEY", "OPENS IRON CHESTS AND VAULTS"],
                        armor: ["ARMOR", "BLOCKS ONE HIT"] }[o[:item]]
      end
      extra = "BUY FOR #{o[:price]} GOLD"
    when :altar then title = "BLOOD ALTAR"; desc = "OFFER 1 HEART FOR A RELIC"
    when :fountain then title = "CLEAR SPRING"; desc = "HEALS YOU FULLY, ONCE"
    when :portal then title = "DESCEND"; desc = "GO DEEPER INTO THE CRYPT"
    end
    lines = [title, desc, extra.empty? ? "PRESS USE" : extra]
    if o[:kind] == :pedestal && o[:relic] then lines.insert(1, RARITY_NAME[o[:relic][:rarity]]) end
    if o[:kind] == :shop && o[:item] == :relic then lines.insert(1, RARITY_NAME[o[:relic][:rarity]]) end
    w = lines.map { |l| text_w(l) }.max + 10; h = lines.size * 8 + 6
    px = clampf((o[:x] - w / 2).round, 4, SW - w - 4); py = (o[:y] - 26 - h).round
    panel(b, px, py, w, h, o[:kind] == :shop ? "#f2c94c" : "#8b8f9c")
    lines.each_with_index do |l, i|
      col = i == 0 ? "gold" : ((i == lines.size - 1 && !extra.empty?) ? "gold" : "white")
      ptext(b, l, px + w / 2, py + 4 + i * 8, col, 1, 0.5)
    end
    ptext(b, "PRESS USE", px + w / 2, py + h + 3, "grey", 1, 0.5) unless extra.empty?
  end

  # ---------- Menus and overlays ----------
  def menu_item(b, label, x, y, i, scale = 1, w = 120)
    sel = $G.menu == i
    tw = text_w(label, scale)
    if sel
      b.fill_rect(x - w / 2, y - 3, w, 5 * scale + 6, Color.new(232, 135, 58, 46))
      ptext(b, ">", x - tw / 2 - 8 - Math.sin($G.time * 8).round, y, "orange", scale)
    end
    ptext(b, label, x, y, sel ? "gold" : "tan", scale, 0.5)
  end

  def menu_sprite(name, x, y, zoom = 1, mirror = false, op = 255)
    bm = Img[name]
    s = @menu.get(bm, x, y); s.ox = bm.width / 2; s.oy = bm.height; s.zoom_x = s.zoom_y = zoom; s.mirror = mirror; s.opacity = op
    s
  end

  def draw_overlay(world)
    g = $G; b = @over.bitmap
    b.clear
    @menu.start; @menu_glow.start
    @over.visible = true
    case g.state
    when :title, :hero, :howto, :shrine, :codex, :tree then backdrop(b); send("draw_" + g.state.to_s, b); draw_toast(b)
    when :options
      if g.opt_from == :title then backdrop(b) else b.fill_rect(0, 0, SW, SH, Color.new(13, 10, 18, 210)) end
      draw_options(b)
    when :pause then b.fill_rect(0, 0, SW, SH, Color.new(13, 10, 18, 210)); draw_pause(b)
    when :traits then b.fill_rect(0, 0, SW, SH, Color.new(13, 10, 18, 215)); draw_traits(b)
    when :traitlist then b.fill_rect(0, 0, SW, SH, Color.new(13, 10, 18, 220)); draw_traitlist(b)
    when :gearpage then b.fill_rect(0, 0, SW, SH, Color.new(13, 10, 18, 222)); draw_gearpage(b)
    when :relics then b.fill_rect(0, 0, SW, SH, Color.new(13, 10, 18, 220)); draw_relics(b)
    when :choice then b.fill_rect(0, 0, SW, SH, Color.new(13, 10, 18, 215)); draw_choice(b)
    when :dead, :win then backdrop(b, false); draw_end(b)
    else @over.visible = false
    end
    @menu.finish; @menu_glow.finish
  end

  def backdrop(b, towers = true)
    b.fill_rect(0, 0, SW, SH, hex_color("#120e18"))
    if towers
      tc = hex_color("#1a1423")
      28.times { |i| h = 30 + ((i * 37) % 50); b.fill_rect(i * 16, SH - h, 15, h, tc) }
    end
    $G.embers.each do |e|
      b.fill_rect(e[:x].round, e[:y].round, 1, 1, hex_color(e[:col], (clampf(e[:life] / 3, 0, 1) * 255).round))
    end
    vg = Img["vignette"]; b.blt(0, 0, vg, vg.rect)
  end

  def draw_title(b)
    t = $G.time
    wob = (Math.sin(t * 2) * 2).round
    l1 = Img["logo_cinder"]; b.blt((SW - l1.width) / 2, 18 + wob, l1, l1.rect)
    l2 = Img["logo_crypt"]; b.blt((SW - l2.width) / 2, 58 + wob, l2, l2.rect)
    shown = HEROES.select { |h| $G.hero_unlocked?(h) }
    shown.each_with_index { |h, i| menu_sprite(h[:sprite], SW / 2 - (shown.size - 1) * 18 + i * 36, 128 + ((t * 3 + i).floor.odd? ? -1 : 0), 2, i >= shown.size / 2) }
    CCGame::TITLE_ITEMS.each_with_index { |label, i| menu_item(b, label, SW / 2, 142 + i * 17, i, 2, 170) }
    ic = Img["ember"]
    line = "EMBERS #{$meta[:embers]}    RUNS #{$meta[:runs]}    WINS #{$meta[:wins]}    DEEPEST FLOOR #{$meta[:best]}"
    w = text_w(line)
    b.blt(SW / 2 - w / 2 - 8, 250, ic, ic.rect)
    ptext(b, line, SW / 2, 251, "grey", 1, 0.5)
    ptext(b, "PRESS USE TO SELECT", SW / 2, 268, "dim", 1, 0.5)
  end

  def draw_hero(b)
    t = $G.time
    ptext(b, "CHOOSE YOUR DELVER", SW / 2, 10, "gold", 2, 0.5)
    n = HEROES.size; w = 68; gap = 4
    x0 = (SW - (n * w + (n - 1) * gap)) / 2
    HEROES.each_with_index do |h, i|
      x = x0 + i * (w + gap); y = 30; hh = 66
      sel = $G.hero_index == i
      open = $G.hero_unlocked?(h)
      panel(b, x, y, w, hh, sel ? "#e8873a" : "#4e4a5e", sel ? "#221a2c" : "#17121e")
      @menu_glow.get(Img["glow_torch"], x + w / 2 - 36, y - 4) if sel && open
      s = menu_sprite(h[:sprite], x + w / 2, y + 48 + ((sel && (t * 4).floor.odd?) ? -2 : 0), 3)
      unless open then s.color.set(20, 15, 28, 255) end
      ptext(b, open ? h[:name].sub("THE ", "") : "LOCKED", x + w / 2, y + 54, sel ? "gold" : (open ? "tan" : "dim"), 1, 0.5)
    end
    h = HEROES[$G.hero_index]
    open = $G.hero_unlocked?(h)
    panel(b, 40, 104, SW - 80, 118, "#4e4a5e", "#17121e")
    ptext(b, h[:name], SW / 2, 112, open ? "gold" : "dim", 2, 0.5)
    ptext(b, h[:weapon], SW / 2, 128, "grey", 1, 0.5)
    hb = Img["heart_full"]
    (h[:hp] / 2).times { |k| b.blt((SW / 2 - (h[:hp] / 2) * 4.5 + k * 9).round, 138, hb, hb.rect) }
    wrap_text(h[:blurb], SW - 120).each_with_index { |l, j| ptext(b, l, SW / 2, 152 + j * 9, "white", 1, 0.5) }
    st = h[:stats]
    hw = WEAPON_BY_ID[HERO_WEAPON[h[:id]]]
    stats = format("STARTS WITH %s   DAMAGE %s   RATE %.1f/S   SPEED %d", hw[:name], hw[:dmg] == hw[:dmg].round ? hw[:dmg].round.to_s : format("%.1f", hw[:dmg]), hw[:rate], h[:speed])
    ptext(b, stats, SW / 2, 176, "tan", 1, 0.5)
    unless open
      ptext(b, "UNLOCK AT THE EMBER SHRINE FOR #{h[:cost]} EMBERS", SW / 2, 196, "orange", 1, 0.5)
    end
    mx = $meta[:dread_max] || 0
    if mx > 0
      d = [$meta[:dread] || 0, mx].min
      ptext(b, "DREAD #{d}: #{DREAD_DESC[d]}", SW / 2, 208, d > 0 ? "red" : "grey", 1, 0.5)
      ptext(b, "UP/DOWN CHANGES DREAD.  MORE DREAD, MORE EMBERS", SW / 2, 230, "dim", 1, 0.5)
    else
      ptext(b, "WIN A RUN TO UNLOCK DREAD LEVELS", SW / 2, 230, "dim", 1, 0.5)
    end
    ptext(b, "< >  CHOOSE     USE  BEGIN     ROLL  SKILL TREE     MENU  BACK", SW / 2, 262, "grey", 1, 0.5)
  end

  def draw_shrine(b)
    ptext(b, "EMBER SHRINE", SW / 2, 10, "orange", 2, 0.5)
    ic = Img["ember"]
    line = "#{$meta[:embers]} EMBERS"
    b.blt(SW / 2 - text_w(line) / 2 - 8, 28, ic, ic.rect)
    ptext(b, line, SW / 2, 29, "gold", 1, 0.5)
    sel = $G.shrine_i
    top = [[0, sel - 6].max, [0, UNLOCKS.size - 12].max].min
    UNLOCKS[top, 12].each_with_index do |u, j|
      i = top + j
      y = 42 + j * 16
      on = unlocked?(u[:id])
      if i == sel then b.fill_rect(30, y - 3, SW - 60, 14, Color.new(232, 135, 58, 46)) end
      ptext(b, i == sel ? ">" : " ", 34, y, "orange")
      ptext(b, u[:name], 44, y, on ? "dim" : (i == sel ? "gold" : "tan"))
      ptext(b, u[:desc], 150, y, on ? "dim" : "white")
      ptext(b, on ? "OWNED" : "#{u[:cost]}", SW - 36, y, on ? "green" : ($meta[:embers] >= u[:cost] ? "gold" : "red"), 1, 1)
    end
    ptext(b, "EARN EMBERS BY GOING DEEP, SLAYING GUARDIANS AND FINDING SECRETS", SW / 2, 246, "grey", 1, 0.5)
    ptext(b, "USE  UNLOCK     MENU  BACK", SW / 2, 262, "grey", 1, 0.5)
  end

  def draw_codex(b)
    found = RELICS.count { |r| $meta[:found][r[:id]] }
    ptext(b, "RELIC CODEX", SW / 2, 10, "gold", 2, 0.5)
    ptext(b, "#{found} OF #{RELICS.size} FOUND", SW / 2, 28, "grey", 1, 0.5)
    pool = {}
    $G.relic_pool.each { |r| pool[r[:id]] = true }
    cols = CCGame::CODEX_COLS; cw = 30; chh = 22
    x0 = (SW - cols * cw) / 2 + 4
    RELICS.each_with_index do |r, i|
      x = x0 + (i % cols) * cw; y = 42 + (i / cols) * chh
      sel = $G.codex_i == i
      fr = Img["frame_" + { common: "common", rare: "rare", epic: "epic", legend: "legend" }[r[:rarity]]]
      if sel then b.fill_rect(x - 4, y - 4, 20, 20, Color.new(232, 135, 58, 90)) end
      b.blt(x - 2, y - 2, fr, fr.rect, $meta[:found][r[:id]] ? 255 : 90)
      if $meta[:found][r[:id]]
        ic = Img["relic_" + r[:id]]; b.blt(x - 1, y - 1, ic, ic.rect)
      else
        ptext(b, pool[r[:id]] ? "?" : "-", x + 4, y + 1, "dim")
      end
    end
    r = RELICS[$G.codex_i]
    panel(b, 30, 182, SW - 60, 56, "#4e4a5e", "#17121e")
    if $meta[:found][r[:id]]
      ptext(b, r[:name], SW / 2, 190, "gold", 2, 0.5)
      ptext(b, RARITY_NAME[r[:rarity]], SW / 2, 207, RARITY_COL[r[:rarity]], 1, 0.5)
      ptext(b, r[:desc], SW / 2, 220, "white", 1, 0.5)
    elsif pool[r[:id]]
      ptext(b, "UNDISCOVERED", SW / 2, 196, "grey", 2, 0.5)
      ptext(b, "FIND IT IN THE CRYPT TO LEARN WHAT IT DOES", SW / 2, 220, "dim", 1, 0.5)
    else
      ptext(b, "LOCKED", SW / 2, 196, "red", 2, 0.5)
      ptext(b, "UNLOCK ITS RELIC CACHE AT THE EMBER SHRINE", SW / 2, 220, "dim", 1, 0.5)
    end
    ptext(b, "ARROWS  BROWSE     MENU  BACK", SW / 2, 262, "grey", 1, 0.5)
  end

  def draw_toast(b)
    m = $G.msg
    return unless m
    w = text_w(m[:text], 2) + 20
    y = $G.state == :tree ? 228 : 130
    panel(b, (SW - w) / 2, y, w, 22, "#e8873a")
    ptext(b, m[:text], SW / 2, y + 6, m[:col], 2, 0.5)
  end

  def draw_howto(b)
    ptext(b, "HOW TO PLAY", SW / 2, 16, "gold", 2, 0.5)
    lines = [
      ["GOAL", "DESCEND 4 FLOORS AND SLAY EACH GUARDIAN."],
      ["", "DEATH ENDS THE RUN. EVERY RUN IS NEW."],
      ["ROOMS", "DOORS SEAL UNTIL ALL FOES ARE DEAD."],
      ["", "MAP: RED BOSS, GOLD CHEST, GREEN SHOP, PURPLE SHRINE."],
      ["RELICS", "STACK RELICS TO BUILD YOUR RUN."],
      ["", "SPEND GOLD IN SHOPS. PAY BLOOD AT ALTARS."],
      ["", ""],
      ["EMPO", "STICK MOVES. AIM BUTTONS AIM BY HAND."],
      ["", "AUTO-AIM SHOOTS THE NEAREST FOE FOR YOU."],
      ["", "ROLL DODGES. USE BUYS AND OPENS. HEAL DRINKS. BOMB BLASTS."],
      ["KEYS", "ARROWS MOVE. WASD AIM. SHIFT ROLL. ENTER USE. CTRL BOMB."],
      ["", "Q HEAL. ESC MENU."],
      ["PAD", "STICKS MOVE AND AIM. B ROLL. A USE. X HEAL."],
    ]
    lines.each_with_index { |l, i| ptext(b, l[0], 40, 44 + i * 15, "orange"); ptext(b, l[1], 96, 44 + i * 15, "white") }
    ptext(b, "ROLLING MAKES YOU UNTOUCHABLE FOR A MOMENT.", SW / 2, 248, "cyan", 1, 0.5)
    ptext(b, "PRESS ANY BUTTON", SW / 2, 266, "dim", 1, 0.5)
  end

  def draw_options(b)
    ptext(b, "OPTIONS", SW / 2, 50, "gold", 2, 0.5)
    CCGame::OPTION_LIST.each_with_index do |(label, key), i|
      txt = key ? "#{label}:  #{$opts[key] ? 'ON' : 'OFF'}" : label
      menu_item(b, txt, SW / 2, 86 + i * 22, i, 2, 260)
    end
  end

  def draw_pause(b)
    g = $G
    ptext(b, "PAUSED", SW / 2, 44, "gold", 3, 0.5)
    CCGame::PAUSE_ITEMS.each_with_index do |label, i|
      label = "SURE? PRESS AGAIN" if i == 4 && g.quit_armed
      menu_item(b, label, SW / 2, 86 + i * 22, i, 2, 260)
    end
    r = g.run_stats; p = g.player
    ptext(b, "TIME #{fmt_time(r[:time])}   KILLS #{r[:kills]}   LEVEL #{p[:level]}", SW / 2, 214, "grey", 1, 0.5)
  end

  def draw_traits(b)
    c = $G.tchoice; p = $G.player
    ptext(b, "LEVEL #{p[:level]}!", SW / 2, 20, "lime", 2, 0.5)
    ptext(b, "CHOOSE A TRAIT", SW / 2, 38, "gold", 1, 0.5)
    n = c[:opts].size; w = 128; gap = 10
    x0 = (SW - (n * w + (n - 1) * gap)) / 2
    c[:opts].each_with_index do |t, i|
      x = x0 + i * (w + gap); y = 58; h = 150; sel = c[:idx] == i
      fam = FAMILIES[t[:fam]]
      oy = sel ? -4 : 0
      panel(b, x, y + oy, w, h, sel ? "#f2c94c" : fam[:hex], sel ? "#221a2c" : "#17121e")
      @menu_glow.get(Img["glow_white"], x + w / 2 - 24, y + 4) if sel
      ptext(b, fam[:name] + (t[:cap] ? " CAPSTONE" : ""), x + w / 2, y + 8 + oy, fam[:col], 1, 0.5)
      wrap_text(t[:name], w - 10).each_with_index { |l, j| ptext(b, l, x + w / 2, y + 22 + j * 12 + oy, "gold", 2, 0.5) }
      rank = p[:traits][t[:id]] || 0
      pips = (0...t[:max]).map { |k| k < rank ? "*" : (k == rank ? "+" : "-") }.join(" ")
      ptext(b, "RANK " + pips, x + w / 2, y + 58 + oy, "tan", 1, 0.5)
      wrap_text(t[:desc], w - 14).each_with_index { |l, j| ptext(b, l, x + w / 2, y + 74 + j * 9 + oy, "white", 1, 0.5) }
      have = p[:fam][t[:fam]] || 0
      if t[:fam] != :core
        nxt = [2, 4, 6].find { |v| v > have }
        if nxt
          bonus = FAMILY_BONUS[t[:fam]][nxt / 2 - 1][0]
          ptext(b, "#{fam[:name]} #{have + 1}/#{nxt}:", x + w / 2, y + 116 + oy, fam[:col], 1, 0.5)
          wrap_text(bonus, w - 14).first(2).each_with_index { |l, j| ptext(b, l, x + w / 2, y + 126 + j * 8 + oy, "grey", 1, 0.5) }
        end
      end
    end
    ptext(b, "< >  CHOOSE     USE  TAKE     MENU  REROLL (#{p[:rerolls]} LEFT)", SW / 2, 226, "grey", 1, 0.5)
    ptext(b, "#{p[:pending] - 1} MORE LEVEL-UPS WAITING", SW / 2, 240, "lime", 1, 0.5) if p[:pending] > 1
  end

  def draw_traitlist(b)
    p = $G.player
    ptext(b, "TRAITS  -  LEVEL #{p[:level]}", SW / 2, 12, "gold", 2, 0.5)
    y = 32
    fams = p[:fam].keys.sort_by { |f| -p[:fam][f] }
    fams.each do |f|
      fam = FAMILIES[f]
      tier = p[:fam_bonus][f] || 0
      ptext(b, "#{fam[:name]} #{p[:fam][f]}", 20, y, fam[:col])
      if FAMILY_BONUS[f]
        FAMILY_BONUS[f].each_with_index { |(txt, _), k| ptext(b, "#{(k + 1) * 2}: " + txt, 110, y + k * 8, k < tier ? fam[:col] : "dim") }
      end
      names = TRAITS.select { |t| t[:fam] == f && p[:traits][t[:id]] }.map { |t| "#{t[:name]} #{p[:traits][t[:id]]}" }.join(", ")
      wrap_text(names, 80).first(2).each_with_index { |l, j| ptext(b, l, 20, y + 9 + j * 8, "white") }
      y += f == :core ? 20 : 28
      break if y > 226
    end
    ptext(b, "NO TRAITS YET. LEVEL UP BY SLAYING FOES.", SW / 2, 60, "grey", 1, 0.5) if fams.empty?
    ptext(b, "PRESS ANY BUTTON", SW / 2, 266, "dim", 1, 0.5)
  end

  def draw_tree(b)
    g = $G
    h = HEROES[g.tree_hero]
    open = g.hero_unlocked?(h)
    owned = g.tree_owned(h[:id])
    ptext(b, "SKILL TREE", SW / 2, 8, "gold", 2, 0.5)
    menu_sprite(h[:sprite], 40, 40, 2)
    ptext(b, "< " + h[:name] + " >", SW / 2, 26, open ? "tan" : "dim", 1, 0.5)
    ic = Img["ember"]; line = "#{$meta[:embers]} EMBERS"
    b.blt(SW - 40 - text_w(line), 26, ic, ic.rect); ptext(b, line, SW - 32, 27, "gold", 1, 1)
    tree_for(h[:id]).each_with_index do |br, bi|
      x = 34 + bi * 132
      ptext(b, br[:name], x + 60, 44, bi == 2 ? "orange" : "tan", 1, 0.5)
      br[:nodes].each_with_index do |nd, ni|
        y = 56 + ni * 38
        got = owned[bi] > ni
        avail = owned[bi] == ni
        sel = g.tree_b == bi && g.tree_n == ni
        border = sel ? "#f2c94c" : (got ? "#63b84f" : (avail ? "#8b8f9c" : "#2a2838"))
        panel(b, x, y, 120, 32, border, got ? "#1d2a20" : "#17121e")
        b.fill_rect(x + 59, y - 6, 2, 6, hex_color(got ? "#63b84f" : "#2a2838")) if ni > 0
        ptext(b, nd[0], x + 60, y + 4, got ? "lime" : (avail ? "gold" : "dim"), 1, 0.5)
        wrap_text(nd[1], 112).first(2).each_with_index { |l, j| ptext(b, l, x + 60, y + 13 + j * 8, got || avail ? "white" : "dim", 1, 0.5) }
        ptext(b, got ? "" : TREE_COSTS[ni].to_s, x + 116, y + 4, $meta[:embers] >= TREE_COSTS[ni] ? "orange" : "red", 1, 1) unless got
      end
    end
    nd = tree_for(h[:id])[g.tree_b][:nodes][g.tree_n]
    ptext(b, nd[0] + ": " + nd[1], SW / 2, 214, "white", 1, 0.5)
    ptext(b, "ARROWS  PICK     USE  LEARN     AIM L/R  HERO     MENU  BACK", SW / 2, 262, "grey", 1, 0.5)
  end

  def draw_gearpage(b)
    p = $G.player
    ptext(b, "EQUIPMENT", SW / 2, 10, "gold", 2, 0.5)
    w = p[:weapon]
    panel(b, 16, 30, SW - 32, 64, RARITY_HEX[w[:rarity]], "#17121e")
    wi = Img["w_" + w[:id]]; b.stretch_blt(Rect.new(24, 38, 24, 24), wi, wi.rect)
    ptext(b, w[:name], 56, 36, RARITY_COL[w[:rarity]], 2)
    ptext(b, RARITY_NAME[w[:rarity]] + " " + ARCH[w[:kind]][:name] + " - " + ARCH_DESC[w[:kind]], 56, 50, "grey")
    ptext(b, format("DAMAGE %.1f  RATE %.1f/S  SHOTS %d  SYNERGY +%d%%", wdmg(p), wrate(p), wcount(p), ((synergy_mult(p) - 1) * 100).round), 56, 60, "lime")
    ptext(b, "TAGS: " + (w[:tags].empty? ? "NONE" : w[:tags].map { |t| FAMILIES[t][:name] }.join(", ")) + "  (EACH MATCHING TRAIT RANK +8%, GEAR PIECE +12%)", 56, 70, "tan")
    wrap_text(w[:desc], SW - 90).first(1).each { |l| ptext(b, l, 56, 80, "white") }
    SLOTS.each_with_index do |sl, i|
      g = p[:gear][sl]
      x = 16 + (i % 2) * 212; y = 100 + (i / 2) * 58
      panel(b, x, y, 204, 52, g ? RARITY_HEX[g[:rarity]] : "#2a2838", "#17121e")
      ptext(b, SLOT_NAME[sl], x + 6, y + 4, "dim")
      if g
        gi = Img["g_" + g[:id]]; b.stretch_blt(Rect.new(x + 6, y + 14, 20, 20), gi, gi.rect)
        ptext(b, g[:name], x + 32, y + 14, RARITY_COL[g[:rarity]])
        sl2 = g[:stats].map { |k, v| stat_line(k, v) }.compact.join("  ")
        ptext(b, sl2, x + 32, y + 24, "lime") unless sl2.empty?
        wrap_text(g[:desc], 166).first(2).each_with_index { |l, j| ptext(b, l, x + 32, y + 33 + j * 8, "white") }
      else
        ptext(b, "EMPTY", x + 32, y + 22, "dim")
      end
    end
    y = 220
    p[:sets].each do |id, n|
      next if n <= 0
      st = SETS[id]
      txt = "#{st[:name]} #{n}/4:  2: #{st[:d2]}   4: #{st[:d4]}"
      ptext(b, txt, SW / 2, y, n >= 2 ? "gold" : "dim", 1, 0.5)
      y += 9
    end
    ptext(b, "PRESS ANY BUTTON", SW / 2, 266, "dim", 1, 0.5)
  end

  def draw_relics(b)
    p = $G.player
    ptext(b, "RELICS (#{p[:relics].size})", SW / 2, 16, "gold", 2, 0.5)
    ptext(b, "NONE YET. OPEN CHESTS AND VISIT SHOPS.", SW / 2, 60, "grey", 1, 0.5) if p[:relics].empty?
    p[:relics].each_with_index do |r, i|
      col = i % 2; row = i / 2
      x = 16 + col * 216; y = 36 + row * 13
      next if y > 232
      ic = Img["relic_" + r[:id]]; b.blt(x, y - 1, ic, ic.rect)
      ptext(b, r[:name], x + 13, y + 1, RARITY_COL[r[:rarity]])
      d = r[:desc]
      d = d[0, 34] + "." if text_w(r[:name]) + text_w(d) > 190 && d.size > 34
      ptext(b, d, x + 13 + text_w(r[:name]) + 5, y + 1, "tan") if text_w(r[:name]) + text_w(d) <= 195
    end
    ptext(b, "AND #{p[:relics].size - 30} MORE", SW / 2, 236, "grey", 1, 0.5) if p[:relics].size > 30
    s = format("DMG %.1f  RATE %.1f/S  SHOTS %d  PIERCE %d  CRIT %d%%  SPEED %d", wdmg(p), wrate(p), wcount(p), [wpierce(p), 99].min, (p[:crit] * 100).round, p[:speed].round)
    ptext(b, s, SW / 2, 250, "grey", 1, 0.5)
    ptext(b, "PRESS ANY BUTTON", SW / 2, 266, "dim", 1, 0.5)
  end

  def draw_choice(b)
    c = $G.choice
    ptext(b, "CHOOSE A RELIC", SW / 2, 40, "gold", 2, 0.5)
    n = c[:relics].size; w = n > 3 ? 100 : 120; gap = n > 3 ? 8 : 14
    x0 = (SW - (n * w + (n - 1) * gap)) / 2
    c[:relics].each_with_index do |r, i|
      x = x0 + i * (w + gap); y = 72; h = 140; sel = c[:idx] == i
      oy = sel ? -4 : 0
      panel(b, x, y + oy, w, h, sel ? "#f2c94c" : RARITY_HEX[r[:rarity]], sel ? "#221a2c" : "#17121e")
      @menu_glow.get(Img["glow_white"], x + w / 2 - 24, y + 20) if sel
      menu_sprite("relic_" + r[:id], x + w / 2, y + 58 + (sel ? (Math.sin($G.time * 5) * 2).round - 4 : 0), 4)
      wrap_text(r[:name], w - 10).each_with_index { |l, j| ptext(b, l, x + w / 2, y + 72 + j * 8 + oy, "gold", 1, 0.5) }
      ptext(b, RARITY_NAME[r[:rarity]], x + w / 2, y + h - 12 + oy, RARITY_COL[r[:rarity]], 1, 0.5)
      wrap_text(r[:desc], w - 14).each_with_index { |l, j| ptext(b, l, x + w / 2, y + 94 + j * 8 + oy, "white", 1, 0.5) }
    end
    ptext(b, "< >  CHOOSE     USE  TAKE", SW / 2, 236, "grey", 1, 0.5)
  end

  def draw_end(b)
    g = $G; p = g.player; r = g.run_stats
    win = g.state == :win
    ptext(b, win ? "THE CRYPT IS SILENT" : "YOU HAVE FALLEN", SW / 2, 30, win ? "gold" : "red", 3, 0.5)
    s = menu_sprite(p[:hero][:sprite], SW / 2, 92, 3)
    unless win then s.color.set(255, 255, 255, 255); s.opacity = 128 end
    msg = win ? p[:hero][:name] + " ESCAPED WITH THE REGENT'S CROWN" + (g.dread > 0 ? " ON DREAD #{g.dread}" : "") : "SLAIN BY " + g.death_by.upcase
    ptext(b, msg, SW / 2, 102, "white", 1, 0.5)
    rows = [["FLOOR REACHED", "#{g.floor_index + 1} - #{FLOORS[g.floor_index][:name]}"], ["FOES SLAIN", r[:kills]], ["GUARDIANS", r[:bosses]], ["SECRETS FOUND", r[:secrets]], ["TIME", fmt_time(r[:time])]]
    rows.each_with_index { |row, i| ptext(b, row[0], 120, 118 + i * 11, "grey"); ptext(b, row[1], SW - 120, 118 + i * 11, "white", 1, 1) }
    shown = p[:relics].first(30)
    shown.each_with_index { |rl, i| ic = Img["relic_" + rl[:id]]; b.blt(SW / 2 - shown.size * 6 + i * 12, 182, ic, ic.rect) }
    if g.award
      a = g.award
      parts = a[:parts].select { |x| x[1] > 0 }.map { |x| "#{x[0]} #{x[1]}" }.join("  ")
      ptext(b, parts, SW / 2, 200, "tan", 1, 0.5)
      extra = a[:mult] > 1 ? format("  (DREAD X%.2f)", a[:mult]) : ""
      ptext(b, "+#{a[:total]} EMBERS" + extra, SW / 2, 212, "orange", 2, 0.5)
    end
    ptext(b, "PRESS USE TO CONTINUE", SW / 2, 250, (g.time * 2).floor.odd? ? "white" : "grey", 1, 0.5) if g.state_t > 1
  end
end

def fmt_time(s)
  s = s.floor
  format("%d:%02d", s / 60, s % 60)
end
