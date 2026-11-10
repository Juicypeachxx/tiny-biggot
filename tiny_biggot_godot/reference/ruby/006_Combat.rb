# Cinder Crypt - bosses, bullets, pickups, bombs, particles.

BOSS_PLANS = {
  "colossus" => %w(ring volley slam ring summon),
  "sporemother" => %w(spiral burst cloud summon spiral burst),
  "librarian" => %w(pages tide ring summon pages tide),
  "tyrant" => %w(charge sweep embers charge sweep),
  "rimewarden" => %w(freeze charge hail shards freeze charge),
  "regent" => %w(teleport beams spiral teleport summon beams curtain),
}
BOSS_SUMMONS = {
  "colossus" => %w(bat bat skeleton), "sporemother" => %w(slime mushroom slime),
  "tyrant" => %w(imp imp), "regent" => %w(cultist ghost), "librarian" => %w(bookwyrm bookwyrm drowned),
  "rimewarden" => %w(wisp wisp),
}

def boss_half?(e); e[:hp] < e[:max_hp] * (dread >= 4 ? 0.7 : 0.5); end

def boss_done(e, wait = 0.8)
  half = boss_half?(e)
  e[:state] = :rest; e[:st] = 0.0; e[:t] = wait * (half ? 0.7 : 1)
end

