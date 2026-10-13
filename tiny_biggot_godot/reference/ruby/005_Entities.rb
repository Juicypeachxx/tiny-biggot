# Cinder Crypt - player, enemies and effects (game logic).

# ---------- Effects ----------
def burst(x, y, cols, n = 8, speed = 60, life = 0.4, size = 1)
  n.times do
    a = rnd * TAU; s = speed * (0.3 + rnd * 0.7)
    $G.particles << { x: x, y: y, vx: Math.cos(a) * s, vy: Math.sin(a) * s, life: life * (0.6 + rnd * 0.6),
                      max: life, col: pick(cols), size: [3, size + (rnd < 0.3 ? 1 : 0)].min, drag: 0.9 }
  end
end

def particle(x, y, vx, vy, life, col, size = 1, drag = 1.0)
  $G.particles << { x: x, y: y, vx: vx, vy: vy, life: life, max: life, col: col, size: size, drag: drag }
end

def float_text(x, y, text, col = "white")
  $G.texts << { x: x + rint(-3, 3), y: y, text: text.to_s, col: col, life: 0.7 }
end

def add_shake(amount)
  $G.shake = [$G.shake, amount].max if $opts[:shake]
end

def dread; $G.dread || 0; end

# ---------- Player ----------
def create_player(hero)
  s = hero[:stats]
  p = {
    hero: hero, x: SW / 2.0, y: SH / 2.0 + 24, r: 4, hit_r: 2.5, face: 1, aim_a: 0.0,
    hp: hero[:hp], max_hp: hero[:hp], potions: 1, max_potions: 2, gold: 0, gold_frac: 0.0, relics: [],
    speed: hero[:speed].to_f, dmg: s[:dmg], rate: s[:rate], shot_speed: s[:shot_speed], life: s[:life], homing: s[:homing],
    size: s[:size], pierce: s[:pierce], count: s[:count] || 1, spread: s[:spread] || nil, bounce: 0, crit: 0.05, crit_mult: 2.0,
    burn: 0.0, chill: 0.0, poison: 0, chain: 0.0, explode: 0, lifesteal: 0.0, gold_mult: 1.0, shop_disc: 0.0, thorns: 0,
    orbitals: 0, dodge_charges: 1, dodge_cd: 0.9, frenzy: 0, rage: 0.0, backshot: 0, triple: 0.0, ward: 0, buckler: false,
    bomb_dodge: false, magnet: false,
    armor: 0, bombs: 1, keys: 0, bomb_mult: 1.0, gold_drop: 1.0, roll_speed: 1.0, potion_heal: 4, reveal: false,
    familiars: 0, aura: 0, elite_mult: 0.0, lens: false, coil: 0, oath: false, ricochet: 0, miser: false, shadowstep: false,
    splinter: 0, revive: 0, storm: 0.0, mirror: false, roll_reload: false,
    fire_cd: 0.0, dodge_t: 0.0, dodge_dir: [1.0, 0.0], charges: 1, charge_t: 0.0, invuln: 0.0, frenzy_t: 0.0,
    buckler_used: false, orbit_a: 0.0, orbit_hit: {}, walk_t: 0.0, moving: false, volleys: [], kills: 0, trail: [],
    aura_t: 0.0, coil_t: 0.0, step_hit: {}, embers_found: 0,
    xp: 0, level: 1, pending: 0, traits: {}, fam: {}, fam_bonus: {}, rerolls: 2, luck: 0,
    burn_dmg: 0.0, vs_burn: 0.0, burn_time: 0.0, burn_leap: 0.0, fire_trail: 0, inferno: false,
    chill_time: 0.0, chill_slow: 0.5, vs_chill: 0.0, ice_armor: false, lance_n: 0, shot_n: 0, shatter: false, chill_spread: false,
    poison_dmg: 0.0, corrode: 0.0, cloud: 0, barbs: 0.0, plague: false, poison_fast: false,
    chain_jumps: 0, storm_dmg: 0.0, thunder_n: 0, tempest: false, tempest_t: 3.0,
    crit_heal: 0.0, desperate: 0.0, bleed: 0, sanguine: false, room_kills: 0, crit_pierce: false,
    armor_regen: 0, ironskin: false, bash: 0, fortress: 0.0, unbreakable: false, evade: 0.0,
    ambush: 0, ambush_left: 0, roll_time: 0.0, smoke: false, nightfall: false, post_roll: false, post_roll_t: 0.0,
    echo: 0.0, interest: 0.0, jackpot: false, midas: false,
    shrapnel: 0.0, sapper: 0, fuse: false, cluster: false, bomb_r: 1.0, boom_elite: false,
    fam_dmg: 0.0, fam_rate: 1.0, fam_multi: 1, carrion: 0.0, legion: false, legion_n: 0,
    curse: 0.0, bloom: false, heavy_n: 0, stun: 0.0, full_hp_dmg: 0.0, blood_rage: false, harvest: false,
    splash: 0.0, elixir: false, volatile: false, back_dmg: false, start_rare: false, trail_t: 0.0
  }
  (hero[:start] || {}).each { |k, v| p[k] += v }
  p
end

def add_relic(p, r)
  p[:relics] << r
  r[:fx].call(p)
  p[:charges] = [p[:charges], p[:dodge_charges]].min
  $meta[:found][r[:id]] = true
  Snd.play("relic")
end

