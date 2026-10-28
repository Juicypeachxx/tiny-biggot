# Tiny Biggot - weapon and equipment engine: equipping, weapon-based stats, attack types, item abilities.

def cw(p); p[:weapon]; end
def gf(p, k); p[:gf] ? p[:gf][k] : 0; end
def cap?(p, k); (p[k] && p[k] != 0) || gf(p, k) > 0; end

# Weapon tags synergise with matching trait families and gear pieces.
def synergy_mult(p)
  w = cw(p)
  return 1.0 unless w && !w[:tags].empty?
  ranks = 0
  w[:tags].each { |t| ranks += p[:fam][t] || 0 }
  pieces = 0
  p[:gear].each_value { |g| pieces += 1 if g && !(g[:tags] & w[:tags]).empty? }
  1 + [0.08 * ranks, 0.64].min + 0.12 * pieces
end

def wdmg(p); cw(p)[:dmg] * p[:dmg] * synergy_mult(p); end
def wrate(p)
  r = cw(p)[:rate] * p[:rate]
  r *= 1 + 2 * p[:spin] if cw(p)[:kind] == :gatling
  r *= 1.2 if p[:haste_t] && p[:haste_t] > 0
  r
end
def wspd(p); cw(p)[:speed] * p[:shot_speed]; end
def wlife(p); cw(p)[:life] * p[:life]; end
def wsize(p); cw(p)[:size] * p[:size]; end
def wpierce(p); cw(p)[:pierce] + p[:pierce]; end
def wcount(p); [1, cw(p)[:count] + p[:count]].max; end
def wspread(p); p[:spread] || cw(p)[:spread]; end
def whoming(p); cw(p)[:homing] + p[:homing]; end
def wbounce(p); (cw(p)[:bounce] || 0) + p[:bounce]; end
def wrange(p); (cw(p)[:range] || 40) * (0.85 + 0.15 * p[:size]) * Math.sqrt(p[:life]); end

def weapon_dps(w, p = nil)
  base = w[:dmg] * w[:rate] * [1, w[:count]].max
  base *= 3 if w[:kind] == :burst
  base *= 2 if w[:kind] == :gatling
  base *= 2 if w[:kind] == :boomer
  base
end

# ---------- Equipping (fully reversible) ----------
# Consumables (armor, bombs, keys, potions) are granted once per item or set tier, never taken back,
# so dropping and re-taking an item can't farm them. Max HP is added and removed with the item.
ONCE_KEYS = [:armor, :bombs, :keys, :potions]
def apply_tuples(p, tuples, sign, src = nil)
  p[:granted] ||= {}
  first = src && !p[:granted][src]
  tuples.each do |k, v|
    if MUL_KEYS.include?(k)
      p[k] = sign > 0 ? p[k] * v : p[k] / v
    elsif ONCE_KEYS.include?(k)
      p[k] = (p[k] || 0) + v if sign > 0 && (first || src.nil?)
    else
      p[k] = (p[k] || 0) + v * sign
      p[:hp] += v * sign if k == :max_hp && v > 0
    end
  end
  p[:granted][src] = true if src && sign > 0
  p[:max_hp] = [2, p[:max_hp]].max
  p[:hp] = [[p[:hp], p[:max_hp]].min, 1].max
  p[:armor] = [0, p[:armor]].max
  p[:revive] = [0, p[:revive]].max
  p[:charges] = [[p[:charges], p[:dodge_charges]].min, 0].max
  p[:potions] = [p[:potions], p[:max_potions]].min
end

def apply_hooks(p, hooks, sign)
  hooks.each { |k, v| p[:gf][k] += v * sign }
end

def equip_weapon(p, w)
  old = p[:weapon]
  if old
    apply_tuples(p, old[:stats], -1, "w:" + old[:id])
    apply_hooks(p, old[:hooks], -1)
  end
  p[:weapon] = w
  apply_tuples(p, w[:stats], 1, "w:" + w[:id])
  apply_hooks(p, w[:hooks], 1)
  p[:spin] = 0.0
  $meta[:found_w] ||= {}
  $meta[:found_w][w[:id]] = true
  old
end