def update_boss(e, dt)
  p = $G.player
  half = boss_half?(e)
  e[:st] += dt
  if e[:state] == :intro
    e[:state] = :pick if e[:t] <= 0
    return
  end
  if e[:state] == :pick
    plan = BOSS_PLANS[e[:boss]]
    nxt = plan[e[:cycle] % plan.size]
    e[:cycle] += 1
    nxt = plan[0] if nxt == "summon" && ($G.enemies.size > 5 || (!half && e[:boss] == "colossus"))
    nxt = "spiral" if nxt == "curtain" && !half
    e[:state] = nxt.to_sym; e[:st] = 0.0; e[:sub] = 0; e[:t] = 0.0
    return
  end
  if e[:state] == :rest
    if !e[:target] || dist(e, e[:target]) < 4
      e[:target] = { x: rint(3 * TS + 40, 25 * TS - 40).to_f, y: rint(4 * TS + 10, 4 * TS + 70).to_f }
    end
    steer(e, e[:target][:x], e[:target][:y], 40, dt, :flyer)
    e[:state] = :pick if e[:t] <= 0
    return
  end
  cx = e[:x]; cy = e[:y] - 4
  case e[:state]
  when :ring
    if e[:t] <= 0
      e[:t] = 0.5; n = half ? 20 : 16
      spr = { "colossus" => "bone", "librarian" => "water", "rimewarden" => "ice" }[e[:boss]] || "red"
      ering(cx, cy, n, 72, e[:sub] * (Math::PI / n), spr)
      e[:sub] += 1
      boss_done(e) if e[:sub] >= 4
    end
  when :volley
    if e[:t] <= 0
      e[:t] = 0.42; efan(cx, cy, ang_to(e, p), half ? 7 : 5, 0.9, 115, "bone")
      e[:sub] += 1
      boss_done(e) if e[:sub] >= 5
    end
  when :slam
    if e[:sub] == 0
      e[:from] = { x: e[:x], y: e[:y] }
      e[:to] = { x: clampf(p[:x], 4 * TS, 24 * TS), y: clampf(p[:y], 4 * TS, 15 * TS) }
      e[:sub] = 1; e[:st] = 0.0; Snd.play("charge")
    end
    k = [1.0, e[:st] / 0.7].min
    e[:x] = e[:from][:x] + (e[:to][:x] - e[:from][:x]) * k
    e[:y] = e[:from][:y] + (e[:to][:y] - e[:from][:y]) * k
    e[:z] = Math.sin(k * Math::PI) * 30
    if k >= 1
      e[:z] = 0.0; add_shake(8); Snd.play("boom")
      ering(e[:x], e[:y], half ? 28 : 22, 85, rnd, "bone")
      burst(e[:x], e[:y] + 8, ["#8b8f9c", "#d9d0b4"], 20, 90)
      e[:slams] = (e[:slams] || 0) + 1
      if e[:slams] >= (half ? 3 : 2) then e[:slams] = 0; boss_done(e, 1)
      else e[:sub] = 0
      end
    end
  when :summon
    if e[:sub] == 0
      e[:sub] = 1
      BOSS_SUMMONS[e[:boss]].each { |t| s = free_spot($G.room, p, 80, :flyer); spawn_enemy(t, s[:x], s[:y]) }
    end
    boss_done(e, 0.6) if e[:st] > 1
  when :spiral
    if e[:t] <= 0
      e[:t] = 0.075
      e[:angle] += e[:boss] == "regent" ? 0.19 : 0.23
      arms = half ? 4 : 2
      arms.times { |i| eshot(cx, cy, e[:angle] + i.to_f / arms * TAU, 70, e[:boss] == "regent" ? "dark" : "spore") }
      if e[:boss] == "regent"
        arms.times { |i| eshot(cx, cy, -e[:angle] + i.to_f / arms * TAU + 0.5, 60, "cyan") }
      end
      Snd.play("ebullet") if e[:sub] % 4 == 0
      e[:sub] += 1
    end
    boss_done(e, 1) if e[:st] > 3.2
  when :burst
    if e[:t] <= 0
      e[:t] = 0.6
      a = ang_to(e, p)
      (half ? 14 : 10).times { eshot(cx, cy, a + (rnd - 0.5) * 1.3, 90 + rnd * 60, "spore") }
      Snd.play("ebullet")
      e[:sub] += 1
      boss_done(e) if e[:sub] >= 3
    end
  when :cloud
    if e[:t] <= 0
      e[:t] = 0.8
      ering(cx, cy, 30, 48, rnd, "spore", ang_to(e, p) + (rnd - 0.5) * 0.6, 0.32)
      e[:sub] += 1
      boss_done(e) if e[:sub] >= 4
    end
  when :pages
    if e[:t] <= 0
      e[:t] = 0.09; e[:angle] += 0.31
      3.times { |i| eshot(cx, cy, e[:angle] + i * TAU / 3, 66, "page") }
      eshot(cx, cy, ang_to(e, p), 95, "water") if e[:sub] % 6 == 0 && half
      Snd.play("ebullet") if e[:sub] % 4 == 0
      e[:sub] += 1
    end
    boss_done(e, 1) if e[:st] > 3.0
  when :tide
    if e[:t] <= 0
      e[:t] = 1.0
      gap = rint(4, 11)
      left = e[:sub].even?
      15.times do |i|
        next if (i - gap).abs <= 1
        y = IY0 * TS + i * TS + 8
        eshot(left ? IX0 * TS + 4 : (IX0 + IW) * TS - 4, y, left ? 0 : Math::PI, 62, "water")
      end
      Snd.play("ebullet")
      e[:sub] += 1
      boss_done(e, 1) if e[:sub] >= (half ? 5 : 4)
    end
  when :freeze
    if e[:t] <= 0
      e[:t] = 0.7
      ering(cx, cy, 28, 46, rnd, "ice", ang_to(e, p) + (rnd - 0.5) * 0.5, 0.3)
      e[:sub] += 1
      boss_done(e) if e[:sub] >= 4
    end
  when :hail
    if e[:t] <= 0
      e[:t] = half ? 0.08 : 0.11
      eshot(rint(IX0 * TS + 8, (IX0 + IW) * TS - 8), IY0 * TS + 4, Math::PI / 2 + (rnd - 0.5) * 0.2, 80 + rnd * 40, "ice")
      Snd.play("ebullet") if e[:sub] % 5 == 0
      e[:sub] += 1
    end
    boss_done(e, 1) if e[:st] > 3.2
  when :shards
    if e[:t] <= 0
      e[:t] = 0.5
      a = ang_to(e, p)
      eshot(cx, cy, a, 110, "iceBig", 4, { fuse: 0.55, burst: "ice" })
      Snd.play("ebullet")
      e[:sub] += 1
      boss_done(e, 1) if e[:sub] >= (half ? 6 : 4)
    end
  when :charge
    if e[:sub] == 0
      e[:sub] = 1; e[:st] = 0.0; e[:ca] = ang_to(e, p); e[:charges] = (e[:charges] || 0) + 1; Snd.play("charge")
    end
    if e[:sub] == 1
      e[:telegraph] = e[:ca]
      if e[:st] > 0.55 then e[:sub] = 2; e[:st] = 0.0; e[:telegraph] = nil end
    elsif e[:sub] == 2
      bx, by = move_body($G.room, e, Math.cos(e[:ca]) * 250 * dt, Math.sin(e[:ca]) * 250 * dt, :flyer)
      particle(e[:x] + rint(-8, 8), e[:y] + 10, 0, -10, 0.3, e[:boss] == "rimewarden" ? pick(["#c8f0ff", "#6fd3e0"]) : pick(["#e8873a", "#f2c94c"]), 2) if rnd < 0.6
      if bx || by || e[:st] > 1.4
        add_shake(7); Snd.play("boom")
        ering(e[:x], e[:y], half ? 16 : 12, 80, rnd, e[:boss] == "rimewarden" ? "ice" : "fire")
        if e[:charges] >= 3 then e[:charges] = 0; boss_done(e, 1.2)
        else e[:sub] = 0
        end
      end
    end
  when :sweep
    if e[:sub] == 0 then e[:sub] = 1; e[:angle] = ang_to(e, p) - 1.9 end
    if e[:t] <= 0
      e[:t] = 0.055; e[:angle] += 0.065
      eshot(cx, cy, e[:angle], 105, "fire")
      eshot(cx, cy, e[:angle] + Math::PI, 105, "fire") if half
      Snd.play("ebullet")
    end
    boss_done(e, 1) if e[:st] > 3
  when :embers
    if e[:t] <= 0
      e[:t] = 0.35
      a = ang_to(e, p) + (rnd - 0.5) * 1.6
      eshot(cx, cy, a, 120, "fireBig", 4, { fuse: 0.7 + rnd * 0.4, burst: "fire" })
      Snd.play("ebullet")
      e[:sub] += 1
      boss_done(e, 1.2) if e[:sub] >= (half ? 7 : 5)
    end
  when :teleport
    if e[:sub] == 0
      e[:sub] = 1; e[:st] = 0.0; burst(e[:x], e[:y], ["#a35bd6", "#5c3483"], 20, 80); Snd.play("portal")
    end
    if e[:sub] == 1
      e[:hidden] = true
      if e[:st] > 0.6
        s = free_spot($G.room, p, 110, :flyer)
        e[:x] = clampf(s[:x], 4 * TS, 24 * TS); e[:y] = clampf(s[:y], 4 * TS, 14 * TS)
        e[:hidden] = false; e[:sub] = 2
        burst(e[:x], e[:y], ["#a35bd6", "#f4ecd8"], 20, 80)
        ering(e[:x], e[:y], half ? 18 : 14, 70, rnd, "darkBig")
      end
    end
    boss_done(e, 0.4) if e[:sub] == 2 && e[:st] > 1.0
  when :beams
    if e[:sub] == 0
      e[:sub] = 1; e[:st] = 0.0
      a = ang_to(e, p); n = half ? 5 : 3
      e[:beams] = (0...n).map { |i| a + (i - (n - 1) / 2.0) * 0.42 }
      Snd.play("charge")
    end
    if e[:sub] == 1 && e[:st] > 0.85 then e[:sub] = 2; e[:st] = 0.0; Snd.play("beam"); add_shake(5) end
    if e[:sub] == 2
      e[:beams].each do |ba|
        dx = Math.cos(ba); dy = Math.sin(ba)
        px = p[:x] - e[:x]; py = p[:y] - e[:y]
        along = px * dx + py * dy
        perp = (px * dy - py * dx).abs
        hurt_player(1, e[:d][:name]) if along > 0 && perp < 7
      end
      if e[:st] > 0.35
        e[:beams] = []
        e[:repeat] = (e[:repeat] || 0) + 1
        if e[:repeat] >= 2 then e[:repeat] = 0; boss_done(e, 0.8)
        else e[:sub] = 0
        end
      end
    end
  when :curtain
    if e[:t] <= 0
      e[:t] = 1.1
      gap = rint(2, 22)
      26.times do |i|
        next if (i - gap).abs <= 1
        eshot(IX0 * TS + i * TS + 8, IY0 * TS + 6, Math::PI / 2, 58, "dark")
      end
      Snd.play("ebullet")
      e[:sub] += 1
      boss_done(e, 1) if e[:sub] >= 5
    end
  end