def hurt_player(amount, source)
  p = $G.player
  return if p[:invuln] > 0 || p[:dodge_t] > 0 || $G.state != :play
  if p[:evade] > 0 && rnd < [p[:evade], 0.6].min
    p[:invuln] = 0.4
    float_text(p[:x], p[:y] - 12, "DODGED", "purple")
    burst(p[:x], p[:y], ["#a35bd6", "#e8c8ff"], 8, 50)
    return
  end
  if p[:buckler] && !p[:buckler_used]
    p[:buckler_used] = true; p[:invuln] = 0.6
    burst(p[:x], p[:y], ["#8b8f9c", "#f4ecd8"], 12, 70)
    float_text(p[:x], p[:y] - 12, "BLOCKED", "grey")
    Snd.play("hit")
    return
  end
  if p[:armor] > 0
    p[:armor] -= 1
    burst(p[:x], p[:y], ["#4d9be6", "#6fd3e0", "#f4ecd8"], 12, 70)
    float_text(p[:x], p[:y] - 12, "ARMOR", "cyan")
    if cap?(p, :unbreakable)
      16.times { |i| spawn_pbullet(p, i / 16.0 * TAU, wdmg(p) * 1.5, "spark") }
      $G.ebullets.reject! { |b| Math.hypot(b[:x] - p[:x], b[:y] - p[:y]) <= 70 }
      add_shake(4)
    end
  else
    p[:hp] -= amount
  end
  if p[:ice_armor]
    $G.enemies.each { |e| e[:chill_t] = 2.5 + p[:chill_time] if Math.hypot(e[:x] - p[:x], e[:y] - p[:y]) < 90 }
    burst(p[:x], p[:y], ["#c8f0ff", "#6fd3e0"], 16, 90)
  end
  p[:invuln] = 1.1
  $G.hitstop = 0.06
  add_shake(5)
  Snd.play("hurt")
  burst(p[:x], p[:y], ["#d8443c", "#8a2a33", "#f4ecd8"], 14, 80)
  $G.ebullets.reject! { |b| Math.hypot(b[:x] - p[:x], b[:y] - p[:y]) <= 34 }
  if p[:ward] > 0
    n = 12 * p[:ward]
    n.times { |i| spawn_pbullet(p, i.to_f / n * TAU, wdmg(p) * 1.2, "hex") }
  end
  return if p[:hp] > 0
  phoenix = p[:gf] && p[:gf][:revive_g] > 0 && !p[:phoenix_used]
  if p[:revive] > 0 || phoenix
    if phoenix then p[:phoenix_used] = true else p[:revive] -= 1 end
    p[:hp] = 4; p[:invuln] = 2.5
    $G.ebullets = []
    burst(p[:x], p[:y], ["#e8873a", "#f2c94c", "#d8443c"], 40, 120, 0.8, 2)
    $G.show_banner("RISEN AGAIN", "YOU CHEAT DEATH ONCE")
    Snd.play("portal")
    return
  end
  $G.on_death(source)
end

def heal_player(n)
  p = $G.player
  before = p[:hp]
  p[:hp] = [p[:max_hp], p[:hp] + n].min
  if p[:hp] > before
    gained = (p[:hp] - before) / 2.0
    float_text(p[:x], p[:y] - 12, "+" + (gained == gained.floor ? gained.to_i.to_s : gained.to_s) + " HP", "pink")
    Snd.play("heal")
    burst(p[:x], p[:y], ["#d8443c", "#ff8a8a"], 10, 40)
  end
end

def has_los?(a, b)
  d = Math.hypot(b[:x] - a[:x], b[:y] - a[:y])
  n = (d / 6).ceil
  (1...n).each do |i|
    k = i.to_f / n
    x = a[:x] + (b[:x] - a[:x]) * k; y = a[:y] + (b[:y] - a[:y]) * k
    return false if solid?($G.room, (x / TS).floor, (y / TS).floor, :bullet)
  end
  true
end

def targetable?(e); e[:spawn_t] <= 0 && !e[:hidden] && e[:hp] > 0; end

def auto_target(p, max_d)
  best = nil; bd = max_d; fb = nil; fd = max_d
  $G.enemies.each do |e|
    next unless targetable?(e)
    d = dist(p, e)
    if d < fd then fd = d; fb = e end
    if d < bd && has_los?(p, e) then bd = d; best = e end
  end
  best || fb
end

def nearest_enemy(from, max_d, skip = nil)
  best = nil; bd = max_d
  $G.enemies.each do |e|
    next unless targetable?(e)
    next if skip && skip[e.object_id]
    d = dist(from, e)
    if d < bd then bd = d; best = e end
  end
  best
end

def spawn_pbullet(p, a, dmg = nil, kind = nil, speed_mul = 1.0)
  kind ||= p[:hero][:shot]
  sp = wspd(p) * (0.94 + rnd * 0.12) * speed_mul
  life = wlife(p)
  life *= (0.85 + rnd * 0.3) if kind == "clod"
  b = {
    x: p[:x] + Math.cos(a), y: p[:y] - 2 + Math.sin(a), vx: Math.cos(a) * sp, vy: Math.sin(a) * sp,
    dmg: dmg || wdmg(p), life: life, max_life: life, r: 2.5 * wsize(p), pierce: wpierce(p), bounce: p[:bounce], homing: whoming(p),
    kind: kind, hit: {}, rot: 0.0, age: 0.0, ric: p[:ricochet], back: kind == "boomer" ? false : nil,
    crit: false, bloom: p[:bloom] && kind == "hex", poison_add: 0
  }
  $G.pbullets << b
  b
end

def player_shoot(p, a, echo_ok = true)
  p[:shot_n] += 1
  n = wcount(p)
  step = wspread(p) || (p[:hero][:id] == "poacher" ? 0.12 : 0.2)
  made = []
  n.times { |i| made << spawn_pbullet(p, a + (i - (n - 1) / 2.0) * step + (p[:hero][:id] == "gravedigger" ? (rnd - 0.5) * 0.12 : 0)) }
  bs = p[:backshot]
  bs.times { |i| made << spawn_pbullet(p, a + Math::PI + (i - (bs - 1) / 2.0) * 0.25) }
  if p[:heavy_n] > 0 && p[:shot_n] % p[:heavy_n] == 0
    made.each { |b| b[:dmg] *= 3; b[:r] *= 1.5 }
  end
  if p[:ambush_left] > 0
    p[:ambush_left] -= 1
    made.each { |b| b[:crit] = true }
  end
  if p[:lance_n] > 0 && p[:shot_n] % p[:lance_n] == 0
    l = spawn_pbullet(p, a, wdmg(p) * 1.6, "lance", 1.3)
    l[:pierce] = 99; l[:r] = 4; l[:chill] = true; l[:life] *= 1.4
  end
  if p[:thunder_n] > 0 && p[:shot_n] % p[:thunder_n] == 0
    t = auto_target(p, 300)
    lightning(t, wdmg(p)) if t
  end
  if p[:barbs] > 0 && rnd < p[:barbs]
    d = spawn_pbullet(p, a + (rnd - 0.5) * 0.4, wdmg(p) * 0.5, "dart", 1.2)
    d[:poison_add] = 2
  end
  p[:volleys] << { t: 0.15 } if echo_ok && p[:echo] > 0 && rnd < p[:echo]
  Snd.play(p[:hero][:sound])
  particle(p[:x] + Math.cos(a) * 8, p[:y] - 2 + Math.sin(a) * 8, 0, 0, 0.06, "#fffbe0", 3)
