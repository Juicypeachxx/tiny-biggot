"""14.1: icons for the new set pieces, recoloured from existing gear icons (hue turned, one colour
family per set). Writes tools/art/src/icons/g_<piece>.png; sheet.py then remasters them like every
other gear icon. Run once after adding a piece: python3 tools/art/set_icons.py"""
import colorsys, os
from PIL import Image

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "src", "icons")
# piece id -> (base icon, the set's hue in degrees, saturation x, value x): every coloured pixel
# takes the set's hue, so a set's pieces match; greys and whites stay.
PIECES = {
    "storm_hood": ("thunder_helm", 270, 1.0, 1.0), "storm_robe": ("thunder_mail", 270, 1.0, 1.0),
    "storm_boots": ("thunder_boots", 270, 1.0, 1.0), "storm_ring": ("thunder_ring", 270, 1.0, 1.0),
    "blood_cap": ("butcher_cap", 355, 1.2, 0.8), "blood_coat": ("bloodplate", 355, 1.2, 0.8),
    "blood_gloves": ("leechgloves", 355, 1.2, 0.85), "blood_fang": ("vampirefang", 355, 1.2, 0.9),
    "hex_veil": ("seerveil", 290, 1.0, 0.9), "hex_shroud": ("ghostsheet", 290, 0.8, 0.8),
    "hex_gloves": ("shadowglove", 290, 1.0, 0.9), "hex_ring": ("toadring", 290, 1.0, 1.0),
    "viper_hood": ("huntershood", 100, 1.2, 1.0), "viper_coat": ("hunterscoat", 100, 1.2, 1.0),
    "viper_tabi": ("ninjatabi", 100, 1.1, 1.0), "viper_fang": ("toothnecklace", 100, 1.2, 1.0),
    "war_helm": ("hornedhelm", 15, 1.2, 1.0), "war_hide": ("berserkerhide", 15, 1.2, 1.0),
    "war_fists": ("boxinggloves", 15, 1.1, 0.9), "war_ring": ("bigring", 15, 1.2, 1.0),
    "beast_helm": ("owlhelm", 32, 1.1, 1.0), "beast_cloak": ("travelcloak", 32, 1.1, 1.0),
    "beast_glove": ("leatherglove", 32, 1.1, 1.0), "beast_collar": ("houndcollar", 32, 1.1, 1.0),
    "drift_hood": ("night_hood", 175, 1.0, 1.0), "drift_cloak": ("night_cloak", 175, 1.0, 1.0),
    "drift_steps": ("ghoststeps", 175, 1.0, 1.0), "drift_ring": ("quickring", 175, 1.0, 1.0),
    "sun_crown": ("kingscrown", 48, 1.3, 1.15), "sun_cuirass": ("polishedcuirass", 48, 1.4, 1.1),
    "sun_boots": ("rocketboots", 48, 1.3, 1.1), "sun_gauntlet": ("emberglove", 48, 1.3, 1.15),
    "sun_heart": ("pocketsun", 48, 1.3, 1.15), "sun_band": ("ember_ring", 48, 1.3, 1.15),
    # 20.3 Chapter IV: BOOKWORM and THE CRITIC'S REGALIA.
    "worm_specs": ("scholarcap", 120, 1.0, 0.9), "worm_cardigan": ("paddedjack", 120, 1.0, 0.9),
    "worm_slippers": ("sandals", 120, 1.0, 0.9), "worm_mitts": ("clothglove", 120, 1.0, 0.9),
    "critic_hat": ("hagglerhat", 352, 1.3, 0.8), "critic_coat": ("smugglercoat", 352, 1.3, 0.8),
    "critic_shoes": ("worntboots", 352, 1.3, 0.8), "critic_gloves": ("goldglove", 352, 1.3, 0.85),
    "critic_monocle": ("clock_monocle", 352, 1.3, 0.9), "critic_signet": ("bigring", 352, 1.3, 0.9),
    "void_crown": ("crownofthorns", 255, 1.2, 0.9), "void_mantle": ("phoenixmantle", 255, 1.2, 0.85),
    "void_steps": ("springheels", 255, 1.2, 0.9), "void_grip": ("shadowglove", 255, 1.3, 0.9),
    "void_star": ("collapsedstar", 255, 1.2, 1.0), "void_band": ("twinring", 255, 1.2, 0.9),
}

def turn(im, deg, sm, vm):
    out = im.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s > 0.15:
                h = deg / 360.0
            s = min(1.0, s * sm)
            v = min(1.0, v * vm)
            r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    return out

if __name__ == "__main__":
    for pid, (base, deg, sm, vm) in PIECES.items():
        turn(Image.open(os.path.join(SRC, "g_" + base + ".png")).convert("RGBA"), deg, sm, vm).save(os.path.join(SRC, "g_" + pid + ".png"))
    print(len(PIECES), "icons")
