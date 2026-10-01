# Tiny Biggot - floors as a chain of rooms: after each room you pick the next door,
# and every door shows its room type and reward. Also tiles, collision and room backgrounds.
T_FLOOR = 0
T_WALL = 1
T_PILLAR = 2
T_DOOR = 3
T_CRATE = 4
DIRS = { "n" => [0, -1], "s" => [0, 1], "e" => [1, 0], "w" => [-1, 0] }
OPP = { "n" => "s", "s" => "n", "e" => "w", "w" => "e" }

def new_floor(index)
  total = [7 + index, 11].min
  { index: index, total: total, depth: 0, shop_depth: rint(total / 2 - 1, total / 2 + 1), shop_done: false, path: [] }
end

def make_room(floor, kind, reward, entrance)
  room = { type: kind, reward: reward, depth: floor[:depth], doors: {}, exits: {}, secret_dirs: {}, sealed: {},
           entrance: entrance, cleared: false, visited: true, seed: rand(1_000_000_000), dist: floor[:depth] }
  # Some fights hide a cracked wall on a side wall: bomb it to open a hidden room.
  if %w(combat elite).include?(kind) && rnd < 0.28
    side = pick(%w(e w) - [entrance])
    room[:secret_dirs][side] = true
    room[:doors][side] = true
  end
  build_room(room)
  room
end

def weighted(h)
  t = h.values.inject(0) { |a, b| a + b }
  x = rand * t
  h.each { |k, v| return k if (x -= v) < 0 }
  h.keys.first
end

def roll_reward(p, elite = false)
  return pick([:rare, :rare, :relic, :level]) if elite
  w = { relic: 16, gold: 16, heal: p[:hp] < p[:max_hp] / 2 ? 22 : 8, supply: 10, armor: 8, level: 14, embers: 5 }
  weighted(w)
end

# Choices for the doors out of the current room.
def gen_choices(floor, p)
  d = floor[:depth] + 1
  return [{ type: "boss" }] if d >= floor[:total]
  out = []
  out << { type: "shop" } if d == floor[:shop_depth] && !floor[:shop_done]
  out << { type: "rest" } if d == floor[:total] - 1
  n = d < 2 ? 2 : (rnd < 0.55 ? 3 : 2)
  tries = 0
  while out.size < n && tries < 40
    tries += 1
    kind = weighted({ "combat" => 46, "elite" => (floor[:index] >= 1 || d >= 3) ? 14 : 0, "treasure" => 7, "shrine" => 8,
                      "challenge" => floor[:index] >= 1 ? 6 : 0, "vault" => 5, "shop" => floor[:shop_done] ? 0 : 2 })
    c = { type: kind }
    c[:reward] = roll_reward(p, kind == "elite") if kind == "combat" || kind == "elite"
    next if out.any? { |o| o[:type] == c[:type] && o[:reward] == c[:reward] }
    next if kind != "combat" && out.any? { |o| o[:type] == kind }
    out << c
  end
  out << { type: "combat", reward: roll_reward(p) } unless out.any? { |o| o[:type] == "combat" || o[:type] == "elite" }
  out.first(3)
end

def assign_exits(room, choices)
  dirs = %w(n w e) - [room[:entrance]] - room[:secret_dirs].keys
  # With few free walls, open doors take priority over locked vaults so a keyless hero is never boxed in.
  choices = choices.each_with_index.sort_by { |c, i| [c[:type] == "vault" ? 1 : 0, i] }.map { |c, i| c } if choices.size > dirs.size
  choices.each_with_index do |c, i|
    d = dirs[i]
    break unless d
    room[:exits][d] = c
    room[:doors][d] = true
    room[:sealed][d] = true if c[:type] == "vault"
    door_tiles(d).each { |cc, rr| room[:grid][rr][cc] = T_DOOR }
  end
end

def build_room(room)
  rng = SeedRng.new(room[:seed])
  g = Array.new(ROWS) { |r| Array.new(COLS) { |c| (c >= IX0 && c < IX0 + IW && r >= IY0 && r < IY0 + IH) ? T_FLOOR : T_WALL } }
  room[:crate_hp] = {}
  room[:layout] = 0
  if %w(combat elite challenge).include?(room[:type])
    clear = lambda do |ix, iy|
      (ix >= 10 && ix <= 15 && (iy <= 3 || iy >= 11)) || ((ix <= 3 || ix >= 22) && iy >= 5 && iy <= 9) ||
        (ix >= 11 && ix <= 14 && iy >= 6 && iy <= 8)
    end
    put = lambda do |ix, iy, t|
      [[ix, iy], [25 - ix, iy], [ix, 14 - iy], [25 - ix, 14 - iy]].each do |a, b|
        next if a < 0 || b < 0 || a >= IW || b >= IH || clear.call(a, b)
        g[b + IY0][a + IX0] = t
        room[:crate_hp][[a + IX0, b + IY0]] = 12.0 if t == T_CRATE
      end
    end
    pat = rng.int(0, 8)
    case pat
    when 1 then put.call(5, 3, 2); put.call(6, 3, 2); put.call(5, 4, 2); put.call(6, 4, 2)
    when 2 then (6..9).each { |i| put.call(i, 6, 2) }; put.call(6, 5, 2)
    when 3 then put.call(4, 2, 2); put.call(8, 2, 2); put.call(4, 5, 2); put.call(8, 5, 2); put.call(12, 3, 4)
    when 4 then 7.times { put.call(rng.int(2, 11), rng.int(1, 6), rng.next_f < 0.6 ? T_CRATE : T_PILLAR) }
    when 5 then (5..9).each { |i| put.call(i, 4, i.odd? ? 2 : 4) }
    when 6 then put.call(7, 2, 2); put.call(7, 3, 2); put.call(3, 6, 4); put.call(10, 5, 4)
    when 7 then [[3, 2], [5, 4], [7, 2], [9, 4]].each { |a, b| put.call(a, b, 2) }
    when 8 then (2..5).each { |i| put.call(i, 3, 4) }; put.call(9, 1, 2); put.call(9, 2, 2)
    end
    room[:layout] = pat
  end
  room[:doors].keys.each { |d| door_tiles(d).each { |c, r| g[r][c] = room[:secret_dirs][d] ? T_WALL : T_DOOR } }
  room[:grid] = g
  room[:bg] = nil