end

def player_damage_mult(p)
  m = 1.0
  m *= 1 + p[:gold] / 1000.0 if p[:miser]
  m *= 1 + p[:gold] / 500.0 if cap?(p, :midas)
  m *= 1 + p[:desperate] * ((p[:max_hp] - p[:hp]) / 2) if p[:desperate] > 0
  m *= 1 + p[:fortress] * [p[:armor], 5].min if p[:fortress] > 0
  m *= 1 + 0.04 * p[:room_kills] if cap?(p, :sanguine)
  m *= 1.5 if p[:post_roll] && p[:post_roll_t] > 0
  m *= 1 + p[:full_hp_dmg] if p[:full_hp_dmg] > 0 && p[:hp] >= p[:max_hp]
  m
end

def update_player(p, dt)
  room = $G.room
  p[:invuln] = [0, p[:invuln] - dt].max
  p[:frenzy_t] = [0, p[:frenzy_t] - dt].max
  p[:post_roll_t] = [0, p[:post_roll_t] - dt].max
  raging = p[:blood_rage] && p[:hp] <= p[:max_hp] / 2
  if p[:charges] < p[:dodge_charges]
    p[:charge_t] += dt
    if p[:charge_t] >= p[:dodge_cd] then p[:charge_t] = 0; p[:charges] += 1 end
  end
  mx, my = Keys.move
  if Keys.roll && p[:dodge_t] <= 0 && p[:charges] > 0
    p[:charges] -= 1
    p[:dodge_t] = 0.26 * (p[:roll_speed] > 1 ? 1.12 : 1) + p[:roll_time]
    p[:ambush_left] = p[:ambush] if p[:ambush] > 0
    p[:post_roll_t] = p[:dodge_t] + 1.0
    $G.zones << { x: p[:x], y: p[:y], r: 24, t: 2.5, kind: :smoke, tick: 0 } if p[:smoke]
    dx, dy = (mx.abs + my.abs > 0.1) ? [mx, my] : [p[:face].to_f, 0.0]
    l = Math.hypot(dx, dy)
    p[:dodge_dir] = [dx / l, dy / l]
    p[:step_hit] = {}
    p[:fire_cd] = 0 if p[:roll_reload]
    Snd.play("dodge")
    $G.bombs << { x: p[:x], y: p[:y], t: 0.7, safe: true } if p[:bomb_dodge] || gf(p, :roll_bomb) > 0
  end
  if p[:dodge_t] > 0
    p[:dodge_t] -= dt
    vx = p[:dodge_dir][0] * 215 * p[:roll_speed]; vy = p[:dodge_dir][1] * 215 * p[:roll_speed]
    p[:trail] << { x: p[:x], y: p[:y], life: 0.18, face: p[:face] }
    if p[:fire_trail] > 0
      p[:trail_t] -= dt
      if p[:trail_t] <= 0 then p[:trail_t] = 0.05; $G.zones << { x: p[:x], y: p[:y] + 2, r: 9, t: 1.0 + 0.6 * p[:fire_trail], kind: :fire, tick: 0 } end
    end
    if p[:shadowstep]
      $G.enemies.each do |e|
        next unless targetable?(e) && !p[:step_hit][e.object_id]
        next unless Math.hypot(e[:x] - p[:x], e[:y] - p[:y]) < e[:r] + 10
        p[:step_hit][e.object_id] = true
        dmg = wdmg(p) * (cap?(p, :nightfall) ? 5.0 : 2.5) + p[:bash] * [p[:armor], 5].max * wdmg(p) * 0.6
        damage_enemy(e, dmg, { col: "purple" })
        if cap?(p, :nightfall) && e[:hp] <= 0 then p[:charges] = [p[:charges] + 1, p[:dodge_charges]].min end
        burst(e[:x], e[:y], ["#a35bd6", "#5c3483"], 8, 50)
      end
    end
  else
    spd = p[:speed] * (raging ? 1.2 : 1)
    vx = mx * spd; vy = my * spd
  end
  p[:moving] = Math.hypot(vx, vy) > 5
  p[:walk_t] += dt if p[:moving]
  p[:face] = vx > 0 ? 1 : -1 if vx.abs > 5 && p[:dodge_t] <= 0
  move_body(room, p, vx * dt, vy * dt, :player)
  p[:trail].each { |t| t[:life] -= dt }
  p[:trail].reject! { |t| t[:life] <= 0 }

  manual = Keys.aim
  aim = nil
  if manual
    aim = manual
  elsif $opts[:autofire] || Keys.fire_held
    t = auto_target(p, 320)
    aim = ang_to(p, { x: t[:x], y: t[:y] - 2 }) if t
  end
  if aim
    p[:aim_a] = aim
    if manual
      p[:face] = Math.cos(aim) >= 0 ? 1 : -1 if p[:dodge_t] <= 0
    elsif Math.cos(aim).abs > 0.2 && p[:dodge_t] <= 0 && !p[:moving]
      p[:face] = Math.cos(aim) > 0 ? 1 : -1
    end
  end
  p[:fire_cd] -= dt
  rate = wrate(p) * (p[:frenzy_t] > 0 ? 1.45 : 1) * (raging ? 1.4 : 1)
  if aim && p[:fire_cd] <= 0 && p[:dodge_t] <= 0 && $G.enemies_active?
    p[:fire_cd] = 1.0 / rate
    player_shoot(p, aim)
    if p[:triple] > 0 && rnd < p[:triple]
      p[:volleys] << { t: 0.07 } << { t: 0.14 }
    end
  end
  p[:volleys].each { |v| v[:t] -= dt; (v[:raw] ? fire_projectiles(p, p[:aim_a]) : player_shoot(p, p[:aim_a])) if v[:t] <= 0 }
  p[:volleys].reject! { |v| v[:t] <= 0 }
  if Keys.heal
    if p[:potions] > 0 && p[:hp] < p[:max_hp] then p[:potions] -= 1; heal_player(p[:potion_heal]); p[:invuln] = [p[:invuln], 3.0].max if p[:elixir]
    else Snd.play("deny")
    end
  end
  if Keys.bomb
    if p[:bombs] > 0
      p[:bombs] -= 1
      $G.bombs << { x: p[:x], y: p[:y] + 2, t: p[:fuse] ? 0.7 : 1.1, safe: p[:fuse] || gf(p, :bomb_immune) > 0 }
      Snd.play("place")
    else
      Snd.play("deny")
    end
  end
  p[:orbit_a] += dt * 3.2
  p[:orbit_hit].keys.each { |k| p[:orbit_hit][k] -= dt; p[:orbit_hit].delete(k) if p[:orbit_hit][k] <= 0 }
  # Ember Heart aura.
  if p[:aura] > 0 || gf(p, :fire_aura) > 0
    p[:aura_t] -= dt
    if p[:aura_t] <= 0
      p[:aura_t] = 0.5
      $G.enemies.each { |e| e[:burn_t] = [e[:burn_t], 1.6].max if targetable?(e) && Math.hypot(e[:x] - p[:x], e[:y] - p[:y]) < 38 + 10 * [p[:aura], 1].max }
    end
  end
  # Static Coil.
  if p[:coil] > 0 && $G.enemies_active?
    p[:coil_t] -= dt
    if p[:coil_t] <= 0
      p[:coil_t] = 4.0
      n = 10 * p[:coil]
      n.times { |i| spawn_pbullet(p, i.to_f / n * TAU, wdmg(p) * 0.8, "spark") }
      Snd.play("ebullet")
    end
  end
  if cap?(p, :tempest) && $G.enemies_active?
    p[:tempest_t] -= dt
    if p[:tempest_t] <= 0
      p[:tempest_t] = 3.0
      $G.enemies.select { |e| targetable?(e) }.sort_by { |e| dist(p, e) }.first(3).each { |e| lightning(e, wdmg(p) * 1.2) }
    end
  end
  update_familiars(p, dt)