def update_sets(p, set, delta)
  return unless set
  s = SETS[set]
  p[:sets][set] = (p[:sets][set] || 0) + delta
  tier = p[:sets][set] >= 4 ? 2 : (p[:sets][set] >= 2 ? 1 : 0)
  have = p[:set_tier][set] || 0
  while have < tier
    have += 1
    if have == 1 then apply_tuples(p, s[:b2], 1, "s2:" + set)
    else apply_tuples(p, s[:b4] || [], 1, "s4:" + set); apply_hooks(p, s[:b4h] || [], 1)
    end
    $G.toast(s[:name] + " SET: " + (have == 1 ? s[:d2] : s[:d4]), "gold") if $G
  end
  while have > tier
    if have == 1 then apply_tuples(p, s[:b2], -1, "s2:" + set)
    else apply_tuples(p, s[:b4] || [], -1, "s4:" + set); apply_hooks(p, s[:b4h] || [], -1)
    end
    have -= 1
  end
  p[:set_tier][set] = have
end

def equip_gear(p, g)
  old = p[:gear][g[:slot]]
  if old
    apply_tuples(p, old[:stats], -1, "g:" + old[:id])
    apply_hooks(p, old[:hooks], -1)
    p[:gear][g[:slot]] = nil
    update_sets(p, old[:set], -1)
  end
  p[:gear][g[:slot]] = g
  apply_tuples(p, g[:stats], 1, "g:" + g[:id])
  apply_hooks(p, g[:hooks], 1)
  update_sets(p, g[:set], 1)
  $meta[:found_g] ||= {}
  $meta[:found_g][g[:id]] = true
  old
end

alias create_player_base create_player
def create_player(hero)
  p = create_player_base(hero)
  p[:dmg] = 1.0; p[:rate] = 1.0; p[:shot_speed] = 1.0; p[:life] = 1.0; p[:size] = 1.0
  p[:pierce] = 0; p[:count] = 0; p[:homing] = 0.0; p[:spread] = nil
  p[:weapon] = nil; p[:gear] = {}; p[:gf] = Hash.new(0); p[:sets] = {}; p[:set_tier] = {}
  p[:spin] = 0.0; p[:xp_mult] = 1.0; p[:haste_t] = 0.0; p[:floor_kills] = 0; p[:step_t] = 0.0; p[:fam_dmg] ||= 0.0
  p[:chain_jumps] ||= 0; p[:echo] ||= 0.0
  equip_weapon(p, WEAPON_BY_ID[HERO_WEAPON[hero[:id]]])
  p
end

# Damage bonuses from item abilities (applied in damage_enemy).
def afflicted?(e); e[:burn_t] > 0 || e[:chill_t] > 0 || e[:poison] > 0 || (e[:bleed_t] && e[:bleed_t] > 0) || (e[:stun_t] && e[:stun_t] > 0) || (e[:curse_t] && e[:curse_t] > 0); end

def hook_mult(p, e)
  return 1.0 unless p[:gf]
  m = 1.0
  m += gf(p, :moving_dmg) if p[:moving]
  m += gf(p, :still_dmg) unless p[:moving]
  m += gf(p, :low_hp_dmg) if p[:hp] <= p[:max_hp] / 2
  d = Math.hypot(e[:x] - p[:x], e[:y] - p[:y])
  m += gf(p, :close_dmg) if d < 60
  m += gf(p, :far_dmg) if d > 140
  m += gf(p, :elite_dmg) if e[:elite]
  m += gf(p, :boss_dmg) if e[:type] == "boss"
  m += gf(p, :armor_dmg) * [p[:armor], 6].min
  m += gf(p, :gold_dmg) * p[:gold] / 100.0
  m += gf(p, :relic_dmg) * p[:relics].size
  m += gf(p, :trait_dmg) * p[:traits].values.inject(0) { |a, b| a + b } if gf(p, :trait_dmg) > 0
  m += gf(p, :status_dmg) if gf(p, :status_dmg) > 0 && afflicted?(e)
  m += gf(p, :first_hit) if e[:hp] >= e[:max_hp]
  m += [0.5, gf(p, :souls) * p[:floor_kills]].min if gf(p, :souls) > 0
  m += e[:mark_v] if e[:mark_t] && e[:mark_t] > 0
  m += e[:shred] if e[:shred]
  m
end

# ---------- Firing ----------
BULLET_KIND = { bolt: "bolt", orb: "hex", spin: "spin", shot: "clod", flask: "flask", boomer: "boomer", flame: "fire",
                disc: "disc", pulse: "pulse", nova: "spark", mine: "mine", rail: "rail", burst: "bolt", gatling: "bolt", summon: "hex" }