end

# ---------- Bullets ----------
def update_pbullets(dt)
  room = $G.room; p = $G.player
  $G.pbullets.each do |b|
    b[:life] -= dt
    b[:age] += dt
    b[:rot] += dt * 18
    if p[:lens] && b[:kind] != "spark"
      b[:r] = [b[:r] + dt * 4, 2.5 * wsize(p) * 2.2].min
      b[:dmg] += b[:dmg] * dt * 0.9
    end
    if b[:back] == false && b[:life] < b[:max_life] * 0.5
      b[:back] = true; b[:hit] = {}
    end
    if b[:back]
      a = Math.atan2(p[:y] - b[:y], p[:x] - b[:x]); sp = Math.hypot(b[:vx], b[:vy])
      b[:vx] = Math.cos(a) * sp; b[:vy] = Math.sin(a) * sp
      b[:life] = [b[:life], 0.02].max
      if Math.hypot(p[:x] - b[:x], p[:y] - b[:y]) < 8 then b[:life] = 0; next end
      b[:x] += b[:vx] * dt; b[:y] += b[:vy] * dt
      pbullet_hits(b, p)
      next
    end
    if b[:homing] > 0
      t = nearest_enemy(b, 120)
      if t
        cur = Math.atan2(b[:vy], b[:vx]); want = ang_to(b, t)
        d = Math.atan2(Math.sin(want - cur), Math.cos(want - cur))
        turn = clampf(d, -b[:homing] * dt, b[:homing] * dt)
        sp = Math.hypot(b[:vx], b[:vy]); na = cur + turn
        b[:vx] = Math.cos(na) * sp; b[:vy] = Math.sin(na) * sp
      end
    end
    nx = b[:x] + b[:vx] * dt; ny = b[:y] + b[:vy] * dt
    c = (nx / TS).floor; r = (ny / TS).floor
    if solid?(room, c, r, :bullet)
      hit_crate(room, c, r, b[:dmg])
      if b[:back] == false
        b[:back] = true; b[:hit] = {}
      elsif b[:bounce] > 0
        b[:bounce] -= 1
        flipped = false
        if solid?(room, (nx / TS).floor, (b[:y] / TS).floor, :bullet) then b[:vx] = -b[:vx]; flipped = true end
        if solid?(room, (b[:x] / TS).floor, (ny / TS).floor, :bullet) then b[:vy] = -b[:vy]; flipped = true end
        unless flipped then b[:vx] = -b[:vx]; b[:vy] = -b[:vy] end
      else
        b[:life] = 0
        explode_at(b[:x], b[:y], b[:dmg] * 0.6 * p[:explode], nil, (18 + (b[:kind] == "flask" ? 8 + 26 * p[:splash] : 0))) if p[:explode] > 0
        burst(b[:x], b[:y], b[:kind] == "flask" ? ["#63b84f", "#b8e05a"] : ["#f4ecd8", "#8b8f9c"], 4, 40, 0.2)
      end
      next
    end
    b[:x] = nx; b[:y] = ny
    pbullet_hits(b, p)
  end
  $G.pbullets.reject! { |b| b[:life] <= 0 }
  $G.pbullets.concat($G.new_pbullets)
  $G.new_pbullets.clear
