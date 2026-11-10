# Tiny Biggot (RPG Maker VX Ace / RGSS3) - core helpers.
# Written for Ruby 1.9: no keyword arguments, no safe navigation, no Array#sum.

SW = 448
SH = 288
TS = 16
COLS = 28
ROWS = 18
IX0 = 1
IY0 = 2
IW = 26
IH = 15
TAU = Math::PI * 2
DT = 1.0 / 60
GFX = "Graphics/CC/"

def clampf(v, a, b); v < a ? a : (v > b ? b : v); end
def rnd; rand; end
def rint(a, b); a + rand(b - a + 1); end
def pick(arr); arr[rand(arr.size)]; end
def dist(a, b); Math.hypot(a[:x] - b[:x], a[:y] - b[:y]); end
def ang_to(a, b); Math.atan2(b[:y] - a[:y], b[:x] - a[:x]); end
def sgn(v); v > 0 ? 1 : (v < 0 ? -1 : 0); end

# Seeded xorshift RNG so a floor's layout stays the same while you walk around it.
class SeedRng
  def initialize(seed); @s = (seed & 0xffffffff); @s = 1 if @s == 0; end
  def next_f
    @s ^= (@s << 13) & 0xffffffff
    @s ^= @s >> 17
    @s ^= (@s << 5) & 0xffffffff
    @s &= 0xffffffff
    @s / 4294967296.0
  end
  def int(a, b); a + (next_f * (b - a + 1)).floor; end
  def pick(arr); arr[(next_f * arr.size).floor]; end
end

# ---------- Bitmap cache ----------
module Img
  @cache = {}
  def self.[](name)
    b = @cache[name]
    return b if b && !b.disposed?
    @cache[name] = Bitmap.new(GFX + name)
  end
  def self.px(hex, size)
    key = "px_" + hex.sub("#", "") + "_" + size.to_s
    @pxok ||= {}
    if @pxok[key].nil?
      @pxok[key] = (begin; self[key]; true; rescue; false; end)
    end
    @pxok[key] ? self[key] : self["px_ffffff_" + size.to_s]
  end
end

# ---------- Sound ----------
module Snd
  @last = {}
  @gap = { "shoot" => 3, "hit" => 3, "ebullet" => 5, "coin" => 2, "bolt" => 3, "hatchet" => 3 }
  @track = nil
  def self.play(name)
    return unless $opts[:sfx]
    f = Graphics.frame_count
    g = @gap[name] || 0
    return if g > 0 && @last[name] && f - @last[name] < g
    @last[name] = f
    pitch = 100
    pitch = 94 + rand(13) if ["shoot", "hit", "kill", "bolt", "hatchet", "ebullet", "spawn"].include?(name)
    vol = name == "ebullet" ? 55 : 85
    begin
      Audio.se_play("Audio/SE/cc_" + name, vol, pitch)
    rescue
    end
  end
  def self.music(n)
    return if @track == n && $opts[:music]
    @track = n
    begin
      if $opts[:music] then Audio.bgm_play("Audio/BGM/cc_track" + n.to_s, 70, 100)
      else Audio.bgm_stop
      end
    rescue
    end
  end
  def self.refresh
    t = @track || 0
    @track = nil
    music(t)
  end
end

# ---------- Input ----------
# Empo's touch buttons and controller press real keys. Default VX Ace bindings:
# arrows = move, W/A/S/D = R/X/Y/Z = aim, Shift = A = roll, Enter/Space/Z = C = use/confirm,
# Q = L = heal, Esc/X = B = pause/back.
module Keys
  def self.move
    x = 0; y = 0
    x -= 1 if Input.press?(:LEFT)
    x += 1 if Input.press?(:RIGHT)
    y -= 1 if Input.press?(:UP)
    y += 1 if Input.press?(:DOWN)
    if x != 0 && y != 0 then x *= 0.7071; y *= 0.7071 end
    [x, y]
  end
  def self.aim
    x = 0; y = 0
    x -= 1 if Input.press?(:X)
    x += 1 if Input.press?(:Z)
    y -= 1 if Input.press?(:R)
    y += 1 if Input.press?(:Y)
    return nil if x == 0 && y == 0
    Math.atan2(y, x)
  end
  def self.roll; Input.trigger?(:A); end
  def self.use; Input.trigger?(:C); end
  def self.heal; Input.trigger?(:L); end
  def self.pause; Input.trigger?(:B); end
  # Bomb: Ctrl key (Empo's BOMB button). F5 as a fallback on keyboards.
  def self.bomb
    (Input.trigger?(:CTRL) rescue false) || (Input.trigger?(:F5) rescue false)
  end
  def self.fire_held; false; end
  def self.up; Input.repeat?(:UP); end
  def self.down; Input.repeat?(:DOWN); end
  def self.left; Input.repeat?(:LEFT); end
  def self.right; Input.repeat?(:RIGHT); end
  def self.confirm; Input.trigger?(:C); end
  def self.back; Input.trigger?(:B); end
  def self.any; Input.trigger?(:C) || Input.trigger?(:B) || Input.trigger?(:A); end