end

def update_familiars(p, dt)
  fam = $G.familiars
  fam << { x: p[:x], y: p[:y], cd: rnd } while fam.size < p[:familiars]
  $G.temp_fams.each { |f| f[:t] -= dt }
  $G.temp_fams.reject! { |f| f[:t] <= 0 }
  all = fam.first(p[:familiars]) + $G.temp_fams
  all.each_with_index do |f, i|
    a = $G.time * 1.6 + i * TAU / [1, all.size].max
    rad = f[:t] ? 26 : 16
    tx = p[:x] + Math.cos(a) * rad; ty = p[:y] - 12 + Math.sin(a) * 7
    f[:x] += (tx - f[:x]) * [1, dt * 6].min; f[:y] += (ty - f[:y]) * [1, dt * 6].min
    f[:cd] -= dt
    next unless f[:cd] <= 0 && $G.enemies_active?
    t = nearest_enemy(f, 220)
    next unless t
    f[:cd] = 0.7 / p[:fam_rate]
    a2 = ang_to(f, t)
    p[:fam_multi].times do |k|
      aa = a2 + (k - (p[:fam_multi] - 1) / 2.0) * 0.18
      $G.pbullets << { x: f[:x], y: f[:y], vx: Math.cos(aa) * 220, vy: Math.sin(aa) * 220, dmg: [2.0, wdmg(p) * 0.45].max * (1 + p[:fam_dmg]),
                       life: 0.9, max_life: 0.9, r: 2.0, pierce: 0, bounce: 0, homing: 3.0, kind: "spark", hit: {}, rot: 0.0, age: 0.0,
                       ric: 0, back: nil, crit: false, bloom: false, poison_add: 0 }
    end
  end
end

def orbital_positions(p)
  out = []
  n = p[:orbitals]
  n.times do |i|
    a = p[:orbit_a] + i.to_f / n * TAU
    out << { x: p[:x] + Math.cos(a) * 20, y: p[:y] - 2 + Math.sin(a) * 20 }
  end
  out
end

# ---------- Enemies ----------
def floor_scale; (1 + 0.42 * $G.floor_index) * (1 + 0.15 * dread); end
def shot_mult; 1 + (dread >= 2 ? 0.08 * (dread - 1) : 0); end

def spawn_enemy(type, x, y, elite = false, instant = false)
  d = ENEMIES[type]
  hp = d[:hp] * floor_scale * (elite ? 2.2 : 1)
  e = {
    type: type, d: d, x: x, y: y, r: d[:r] * (elite ? 1.2 : 1), hp: hp, max_hp: hp, speed: d[:speed] * (1 + $G.floor_index * 0.05),
    t: rnd * 1.5, state: :idle, st: 0.0, vx: 0.0, vy: 0.0, flash: 0.0, burn_t: 0.0, burn_tick: 0.0, poison: 0.0, poison_t: 0.0,
    chill_t: 0.0, elite: elite, face: 1, kx: 0.0, ky: 0.0, spawn_t: instant ? 0.0 : 0.75, anim: rnd * 10, hidden: false,
    scale: (d[:scale] || 1) * (elite ? 1.2 : 1), gold: d[:gold] * (elite ? 3 : 1), z: 0.0, boss: nil
  }
  # Never leave a body wedged inside a pillar or crate.
  if !d[:fly] && hits_solid?($G.room, e[:x], e[:y], e[:r], :walker)
    sp = free_spot($G.room, nil, 0, :walker, e[:r] + 1)
    e[:x] = sp[:x]; e[:y] = sp[:y]
  end
  $G.enemies << e
  Snd.play("spawn") unless instant
  e
end

def spawn_boss(key)
  d = BOSSES[key]
  hp = d[:hp] * (1 + 0.15 * dread)
  e = {
    type: "boss", boss: key, d: d, x: SW / 2.0, y: 7.0 * TS, r: d[:r], hp: hp, max_hp: hp, speed: 30,
    t: 1.5, state: :intro, st: 0.0, vx: 0.0, vy: 0.0, flash: 0.0, burn_t: 0.0, burn_tick: 0.0, poison: 0.0, poison_t: 0.0,
    chill_t: 0.0, elite: true, face: 1, kx: 0.0, ky: 0.0, spawn_t: 0.0, anim: 0.0, hidden: false, scale: d[:scale], z: 0.0,
    gold: 0, cycle: 0, sub: 0, angle: 0.0, beams: [], target: nil, telegraph: nil
  }
  $G.enemies << e
  $G.boss = e
  Snd.play("roar")
  add_shake(6)
  e
