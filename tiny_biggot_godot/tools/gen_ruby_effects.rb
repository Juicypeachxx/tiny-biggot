# Runs the ORIGINAL Ruby item code (reference/ruby) headless and records what
# every relic, trait, family bonus, skill node, weapon and gear piece does to a
# fresh player of each hero. tests/effects_test.gd replays the same items in
# Godot and compares every field. Usage: ruby tools/gen_ruby_effects.rb > tests/ruby_effects.json
require "json"
R = File.expand_path("../reference/ruby/", __dir__) + "/"
Snd = Module.new { def self.play(*); end; def self.music(*); end }
$G = nil
%w(000_Core 001_Data 002_01b_traits 003_01c_items 005_Entities 006_Combat 007_04b_items).each do |f|
  src = File.read(R + f + ".rb")
  src = src.sub(/^module Snd.*?^end\n/m, "") if f == "000_Core"
  eval(src, TOPLEVEL_BINDING, f)
end
$meta[:found_w] = {}; $meta[:found_g] = {}

def snap(p)
  out = {}
  p.each do |k, v|
    case v
    when Integer, Float, TrueClass, FalseClass then out[k] = v
    when NilClass then out[k] = nil if k == :spread
    end
  end
  out[:gf] = p[:gf].select { |k, v| v != 0 }.map { |k, v| [k.to_s, v] }.to_h
  out
end
def fresh(h); Marshal.load(Marshal.dump(create_player(h))); end
# Only fields that differ from the hero's fresh player (gf compared whole).
def diff(base, s)
  out = {}
  s.each { |k, v| out[k] = v if k != :gf && base[k] != v }
  out[:gf] = s[:gf] if s[:gf] != base[:gf]
  out
end

res = {}
HEROES.each do |h|
  r = { "base" => snap(fresh(h)), "relics" => {}, "traits" => {}, "bonus" => {}, "nodes" => {}, "gear" => {}, "weapons" => {} }
  RELICS.each { |x| p = fresh(h); add_relic(p, x); r["relics"][x[:id]] = snap(p) }
  TRAITS.each { |t| p = fresh(h); t[:max].times { t[:fx].call(p) }; r["traits"][t[:id]] = snap(p) }
  FAMILY_BONUS.each { |f, list| list.each_with_index { |b, i| p = fresh(h); b[1].call(p); r["bonus"]["#{f}#{i}"] = snap(p) } }
  tree_for(h[:id]).each { |br| br[:nodes].each { |n| p = fresh(h); n[2].call(p); r["nodes"][n[0]] = snap(p) } }
  GEAR.each { |g| p = fresh(h); equip_gear(p, g); r["gear"][g[:id]] = snap(p) }
  # full sets: equip all four pieces of each set
  SETS.each_key { |s| p = fresh(h); GEAR.select { |g| g[:set] == s }.each { |g| equip_gear(p, g) }; r["gear"]["set:" + s] = snap(p) }
  WEAPONS.each { |w| p = fresh(h); equip_weapon(p, w); q = snap(p); q[:wdmg] = wdmg(p); q[:wrate] = wrate(p); q[:wrange] = wrange(p); r["weapons"][w[:id]] = q }
  b = r["base"]
  %w(relics traits bonus nodes gear weapons).each { |k| r[k].each_key { |id| r[k][id] = diff(b, r[k][id]).merge(r[k][id].select { |f, _| [:wdmg, :wrate, :wrange].include?(f) }) } }
  res[h[:id]] = r
end
puts JSON.generate(res)