def spawn_pbullet(p, a, dmg = nil, kind = nil, speed_mul = 1.0)
  w = cw(p)
  kind ||= BULLET_KIND[w[:kind]] || "bolt"
  sp = wspd(p) * (0.94 + rnd * 0.12) * speed_mul
  sp = 220 * speed_mul if sp <= 0
  life = wlife(p)
  life = 0.9 if life <= 0
  life *= (0.85 + rnd * 0.3) if kind == "clod" || kind == "fire"
  size = wsize(p)
  b = {
    x: p[:x] + Math.cos(a), y: p[:y] - 2 + Math.sin(a), vx: Math.cos(a) * sp, vy: Math.sin(a) * sp,
    dmg: dmg || wdmg(p), life: life, max_life: life, r: (kind == "fire" ? 2.0 : 2.5) * size, pierce: wpierce(p),
    bounce: wbounce(p), homing: whoming(p), kind: kind, hit: {}, rot: 0.0, age: 0.0, ric: p[:ricochet],
    back: kind == "boomer" ? false : nil, crit: false, bloom: p[:bloom], poison_add: 0, split: gf(p, :split),
    grow: gf(p, :grow), accel: gf(p, :accel), icon: w[:id], tag: w[:tags].first
  }
  if kind == "pulse" then b[:nohit] = true; b[:pulse_t] = 0.0; b[:linger] = gf(p, :linger) end
  if kind == "mine"
    b[:nohit] = true; b[:vx] = 0.0; b[:vy] = 0.0; b[:arm] = 0.3; b[:life] = 8.0
    b[:x] = p[:x] + Math.cos(a) * 10; b[:y] = p[:y] + Math.sin(a) * 10
    # Mines are tossed toward the aim and skid to a stop, so they can be planted on archers and casters.
    tgt = $G.enemies.select { |e| targetable?(e) && Math.cos(ang_to(p, e) - a) > 0.85 }.min_by { |e| dist(p, e) }
    reach = tgt ? [dist(p, tgt) - 10, 4].max : 50.0
    toss = [reach, 110 * p[:shot_speed]].min * 6.5
    b[:mvx] = Math.cos(a) * toss; b[:mvy] = Math.sin(a) * toss
  end
  if kind == "rail" then b[:pierce] = 99; b[:r] = 4.0 * size end
  $G.pbullets << b
  b
end

def fire_projectiles(p, a)
  w = cw(p)
  n = wcount(p)
  step = wspread(p)
  made = []
  case w[:kind]
  when :nova
    n.times { |i| made << spawn_pbullet(p, a + i * TAU / n) }
  when :flame
    n.times { made << spawn_pbullet(p, a + (rnd - 0.5) * 2 * step, nil, nil, 0.8 + rnd * 0.4) }
  when :mine
    live = $G.pbullets.count { |b| b[:kind] == "mine" }
    made << spawn_pbullet(p, a) if live < 6 + n
  else
    jit = w[:kind] == :shot ? 0.12 : (w[:kind] == :gatling ? step : 0)
    n.times { |i| made << spawn_pbullet(p, a + (i - (n - 1) / 2.0) * step + (rnd - 0.5) * jit) }
  end
  bs = p[:backshot]
  bs.times { |i| made << spawn_pbullet(p, a + Math::PI + (i - (bs - 1) / 2.0) * 0.25) }
  if w[:kind] == :summon
    while $G.temp_fams.size >= 4 do $G.temp_fams.shift end
    $G.temp_fams << { x: p[:x], y: p[:y], cd: 0.3, t: 6.0 }
  end
  made
end

def melee_hit(p, e, dmg, force_crit = false, kb = 90)
  a = ang_to(p, e)
  k = kb * (gf(p, :knock) > 0 ? gf(p, :knock) : 1)
  crit = damage_enemy(e, dmg, { kx: Math.cos(a) * k, ky: Math.sin(a) * k, force_crit: force_crit })
  on_hit_effects(e, dmg, crit, p, nil)
end

def parry_bullets(p, test)
  return if gf(p, :parry) <= 0
  $G.ebullets.reject! do |b|
    next false unless test.call(b)
    burst(b[:x], b[:y], ["#f4ecd8", "#ffffff"], 3, 40, 0.2)
    if gf(p, :reflect) > 0
      a = Math.atan2(b[:y] - p[:y], b[:x] - p[:x])
      nb = spawn_pbullet(p, a, wdmg(p) * 0.6, "spark", 1.2)
      nb[:x] = b[:x]; nb[:y] = b[:y]
    end
    true
  end
end