end

def eshot(x, y, a, speed, spr = "red", r = 2.5, extra = nil)
  speed *= shot_mult
  b = { x: x, y: y, vx: Math.cos(a) * speed, vy: Math.sin(a) * speed, spr: spr, r: r, life: 6.0 }
  b.merge!(extra) if extra
  $G.ebullets << b
end

def ering(x, y, n, speed, off = 0, spr = "red", gap_a = nil, gap_w = 0)
  n.times do |i|
    a = off + i.to_f / n * TAU
    if gap_a
      d = Math.atan2(Math.sin(a - gap_a), Math.cos(a - gap_a))
      next if d.abs < gap_w
    end
    eshot(x, y, a, speed, spr, spr.end_with?("Big") ? 4 : 2.5)
  end
  Snd.play("ebullet")
end

def efan(x, y, a, n, spread, speed, spr = "red")
  n.times { |i| eshot(x, y, a + (n > 1 ? (i.to_f / (n - 1) - 0.5) * spread : 0), speed, spr) }
  Snd.play("ebullet")
end

def damage_enemy(e, dmg, o = {})
  return if e[:hp] <= 0 || e[:spawn_t] > 0 || e[:hidden]
  p = $G.player
  crit = false
  if o[:force_crit] || (!o[:no_crit] && rnd < p[:crit] + (e[:chill_t] > 0 ? gf(p, :chill_crit) : 0)) then dmg *= p[:crit_mult]; crit = true end
  dmg *= 1 + p[:rage] if p[:rage] > 0 && p[:hp] <= 2
  dmg *= 1 + p[:elite_mult] if e[:elite] && p[:elite_mult] > 0
  dmg *= 1 + p[:vs_burn] if e[:burn_t] > 0 && p[:vs_burn] > 0
  dmg *= 1 + p[:vs_chill] if e[:chill_t] > 0 && p[:vs_chill] > 0
  dmg *= 1 + p[:corrode] * e[:poison] if p[:corrode] > 0 && e[:poison] > 0
  dmg *= 1.25 if e[:curse_t] && e[:curse_t] > 0
  dmg *= 2 if o[:boom] && p[:boom_elite] && e[:elite]
  dmg *= player_damage_mult(p) * hook_mult(p, e) unless o[:no_mult]
  e[:hp] -= dmg
  e[:flash] = 0.08
  if o[:kx] && e[:type] != "boss" then e[:kx] += o[:kx]; e[:ky] += o[:ky] end
  float_text(e[:x], e[:y] - e[:r] - 6, [1, dmg.round].max, crit ? "gold" : (o[:col] || "white"))
  Snd.play("hit") unless o[:silent]
  if crit
    heal_player(1) if p[:crit_heal] > 0 && rnd < p[:crit_heal]
    if p[:bleed] > 0 then e[:bleed_t] = 3.0; e[:bleed_dps] = dmg * 0.25 * p[:bleed] end
  end
  if e[:hp] > 0 && cap?(p, :shatter) && e[:chill_t] > 0 && e[:type] != "boss" && e[:hp] < e[:max_hp] * 0.3
    e[:shattered] = true
    e[:hp] = 0
  end
  kill_enemy(e, o) if e[:hp] <= 0
  crit
end