end

def pbullet_hits(b, p)
  $G.enemies.each do |e|
    next if e[:hp] <= 0 || e[:spawn_t] > 0 || e[:hidden] || b[:hit][e.object_id]
    er = e[:r] + (e[:type] == "boss" ? 2 : 0)
    next unless Math.hypot(e[:x] - b[:x], (e[:y] - e[:z]) - b[:y]) < er + b[:r]
    b[:hit][e.object_id] = true
    sp = Math.hypot(b[:vx], b[:vy]); sp = 1 if sp == 0
    kb = p[:hero][:id] == "brute" ? 160 : 70
    dmg = b[:dmg]
    dmg *= 2 if b[:back] && p[:back_dmg]
    crit = damage_enemy(e, dmg, { kx: b[:vx] / sp * kb, ky: b[:vy] / sp * kb, force_crit: b[:crit] })
    e[:burn_t] = 3.0 + p[:burn_time] if p[:burn] > 0 && rnd < p[:burn]
    if (b[:chill] || (p[:chill] > 0 && rnd < p[:chill])) then e[:chill_t] = 2.0 + p[:chill_time]; burst(e[:x], e[:y], ["#6fd3e0", "#ffffff"], 5, 30) end
    e[:poison] = [12, e[:poison] + p[:poison] + b[:poison_add]].min if p[:poison] > 0 || b[:poison_add] > 0
    e[:stun_t] = e[:type] == "boss" ? 0.25 : 1.0 if p[:stun] > 0 && rnd < p[:stun]
    e[:curse_t] = 3.0 if p[:curse] > 0 && rnd < p[:curse]
    chain_from(e, dmg * 0.6) if p[:chain] > 0 && rnd < p[:chain]
    explode_at(b[:x], b[:y], dmg * 0.5 * p[:explode], e, 18 + (b[:kind] == "flask" ? 8 + 26 * p[:splash] : 0)) if p[:explode] > 0
    explode_at(b[:x], b[:y], dmg * 0.6, e, 16, "#e8873a", true) if p[:shrapnel] > 0 && rnd < p[:shrapnel]
    lightning(e, dmg) if p[:storm] > 0 && rnd < p[:storm]
    burst(b[:x], b[:y], ["#f4ecd8", "#fffbe0"], 3, 50, 0.2)
    if b[:bloom]
      b[:bloom] = false
      a0 = Math.atan2(b[:vy], b[:vx])
      [-0.5, 0.5].each do |da|
        nb = b.dup; nb[:hit] = b[:hit].dup; nb[:dmg] = dmg * 0.6; nb[:r] = b[:r] * 0.8; nb[:bloom] = false
        nb[:vx] = Math.cos(a0 + da) * sp; nb[:vy] = Math.sin(a0 + da) * sp
        $G.new_pbullets << nb
      end
    end
    if b[:pierce] > 0
      b[:pierce] -= 1
    elsif crit && p[:crit_pierce]
      # Piercing crit: keep flying.
    elsif b[:ric] && b[:ric] > 0
      t = nearest_enemy(b, 110, b[:hit])
      if t
        b[:ric] -= 1
        a = ang_to(b, t); b[:vx] = Math.cos(a) * sp; b[:vy] = Math.sin(a) * sp
        b[:life] = [b[:life], 0.5].max
      else
        b[:life] = 0
      end
      break
    else
      b[:life] = 0
      break
    end
  end