def attack_slash(p, a, force_crit)
  w = cw(p)
  r = wrange(p)
  arc = (w[:arc] || 110) * Math::PI / 180
  dmg = wdmg(p)
  $G.enemies.dup.each do |e|
    next unless targetable?(e)
    next if Math.hypot(e[:x] - p[:x], e[:y] - p[:y]) - e[:r] > r
    da = Math.atan2(Math.sin(ang_to(p, e) - a), Math.cos(ang_to(p, e) - a))
    next if da.abs > arc / 2
    melee_hit(p, e, dmg, force_crit, 110)
  end
  parry_bullets(p, lambda { |b|
    d = Math.hypot(b[:x] - p[:x], b[:y] - p[:y])
    da = Math.atan2(Math.sin(Math.atan2(b[:y] - p[:y], b[:x] - p[:x]) - a), Math.cos(Math.atan2(b[:y] - p[:y], b[:x] - p[:x]) - a))
    d < r + 4 && da.abs <= arc / 2
  })
  $G.swings << { kind: :slash, x: p[:x], y: p[:y] - 2, a: a, r: r, arc: arc, t: 0.14, max: 0.14, tag: w[:tags].first }
end

def attack_line(p, a, len, width, tip_crit, force_crit)
  dx = Math.cos(a); dy = Math.sin(a)
  hits = []
  $G.enemies.each do |e|
    next unless targetable?(e)
    px = e[:x] - p[:x]; py = e[:y] - p[:y]
    along = px * dx + py * dy
    perp = (px * dy - py * dx).abs
    hits << [e, along] if along > -e[:r] && along < len + e[:r] && perp < width / 2.0 + e[:r]
  end
  hits.sort_by { |h| h[1] }.each_with_index do |(e, along), i|
    dmg = wdmg(p) * (1 + gf(p, :pierce_dmg) * i)
    melee_hit(p, e, dmg, force_crit || (tip_crit && along > len * 0.7), 80)
  end
  parry_bullets(p, lambda { |b|
    px = b[:x] - p[:x]; py = b[:y] - p[:y]
    al = px * dx + py * dy
    al > 0 && al < len && (px * dy - py * dx).abs < width / 2.0 + 4
  })
  $G.swings << { kind: tip_crit ? :whip : :thrust, x: p[:x], y: p[:y] - 2, a: a, len: len, width: width, t: 0.12, max: 0.12, tag: cw(p)[:tags].first }
end

def attack_beam(p, a, force_crit)
  w = cw(p)
  range = wrange(p)
  dx = Math.cos(a); dy = Math.sin(a)
  len = range
  steps = (range / 4).floor
  (1..steps).each do |i|
    x = p[:x] + dx * i * 4; y = p[:y] - 2 + dy * i * 4
    if solid?($G.room, (x / TS).floor, (y / TS).floor, :bullet) then len = i * 4; break end
  end
  hits = []
  $G.enemies.each do |e|
    next unless targetable?(e)
    px = e[:x] - p[:x]; py = e[:y] - 2 - p[:y]
    along = px * dx + py * dy
    hits << [e, along] if along > 0 && along < len && (px * dy - py * dx).abs < e[:r] + 3 * wsize(p)
  end
  hits = hits.sort_by { |h| h[1] }
  hits = hits.first(1 + wpierce(p)) if wpierce(p) < 99
  len = hits.last[1] if !hits.empty? && wpierce(p) < 99
  hits.each { |e, _| melee_hit(p, e, wdmg(p), force_crit, 10) }
  bt = [0.07, 1.15 / wrate(p)].max
  $G.swings.reject! { |s| s[:kind] == :beam }
  $G.swings << { kind: :beam, x: p[:x], y: p[:y] - 2, a: a, len: len, t: bt, max: bt, tag: w[:tags].first }
end

def attack_zap(p, a, force_crit)
  w = cw(p)
  range = wrange(p)
  best = nil; bd = 1e9
  $G.enemies.each do |e|
    next unless targetable?(e)
    d = dist(p, e)
    next if d > range || !has_los?(p, e)
    da = Math.atan2(Math.sin(ang_to(p, e) - a), Math.cos(ang_to(p, e) - a)).abs
    score = d + da * 60
    if score < bd then bd = score; best = e end
  end
  return unless best
  hit = {}
  cur = { x: p[:x], y: p[:y] - 2 }
  tgt = best
  ((w[:chain] || 2) + p[:chain_jumps] + 1).times do
    break unless tgt
    n = [(dist(cur, tgt) / 6).ceil, 1].max
    (0..n).each { |i| k = i.to_f / n; particle(cur[:x] + (tgt[:x] - cur[:x]) * k + rint(-2, 2), cur[:y] + (tgt[:y] - cur[:y]) * k + rint(-2, 2), 0, 0, 0.12, rnd < 0.5 ? "#6fd3e0" : "#ffffff") }
    hit[tgt.object_id] = true
    melee_hit(p, tgt, wdmg(p), force_crit, 20)
    cur = tgt
    tgt = nearest_enemy(cur, 70, hit)
  end
  Snd.play("beam") if rnd < 0.2