def kill_enemy(e, o = {})
  p = $G.player
  e[:hp] = 0
  p[:kills] += 1
  p[:room_kills] += 1
  $G.run_stats[:kills] += 1
  boss = e[:type] == "boss"
  cols = boss ? ["#f4ecd8", "#f2c94c", "#d8443c", "#a35bd6"] : ["#f4ecd8", "#8b8f9c", SPRITE_COLOR[e[:d][:sprite]] || "#d8443c"]
  burst(e[:x], e[:y], cols, boss ? 60 : 14, boss ? 140 : 70, boss ? 1.0 : 0.45)
  Snd.play(boss ? "boom" : "kill")
  add_shake(boss ? 10 : 2)
  # Experience.
  xp = boss ? 40 + 10 * $G.floor_index : (ENEMY_XP[e[:type]] || 3) * (e[:elite] ? 3 : 1)
  gain_xp(p, xp)
  unless boss
    if e[:gold] > 0 && rnd < [0.95, e[:gold] * 1.8 * p[:gold_drop]].min
      rint(1, e[:elite] ? 5 : 2).times { drop_pickup(:coin, e[:x], e[:y]) }
    end
    drop_pickup(:heart, e[:x], e[:y]) if rnd < (e[:elite] ? 0.22 : 0.03)
    roll = rnd
    if roll < (e[:elite] ? 0.06 : 0.012) then drop_pickup(:ember, e[:x], e[:y])
    elsif roll < (e[:elite] ? 0.14 : 0.03) then drop_pickup(:bomb, e[:x], e[:y])
    elsif roll < (e[:elite] ? 0.2 : 0.042) then drop_pickup(:key, e[:x], e[:y])
    elsif roll < (e[:elite] ? 0.26 : 0.054) then drop_pickup(:armor, e[:x], e[:y])
    elsif e[:elite] && roll < 0.36 then drop_pickup(:gem, e[:x], e[:y])
    end
  end
  3.times { drop_pickup(:gem, e[:x], e[:y]) } if p[:jackpot] && e[:elite]
  heal_player(1) if p[:lifesteal] > 0 && rnd < p[:lifesteal]
  p[:frenzy_t] = 2 + p[:frenzy] if p[:frenzy] > 0
  if o[:bomb] && p[:harvest]
    drop_pickup(:bomb, e[:x], e[:y]) if rnd < 0.3
    drop_pickup(:heart, e[:x], e[:y]) if rnd < 0.08
  end
  if p[:splinter] > 0
    n = 4 * p[:splinter]
    n.times do |i|
      a = i.to_f / n * TAU + rnd
      $G.pbullets << { x: e[:x], y: e[:y], vx: Math.cos(a) * 180, vy: Math.sin(a) * 180, dmg: wdmg(p) * 0.5, life: 0.4, max_life: 0.4, r: 2.0,
                       pierce: 0, bounce: 0, homing: 0.0, kind: "spark", hit: { e.object_id => true }, rot: 0.0, age: 0.0, ric: 0, back: nil,
                       crit: false, bloom: false, poison_add: 0 }
    end
  end
  # Trait death effects.
  if cap?(p, :inferno) && e[:burn_t] > 0
    explode_at(e[:x], e[:y], wdmg(p) * 1.5, e, 30, "#e8873a")
    $G.enemies.each { |o2| o2[:burn_t] = [o2[:burn_t], 3.0 + p[:burn_time]].max if Math.hypot(o2[:x] - e[:x], o2[:y] - e[:y]) < 46 }
  end
  if e[:shattered]
    burst(e[:x], e[:y], ["#c8f0ff", "#6fd3e0", "#ffffff"], 18, 90)
    8.times { |i| a = i / 8.0 * TAU; $G.pbullets << { x: e[:x], y: e[:y], vx: Math.cos(a) * 170, vy: Math.sin(a) * 170, dmg: wdmg(p) * 0.8, life: 0.45, max_life: 0.45, r: 2.5, pierce: 1, bounce: 0, homing: 0.0, kind: "lance", hit: { e.object_id => true }, rot: 0.0, age: 0.0, ric: 0, back: nil, crit: false, bloom: false, poison_add: 0, chill: true } }
    float_text(e[:x], e[:y] - 14, "SHATTER", "cyan")
  end
  if (cap?(p, :plague) || p[:volatile]) && e[:poison] > 0
    $G.enemies.each { |o2| o2[:poison] = [12, o2[:poison] + e[:poison]].min if !o2.equal?(e) && Math.hypot(o2[:x] - e[:x], o2[:y] - e[:y]) < 60 } if cap?(p, :plague)
    explode_at(e[:x], e[:y], wdmg(p) * (1 + e[:poison] * 0.3), e, 28, "#b8e05a") if p[:volatile]
  end
  $G.zones << { x: e[:x], y: e[:y], r: 18 + 6 * p[:cloud], t: 3.0, kind: :poison, tick: 0 } if p[:cloud] > 0
  if p[:chill_spread] && e[:chill_t] > 0
    $G.enemies.each { |o2| o2[:chill_t] = [o2[:chill_t], 2.0].max if Math.hypot(o2[:x] - e[:x], o2[:y] - e[:y]) < 50 }
  end
  if p[:carrion] > 0 && rnd < p[:carrion] && $G.temp_fams.size < 8
    $G.temp_fams << { x: e[:x], y: e[:y], cd: 0.2, t: 6.0 }
  end
  if cap?(p, :legion)
    p[:legion_n] += 1
    if p[:legion_n] >= 5 && $G.temp_fams.size < 6 then p[:legion_n] = 0; $G.temp_fams << { x: e[:x], y: e[:y], cd: 0.2, t: 10.0 } end
  end
  if e[:type] == "slime"
    2.times do |i|
      sl = spawn_enemy("slimelet", e[:x] + (i == 1 ? 6 : -6), e[:y], false, true)
      sl[:kx] = (i == 1 ? 80 : -80)
    end
  end
  ering(e[:x], e[:y], 8 + (e[:elite] ? 4 : 0), 60, rnd, "water") if e[:type] == "drowned"
  $G.on_boss_dead(e) if boss
end

def gain_xp(p, n)
  p[:xp] += n
  while p[:xp] >= xp_needed(p[:level])
    p[:xp] -= xp_needed(p[:level])
    p[:level] += 1
    p[:pending] += 1
    float_text(p[:x], p[:y] - 18, "LEVEL UP!", "lime")
    burst(p[:x], p[:y], ["#b8e05a", "#f2c94c", "#ffffff"], 18, 80)
    Snd.play("unlock")
  end
end

def update_enemies(dt)
  p = $G.player; room = $G.room
  $G.enemies.each do |e|
    next if e[:hp] <= 0
    e[:anim] += dt
    e[:flash] = [0, e[:flash] - dt].max
    if e[:spawn_t] > 0 then e[:spawn_t] -= dt; next end
    slow = e[:chill_t] > 0 ? p[:chill_slow] : 1
    e[:chill_t] = [0, e[:chill_t] - dt].max
    e[:curse_t] -= dt if e[:curse_t] && e[:curse_t] > 0
    if e[:bleed_t] && e[:bleed_t] > 0
      e[:bleed_t] -= dt; e[:bleed_tick] = (e[:bleed_tick] || 0) - dt
      if e[:bleed_tick] <= 0 then e[:bleed_tick] = 0.5; damage_enemy(e, e[:bleed_dps] * 0.5, { no_crit: true, col: "red", silent: true, no_mult: true }) end
      particle(e[:x] + rint(-3, 3), e[:y], 0, 30, 0.3, "#8a2a33") if rnd < 0.25
      next if e[:hp] <= 0
    end
    if e[:burn_t] > 0
      e[:burn_t] -= dt; e[:burn_tick] -= dt
      if e[:burn_tick] <= 0
        e[:burn_tick] = 0.5
        damage_enemy(e, (1 + wdmg(p) * 0.2) * (1 + p[:burn_dmg]), { no_crit: true, col: "orange", silent: true })
        if p[:burn_leap] > 0 && rnd < p[:burn_leap]
          o2 = $G.enemies.find { |x| !x.equal?(e) && x[:hp] > 0 && x[:burn_t] <= 0 && Math.hypot(x[:x] - e[:x], x[:y] - e[:y]) < 50 }
          if o2 then o2[:burn_t] = 3.0 + p[:burn_time]; particle(o2[:x], o2[:y] - 4, 0, -20, 0.4, "#f2c94c", 2) end
        end
      end
      particle(e[:x] + rint(-4, 4), e[:y] - 4, 0, -25, 0.3, pick(["#e8873a", "#f2c94c"])) if rnd < 0.3
    end
    if e[:poison] > 0
      e[:poison_t] -= dt
      if e[:poison_t] <= 0
        e[:poison_t] = p[:poison_fast] ? 0.3 : 0.6
        damage_enemy(e, e[:poison] * 1.2 * (1 + p[:poison_dmg]), { no_crit: !p[:fam_bonus][:venom] || p[:fam_bonus][:venom] < 3, col: "lime", silent: true })
        e[:poison] = [0, e[:poison] - 0.25].max
      end
    end
    next if e[:hp] <= 0
    ddt = dt * slow
    if e[:stun_t] && e[:stun_t] > 0
      e[:stun_t] -= dt
      particle(e[:x] + Math.cos($G.time * 8) * 6, e[:y] - e[:r] - 6, 0, 0, 0.05, "#f2c94c") if rnd < 0.5
      next
    end
    e[:t] -= ddt
    if e[:type] == "boss" then update_boss(e, ddt)
    else send("ai_" + e[:d][:ai].to_s, e, ddt, p)
    end
    if e[:kx] != 0 || e[:ky] != 0
      move_body(room, e, e[:kx] * dt, e[:ky] * dt, e[:d][:fly] ? :flyer : :walker)
      e[:kx] *= 0.82; e[:ky] *= 0.82
      e[:kx] = 0.0 if e[:kx].abs < 2
      e[:ky] = 0.0 if e[:ky].abs < 2
    end
    if !e[:hidden] && Math.hypot(e[:x] - p[:x], e[:y] - p[:y]) < e[:r] + p[:r]
      hurt_player(1, e[:type] == "boss" ? e[:d][:name] : "a " + e[:type])
      if p[:thorns] > 0 && !(e[:thorn_cd] && e[:thorn_cd] > 0)
        damage_enemy(e, p[:thorns], { no_crit: true, col: "green" })
        e[:thorn_cd] = 0.5
      end
    end
    e[:thorn_cd] -= dt if e[:thorn_cd] && e[:thorn_cd] > 0
    if p[:orbitals] > 0
      orbital_positions(p).each do |o|
        if Math.hypot(o[:x] - e[:x], o[:y] - e[:y]) < e[:r] + 5 && !p[:orbit_hit][e.object_id]
          p[:orbit_hit][e.object_id] = 0.35
          damage_enemy(e, wdmg(p) * 0.7, {})
        end
      end
    end
  end
  $G.enemies.reject! { |e| e[:hp] <= 0 }
