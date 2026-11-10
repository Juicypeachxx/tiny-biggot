# Tiny Biggot - weapons and gear in the run: drops, door rewards, shops, swapping, boss loot, room hooks.

class CCGame
  attr_accessor :swings

  def drop_item(item, x, y)
    @room[:objects] << { kind: :item, item: item, x: clampf(x.to_f, 3 * TS, 25 * TS), y: clampf(y.to_f, 4 * TS, 15 * TS), t: 0.0 }
  end

  def drop_gear_at(x, y)
    drop_item(random_gear(roll_item_rarity(@floor_index, :elite)), x, y)
  end

  def item_price(item)
    base = { common: 26, rare: 44, epic: 68, legend: 96 }[item[:rarity]]
    price(base + @floor_index * 8)
  end

  alias give_reward_base give_reward
  def give_reward(kind)
    cx = 14.0 * TS; cy = 9.5 * TS
    case kind
    when :weapon then drop_item(random_weapon(roll_item_rarity(@floor_index), @player[:weapon]), cx, cy)
    when :gear then drop_item(random_gear(roll_item_rarity(@floor_index)), cx, cy)
    else give_reward_base(kind)
    end
  end

  alias setup_objects_base setup_objects
  def setup_objects(room)
    setup_objects_base(room)
    cx = 14.0 * TS; cy = 9.5 * TS
    case room[:type]
    when "shop"
      w = random_weapon(roll_item_rarity(@floor_index), @player[:weapon])
      g = random_gear(roll_item_rarity(@floor_index))
      room[:objects] << { kind: :shop, item: :weapon, thing: w, x: cx - 40, y: cy + 34, price: item_price(w) }
      room[:objects] << { kind: :shop, item: :gear, thing: g, x: cx + 40, y: cy + 34, price: item_price(g) }
    when "treasure"
      if rnd < 0.35
        it = rnd < 0.5 ? random_weapon(roll_item_rarity(@floor_index, :elite), @player[:weapon]) : random_gear(roll_item_rarity(@floor_index, :elite))
        room[:objects] << { kind: :item, item: it, x: cx, y: cy + 36, t: 0.0 }
      end
    end
  end

  def swap_item(o, it)
    p = @player
    old = it[:item] == :weapon ? equip_weapon(p, it) : equip_gear(p, it)
    Snd.play("relic")
    show_banner(it[:name], it[:item] == :weapon ? ARCH[it[:kind]][:name] + " - " + it[:desc] : SLOT_NAME[it[:slot]] + " - " + it[:desc])
    burst(o[:x], o[:y], [RARITY_HEX[it[:rarity]], "#ffffff"], 14, 60)
    old
  end

  alias interact_base interact
  def interact(o)
    p = @player
    if o[:kind] == :item
      old = swap_item(o, o[:item])
      if old then o[:item] = old; o[:t] = 0.0 else o[:gone] = true end
      return
    end
    if o[:kind] == :shop && (o[:item] == :weapon || o[:item] == :gear)
      return deny(o, "NEED #{o[:price]} GOLD") if p[:gold] < o[:price]
      p[:gold] -= o[:price]
      o[:gone] = true
      Snd.play("coin")
      old = swap_item(o, o[:thing])
      drop_item(old, o[:x], o[:y] - 22) if old
      return
    end
    interact_base(o)
  end

  alias on_boss_dead_base on_boss_dead
  def on_boss_dead(boss)
    on_boss_dead_base(boss)
    drop_item(random_weapon(roll_item_rarity(@floor_index, :boss), @player[:weapon]), boss[:x] - 20, boss[:y] + 20)
    drop_item(random_gear(roll_item_rarity(@floor_index, :boss)), boss[:x] + 20, boss[:y] + 20) if rnd < 0.5
  end

  alias room_cleared_base room_cleared
  def room_cleared
    p = @player
    room_cleared_base
    if gf(p, :room_armor) > 0 then p[:armor] += gf(p, :room_armor).to_i end
    if gf(p, :room_gold) > 0 then g = gf(p, :room_gold).to_i; p[:gold] += g; float_text(p[:x], p[:y] - 22, "+#{g} GOLD", "gold") end
  end

  alias start_floor_base start_floor
  def start_floor
    @player[:floor_kills] = 0 if @player
    start_floor_base
  end

  alias enter_room_base enter_room
  def enter_room(room)
    @swings = []
    enter_room_base(room)
  end
end