end

def player_shoot(p, a, echo_ok = true)
  w = cw(p)
  p[:shot_n] += 1
  forced = false
  if p[:ambush_left] > 0 then p[:ambush_left] -= 1; forced = true end
  made = []
  case w[:kind]
  when :slash then attack_slash(p, a, forced); Snd.play("hatchet")
  when :thrust
    n = wcount(p); step = wspread(p)
    n.times { |i| attack_line(p, a + (i - (n - 1) / 2.0) * step, wrange(p), (w[:width] || 8) * wsize(p), false, forced) }
    Snd.play("hatchet")
  when :whip then attack_line(p, a, wrange(p), (w[:width] || 6) * wsize(p), true, forced); Snd.play("dodge")
  when :beam then attack_beam(p, a, forced); Snd.play("shoot") if p[:shot_n] % 3 == 0
  when :zap then attack_zap(p, a, forced)
  else
    made = fire_projectiles(p, a)
    if w[:kind] == :burst then p[:volleys] << { t: 0.07, raw: true } << { t: 0.14, raw: true } end
    Snd.play(w[:kind] == :flame ? "dodge" : (w[:kind] == :spin || w[:kind] == :boomer || w[:kind] == :disc ? "hatchet" : (w[:kind] == :bolt || w[:kind] == :rail ? "bolt" : "shoot")))
  end
  made.each { |b| b[:crit] = true } if forced
  nb = (p[:heavy_n] > 0 && p[:shot_n] % p[:heavy_n] == 0) || (gf(p, :nth_big) > 0 && p[:shot_n] % gf(p, :nth_big).to_i == 0)
  made.each { |b| b[:dmg] *= 3; b[:r] *= 1.5 } if nb
  if gf(p, :nth_nova) > 0 && p[:shot_n] % gf(p, :nth_nova).to_i == 0
    8.times { |i| spawn_pbullet(p, a + i * TAU / 8, wdmg(p) * 0.7, w[:tags].include?(:pyre) ? "fire" : "spark") }
  end
  zn = [p[:thunder_n], gf(p, :nth_zap).to_i].select { |v| v > 0 }.min
  if zn && p[:shot_n] % zn == 0
    t = auto_target(p, 300)
    lightning(t, wdmg(p)) if t
  end
  if p[:lance_n] > 0 && p[:shot_n] % p[:lance_n] == 0
    l = spawn_pbullet(p, a, wdmg(p) * 1.6, "lance", 1.3)
    l[:pierce] = 99; l[:r] = 4; l[:chill] = true; l[:life] = 1.0; l[:split] = 0
  end
  if p[:barbs] > 0 && rnd < p[:barbs]
    d = spawn_pbullet(p, a + (rnd - 0.5) * 0.4, wdmg(p) * 0.5, "dart", 1.2)
    d[:poison_add] = 2; d[:split] = 0
  end
  p[:volleys] << { t: 0.15 } if echo_ok && p[:echo] > 0 && rnd < p[:echo]
  particle(p[:x] + Math.cos(a) * 8, p[:y] - 2 + Math.sin(a) * 8, 0, 0, 0.06, "#fffbe0", 3) unless [:slash, :thrust, :whip, :beam, :zap].include?(w[:kind])
end

