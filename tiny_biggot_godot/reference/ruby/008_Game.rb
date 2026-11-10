# Tiny Biggot - game state, run flow, room choice, rewards, traits, unlocks and menus.

class CCGame
  attr_accessor :state, :time, :menu, :hero_index, :floor_index, :floor, :room, :player,
                :enemies, :pbullets, :ebullets, :pickups, :particles, :texts, :bombs,
                :locked, :boss, :shake, :hitstop, :banner, :prompt, :choice, :run_stats, :death_by,
                :quit_armed, :embers, :opt_from, :state_t, :fade, :dyn_dirty, :win_timer,
                :dread, :familiars, :award, :msg, :codex_i, :shrine_i,
                :zones, :temp_fams, :new_pbullets, :tchoice, :tree_hero, :tree_b, :tree_n, :pause_page

  TITLE_ITEMS = ["START RUN", "SKILL TREES", "EMBER SHRINE", "CODEX", "HOW TO PLAY", "OPTIONS"]
  PAUSE_ITEMS = ["RESUME", "GEAR", "TRAITS", "RELICS", "OPTIONS", "ABANDON RUN"]
  OPTION_LIST = [["AUTO-AIM FIRE", :autofire], ["MUSIC", :music], ["SOUND EFFECTS", :sfx], ["SCREEN SHAKE", :shake], ["BACK", nil]]
  CODEX_COLS = 11

  def initialize
    @state = :title; @time = 0.0; @menu = 0; @hero_index = 0; @floor_index = 0
    @enemies = []; @pbullets = []; @ebullets = []; @pickups = []; @particles = []; @texts = []; @bombs = []; @familiars = []
    @zones = []; @temp_fams = []; @new_pbullets = []
    @locked = false; @boss = nil; @shake = 0.0; @hitstop = 0.0; @banner = nil; @prompt = nil; @choice = nil; @tchoice = nil
    @run_stats = { kills: 0, gold: 0, time: 0.0, floor: 1, bosses: 0, secrets: 0 }; @death_by = ""; @quit_armed = false
    @embers = []; @opt_from = :title; @state_t = 0.0; @fade = nil; @dyn_dirty = true
    @wave_delay = 0; @boss_delay = nil; @win_timer = nil; @spawned = false
    @dread = $meta[:dread] || 0; @award = nil; @msg = nil; @codex_i = 0; @shrine_i = 0
    @tree_hero = 0; @tree_b = 0; @tree_n = 0; @pause_page = nil; @swings = []
  end

  def enemies_active?
    @enemies.any? { |e| e[:spawn_t] <= 0 && !e[:hidden] }
  end

  def hero_unlocked?(h); h[:cost] == 0 || unlocked?("hero_" + h[:id]); end

  def relic_pool
    ids = BASE_RELICS.dup
    ids += CACHE_1 if unlocked?("cache1")
    ids += CACHE_2 if unlocked?("cache2")
    ids += CACHE_3 if unlocked?("cache3")
    ids.map { |i| RELIC_BY_ID[i] }
  end

  def tree_owned(hero_id)
    $meta[:tree] ||= {}
    $meta[:tree][hero_id] ||= [0, 0, 0]
  end

  # ---------- Run flow ----------
  def new_run
    hero = HEROES[@hero_index]
    @player = create_player(hero)
    @run_stats = { kills: 0, gold: 0, time: 0.0, floor: 1, bosses: 0, secrets: 0 }
    @floor_index = 0
    @familiars = []; @temp_fams = []; @zones = []
    @dread = [$meta[:dread] || 0, $meta[:dread_max] || 0].min
    p = @player
    tree_for(hero[:id]).each_with_index do |br, bi|
      tree_owned(hero[:id])[bi].times { |ni| br[:nodes][ni][2].call(p) }
    end
    p[:gold] += 20 if unlocked?("perk_gold")
    p[:bombs] += 2 if unlocked?("perk_bombs")
    if unlocked?("perk_potion") then p[:potions] += 1; p[:max_potions] = [p[:max_potions], p[:potions]].max end
    p[:keys] += 1 if unlocked?("perk_key")
    if unlocked?("perk_heart") then p[:max_hp] += 2; p[:hp] += 2 end
    if @dread >= 5 then p[:max_hp] = [2, p[:max_hp] - 2].max; p[:hp] = [p[:hp], p[:max_hp]].min end
    if unlocked?("perk_relic")
      r = roll_relics(1, :chest)[0]
      add_relic(p, r) if r
    end
    if p[:start_rare]
      r = roll_relics(1, :iron)[0]
      add_relic(p, r) if r
    end
    $meta[:runs] += 1; write_save
    start_floor
  end

  def start_floor
    @floor = new_floor(@floor_index)
    @run_stats[:floor] = @floor_index + 1
    $meta[:best] = [$meta[:best], @floor_index + 1].max; write_save
    Snd.music(@floor_index)
    @room = nil
    enter_room(make_room(@floor, "start", nil, nil))
    @state = :play
    show_banner(FLOORS[@floor_index][:name], "FLOOR #{@floor_index + 1} OF #{FLOORS.size}" + (@dread > 0 ? "   DREAD #{@dread}" : ""))
  end

  def enter_room(room)
    @room = room
    @pickups = room[:pickups] || []
    @enemies = []; @pbullets = []; @ebullets = []; @bombs = []; @particles = []; @texts = []; @zones = []; @new_pbullets = []
    @boss = nil; @win_timer = nil
    p = @player
    p[:buckler_used] = false; p[:volleys] = []; p[:trail] = []; p[:dodge_t] = 0.0; p[:room_kills] = 0
    p[:armor] = [p[:armor], 1].max if p[:ironskin]
    spots = { "s" => [14.0 * TS, 16.0 * TS], "n" => [14.0 * TS, 2.6 * TS], "e" => [26.0 * TS - 2, 9.5 * TS], "w" => [2.0 * TS + 2, 9.5 * TS] }
    if room[:entrance] then p[:x], p[:y] = spots[room[:entrance]] else p[:x] = 14.0 * TS; p[:y] = 10.0 * TS end
    @familiars.each { |f| f[:x] = p[:x]; f[:y] = p[:y] }
    build_room_bg(room, @floor_index) unless room[:bg]
    setup_objects(room) unless room[:objects]
    @locked = false
    @spawned = false
    case room[:type]
    when "combat", "elite"
      @locked = true
      room[:waves_left] = (room[:type] == "elite" ? 2 : 1) + (rnd < 0.25 + 0.08 * @floor_index ? 1 : 0)
      @wave_delay = 0.35
      Snd.play("door")
    when "boss"
      @locked = true
      @boss_delay = 1.0
      Snd.play("door")
      Snd.music(BOSS_TRACK)
    when "challenge"
      # Exits stay shut until the bell is rung and the waves are beaten, or until the player skips it.
      open_exits
    else
      open_exits
    end
    @dyn_dirty = true
    $R.room_changed if $R
  end

  def open_exits
    return if @room[:exits_open]
    @room[:exits_open] = true
    return if @room[:type] == "boss"
    assign_exits(@room, gen_choices(@floor, @player))
    @room[:exits].each do |d, c|
      next unless c[:type] == "vault"
      x, y = door_center(d)
      ix = { "w" => 22, "e" => -22 }[d] || 0
      iy = { "n" => 26, "s" => -22 }[d] || 0
      @room[:objects] << { kind: :lockdoor, dir: d, x: x + ix, y: y + iy }
    end
    @dyn_dirty = true
  end

  def leave_room(dir)
    c = @room[:exits][dir]
    return unless c
    if c[:type] != "secret"
      @floor[:depth] += 1
      @floor[:path] << c
    end
    @floor[:shop_done] = true if c[:type] == "shop"
    $meta[:secrets] += 1 if c[:type] == "secret"
    @run_stats[:secrets] += 1 if c[:type] == "secret"
    nr = make_room(@floor, c[:type], c[:reward], OPP[dir])
    start_fade { enter_room(nr) }
  end

  def price(v)
    v *= 1 + 0.08 * @dread if @dread >= 3
    [1, (v * (1 - @player[:shop_disc])).round].max
  end

  def setup_objects(room)
    room[:objects] = []
    cx = 14.0 * TS; cy = 9.5 * TS
    f = @floor_index
    mk = lambda { |kind, x, y| { kind: kind, x: x.to_f, y: y.to_f, vx: 0.0, vy: 0.0, z: 0.0, vz: 0.0, t: 1.0, r: 3 } }
    case room[:type]
    when "treasure"
      if rnd < 0.35
        room[:objects] << { kind: :chest, x: cx - 24, y: cy }
        room[:objects] << { kind: :ichest, x: cx + 24, y: cy }
      else
        room[:objects] << { kind: :chest, x: cx, y: cy }
      end
    when "shop"
      roll_relics(3, :shop).each_with_index do |r, i|
        base = { common: 30, rare: 48, epic: 70, legend: 95 }[r[:rarity]]
        room[:objects] << { kind: :shop, item: :relic, relic: r, x: cx - 120 + i * 40, y: cy - 8, price: price(base + f * 8 + rint(0, 8)) }
      end
      extras = [[:potion, 18], [:heart, 12], [pick([:bomb, :key]), 10], [:armor, 16]]
      extras.each_with_index do |(it, c), i|
        room[:objects] << { kind: :shop, item: it, x: cx + 8 + i * 34, y: cy - 8, price: price(c + f * 3) }
      end
    when "shrine"
      roll = rnd
      room[:objects] << if roll < 0.4 then { kind: :altar, x: cx, y: cy }
                        elsif roll < 0.7 then { kind: :fountain, x: cx, y: cy }
                        else { kind: :idol, x: cx, y: cy, uses: 3 }
                        end
    when "vault"
      room[:objects] << { kind: :ichest, x: cx - 26, y: cy, free: true }
      room[:objects] << { kind: :ichest, x: cx + 26, y: cy, free: true }
      room[:pickups] = (0...4).map { mk.call(:gem, cx + rint(-40, 40), cy + 30) }
    when "secret"
      roll = rnd
      if roll < 0.45
        room[:objects] << { kind: :pedestal, relic: roll_relics(1, :secret)[0], x: cx, y: cy }
      elsif roll < 0.75
        room[:objects] << { kind: :cchest, x: cx, y: cy }
        room[:pickups] = (0...6).map { mk.call(:coin, cx + rint(-50, 50), cy + rint(20, 40)) }
      else
        room[:pickups] = (0...3).map { |i| mk.call(:ember, cx - 20 + i * 20, cy) } + (0...3).map { |i| mk.call(:gem, cx - 20 + i * 20, cy + 20) }
      end
    when "challenge"
      room[:objects] << { kind: :bell, x: cx, y: cy }
    when "rest"
      room[:objects] << { kind: :campfire, x: cx, y: cy }
    end
  end

  def roll_rarity(source)
    w = LOOT[source] || LOOT[:chest]
    order = [:common, :rare, :epic, :legend]
    best = nil
    (1 + (@player ? @player[:luck] : 0)).times do
      t = w.values.inject(0) { |a, b| a + b }
      x = rand * t
      got = :common
      w.each { |k, v| if (x -= v) < 0 then got = k; break end }
      best = got if best.nil? || order.index(got) > order.index(best)
    end
    best
  end

  def roll_relics(n, source = :chest)
    owned = {}
    @player[:relics].each { |r| owned[r[:id]] = true }
    offered = {}
    (@room && @room[:objects] || []).each { |o| offered[o[:relic][:id]] = true if o[:relic] }
    pool = relic_pool.select { |r| !owned[r[:id]] && !offered[r[:id]] }
    pool = relic_pool.select { |r| !owned[r[:id]] } if pool.size < n
    out = []
    n.times do
      break if pool.empty?
      rar = roll_rarity(source)
      order = [:legend, :epic, :rare, :common]
      cands = []
      i = order.index(rar)
      while cands.empty? && i < order.size
        cands = pool.select { |r| r[:rarity] == order[i] }
        i += 1
      end
      cands = pool if cands.empty?
      r = pick(cands)
      out << r
      pool.delete(r)
    end
    out
  end

  def spawn_wave(hard = false)
    fdef = FLOORS[@floor_index]
    n = rint(3, 4) + [@floor_index, 4].min + (@room[:depth] > 3 ? 1 : 0)
    ec = (@floor_index == 0 ? 0.05 : 0.08 + @floor_index * 0.035) + (@dread >= 3 ? 0.08 : 0) + (hard ? 0.35 : 0)
    ec += 0.45 if @room[:type] == "elite"
    n.times do
      type = pick(fdef[:pool])
      s = free_spot(@room, @player, 90, ENEMIES[type][:fly] ? :flyer : :walker)
      spawn_enemy(type, s[:x], s[:y], rnd < ec)
    end
    @room[:waves_left] -= 1
  end

  def give_reward(kind)
    cx = 14.0 * TS; cy = 9.5 * TS
    case kind
    when :relic then @room[:objects] << { kind: :chest, x: cx, y: cy }
    when :rare then @room[:objects] << { kind: :ichest, x: cx, y: cy, free: true }
    when :gold then rint(4, 6).times { drop_pickup(:gem, cx, cy) }; rint(3, 6).times { drop_pickup(:coin, cx, cy) }
    when :heal then drop_pickup(:heart, cx - 8, cy); drop_pickup(:heart, cx + 8, cy); drop_pickup(:potion, cx, cy)
    when :supply then 2.times { drop_pickup(:bomb, cx, cy) }; drop_pickup(:key, cx, cy)
    when :armor then 2.times { drop_pickup(:armor, cx, cy) }
    when :level then gain_xp(@player, xp_needed(@player[:level]) - @player[:xp])
    when :embers then 3.times { drop_pickup(:ember, cx, cy) }
    end
  end

  def room_cleared
    @locked = false
    @room[:cleared] = true
    @dyn_dirty = true
    Snd.play("door")
    p = @player
    if p[:interest] > 0 && p[:gold] > 0
      g = (p[:gold] * p[:interest]).floor
      if g > 0 then p[:gold] += g; float_text(p[:x], p[:y] - 16, "+#{g} INTEREST", "gold") end
    end
    p[:bombs] += p[:sapper] if p[:sapper] > 0
    p[:armor] += p[:armor_regen] if p[:armor_regen] > 0
    if @room[:type] == "challenge"
      give_reward(:rare)
      show_banner("CHALLENGE BEATEN", "AN IRON CHEST APPEARS")
      Snd.play("unlock")
    else
      give_reward(@room[:reward]) if @room[:reward]
    end
    open_exits
  end

  def open_secret_door(d)
    return unless @room[:secret_dirs][d]
    open_secret(@room, d)
    @dyn_dirty = true
    $R.room_changed if $R
    show_banner("A HIDDEN ROOM", "THE CRACKED WALL GIVES WAY")
    Snd.play("unlock")
  end

  def on_boss_dead(boss)
    @ebullets = []
    @enemies.each { |e| if !e.equal?(boss) && e[:hp] > 0 then e[:hp] = 0; burst(e[:x], e[:y], ["#f4ecd8"], 8, 50) end }
    @locked = false
    @room[:cleared] = true
    @dyn_dirty = true
    @run_stats[:bosses] += 1; $meta[:bosses] += 1
    p = @player
    if p[:oath] then p[:max_hp] += 2; p[:hp] += 2 end
    Snd.music(@floor_index)
    show_banner(boss[:d][:name] + " FALLS", "")
    12.times { drop_pickup(:coin, boss[:x], boss[:y]) }
    drop_pickup(:heart, boss[:x], boss[:y])
    drop_pickup(:ember, boss[:x], boss[:y])
    last = @floor_index >= FLOORS.size - 1
    @room[:objects] << { kind: :chest, x: 14.0 * TS - (last ? 0 : 28), y: 10.0 * TS, boss: true }
    if last then @win_timer = 4.5 else @room[:objects] << { kind: :portal, x: 14.0 * TS + 28, y: 10.0 * TS } end
  end

  def award_embers(win)
    r = @run_stats; p = @player
    parts = [["FLOORS", (@floor_index + (win ? 1 : 0)) * 6], ["GUARDIANS", r[:bosses] * 12], ["FOES", r[:kills] / 8],
             ["EMBER SHARDS", p[:embers_found]], ["SECRETS", r[:secrets] * 5], ["LEVEL", p[:level]]]
    parts << ["VICTORY", 40] if win
    base = parts.inject(0) { |a, x| a + x[1] }
    mult = 1 + 0.25 * @dread
    total = (base * mult).round
    $meta[:embers] += total
    $meta[:kills] += r[:kills]
    @award = { parts: parts, mult: mult, total: total }
    write_save
  end

  def on_death(source)
    @death_by = source || "the crypt"
    @state = :dead; @state_t = 0.0; @menu = 0
    award_embers(false)
    Snd.play("die")
    Snd.music(0)
  end

  def on_win
    $meta[:wins] += 1
    $meta[:dread_max] = [[($meta[:dread_max] || 0), @dread + 1].max, 5].min
    award_embers(true)
    @state = :win; @state_t = 0.0; Snd.play("win"); Snd.music(0)
  end

  def show_banner(text, sub); @banner = { text: text, sub: sub, t: 2.6 }; end
  def toast(text, col = "white"); @msg = { text: text, col: col, t: 2.0 }; end
  def start_fade(&blk); @fade = { t: 0.0, phase: :out, cb: blk }; end

  # ---------- Traits ----------
  def trait_weight(p, t)
    rank = p[:traits][t[:id]] || 0
    return 0 if rank >= t[:max]
    fam = p[:fam][t[:fam]] || 0
    if t[:cap]
      return 0 if fam < 3
      return 6
    end
    w = 3
    w += [fam, 4].min * 2 if t[:fam] != :core
    w
  end

  def offer_traits
    p = @player
    cands = TRAITS.map { |t| [t, trait_weight(p, t)] }.select { |t, w| w > 0 }
    opts = []
    3.times do
      break if cands.empty?
      tot = cands.inject(0) { |a, x| a + x[1] }
      x = rand * tot
      idx = 0
      cands.each_with_index { |(t, w), i| if (x -= w) < 0 then idx = i; break end }
      opts << cands[idx][0]
      cands.delete_at(idx)
    end
    if opts.empty? then p[:pending] = 0; return end
    @tchoice = { opts: opts, idx: [1, opts.size - 1].min }
    @state = :traits
  end

  def take_trait(t)
    p = @player
    p[:traits][t[:id]] = (p[:traits][t[:id]] || 0) + 1
    t[:fx].call(p)
    p[:charges] = [p[:charges], p[:dodge_charges]].min
    p[:fam][t[:fam]] = (p[:fam][t[:fam]] || 0) + 1
    if FAMILY_BONUS[t[:fam]]
      tier = [p[:fam][t[:fam]] / 2, 3].min
      have = p[:fam_bonus][t[:fam]] || 0
      while have < tier
        b = FAMILY_BONUS[t[:fam]][have]
        b[1].call(p)
        have += 1
        toast(FAMILIES[t[:fam]][:name] + " " + (have * 2).to_s + ": " + b[0], FAMILIES[t[:fam]][:col])
      end
      p[:fam_bonus][t[:fam]] = have
    end
    p[:pending] -= 1
    Snd.play("relic")
  end

  # ---------- Update ----------
  def update(dt)
    @time += dt
    if @banner then @banner[:t] -= dt; @banner = nil if @banner[:t] <= 0 end
    if @msg then @msg[:t] -= dt; @msg = nil if @msg[:t] <= 0 end
    @shake = [0, @shake - dt * 30].max
    if @fade
      @fade[:t] += dt / 0.16
      if @fade[:phase] == :out && @fade[:t] >= 1
        @fade[:cb].call; @fade[:phase] = :in; @fade[:t] = 0.0
      elsif @fade[:phase] == :in && @fade[:t] >= 1
        @fade = nil
      end
      return
    end
    case @state
    when :title then update_title(dt)
    when :hero then update_hero
    when :tree then update_embers(dt); update_tree
    when :howto then (if Keys.any then @state = :title; Snd.play("select") end)
    when :options then update_options
    when :shrine then update_embers(dt); update_shrine
    when :codex then update_embers(dt); update_codex
    when :pause then update_pause
    when :relics, :traitlist, :gearpage then (if Keys.any then @state = :pause; Snd.play("select") end)
    when :choice then update_choice
    when :traits then update_traits
    when :dead, :win
      update_embers(dt)
      @state_t += dt
      if Keys.any && @state_t > 1 then @state = :title; @menu = 0; Snd.play("confirm") end
    when :play then update_play(dt)
    end
  end

  def update_play(dt)
    @run_stats[:time] += dt
    if Keys.pause then @state = :pause; @menu = 0; @quit_armed = false; Snd.play("select"); return end
    if @hitstop > 0 then @hitstop -= dt; return end
    p = @player
    update_player(p, dt)
    return if @state != :play
    update_enemies(dt)
    update_pbullets(dt)
    update_ebullets(dt)
    update_pickups(dt)
    update_bombs(dt)
    update_zones(dt)
    update_particles(dt)
    @swings.each { |w| w[:t] -= dt }
    @swings.reject! { |w| w[:t] <= 0 }
    return if @state != :play
    if %w(combat elite challenge).include?(@room[:type]) && @locked
      alive = @enemies.size
      if @room[:waves_left] > 0 && alive <= (@spawned ? 1 : 0)
        @wave_delay -= dt
        if @wave_delay <= 0 then spawn_wave(@room[:type] == "challenge"); @spawned = true; @wave_delay = 0.6 end
      elsif alive == 0 && @room[:waves_left] <= 0
        room_cleared
      end
    end
    if @room[:type] == "boss" && @locked && !@boss && @boss_delay
      @boss_delay -= dt
      if @boss_delay <= 0
        @boss_delay = nil
        spawn_boss(FLOORS[@floor_index][:boss])
        show_banner(@boss[:d][:name], "")
      end
    end
    if @win_timer
      @win_timer -= dt
      if @win_timer <= 0 && @room[:objects].all? { |o| o[:kind] != :chest || o[:opened] }
        @win_timer = nil
        on_win
        return
      end
    end
    # Level-ups wait until the room is safe.
    if p[:pending] > 0 && !@locked && @enemies.empty? then offer_traits; return end
    @prompt = nil
    best = 24
    @room[:objects].each do |o|
      next if o[:used] || o[:opened] || o[:gone]
      d = Math.hypot(p[:x] - o[:x], p[:y] - o[:y])
      if d < best then best = d; @prompt = o end
    end
    interact(@prompt) if @prompt && Keys.use
    unless @locked
      dir = nil
      if p[:y] < TS * 1.2 then dir = "n"
      elsif p[:y] > SH - TS * 0.7 then dir = "s"
      elsif p[:x] < TS * 0.6 then dir = "w"
      elsif p[:x] > SW - TS * 0.6 then dir = "e"
      end
      if dir && @room[:exits][dir] && !@room[:sealed][dir]
        p[:x] = clampf(p[:x], TS, SW - TS); p[:y] = clampf(p[:y], TS * 1.3, SH - TS)
        leave_room(dir)
      end
    end
  end

  def deny(o, text)
    Snd.play("deny")
    float_text(o[:x], o[:y] - 18, text, "red")
  end

  def open_choice(source, o)
    n = unlocked?("perk_choice") ? 4 : 3
    ch = roll_relics(n, source)
    if ch.empty? then 15.times { drop_pickup(:coin, o[:x], o[:y]) }
    else @choice = { relics: ch, idx: [1, ch.size - 1].min }; @state = :choice
    end
  end

  def interact(o)
    p = @player
    case o[:kind]
    when :chest
      o[:opened] = true
      Snd.play("open")
      burst(o[:x], o[:y], ["#f2c94c", "#fffbe0"], 16, 60)
      open_choice(o[:boss] ? :boss : :chest, o)
    when :ichest
      if !o[:free]
        return deny(o, "NEEDS A KEY") if p[:keys] <= 0
        p[:keys] -= 1
      end
      o[:opened] = true
      Snd.play("lock"); Snd.play("open")
      burst(o[:x], o[:y], ["#8b8f9c", "#f4ecd8", "#f2c94c"], 18, 60)
      open_choice(:iron, o)
    when :cchest
      return deny(o, "TOO WEAK") if p[:max_hp] <= 2
      o[:opened] = true
      p[:max_hp] -= 2; p[:hp] = [p[:hp], p[:max_hp]].min
      add_shake(4); Snd.play("hurt")
      burst(o[:x], o[:y], ["#a35bd6", "#5c3483", "#d8443c"], 20, 70)
      open_choice(:cursed, o)
    when :pedestal
      o[:opened] = true
      if o[:relic] then add_relic(p, o[:relic]); show_banner(o[:relic][:name], o[:relic][:desc]) end
    when :shop
      return deny(o, "NEED #{o[:price]} GOLD") if p[:gold] < o[:price]
      return deny(o, "POTIONS FULL") if o[:item] == :potion && p[:potions] >= p[:max_potions]
      return deny(o, "HEALTH FULL") if o[:item] == :heart && p[:hp] >= p[:max_hp]
      p[:gold] -= o[:price]
      o[:gone] = true
      Snd.play("coin")
      case o[:item]
      when :relic then add_relic(p, o[:relic]); show_banner(o[:relic][:name], o[:relic][:desc])
      when :potion then p[:potions] += 1; Snd.play("heal")
      when :heart then heal_player(2)
      when :bomb then p[:bombs] += 1
      when :key then p[:keys] += 1
      when :armor then p[:armor] += 1
      end
    when :altar
      return deny(o, "TOO WEAK") if p[:hp] <= 2
      p[:hp] -= 2; o[:used] = true; add_shake(4); Snd.play("hurt")
      burst(o[:x], o[:y], ["#d8443c", "#8a2a33"], 20, 70)
      r = roll_relics(1, :altar)[0]
      if r then add_relic(p, r); show_banner(r[:name], r[:desc]) end
    when :fountain
      o[:used] = true; heal_player(p[:max_hp])
      burst(o[:x], o[:y], ["#6fd3e0", "#f4ecd8"], 20, 60)
    when :campfire
      o[:used] = true
      heal_player((p[:max_hp] / 2.0).ceil)
      p[:charges] = p[:dodge_charges]
      burst(o[:x], o[:y], ["#e8873a", "#f2c94c"], 20, 50)
      toast("YOU REST BY THE FIRE", "orange")
    when :idol
      cost = price(15 + @floor_index * 3)
      return deny(o, "NEED #{cost} GOLD") if p[:gold] < cost
      p[:gold] -= cost
      o[:uses] -= 1; o[:used] = true if o[:uses] <= 0
      Snd.play("coin")
      roll = rnd
      if roll < 0.28 then 2.times { drop_pickup(:gem, o[:x], o[:y] + 10) }; toast("THE IDOL PAYS OUT", "gold")
      elsif roll < 0.42 then r = roll_relics(1, :chest)[0]; (add_relic(p, r); show_banner(r[:name], r[:desc])) if r
      elsif roll < 0.62 then drop_pickup(pick([:bomb, :key, :armor, :potion]), o[:x], o[:y] + 10); toast("A GIFT FROM THE IDOL", "white")
      elsif roll < 0.8 then toast("THE IDOL KEEPS YOUR GOLD", "grey"); Snd.play("deny")
      else hurt_player(1, "a greedy idol"); toast("THE IDOL BITES", "red")
      end
    when :bell
      o[:used] = true
      Snd.play("bell")
      @locked = true; @spawned = false; @wave_delay = 0.8
      @room[:waves_left] = 3
      @dyn_dirty = true
      show_banner("THE BELL TOLLS", "SURVIVE THREE HARD WAVES")
    when :lockdoor
      return deny(o, "NEEDS A KEY") if p[:keys] <= 0
      p[:keys] -= 1
      o[:used] = true
      @room[:sealed].delete(o[:dir])
      @dyn_dirty = true
      Snd.play("lock"); Snd.play("door")
      toast("THE VAULT DOOR OPENS", "gold")
    when :portal
      Snd.play("portal")
      start_fade { @floor_index += 1; heal_player(2); start_floor }
    end
  end

  # ---------- Menus ----------
  def menu_nav(n, horizontal = false)
    if horizontal ? Keys.left : Keys.up then @menu = (@menu + n - 1) % n; Snd.play("select") end
    if horizontal ? Keys.right : Keys.down then @menu = (@menu + 1) % n; Snd.play("select") end
    Keys.confirm
  end

  def update_embers(dt)
    if @embers.size < 50 && rnd < 0.5
      @embers << { x: rnd * SW, y: SH + 4.0, vy: -(10 + rnd * 25), vx: (rnd - 0.5) * 8, life: 6 + rnd * 4, col: pick(["#e8873a", "#f2c94c", "#d8443c"]) }
    end
    @embers.each { |e| e[:x] += (e[:vx] + Math.sin(@time * 2 + e[:y] * 0.05) * 6) * dt; e[:y] += e[:vy] * dt; e[:life] -= dt }
    @embers.reject! { |e| e[:life] <= 0 || e[:y] < -4 }
  end

  def update_title(dt)
    update_embers(dt)
    return unless menu_nav(TITLE_ITEMS.size)
    Snd.play("confirm")
    case @menu
    when 0 then @state = :hero; @menu = @hero_index
    when 1 then @state = :tree; @tree_hero = @hero_index; @tree_b = 0; @tree_n = 0
    when 2 then @state = :shrine; @menu = @shrine_i
    when 3 then @state = :codex; @menu = @codex_i
    when 4 then @state = :howto
    else @state = :options; @opt_from = :title; @menu = 0
    end
  end

  def update_hero
    @menu = @hero_index
    go = menu_nav(HEROES.size, true)
    @hero_index = @menu
    mx = $meta[:dread_max] || 0
    if mx > 0
      if Keys.up then $meta[:dread] = ((($meta[:dread] || 0) + 1) % (mx + 1)); Snd.play("select") end
      if Keys.down then $meta[:dread] = ((($meta[:dread] || 0) + mx) % (mx + 1)); Snd.play("select") end
    end
    if Keys.roll then @state = :tree; @tree_hero = @hero_index; @tree_b = 0; @tree_n = 0; @tree_from = :hero; Snd.play("select"); return end
    if Keys.back then @state = :title; @menu = 0; Snd.play("select"); write_save; return end
    return unless go
    h = HEROES[@hero_index]
    if hero_unlocked?(h) then Snd.play("confirm"); write_save; start_fade { new_run }
    else Snd.play("deny"); toast("UNLOCK THIS HERO AT THE EMBER SHRINE", "orange")
    end
  end

  # Skill tree: LEFT/RIGHT pick a branch, UP/DOWN a node, USE buys, AIM LEFT/RIGHT change hero.
  def update_tree
    if Input.trigger?(:X) then @tree_hero = (@tree_hero + HEROES.size - 1) % HEROES.size; Snd.play("select") end
    if Input.trigger?(:Z) then @tree_hero = (@tree_hero + 1) % HEROES.size; Snd.play("select") end
    if Keys.left then @tree_b = (@tree_b + 2) % 3; Snd.play("select") end
    if Keys.right then @tree_b = (@tree_b + 1) % 3; Snd.play("select") end
    if Keys.up then @tree_n = (@tree_n + 3) % 4; Snd.play("select") end
    if Keys.down then @tree_n = (@tree_n + 1) % 4; Snd.play("select") end
    if Keys.back then @state = @tree_from == :hero ? :hero : :title; @menu = @tree_from == :hero ? @hero_index : 1; @tree_from = nil; Snd.play("select"); return end
    return unless Keys.confirm
    h = HEROES[@tree_hero]
    owned = tree_owned(h[:id])
    if !hero_unlocked?(h) then Snd.play("deny"); toast("UNLOCK THIS HERO FIRST", "orange"); return end
    if owned[@tree_b] > @tree_n then Snd.play("deny"); toast("ALREADY LEARNED", "grey"); return end
    if owned[@tree_b] < @tree_n then Snd.play("deny"); toast("LEARN THE SKILL ABOVE FIRST", "red"); return end
    cost = TREE_COSTS[@tree_n]
    if $meta[:embers] < cost then Snd.play("deny"); toast("NOT ENOUGH EMBERS", "red"); return end
    $meta[:embers] -= cost
    owned[@tree_b] += 1
    write_save
    Snd.play("unlock")
    toast(tree_for(h[:id])[@tree_b][:nodes][@tree_n][0] + " LEARNED", "gold")
  end

  def update_shrine
    @menu = @shrine_i
    go = menu_nav(UNLOCKS.size)
    @shrine_i = @menu
    if Keys.back then @state = :title; @menu = 2; Snd.play("select"); return end
    return unless go
    u = UNLOCKS[@shrine_i]
    if unlocked?(u[:id]) then Snd.play("deny"); toast("ALREADY UNLOCKED", "grey")
    elsif $meta[:embers] < u[:cost] then Snd.play("deny"); toast("NOT ENOUGH EMBERS", "red")
    else
      $meta[:embers] -= u[:cost]; $meta[:unlocked][u[:id]] = true
      write_save
      Snd.play("unlock"); toast(u[:name] + " UNLOCKED", "gold")
    end
  end

  def update_codex
    n = RELICS.size
    if Keys.left then @codex_i = (@codex_i + n - 1) % n; Snd.play("select") end
    if Keys.right then @codex_i = (@codex_i + 1) % n; Snd.play("select") end
    if Keys.up then @codex_i = (@codex_i - CODEX_COLS) % n; Snd.play("select") end
    if Keys.down then @codex_i = (@codex_i + CODEX_COLS) % n; Snd.play("select") end
    if Keys.back || Keys.confirm then @state = :title; @menu = 3; Snd.play("select") end
  end

  def update_options
    go = menu_nav(OPTION_LIST.size)
    back_menu = @opt_from == :title ? 5 : 4
    if Keys.back then @state = @opt_from; @menu = back_menu; Snd.play("select"); return end
    key = OPTION_LIST[@menu][1]
    if go || (key && (Keys.left || Keys.right))
      if key.nil? then @state = @opt_from; @menu = back_menu; Snd.play("select"); return end
      $opts[key] = !$opts[key]
      Snd.refresh if key == :music
      Snd.play("confirm")
      write_save
    end
  end

  def update_pause
    if Keys.back then @state = :play; Snd.play("select"); return end
    if menu_nav(PAUSE_ITEMS.size)
      Snd.play("confirm")
      case @menu
      when 0 then @state = :play
      when 1 then @state = :gearpage
      when 2 then @state = :traitlist
      when 3 then @state = :relics
      when 4 then @state = :options; @opt_from = :pause; @menu = 0
      when 5
        if @quit_armed then on_death("giving up")
        else @quit_armed = true
        end
      end
    end
    @quit_armed = false if @menu != 5
  end

  def update_choice
    c = @choice
    @menu = c[:idx]
    go = menu_nav(c[:relics].size, true)
    c[:idx] = @menu
    return unless go
    r = c[:relics][c[:idx]]
    add_relic(@player, r)
    show_banner(r[:name], r[:desc])
    @choice = nil
    @state = :play
  end

  # Trait pick: LEFT/RIGHT choose, USE takes it, MENU rerolls (limited).
  def update_traits
    c = @tchoice
    @menu = c[:idx]
    go = menu_nav(c[:opts].size, true)
    c[:idx] = @menu
    if Keys.back
      if @player[:rerolls] > 0
        @player[:rerolls] -= 1
        Snd.play("confirm")
        offer_traits
      else
        Snd.play("deny")
      end
      return
    end
    return unless go
    take_trait(c[:opts][c[:idx]])
    @tchoice = nil
    @state = :play
    offer_traits if @player[:pending] > 0
  end
end