end

def steer(e, tx, ty, speed, dt, mode)
  a = Math.atan2(ty - e[:y], tx - e[:x])
  d = Math.hypot(tx - e[:x], ty - e[:y])
  return [false, false] if d < 1
  s = [speed * dt, d].min
  e[:face] = Math.cos(a) > 0 ? 1 : -1 if Math.cos(a).abs > 0.2
  move_body($G.room, e, Math.cos(a) * s, Math.sin(a) * s, mode)
end

def ai_bat(e, dt, p)
  a = ang_to(e, p) + Math.sin(e[:anim] * 6) * 0.9
  if e[:t] <= 0 then e[:t] = rnd * 2 + 1.5; e[:dash] = 0.4 end
  e[:dash] = (e[:dash] || 0) - dt
  sp = e[:speed] * (e[:dash] > 0 ? 2.2 : 1)
  move_body($G.room, e, Math.cos(a) * sp * dt, Math.sin(a) * sp * dt, :flyer)
  e[:face] = p[:x] > e[:x] ? 1 : -1
end

def ai_slime(e, dt, p)
  if e[:state] == :hop
    e[:st] -= dt
    move_body($G.room, e, e[:vx] * dt, e[:vy] * dt, :walker)
    if e[:st] <= 0 then e[:state] = :idle; e[:t] = 0.7 + rnd * 0.6 end
  elsif e[:t] <= 0
    a = ang_to(e, p) + (rnd - 0.5) * 0.6
    e[:vx] = Math.cos(a) * e[:speed] * 2.6; e[:vy] = Math.sin(a) * e[:speed] * 2.6
    e[:state] = :hop; e[:st] = 0.35; e[:face] = e[:vx] > 0 ? 1 : -1
  end
end

def wander_keep(e, dt, p, near, far)
  d = dist(e, p)
  if !e[:wander] || e[:wt] <= 0
    want = d < near ? -1 : (d > far ? 1 : 0)
    off = want == 0 ? (Math::PI / 2) * (rnd < 0.5 ? 1 : -1) : (want < 0 ? Math::PI : 0)
    a = ang_to(e, p) + off + (rnd - 0.5) * 0.8
    e[:wander] = { x: e[:x] + Math.cos(a) * 40, y: e[:y] + Math.sin(a) * 40 }
    e[:wt] = 0.8 + rnd * 0.6
  end
  e[:wt] -= dt
  bx, by = steer(e, e[:wander][:x], e[:wander][:y], e[:speed], dt, e[:d][:fly] ? :flyer : :walker)
  e[:wt] = 0 if bx || by
  e[:face] = p[:x] > e[:x] ? 1 : -1
end

def ai_archer(e, dt, p)
  if e[:state] == :aim
    e[:st] -= dt
    if e[:st] <= 0
      a = ang_to(e, p)
      if $G.floor_index >= 2 || e[:elite] then efan(e[:x], e[:y] - 2, a, 3, 0.4, 100, "bone")
      else eshot(e[:x], e[:y] - 2, a, 100, "bone", 2); Snd.play("ebullet")
      end
      e[:state] = :idle; e[:t] = 1.8 + rnd
    end
    return
  end
  wander_keep(e, dt, p, 80, 140)
  if e[:t] <= 0 then e[:state] = :aim; e[:st] = 0.45 end
end

def ai_spore(e, dt, p)
  if !e[:wander] || e[:wt] <= 0 then e[:wander] = free_spot($G.room, nil, 0); e[:wt] = 2 + rnd * 2 end
  e[:wt] -= dt
  steer(e, e[:wander][:x], e[:wander][:y], e[:speed], dt, :walker) if e[:state] != :puff
  if e[:t] <= 0 && e[:state] != :puff then e[:state] = :puff; e[:st] = 0.5 end
  if e[:state] == :puff
    e[:st] -= dt
    if e[:st] <= 0
      n = 8 + [3, $G.floor_index].min * 2 + (e[:elite] ? 4 : 0)
      e[:flip] = !e[:flip]
      ering(e[:x], e[:y] - 3, n, 52, e[:flip] ? 0 : Math::PI / n, "spore")
      e[:state] = :idle; e[:t] = 2.6 + rnd * 1.2
    end
  end
end