end

def lightning(e, dmg)
  p = $G.player
  x = e[:x]; y = e[:y]
  12.times { |i| particle(x + rint(-2, 2), y - 60 + i * 5, 0, 0, 0.18, i.even? ? "#ffffff" : "#6fd3e0", 2) }
  burst(x, y, ["#6fd3e0", "#ffffff"], 10, 70, 0.3)
  Snd.play("beam") if rnd < 0.3
  $G.enemies.each do |o|
    next if o[:hp] <= 0
    damage_enemy(o, dmg * 1.5 * (1 + p[:storm_dmg]), { no_crit: true, col: "cyan", silent: true }) if Math.hypot(o[:x] - x, o[:y] - y) < 24 + o[:r]
  end
end

def hit_crate(room, c, r, dmg)
  return unless room[:grid][r] && room[:grid][r][c] == T_CRATE
  k = [c, r]
  room[:crate_hp][k] -= dmg
  burst(c * TS + 8, r * TS + 8, ["#7a5236", "#4b3324"], 3, 40, 0.25)
  if room[:crate_hp][k] <= 0
    room[:grid][r][c] = T_FLOOR
    burst(c * TS + 8, r * TS + 8, ["#7a5236", "#4b3324", "#e3b08a"], 14, 70, 0.5)
    Snd.play("kill")
    drop_pickup(:coin, c * TS + 8.0, r * TS + 8.0) if rnd < 0.35
    drop_pickup(:heart, c * TS + 8.0, r * TS + 8.0) if rnd < 0.05
    $G.dyn_dirty = true
  end