# ---------- Hits ----------
def on_hit_effects(e, dmg, crit, p, b)
  e[:burn_t] = 3.0 + p[:burn_time] if p[:burn] > 0 && rnd < p[:burn]
  if (b && b[:chill]) || (p[:chill] > 0 && rnd < p[:chill]) then e[:chill_t] = 2.0 + p[:chill_time]; burst(e[:x], e[:y], ["#6fd3e0", "#ffffff"], 5, 30) end
  padd = b ? b[:poison_add] : 0
  e[:poison] = [12, e[:poison] + p[:poison] + padd].min if p[:poison] > 0 || padd > 0
  e[:stun_t] = e[:type] == "boss" ? 0.25 : 1.0 if p[:stun] > 0 && rnd < p[:stun]
  e[:curse_t] = 3.0 if p[:curse] > 0 && rnd < p[:curse]
  if gf(p, :mark) > 0 then e[:mark_t] = 3.0; e[:mark_v] = gf(p, :mark) end
  e[:shred] = [5 * gf(p, :shred), (e[:shred] || 0) + gf(p, :shred)].min if gf(p, :shred) > 0
  heal_player(1) if gf(p, :leech) > 0 && rnd < gf(p, :leech)
  drop_pickup(:coin, e[:x], e[:y]) if gf(p, :gold_hit) > 0 && rnd < gf(p, :gold_hit)
  chain_from(e, dmg * 0.6) if (p[:chain] > 0 && rnd < p[:chain]) || (crit && gf(p, :crit_chain) > 0)
  kind = b ? b[:kind] : nil
  explode_at(e[:x], e[:y], dmg * 0.5 * p[:explode], e, 18 + (kind == "flask" ? 8 + 26 * p[:splash] : 0)) if p[:explode] > 0 && e[:hp] > -999
  explode_at(e[:x], e[:y], dmg * 0.6, e, 16, "#e8873a", true) if p[:shrapnel] > 0 && rnd < p[:shrapnel]
  explode_at(e[:x], e[:y], dmg * 0.8, e, 22, "#f2c94c", true) if crit && gf(p, :crit_explode) > 0 && rnd < gf(p, :crit_explode)
  lightning(e, dmg) if p[:storm] > 0 && rnd < p[:storm]
  if gf(p, :execute) > 0 && e[:hp] > 0 && e[:type] != "boss" && e[:hp] < e[:max_hp] * gf(p, :execute)
    float_text(e[:x], e[:y] - 16, "EXECUTE", "red")
    e[:hp] = 0
    kill_enemy(e, {})
  end
end

def pbullet_hits(b, p)
  return if b[:nohit]
  $G.enemies.each do |e|
    next if e[:hp] <= 0 || e[:spawn_t] > 0 || e[:hidden] || b[:hit][e.object_id]
    er = e[:r] + (e[:type] == "boss" ? 2 : 0)
    next unless Math.hypot(e[:x] - b[:x], (e[:y] - e[:z]) - b[:y]) < er + b[:r]
    b[:hit][e.object_id] = true
    sp = Math.hypot(b[:vx], b[:vy]); sp = 1 if sp == 0
    kb = (cw(p)[:kind] == :spin ? 160 : 70) * (gf(p, :knock) > 0 ? gf(p, :knock) : 1)
    dmg = b[:dmg]
    dmg *= 2 if b[:back] && p[:back_dmg]
    crit = damage_enemy(e, dmg, { kx: b[:vx] / sp * kb, ky: b[:vy] / sp * kb, force_crit: b[:crit] })
    on_hit_effects(e, dmg, crit, p, b)
    burst(b[:x], b[:y], ["#f4ecd8", "#fffbe0"], 3, 50, 0.2)
    if b[:split] && b[:split] > 0 && b[:kind] != "spark"
      n = b[:split].to_i
      a0 = Math.atan2(b[:vy], b[:vx])
      n.times do |i|
        da = (i - (n - 1) / 2.0) * 0.6 + (n == 1 ? 0.5 : 0)
        nb = b.dup; nb[:hit] = b[:hit].dup; nb[:dmg] = dmg * 0.5; nb[:r] = [b[:r] * 0.7, 2.0].max; nb[:split] = 0; nb[:bloom] = false
        nb[:back] = nil; nb[:kind] = b[:kind] == "boomer" || b[:kind] == "spin" || b[:kind] == "disc" ? "spark" : b[:kind]
        nb[:vx] = Math.cos(a0 + da) * sp; nb[:vy] = Math.sin(a0 + da) * sp; nb[:life] = [b[:life], 0.4].max
        $G.new_pbullets << nb
      end
      b[:split] = 0
    end
    if b[:bloom]
      b[:bloom] = false
      a0 = Math.atan2(b[:vy], b[:vx])
      [-0.5, 0.5].each do |da|
        nb = b.dup; nb[:hit] = b[:hit].dup; nb[:dmg] = dmg * 0.6; nb[:r] = b[:r] * 0.8; nb[:bloom] = false; nb[:split] = 0
        nb[:vx] = Math.cos(a0 + da) * sp; nb[:vy] = Math.sin(a0 + da) * sp
        $G.new_pbullets << nb
      end
    end
    b[:dmg] *= 1 + gf(p, :pierce_dmg) if gf(p, :pierce_dmg) > 0
    if b[:pierce] > 0
      b[:pierce] -= 1
    elsif crit && p[:crit_pierce]
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