end

def door_tiles(d)
  case d
  when "n" then [[13, 0], [14, 0], [13, 1], [14, 1]]
  when "s" then [[13, 17], [14, 17]]
  when "w" then [[0, 8], [0, 9], [0, 10]]
  else [[27, 8], [27, 9], [27, 10]]
  end
end

def door_dir_at(c, r)
  return "n" if r <= 1
  return "s" if r >= 17
  c == 0 ? "w" : "e"
end

def door_center(d)
  case d
  when "n" then [14.0 * TS, 1.0 * TS]
  when "s" then [14.0 * TS, 17.5 * TS]
  when "w" then [0.5 * TS, 9.5 * TS]
  else [27.5 * TS, 9.5 * TS]
  end
end

def open_secret(room, d)
  return unless room[:secret_dirs][d]
  room[:secret_dirs].delete(d)
  room[:exits][d] = { type: "secret" }
  door_tiles(d).each { |c, r| room[:grid][r][c] = T_DOOR }
end

# ---------- Collision ----------
def tile_at(room, c, r)
  return T_WALL if r < 0 || c < 0 || r >= ROWS || c >= COLS
  room[:grid][r][c]
end

# mode: :player, :walker, :flyer, :bullet
def solid?(room, c, r, mode)
  t = tile_at(room, c, r)
  return false if t == T_FLOOR
  return (mode != :player || $G.locked || room[:sealed][door_dir_at(c, r)]) if t == T_DOOR
  return true if t == T_WALL
  mode != :flyer
end

def hits_solid?(room, x, y, r, mode)
  c0 = ((x - r) / TS).floor; c1 = ((x + r - 0.01) / TS).floor
  r0 = ((y - r) / TS).floor; r1 = ((y + r - 0.01) / TS).floor
  (r0..r1).each { |rr| (c0..c1).each { |cc| return true if solid?(room, cc, rr, mode) } }
  false
end

def move_body(room, e, dx, dy, mode)
  bx = false; by = false
  if dx != 0
    if !hits_solid?(room, e[:x] + dx, e[:y], e[:r], mode)
      e[:x] += dx
    else
      bx = true
      st = sgn(dx)
      dx.abs.ceil.times { break if hits_solid?(room, e[:x] + st, e[:y], e[:r], mode); e[:x] += st }
    end
  end
  if dy != 0
    if !hits_solid?(room, e[:x], e[:y] + dy, e[:r], mode)
      e[:y] += dy
    else
      by = true
      st = sgn(dy)
      dy.abs.ceil.times { break if hits_solid?(room, e[:x], e[:y] + st, e[:r], mode); e[:y] += st }
    end
  end
  [bx, by]
end

def free_spot(room, from, min_d, mode = :walker, rad = 8)
  300.times do
    c = rint(IX0 + 1, IX0 + IW - 2); r = rint(IY0 + 1, IY0 + IH - 2)
    x = c * TS + 8; y = r * TS + 8
    next if solid?(room, c, r, mode)
    next if mode != :flyer && hits_solid?(room, x, y, rad, mode)
    next if from && Math.hypot(x - from[:x], y - from[:y]) < min_d
    return { x: x.to_f, y: y.to_f }
  end
  { x: SW / 2.0, y: SH / 2.0 + 16 }
end

# ---------- Room background (composed from the floor's tile kit) ----------
def build_room_bg(room, floor_index)
  kit = Img["kit#{floor_index}"]
  b = Bitmap.new(SW, SH)
  rng = SeedRng.new(room[:seed] ^ 0x5bd1e995)
  rc = Rect.new(0, 0, TS, TS)
  b.fill_rect(0, 0, SW, SH, hex_color("#140f1c"))
  (IY0...(IY0 + IH)).each do |r|
    (IX0...(IX0 + IW)).each do |c|
      v = rng.int(0, 7) * 2 + ((r + c) % 2 == 1 ? 0 : 1)
      rc.set(v * TS, 0, TS, TS)
      b.blt(c * TS, r * TS, kit, rc)
    end
  end
  b.fill_rect(TS, IY0 * TS, IW * TS, 5, Color.new(10, 6, 16, 90))
  COLS.times do |c|
    rc.set(0, TS, TS, TS); b.blt(c * TS, 0, kit, rc)
    rc.set(TS, TS, TS, TS); b.blt(c * TS, TS, kit, rc)
    rc.set(2 * TS, TS, TS, TS); b.blt(c * TS, 17 * TS, kit, rc)
  end
  (IY0...(ROWS - 1)).each do |r|
    rc.set(3 * TS, TS, TS, TS); b.blt(0, r * TS, kit, rc)
    rc.set(4 * TS, TS, TS, TS); b.blt(27 * TS, r * TS, kit, rc)
  end
  pr = Rect.new(0, 2 * TS, TS + 1, 2 * TS)
  (IY0...(IY0 + IH)).each do |r|
    (IX0...(IX0 + IW)).each do |c|
      next unless room[:grid][r][c] == T_PILLAR
      b.blt(c * TS, r * TS - 4, kit, pr)
    end
  end
  room[:bg] = b
end