end

def chain_from(src, dmg)
  p = $G.player
  hit = { src.object_id => true }
  cur = src
  (1 + p[:chain_jumps]).times do
    best = nil; bd = 80
    $G.enemies.each do |e|
      next if hit[e.object_id] || !targetable?(e)
      d = dist(cur, e)
      if d < bd then bd = d; best = e end
    end
    break unless best
    n = (bd / 6).ceil
    (0..n).each do |i|
      k = i.to_f / n
      particle(cur[:x] + (best[:x] - cur[:x]) * k + rint(-2, 2), cur[:y] + (best[:y] - cur[:y]) * k + rint(-2, 2), 0, 0, 0.15, rnd < 0.5 ? "#6fd3e0" : "#ffffff")
    end
    damage_enemy(best, dmg * (1 + p[:storm_dmg]), { col: "cyan" })
    hit[best.object_id] = true
    cur = best
  end
end

def explode_at(x, y, dmg, skip, radius = 18, col = nil, boom = false, from_bomb = false)
  burst(x, y, col ? [col, "#f2c94c", "#fffbe0"] : ["#e8873a", "#f2c94c", "#d8443c"], 8 + (radius / 4).round, 70 + radius, 0.3)
  $G.enemies.each do |e|
    next if e.equal?(skip) || e[:hp] <= 0
    next unless Math.hypot(e[:x] - x, e[:y] - y) < radius + e[:r]
    damage_enemy(e, dmg, { no_crit: true, col: "orange", silent: true, boom: boom || from_bomb, bomb: from_bomb })
  end
end