# Grow, accelerate, hover, pulse and mines run before the normal bullet update.
alias update_pbullets_base update_pbullets
def update_pbullets(dt)
  p = $G.player
  $G.pbullets.each do |b|
    if b[:grow] && b[:grow] > 0
      b[:r] = [b[:r] + dt * 6 * b[:grow], 12.0].min
      b[:dmg] *= 1 + dt * 0.8 * b[:grow]
    end
    if b[:accel] && b[:accel] > 0
      f = b[:accel] ** dt
      b[:vx] *= f; b[:vy] *= f
    end
    if b[:kind] == "pulse"
      if b[:linger] && b[:linger] > 0 && b[:age] > b[:max_life] * 0.25 && !b[:hovering]
        b[:hovering] = true; b[:vx] = 0.0; b[:vy] = 0.0; b[:life] += b[:linger]
      end
      b[:pulse_t] -= dt
      if b[:pulse_t] <= 0
        b[:pulse_t] = 0.3
        rad = 14 + 8 * b[:r] / 2.5
        $G.enemies.dup.each do |e|
          next unless targetable?(e) && Math.hypot(e[:x] - b[:x], e[:y] - b[:y]) < rad + e[:r]
          crit = damage_enemy(e, b[:dmg] * 0.5, { silent: true })
          on_hit_effects(e, b[:dmg] * 0.5, crit, p, b)
        end
      end
    end
    if b[:kind] == "mine"
      if b[:mvx]
        nx = b[:x] + b[:mvx] * dt; ny = b[:y] + b[:mvy] * dt
        if solid?($G.room, (nx / TS).floor, (ny / TS).floor, :bullet) then b[:mvx] = nil
        else
          b[:x] = nx; b[:y] = ny
          f = 0.0015 ** dt
          b[:mvx] *= f; b[:mvy] *= f
          b[:mvx] = nil if Math.hypot(b[:mvx], b[:mvy]) < 12
        end
      end
      b[:arm] -= dt
      b[:life] = [b[:life], 0.5].max if b[:life] < 0.5 && b[:arm] > -7
      if b[:arm] <= 0 && $G.enemies.any? { |e| targetable?(e) && Math.hypot(e[:x] - b[:x], e[:y] - b[:y]) < 20 + e[:r] }
        b[:life] = 0
        Snd.play("boom"); add_shake(2)
        $G.enemies.dup.each do |e|
          next unless targetable?(e) && Math.hypot(e[:x] - b[:x], e[:y] - b[:y]) < 30 + e[:r]
          crit = damage_enemy(e, b[:dmg], { boom: true })
          on_hit_effects(e, b[:dmg], crit, p, b)
        end
        burst(b[:x], b[:y], ["#e8873a", "#f2c94c", "#4e4a5e"], 18, 100, 0.4, 2)
      end
    end
  end
  update_pbullets_base(dt)
end

# ---------- Kills, hurt and roll hooks ----------
alias kill_enemy_base kill_enemy
def kill_enemy(e, o = {})
  kill_enemy_base(e, o)
  p = $G.player
  return unless p && p[:gf]
  p[:floor_kills] += 1
  explode_at(e[:x], e[:y], wdmg(p) * gf(p, :kill_explode), e, 26, "#e8873a", true) if gf(p, :kill_explode) > 0
  $G.temp_fams << { x: e[:x], y: e[:y], cd: 0.2, t: 6.0 } if gf(p, :kill_wisp) > 0 && rnd < gf(p, :kill_wisp) && $G.temp_fams.size < 8
  heal_player(1) if gf(p, :kill_heal) > 0 && rnd < gf(p, :kill_heal)
  p[:charges] = [p[:charges] + 1, p[:dodge_charges]].min if gf(p, :kill_roll) > 0 && rnd < gf(p, :kill_roll)
  p[:haste_t] = [p[:haste_t], gf(p, :kill_haste)].max if gf(p, :kill_haste) > 0
  drop_pickup(:bomb, e[:x], e[:y]) if gf(p, :bomb_on_kill) > 0 && rnd < gf(p, :bomb_on_kill)
  $G.drop_gear_at(e[:x], e[:y]) if e[:elite] && e[:type] != "boss" && rnd < 0.05
end