end

# ---------- Pixel font ----------
FONT_CHARS = " !$%'()*+,-./0123456789:<=>?ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_~"
FONT_INDEX = {}
FONT_CHARS.each_char.with_index { |c, i| FONT_INDEX[c] = i }
COL = {
  white: "white", gold: "gold", orange: "orange", red: "red", grey: "grey", dim: "dim", tan: "tan",
  cyan: "cyan", green: "green", lime: "lime", purple: "purple", pink: "pink", bone: "bone"
}

def text_w(str, scale = 1)
  n = str.to_s.size
  n > 0 ? (n * 4 - 1) * scale : 0
end

# Draws pixel text into a bitmap. color is a font colour name ("white", "gold", ...).
def ptext(bmp, str, x, y, color = "white", scale = 1, align = 0, shadow = true)
  s = str.to_s.upcase
  w = text_w(s, scale)
  cx = (x - w * align).round
  y = y.round
  sheet = Img["font#{scale}_#{color}"]
  sh = shadow ? Img["font#{scale}_shadow"] : nil
  rect = Rect.new(0, 0, 3 * scale, 5 * scale)
  px = cx
  s.each_char do |ch|
    i = FONT_INDEX[ch] || FONT_INDEX["?"]
    if i > 0
      rect.x = i * 4 * scale
      bmp.blt(px, y + scale, sh, rect) if sh
      bmp.blt(px, y, sheet, rect)
    end
    px += 4 * scale
  end
  w
end

def wrap_text(str, max_w)
  lines = []
  cur = ""
  str.split(" ").each do |w|
    test = cur.empty? ? w : cur + " " + w
    if text_w(test) > max_w && !cur.empty?
      lines << cur
      cur = w
    else
      cur = test
    end
  end
  lines << cur unless cur.empty?
  lines
end

def hex_color(h, a = 255)
  h = h.sub("#", "")
  Color.new(h[0, 2].to_i(16), h[2, 2].to_i(16), h[4, 2].to_i(16), a)
end

def panel(bmp, x, y, w, h, border = "#5c5a78", fill = "#1a1423")
  bmp.fill_rect(x - 1, y - 1, w + 2, h + 2, hex_color("#140f1c"))
  bmp.fill_rect(x, y, w, h, hex_color(border))
  bmp.fill_rect(x + 1, y + 1, w - 2, h - 2, hex_color(fill))
end

# Cached text bitmaps for floating numbers.
module TextCache
  @c = {}
  def self.get(str, color)
    key = str + "|" + color
    b = @c[key]
    return b if b
    b = Bitmap.new(text_w(str) + 1, 7)
    ptext(b, str, 0, 0, color)
    @c[key] = b
  end
end

# ---------- Save data ----------
SAVE_FILE = "TinyBiggot.rvdata2"
$opts = { autofire: true, music: true, sfx: true, shake: true }
$meta = { runs: 0, wins: 0, best: 0, embers: 0, unlocked: {}, found: {}, secrets: 0, bosses: 0, kills: 0, dread_max: 0, dread: 0, tree: {} }
def unlocked?(id); $meta[:unlocked][id] ? true : false; end
def load_save
  return unless File.exist?(SAVE_FILE)
  data = File.open(SAVE_FILE, "rb") { |f| Marshal.load(f) }
  $opts.merge!(data[:opts]) if data[:opts]
  $meta.merge!(data[:meta]) if data[:meta]
  $meta[:unlocked] ||= {}; $meta[:found] ||= {}
rescue
end
def write_save
  File.open(SAVE_FILE, "wb") { |f| Marshal.dump({ opts: $opts, meta: $meta }, f) }
rescue
end