def update_ebullets(dt)
  room = $G.room; p = $G.player
  orbs = p[:orbitals] > 0 ? orbital_positions(p) : []
  $G.ebullets.each do |b|
    b[:life] -= dt
    if b[:fuse]
      b[:fuse] -= dt; b[:vx] *= 0.97; b[:vy] *= 0.97
      if b[:fuse] <= 0 then b[:life] = 0; ering(b[:x], b[:y], 8, 70, rnd, b[:burst]); next end
    end
    slow = (p[:mirror] && Math.hypot(b[:x] - p[:x], b[:y] - p[:y]) < 40) ? 0.5 : 1.0
    b[:x] += b[:vx] * dt * slow; b[:y] += b[:vy] * dt * slow
    if solid?(room, (b[:x] / TS).floor, (b[:y] / TS).floor, :bullet)
      b[:life] = 0
      burst(b[:x], b[:y], ["#8b8f9c", "#4e4a5e"], 3, 30, 0.2)
      next
    end
    orbs.each do |o|
      if Math.hypot(o[:x] - b[:x], o[:y] - b[:y]) < 6 then b[:life] = 0; burst(b[:x], b[:y], ["#f4ecd8"], 4, 40, 0.2) end
    end
    if b[:life] > 0 && Math.hypot(p[:x] - b[:x], (p[:y] - 2) - b[:y]) < b[:r] + p[:hit_r]
      if p[:dodge_t] <= 0 && p[:invuln] <= 0 then b[:life] = 0; hurt_player(1, "a stray shot") end
    end
  end
  $G.ebullets.reject! { |b| b[:life] <= 0 }
end

# ---------- Pickups ----------
def drop_pickup(kind, x, y)
  a = rnd * TAU; s = 30 + rnd * 50
  $G.pickups << { kind: kind, x: x.to_f, y: y.to_f, vx: Math.cos(a) * s, vy: Math.sin(a) * s, z: 0.0, vz: 60 + rnd * 40, t: 0.0, r: 3 }
end

def update_pickups(dt)
  p = $G.player; room = $G.room
  $G.pickups.each do |k|
    k[:t] += dt
    k[:vz] -= 300 * dt; k[:z] += k[:vz] * dt
    if k[:z] < 0 then k[:z] = 0.0; k[:vz] = k[:vz].abs > 30 ? -k[:vz] * 0.4 : 0.0 end
    k[:vx] *= 0.9; k[:vy] *= 0.9
    d = Math.hypot(p[:x] - k[:x], p[:y] - k[:y])
    coinlike = k[:kind] == :coin || k[:kind] == :gem
    if coinlike && (d < (p[:magnet] ? 90 : 40) || !$G.locked) && k[:t] > 0.4
      a = Math.atan2(p[:y] - k[:y], p[:x] - k[:x])
      k[:vx] += Math.cos(a) * 900 * dt; k[:vy] += Math.sin(a) * 900 * dt
    end
    if coinlike && !$G.locked then k[:x] += k[:vx] * dt; k[:y] += k[:vy] * dt
    else move_body(room, k, k[:vx] * dt, k[:vy] * dt, :walker)
    end
    next unless d < 9 && k[:t] > 0.25
    if k[:kind] == :coin
      p[:gold_frac] += p[:gold_mult]; g = p[:gold_frac].floor; p[:gold_frac] -= g; p[:gold] += g; $G.run_stats[:gold] += g
      k[:dead] = true; Snd.play("coin")
      particle(k[:x], k[:y] - 3, 0, -20, 0.2, "#f2c94c")
    elsif k[:kind] == :gem
      p[:gold_frac] += 5 * p[:gold_mult]; g = p[:gold_frac].floor; p[:gold_frac] -= g; p[:gold] += g; $G.run_stats[:gold] += g
      k[:dead] = true; Snd.play("coin"); float_text(p[:x], p[:y] - 12, "+#{g} GOLD", "gold")
    elsif k[:kind] == :bomb
      k[:dead] = true; p[:bombs] += 1; Snd.play("coin"); float_text(p[:x], p[:y] - 12, "+BOMB", "white")
    elsif k[:kind] == :key
      k[:dead] = true; p[:keys] += 1; Snd.play("coin"); float_text(p[:x], p[:y] - 12, "+KEY", "gold")
    elsif k[:kind] == :armor
      k[:dead] = true; p[:armor] += 1; Snd.play("heal"); float_text(p[:x], p[:y] - 12, "+ARMOR", "cyan")
    elsif k[:kind] == :ember
      k[:dead] = true; p[:embers_found] += 3; Snd.play("relic"); float_text(p[:x], p[:y] - 12, "+3 EMBERS", "orange")
    elsif k[:kind] == :heart && p[:hp] < p[:max_hp]
      k[:dead] = true; heal_player(2)
    elsif k[:kind] == :potion && p[:potions] < p[:max_potions]
      k[:dead] = true; p[:potions] += 1; Snd.play("heal"); float_text(p[:x], p[:y] - 12, "+POTION", "pink")
    end
  end
  $G.pickups.reject! { |k| k[:dead] }