alias hurt_player_base hurt_player
def hurt_player(amount, source)
  p = $G.player
  before = p[:invuln]
  hurt_player_base(amount, source)
  return unless p[:gf] && $G.state == :play && p[:invuln] > before && p[:invuln] >= 1.0
  if gf(p, :frost_skin) > 0
    $G.enemies.each { |e| e[:chill_t] = 2.5 if Math.hypot(e[:x] - p[:x], e[:y] - p[:y]) < 90 }
    burst(p[:x], p[:y], ["#c8f0ff", "#6fd3e0"], 14, 80)
  end
  $G.enemies.select { |e| targetable?(e) }.sort_by { |e| dist(p, e) }.first(3).each { |e| lightning(e, wdmg(p)) } if gf(p, :spark_skin) > 0
  n = gf(p, :thorns_nova).to_i
  n.times { |i| spawn_pbullet(p, i * TAU / n, wdmg(p) * 0.8, "dart") } if n > 0
  12.times { |i| spawn_pbullet(p, i * TAU / 12, wdmg(p) * 1.2, "spark") } if gf(p, :reflect_hit) > 0
end

alias update_player_base update_player
def update_player(p, dt)
  rolling_before = p[:dodge_t] > 0
  # Gatling spin-up while there is something to shoot.
  if cw(p)[:kind] == :gatling
    p[:spin] = $G.enemies_active? ? [1.0, p[:spin] + dt * 0.5].min : [0.0, p[:spin] - dt].max
  end
  hasted = p[:haste_t] > 0
  p[:haste_t] = [0, p[:haste_t] - dt].max
  p[:speed] *= 1.3 if hasted
  update_player_base(p, dt)
  p[:speed] /= 1.3 if hasted
  if !rolling_before && p[:dodge_t] > 0
    n = gf(p, :roll_nova).to_i
    n.times { |i| spawn_pbullet(p, i * TAU / n, wdmg(p) * 0.8, "spark") } if n > 0
    if gf(p, :roll_zap) > 0
      t = auto_target(p, 220)
      lightning(t, wdmg(p) * 1.5) if t
    end
    p[:ambush_left] += gf(p, :roll_ambush).to_i
  end
  if p[:moving] && (gf(p, :fire_steps) > 0 || gf(p, :toxic_steps) > 0)
    p[:step_t] -= dt
    if p[:step_t] <= 0
      p[:step_t] = 0.18
      $G.zones << { x: p[:x], y: p[:y] + 3, r: 9, t: 1.4, kind: :fire, tick: 0 } if gf(p, :fire_steps) > 0
      $G.zones << { x: p[:x], y: p[:y] + 3, r: 11, t: 2.2, kind: :poison, tick: 0 } if gf(p, :toxic_steps) > 0
    end
  end
  $G.enemies.each { |e| e[:mark_t] -= dt if e[:mark_t] && e[:mark_t] > 0 }
end

alias gain_xp_base gain_xp
def gain_xp(p, n)
  gain_xp_base(p, (n * (p[:xp_mult] || 1.0)).round)
end

# Door rewards now include weapons and gear.
def roll_reward(p, elite = false)
  return pick([:rare, :rare, :relic, :level, :weapon, :gear]) if elite
  w = { relic: 14, gold: 13, heal: p[:hp] < p[:max_hp] / 2 ? 20 : 7, supply: 9, armor: 6, level: 12, embers: 4, weapon: 11, gear: 13 }
  weighted(w)
end

REWARDS[:weapon] = { name: "WEAPON", icon: "icon_weapon", col: "orange" }
REWARDS[:gear] = { name: "GEAR", icon: "icon_gear", col: "cyan" }

def roll_item_rarity(floor_index, source = :drop)
  f = floor_index
  w = { common: [60 - 9 * f, 10].max, rare: 30, epic: 8 + 4 * f, legend: 2 + 2 * f }
  w = { common: 0, rare: 30, epic: 45, legend: 25 } if source == :boss
  w = { common: 0, rare: 50, epic: 38, legend: 12 } if source == :elite
  weighted(w)
end

def random_weapon(rarity, exclude = nil)
  pool = WEAPONS.select { |w| w[:rarity] == rarity && !(exclude && w[:id] == exclude[:id]) && !HERO_WEAPON.values.include?(w[:id]) }
  pool = WEAPONS.select { |w| w[:rarity] == rarity } if pool.empty?
  pick(pool)
end

def random_gear(rarity)
  pool = GEAR.select { |g| g[:rarity] == rarity }
  pick(pool)
end