def ai_cultist(e, dt, p)
  if e[:state] == :cast
    e[:st] -= dt; e[:ct] -= dt
    if e[:ct] <= 0
      e[:ct] = 0.06; e[:ca] += 0.42
      eshot(e[:x], e[:y] - 3, e[:ca], 62, "dark")
      eshot(e[:x], e[:y] - 3, e[:ca] + Math::PI, 62, "dark") if e[:elite] || $G.floor_index >= 4
      Snd.play("ebullet")
    end
    if e[:st] <= 0 then e[:state] = :idle; e[:t] = 3 + rnd * 1.5 end
    return
  end
  if !e[:wander] || e[:wt] <= 0 then e[:wander] = free_spot($G.room, p, 60); e[:wt] = 1.5 + rnd end
  e[:wt] -= dt
  steer(e, e[:wander][:x], e[:wander][:y], e[:speed], dt, :walker)
  if e[:t] <= 0 then e[:state] = :cast; e[:st] = 1.1; e[:ct] = 0.3; e[:ca] = ang_to(e, p) end
end

def ai_imp(e, dt, p)
  e[:dir] ||= rnd < 0.5 ? 1 : -1
  e[:orb] = (e[:orb] || rnd * TAU) + dt * 0.9 * e[:dir]
  tx = p[:x] + Math.cos(e[:orb]) * 85; ty = p[:y] + Math.sin(e[:orb]) * 70
  steer(e, clampf(tx, 30, SW - 30), clampf(ty, 44, SH - 30), e[:speed], dt, :flyer)
  e[:face] = p[:x] > e[:x] ? 1 : -1
  if e[:t] <= 0
    efan(e[:x], e[:y], ang_to(e, p), e[:elite] ? 5 : 3, 0.5, 92, "fire")
    e[:t] = 2.2 + rnd
  end
end

def ai_knight(e, dt, p)
  case e[:state]
  when :tele
    e[:st] -= dt
    if e[:st] <= 0 then e[:state] = :charge; e[:st] = 0.9; Snd.play("charge") end
    return
  when :charge
    e[:st] -= dt
    bx, by = move_body($G.room, e, Math.cos(e[:ca]) * 230 * dt, Math.sin(e[:ca]) * 230 * dt, :walker)
    particle(e[:x], e[:y] + 5, 0, 0, 0.25, "#8b8f9c", 2) if rnd < 0.5
    if bx || by
      e[:state] = :stun; e[:st] = 0.9; add_shake(3); Snd.play("hit")
      burst(e[:x], e[:y], ["#8b8f9c", "#f4ecd8"], 10, 60)
      ering(e[:x], e[:y], 8, 70, 0, "red") if $G.floor_index >= 3 || e[:elite]
    elsif e[:st] <= 0
      e[:state] = :idle; e[:t] = 1.2
    end
    return
  when :stun
    e[:st] -= dt
    if e[:st] <= 0 then e[:state] = :idle; e[:t] = 1 end
    return
  end
  steer(e, p[:x], p[:y], e[:speed], dt, :walker)
  if e[:t] <= 0 && dist(e, p) < 170
    e[:state] = :tele; e[:st] = 0.6; e[:ca] = ang_to(e, p); e[:face] = Math.cos(e[:ca]) > 0 ? 1 : -1
  end
end

def ai_ghost(e, dt, p)
  e[:cyc] = (e[:cyc] || rnd * 3) + dt
  vis = (e[:cyc] % 3.6) < 2.4
  e[:hidden] = true if !vis && !e[:hidden]
  if vis && e[:hidden]
    e[:hidden] = false
    ering(e[:x], e[:y], 6 + [4, $G.floor_index].min, 55, rnd * TAU, "cyan") if $G.floor_index >= 1
  end
  steer(e, p[:x], p[:y], e[:speed] * (e[:hidden] ? 1.4 : 0.8), dt, :flyer)
end

# Flying book: flutters around and fires fans of pages.
def ai_book(e, dt, p)
  wander_keep(e, dt, p, 70, 130)
  if e[:t] <= 0
    efan(e[:x], e[:y] - 2, ang_to(e, p), e[:elite] ? 7 : 5, 0.8, 80, "page")
    e[:t] = 2.4 + rnd
  end
end

# Drowned: shambles closer, spits water, bursts when it dies.
def ai_drowned(e, dt, p)
  steer(e, p[:x], p[:y], e[:speed], dt, :walker)
  if e[:t] <= 0 && dist(e, p) < 160
    efan(e[:x], e[:y] - 3, ang_to(e, p), 3, 0.35, 75, "water")
    e[:t] = 2.6 + rnd
  end
end

# Frost wisp: darts around the player and leaves drifting ice motes.
def ai_wisp(e, dt, p)
  e[:dir] ||= rnd < 0.5 ? 1 : -1
  e[:orb] = (e[:orb] || rnd * TAU) + dt * 1.6 * e[:dir]
  tx = p[:x] + Math.cos(e[:orb]) * 60; ty = p[:y] + Math.sin(e[:orb]) * 50
  steer(e, clampf(tx, 30, SW - 30), clampf(ty, 44, SH - 30), e[:speed], dt, :flyer)
  e[:face] = p[:x] > e[:x] ? 1 : -1
  if e[:t] <= 0
    a = ang_to(e, p)
    eshot(e[:x], e[:y], a, 22, "ice", 2.5)
    eshot(e[:x], e[:y], a + 0.5, 22, "ice", 2.5) if e[:elite]
    e[:t] = 1.1 + rnd * 0.4
  end
end

# Ice golem: lumbers forward, then slams the floor with a ring of ice.
def ai_golem(e, dt, p)
  if e[:state] == :slam
    e[:st] -= dt
    if e[:st] <= 0
      add_shake(4); Snd.play("boom")
      ering(e[:x], e[:y], e[:elite] ? 18 : 12, 70, rnd, "ice")
      burst(e[:x], e[:y] + 6, ["#c8f0ff", "#4d9be6"], 14, 70)
      e[:state] = :idle; e[:t] = 2.4 + rnd
    end
    return
  end
  steer(e, p[:x], p[:y], e[:speed], dt, :walker)
  if e[:t] <= 0 && dist(e, p) < 130 then e[:state] = :slam; e[:st] = 0.7; Snd.play("charge") end
end