end

def update_bombs(dt)
  fresh = []
  $G.bombs.each do |b|
    b[:t] -= dt
    next unless b[:t] <= 0
    p = $G.player; room = $G.room
    rad = (b[:mini] ? 20 : 32) * p[:bomb_r]
    Snd.play("boom"); add_shake(b[:mini] ? 2 : 5)
    explode_at(b[:x], b[:y], [10.0, wdmg(p) * 3].max * p[:bomb_mult] * (b[:mini] ? 0.5 : 1), nil, rad, nil, true, true)
    burst(b[:x], b[:y], ["#e8873a", "#f2c94c", "#4e4a5e"], b[:mini] ? 10 : 24, 110, 0.5, 2)
    hurt_player(1, "your own bomb") if !b[:safe] && Math.hypot(p[:x] - b[:x], p[:y] - b[:y]) < 22
    c0 = ((b[:x] - rad) / TS).floor; c1 = ((b[:x] + rad) / TS).floor
    r0 = ((b[:y] - rad) / TS).floor; r1 = ((b[:y] + rad) / TS).floor
    (r0..r1).each { |r| (c0..c1).each { |c| hit_crate(room, c, r, 999) if tile_at(room, c, r) == T_CRATE } }
    room[:secret_dirs].keys.each do |d|
      cx, cy = door_center(d)
      $G.open_secret_door(d) if Math.hypot(cx - b[:x], cy - b[:y]) < 44
    end
    if cap?(p, :cluster) && !b[:mini]
      4.times { |i| a = i / 4.0 * TAU + 0.4; fresh << { x: b[:x] + Math.cos(a) * 22, y: b[:y] + Math.sin(a) * 22, t: 0.35 + i * 0.05, safe: true, mini: true } }
    end
  end
  $G.bombs.reject! { |b| b[:t] <= 0 }
  $G.bombs.concat(fresh)
end

def update_zones(dt)
  p = $G.player
  $G.zones.each do |z|
    z[:t] -= dt
    z[:tick] -= dt
    case z[:kind]
    when :smoke
      $G.ebullets.reject! { |b| Math.hypot(b[:x] - z[:x], b[:y] - z[:y]) < z[:r] }
    when :fire, :poison
      next unless z[:tick] <= 0
      z[:tick] = 0.4
      $G.enemies.each do |e|
        next unless targetable?(e) && Math.hypot(e[:x] - z[:x], e[:y] - z[:y]) < z[:r] + e[:r]
        if z[:kind] == :fire
          e[:burn_t] = [e[:burn_t], 2.0 + p[:burn_time]].max
          damage_enemy(e, wdmg(p) * 0.3, { no_crit: true, col: "orange", silent: true })
        else
          e[:poison] = [12, e[:poison] + 1].min
        end
      end
    end
  end
  $G.zones.reject! { |z| z[:t] <= 0 }
end

def update_particles(dt)
  $G.particles.each do |q|
    q[:life] -= dt; q[:x] += q[:vx] * dt; q[:y] += q[:vy] * dt
    q[:vx] *= q[:drag]; q[:vy] *= q[:drag]
  end
  $G.particles.reject! { |q| q[:life] <= 0 }
  $G.particles.shift($G.particles.size - 400) if $G.particles.size > 400
  $G.texts.each { |t| t[:life] -= dt; t[:y] -= 22 * dt }
  $G.texts.reject! { |t| t[:life] <= 0 }
  $G.texts.shift($G.texts.size - 40) if $G.texts.size > 40
end
