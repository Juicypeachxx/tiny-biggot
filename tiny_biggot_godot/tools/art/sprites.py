# Sample sprites for ROADMAP 5.1. Legend:
# . clear  o outline  0 deep shadow
# 1 2 3  main material dark/mid/light (per sprite hue)
# j k l  bone   4 5 6 skin   7 8 9 metal   p q r gold   u v w wood   a b c second hue
# x emissive core  y emissive soft
S = {}
S["hexer"] = ("halo:1 main:#7b4bb0 second:#3f7fbf glow:#7ff0ff", [
"....oooo....",
"...o3332o...",
"..o333222o..",
"..o3ooooo2o.",
".o3o0x0x0o1o",
".o32o000o21o",
".o322oooo21o",
"..o3qqqq21o.",
".o332qx2221o",
"o5333222215o",
".o33322221o.",
".o33222211o.",
"o3322222111o",
".oooo..oooo.",
])
S["bat"] = ("main:#5d3f86 glow:#ff4a4a", [
"o...o..o...o",
"o3o.o33o.o3o",
"o32oy33yo23o",
"o322o22o223o",
".o221oo122o.",
".o2o1oo1o2o.",
"..o.o..o.o..",
"............",
])
S["skeleton"] = ("glow:#ff5a3a", [
"...oooooo...",
"..olllllko..",
"..ol0yl0yo..",
"..olllklko..",
"...oljkjo...",
"..ooolkooo..",
".olkolkolko.",
".oj..olko.jo",
"....oljko...",
"...ollokko..",
"...ojo.ojo..",
"..ooo..ooo..",
])
S["slime"] = ("main:#4fae46 glow:#eaffb0", [
"....oooo....",
"...o3332o...",
"..o3y33322o.",
".o33333222o.",
".o30x330x21o",
"o3222332221o",
"o3222222221o",
"o1122222111o",
".oooooooooo.",
])
S["colossus"] = ("main:#7a2a2a glow:#ff3b30", [
"....oooooooo....",
"..oollllllllkoo.",
".ollllllllllkkko",
"olllllllllkkkkko",
"ollllll0lkkkkkko",
"oll000llkk000kko",
"oll0y0llkk0y0kko",
"olk000lllk000kjo",
"ollkkkllllkkkkjo",
".olkkkl00lkkkjo.",
".oolkkk00kkkjoo.",
"..ojlkkkkkkjjo..",
"..ojololololjo..",
"..oj0o0o0o0ojo..",
"...ojjjjjjjjo...",
"....oooooooo....",
])
S["heart_full"] = ("main:#d8443c", [
".oo...oo.",
"o33o.o32o",
"o3322221o",
"o3222221o",
".o22221o.",
"..o221o..",
"...o1o...",
"....o....",
])
S["heart_half"] = ("main:#d8443c second:#5a4a6a", [
".oo...oo.",
"o33o.obbo",
"o3322bbao",
"o3222bbao",
".o222bao.",
"..o22ao..",
"...o2o...",
"....o....",
])
S["heart_empty"] = ("main:#5a4a6a", [
".oo...oo.",
"o22o.o21o",
"o2111111o",
"o2111111o",
".o11111o.",
"..o111o..",
"...o1o...",
"....o....",
])
S["w_hexwand"] = ("halo:1 main:#7b4bb0 glow:#7ff0ff", [
"........oyo.",
".......oyxyo",
"......oqoyo.",
".....owqo...",
"....owvo....",
"...owvo.....",
"..owvo......",
".owvo.......",
"ovuo........",
"ouo.........",
".o..........",
"............",
])
S["w_repeater"] = ("main:#6b4a2a", [
"............",
"..o.........",
".o9o......o.",
"o989ooooo797",
"o87vwwwwvvvo",
".o7ouuuvvoo.",
"..oo.o8o.o..",
".....ouo....",
"....ovuo....",
"....ouuo....",
".....oo.....",
"............",
])
S["w_pithatchet"] = ("main:#6b4a2a", [
".....ooo....",
"....o999o...",
"...o98877o..",
"...o877wo...",
"...o77owo...",
"....oo.ovo..",
".......ovo..",
"........ovo.",
"........ovo.",
".........ouo",
".........ouo",
"..........o.",
])
S["w_graveshovel"] = ("main:#6b4a2a", [
"..oo........",
".owvo.......",
".ovuo.......",
"..ovo.......",
"...ovo......",
"....ovo.....",
".....ovo....",
"......o8o...",
".....o9887o.",
"......o877o.",
".......o77o.",
"........oo..",
])
S["w_flasksling"] = ("halo:1 main:#5fbf4a glow:#eaffb0", [
"............",
".....ooo....",
".....o9o....",
"....o989o...",
"...oo9o9oo..",
"..o3y33322o.",
"..o3y33322o.",
"..o3333222o.",
"..o3322221o.",
"...o22211o..",
"....oooo....",
"............",
])

# ---- 5.2: the heroes (12x14). Rows 0-6 head, 7-10 body (hands at row 9, cols 1 and 10),
# 11 legs, 12 feet, 13 the ground outline: the gear overlay (hero_gear.gd) uses the same rows.
S["poacher"] = ("main:#4a7a3e second:#b8403a skin:#e0a47a", [
"...oooooo...", "..ouwwwvuo..", "oouuuuuuuuoo", "..o444444o..", "..o505505o..", "..ocbbbbao..", ".o3cbbbba1o.",
"o3o322221o1o", "o3ouuquuuo1o", "o5o322221o5o", ".oo322221oo.", "..o22oo21o..", "..ouuoouuo..", "..ooo..ooo.."])
S["brute"] = ("main:#8a5a3a second:#d07a2a skin:#c88a5a", [
".l..oooo..l.", ".loo9888ool.", ".ol978887lo.", "..o777777o..", "..o505505o..", "..o5bbbb5o..", "..ocbbbbao..",
"o5o6555q4o5o", "o5o655u54o5o", "o6ou55554o6o", ".oo3q2222oo.", "..o32oo21o..", "..ouuoouuo..", "..ooo..ooo.."])
S["gravedigger"] = ("main:#6a4a32 second:#5a5a66 skin:#d89a70", [
"...oooooo...", "..ocbbbbbo..", ".ocbbbbbbbao", "..o466664o..", "..o505505o..", "..ouvvvvuo..", "..o3uvvu1o..",
"o3o323321o1o", "o3o322221o1o", "o5o3q2221o5o", ".oo322221oo.", "..o88oo88o..", "..ouuoouuo..", "..ooo..ooo.."])
S["alchemist"] = ("main:#3a78c0 second:#5fbf4a glow:#b8ff7a skin:#f0c8a0 halo:1", [
"....oooo....", "...o3332o...", "..o3qrrq2o..", "..o344441o..", "..o305501o..", "..o355551o..", ".o33o55o11o.",
"o3o322221o1o", "o3ouuquuuo1o", "o5o3cy221o5o", ".oo322221oo.", "..o32oo21o..", "..ouuoouuo..", "..ooo..ooo.."])
S["warden"] = ("main:#2e4a8a glow:#ffb040 halo:1", [
"....oooo....", "...o3322o...", "..o333221o..", "..o987789o..", "..o7x77x7o..", "..o878878o..", ".o33o77o11o.",
"o3o322221o1o", "o3o3qqqq1o1o", "o8o322221oyo", ".oo322221oxo", "..o32oo21o..", "..o88oo88o..", "..ooo..ooo.."])
S["gaolbird"] = ("main:#2a2a3a second:#2e3450 skin:#e8b890 glow:#fff4d0", [
"....oooo....", "...obbbbo...", "..obbbbbbo..", "..obxbbxbo..", "..obbbbbqro.", "..o5aaaaqo..", "...o5445o...", "o5ollllllo5o", "o5o222222o5o", "o5ollllllo5o", ".oo222222oo.", "..olkoolko..", "..o28oo82o..", "..ooo..ooo..", ])
S["banehunter"] = ("main:#5a3c28 second:#d8443c skin:#e3b08a", [  # his pick (6 Oct): the old design, remastered
"..9.oooo.9..", "..8olllko8..", "..olllllko..", ".ollllllkko.", "..ol5555jo..", "..o505504o..", "..o5555a5o..", ".o93222218o.", ".o32w22w21o.", "o532288215o.", ".oo322221oo.", "..o98oo87o..", "..ouuoouuo..", "...oo..oo...", ])
S["oathbreaker"] = ("main:#8a2a3a glow:#ff4a3a", [
"....oooo....", "...o9887o...", "..o988887o..", "..o877778o..", "..o7xyyx7o..", "..o877778o..", "..o787787o..",
"o9o832218o7o", "o8o322221o7o", "o8o32qq21o8o", ".oo322221oo.", "..o87oo87o..", "..o98oo98o..", "..ooo..ooo.."])
S["wayfarer"] = ("main:#c98a3a second:#d8443c skin:#e3b08a", [  # his pick (6 Oct): the old design, remastered
"............", "....oooo....", "...oqrrqo...", "oooqqpqqqooo", "orqqqqqqqqpo", ".ooo555oooo.", "..o505504o..", ".oll5555kko.", ".oljlllljko.", "o5cbbbbbba5o", ".oolllllk8o.", "..ojjoojjo8.", "..ouuoouuo..", "...oo..oo...", ])
S["racketeer"] = ("main:#5a3a8a second:#2a2433 skin:#e0b090", [
"...oooooo...", "...obbbbo...", "...oqqqqo...", ".oabbbbbbao.", "..o505505o..", "..o45r554o..", "...o5445o...",
"o3o3l22l1o1o", "o3o32a221o1o", "o5o32a221o5o", ".oo322221oo.", "..o32oo21o..", "..oaaooaao..", "..ooo..ooo.."])
S["condemned"] = ("main:#2a2838 skin:#e3b08a", [  # his pick (6 Oct): the old design, remastered
"............", "....oooo....", "...o5665o...", "..o566654o..", "..o555554o..", "..o505504o..", "..o555554o..", ".olllllllko.", ".o32222221o.", "85lllllllk58", ".o32222221o.", "..olkoolko..", "..ouuoouuo..", "...oo..oo...", ])
S["cartomancer"] = ("main:#c0403a second:#2a2433 skin:#e3b08a", [  # his pick (6 Oct): the old design, remastered
"...oooooo...", "...ocbblo...", "...ocbbl3o..", "...ocbbao...", ".ocbbbbbbao.", "..o555554o..", "..o505504o..", ".o33rqqp21o.", ".o31222211o.", "o5322112215l", ".oo322221ool", "..o11oo11o..", "..oaaooaao..", "...oo..oo...", ])
S["sellsword"] = ("main:#3f7a5a second:#d8443c skin:#e3b08a", [  # his pick (6 Oct): the old design, remastered
"....ocbo....", "....ocbbo...", "...o9998ao..", "..o998887o..", "..o777777o..", "..o555554o..", "..o505504o..", ".o98322187o.", ".o82322317o.", "o5832222175o", ".oo322221oo.", "..o87oo87o..", "..ouuoouuo..", "...oo..oo...", ])
S["beekeeper"] = ("main:#e8dfc0", [
"...oooooo...", "...olllllo..", "olllllllllko", "..o070070o..", "..o707707o..", "..o070070o..", "..olllllko..",
"o3o322221o1o", "o3o3pqp21o1o", "olo322221olo", ".oo322221oo.", "..o32oo21o..", "..ouuoouuo..", "..ooo..ooo.."])
S["tinkerer"] = ("main:#c9a35a glow:#6fd3e0 skin:#e3b08a", [  # his pick (6 Oct): the old design, remastered
"....oooo....", "...owvvuo...", "..orqvvqpo..", "..oqyvvyqo..", "..ovvvvvuo..", "..o555554o..", "..o505504o..", ".owv3221vuo.", ".ov382281uo.", "o5v322221u5o", ".oo322221oo.", "..o87oo87o..", "..o00oo00o..", "...oo..oo...", ])
S["boneweaver"] = ("main:#4a2a6a glow:#c08aff", [
"....oooo....", "...o3322o...", "..o3llll1o..", "..o3yllyo1o.", "..o3ljjl1o..", "..o3lkkl1o..", ".o33o00o11o.",
"o3o3l2l21o1o", "o3o32l2l1o1o", "olo322221olo", ".oo322221oo.", ".o32222221o.", ".o32222221o.", ".oooooooooo."])
S["mirrorknight"] = ("main:#a0b8d8 glow:#6fd3e0 skin:#e3b08a", [  # his pick (6 Oct): the old design, remastered
"....oyo.....", "...o998o....", "..o9x98x8o..", "..o998887o..", "..o9oooo7o..", "..o555554o..", "..o505504o..", ".o88998877o.", ".o89y88y87o.", "o5899988875o", ".oo998887oo.", "..o88oo87o..", "..o77oo77o..", "...oo..oo...", ])
S["plaguesaint"] = ("main:#4a7a4a", [
"...oooooo...", "..oqqqqqqo..", "..olllllko..", "..ol0ll0ko..", "..olllllllo.", "..ojllllllko", ".o33ojjo11o.",
"o3o3l22l1o1o", "o3o32q221o1o", "o5o3qqq21o5o", ".oo32q221oo.", ".o32222221o.", ".o32222221o.", ".oooooooooo."])
S["frostwitch"] = ("main:#4a88d0 glow:#bff4ff skin:#f0dce8 halo:1", [
".....oyo....", "....o32o....", "...o3322o...", "o3332222211o", "..o505505o..", "..o455554o..", "..ollllllo..",
"o3o322221o1o", "o3o32y221o1o", "o5o322221o5o", ".o32222221o.", ".o32222221o.", ".o33222211o.", ".oooooooooo."])
S["demolitionist"] = ("main:#6a5a32 second:#d8443c glow:#ffa040 skin:#e3b08a", [  # his pick (6 Oct): the old design, remastered
"...oooooo...", "..o332221o..", "..o988887o..", "..o8yooy7o..", "..o322221o..", "..o555554o..", "..o505504o..", ".owv3221vuo.", ".ov3b22b1uo.", "o5v322221u5o", ".oo322221oo.", "..o87oo87o..", "..o00oo00o..", "...oo..oo...", ])
S["executioner"] = ("main:#2a2030 second:#9a2a2a glow:#ff4a3a skin:#c08060", [
"....oooo....", "...o3332o...", "..o333322o..", "..o3y22y1o..", "..o322221o..", "..o322221o..", ".o33o22o11o.",
"o5o655554o5o", "o5o6b5554o5o", "o5o65b554o5o", ".oo2222b1oo.", "..o32oo21o..", "..ouuoouuo..", "..ooo..ooo.."])
S["pilgrim"] = ("main:#c9a35a skin:#e3b08a", [  # his pick (6 Oct): the old design, remastered
"..oooooooo..", ".o33322221o.", "..orqqqqpo..", "..oqqqqqpo..", "..oooooooo..", "..o555554o..", "..o505504o..", ".ollkkkkkjo.", ".olkqkkqkjo.", "o5lkkkkkkj5o", ".ookkkkkjoo.", "..ovvoovvo..", "..ouuoouuo..", "...oo..oo...", ])
S["beastmaster"] = ("main:#4a7a3a skin:#a8704a", [
"u..u....u..u", ".uu.oooo.uu.", "...ovwwvo...", "..ovvvvvvuo.", "..o505505o..", "..o455554o..", ".ouo5445ouo.",
"o3ou2222uo1o", "o3o322221o1o", "o5o3uqu21o5o", ".oo322221oo.", "..ouvoovuo..", "..ouuoouuo..", "..ooo..ooo.."])
HEROES = ["hexer", "poacher", "brute", "gravedigger", "alchemist", "warden", "gaolbird", "banehunter", "oathbreaker",
	"wayfarer", "racketeer", "condemned", "cartomancer", "sellsword", "beekeeper", "tinkerer", "boneweaver",
	"mirrorknight", "plaguesaint", "frostwitch", "demolitionist", "executioner", "pilgrim", "beastmaster"]

# ---- 5.3a: the first three floors' foes and guardians.
S["mushroom"] = ("main:#d8443c", [
"...oooooo...", "..o33l3221o.", ".o3l3322l21o", "o33322222l1o", "o3222l22221o", "oo11111111oo",
"..olyllyko..", "..oll00lko..", "..ollllkko..", ".ojlllkkkjo.", "..oooooooo.."])
S["imp"] = ("main:#d8443c second:#e8873a glow:#ffe060", [
".c........c.", ".bo.oooo.ob.", "..ob3332bo..", "o.o3y33y2o.o", "oao3l2l21oao", "oaao3221oaao",
".oo332221oo.", "...o3221o...", "..o21oo12o..", "..ooo..ooo.."])
S["ghost"] = ("main:#a0b0d0 bone:#e8eef8 glow:#7ff0ff", [
"...oooooo...", "..olllllko..", ".ollllllkko.", ".ol00ll00ko.", ".ollllllkko.", ".olll00lkko.",
"olllllllkkko", "olkkolkkolko", ".o..o..o..o."])
S["bookwyrm"] = ("main:#7a5236 second:#d8443c glow:#ffe060", [
".oooooooooo.", "o3322222221o", "o32y2222y21o", "o3222qq2221o", "olklklklklko", "o000bbbb000o",
"olklklklklko", "o2111111111o", ".oooooooooo."])
S["drowned"] = ("main:#5a9a5a second:#3a6aa0 glow:#e0ffd0", [
"...oooooo...", "..ouvvvuuo..", "..o33322uo..", "..o3y22y1o..", "..o322221o..", "..o3o00o1o..",
".obo3221obo.", "o3ocbbbbao1o", "o3ocbbbbao1o", "o2obabbbao2o", "..oa3oo3ao..", "..ooo..ooo.."])
S["bat2"] = ("main:#8a3a3a glow:#ffb040", [
"o...o..o...o", "oo.o3oo3o.oo", "o3oo3333oo3o", "o32oy33yo23o", "o3222ll2223o", "o21o2222o12o",
".oo.o22o.oo.", ".....oo....."])
S["sporemother"] = ("main:#8a4ab0 second:#5a9a3a glow:#e8ff8a", [
"....oooooooo....", "..oo33y33322oo..", ".o333332y22221o.", "o33y33322222y21o", "o33332222222221o",
"o22222222222111o", ".oo1111111111oo.", "...ollllllllo...", "...olyllllyko...", "...ollllllkko...",
"...oll0000lko...", "...olllllkkko...", "..ojllllllkkjo..", ".ocjllllllkkjco.", "occbbcbbcbbcbbco",
".oooooooooooooo."])
S["librarian"] = ("main:#3a6ab0 second:#6fd3e0 glow:#bff4ff", [
".....oooooo.....", "....o333322o....", "...o33333222o...", "..o3330000221o..", "..o33xx00xx21o..",
"..o3300000021o..", "..o3300ll0021o..", ".o333o0ll0o221o.", "o33332222222221o", "o3qlllllkllllq1o",
"o5qljjlkljjlq51o", "o33qqqqqqqqq221o", "o33222222222221o", "o3222b222222b21o", "occbbccbbccbbcco",
".oooooooooooooo."])

# Elites (his ask, 6 Oct): a little different from the normal foe, not only gold-edged. Each gets a
# richer, darker body, hot gold eyes, an extra mark drawn over it (row -> overlay, '.' keeps the
# pixel), and the gold outline.
ELITE = {
	"bat": {0: "...q....q..."},
	"bat2": {0: "...q....q..."},
	"slime": {0: "...qrqqrq...", 1: "...oqrrqo..."},
	"skeleton": {0: "...o8998o...", 1: "..o877778o.."},
	"mushroom": {1: ".....q......", 2: "...q....q...", 3: ".........q..", 4: ".....q......"},
	"imp": {0: ".q........q.", 1: ".q........q."},
	"ghost": {0: "...qrqqrq..."},
	"bookwyrm": {1: ".q........q.", 3: ".....rr.....", 7: ".q........q."},
	"drowned": {0: "...qoqqoq...", 6: "..q......q.."},
}

# ---- 5.3b: Cinderforge and the floors after it. M(): a symmetric sprite from its left halves;
# the right side takes the shaded tones (3->1, 9->7, l->k ...), so the light comes from the left.
_MIR = str.maketrans("3197lk64rpwuca", "1379kl46prwuac")
def M(rows):
    return [r + r[::-1].translate(_MIR) for r in rows]

S["cultist"] = ("main:#a03040 glow:#ffb040", [
"....oooo....", "...o3332o...", "..o333322o..", "..o0y00y0o..", "..o300001o..", ".o33o00o11o.",
"o3o3q22q1o1o", "o3o322221o1o", "o5o32qq21o8o", ".o3222221o9o", ".o32222221o.", ".oooooooooo."])
S["knight"] = ("main:#4a5a8a second:#4a7ad0", [
"....obbo....", "...o9988o...", "..o998887o..", "..o707707o..", "..o888887o..", ".o98o88o87o.",
"o9o332218o7o", "o9o3q22q1o7o", "o8o322221o8o", ".oo322221oo.", "..o98oo87o..", "..ooo..ooo.."])
S["wisp"] = ("main:#6fb8e8 glow:#dff8ff halo:1", [
".....o......", "....oyo.....", "...oyxyo.o..", "..oy3xx3yo..", ".oy33xx33yo.", ".oy303303yo.",
"..oy3223yo..", "...oy22yo...", "....oyyo....", ".....oo....."])
S["golem"] = ("main:#6a7a9a glow:#9ff0ff", [
"..oooooooo..", ".o33322221o.", ".o3y3222y1o.", ".o32222221o.", "oo32222221oo", "o33o2yy2o11o",
"o32o2yy2o21o", "o32o2222o21o", "oo1o2222o1oo", ".oo322221oo.", ".o322oo221o.", ".oooo..oooo."])
S["bogling"] = ("main:#6a8a3a glow:#ffe060", [
"..ooo..ooo..", ".oxyo..oyxo.", ".o33332222o.", "o3332222221o", "o3oooooooo1o", ".o32222221o.",
"o3o322221o1o", ".oo3o22o1oo.", ".ooo.oo.ooo."])
S["gnat"] = ("main:#4a5a3a bone:#d8e8e0 glow:#ff5a3a", [
"..oo....oo..", ".ollo..ollo.", ".olkloolklo.", "..ooy33yoo..", "...o3322o...", "...o2112o...",
"....o11o....", ".....oo....."])
S["hexwife"] = ("main:#3a4a3a skin:#8aa070 glow:#c8ff5a", [
".....oo.....", "....o32o....", "...o3322o...", ".oo333221oo.", "..o5y55y4o..", "..o455554o..",
".o33o44o11o.", "o3o322221ouo", "o3o3q2221ouo", "o5o322221o5o", ".o32222221o.", ".oooooooooo."])
S["longbowman"] = ("main:#4a6a3a skin:#e0a47a", [
"....oooo..o.", "...o3332o.vo", "..o333221ovo", "..o505504olo", "..o455554olo", ".o33o55o1ovo",
"o3o322221o5o", "o3o3uqu21ovo", "o5o322221oo.", ".oo322221o..", "..o32oo21o..", "..ooo..ooo.."])
S["lancer"] = ("main:#a03a3a skin:#d89a70", [
"....oooo..o.", "...o9988oo9o", "..o998887o8o", "..o505504ouo", "..o455554ouo", ".o98o88o8ouo",
"o9o332218ouo", "o9o3q22q1ouo", "o8o322221o5o", ".oo322221ouo", "..o98oo87ouo", "..ooo..oooo."])
S["warpriest"] = ("main:#6a3a8a", [
"....oooo....", "...oqrrqo...", "..oqrqqqpo..", "..op0pp0po..", "..oqqqqqpo..", ".o33oqqo11o.",
"o3o3lql21o1o", "o3o3lll21o8o", "o5o3lql21o9o", ".oo322221o9o", "..o32oo21o..", "..ooo..ooo.."])
S["torchimp"] = ("main:#e07a3a second:#6a3a2a glow:#fff07a halo:1", [
"....oyyo....", "...oyxxyo...", "..ob3332bo..", "o.o3y33y2o.o", "oao3l2l21oao", "oaao3221oaao",
".oo332221oo.", "...o3221o...", "..o21oo12o..", "..ooo..ooo.."])
S["monk"] = ("main:#d07a2a second:#6a3a2a skin:#c88a5a", [
"....oooo....", "...o6665o...", "..o666554o..", "..o505504o..", "..o455554o..", ".o33o44o11o.",
"o3o322221o1o", "o3obbbbbbo1o", "o5o322221o5o", ".oo322221oo.", "..o32oo21o..", "..ooo..ooo.."])
S["icearcher"] = ("main:#8ab8e0 skin:#f0dce8", [
"....oooo..o.", "...olllko.vo", "..ollllkkovo", "..o505504olo", "..o455554olo", ".olko55okovo",
"o3o322221o5o", "o3o3uqu21ovo", "o5o322221oo.", ".oo322221o..", "..o32oo21o..", "..ooo..ooo.."])
S["snowlantern"] = ("main:#8ab8e0 glow:#bff0ff halo:1", [
"....oooo....", "...o9889o...", "..oooooooo..", "..o3yyyy1o..", ".o3y0yy0y1o.", ".o3yyyyyy1o.",
".o3yy00yy1o.", "..o322221o..", "..oooooooo..", "....o99o...."])
S["gunman"] = ("main:#8a6a3a second:#c0403a skin:#d89a70", [
"...oooooo...", "..ouvvvvuo..", "ouuuuuuuuuuo", "..o505504o..", "..o455554o..", ".o33o44o11o.",
"o3o3bbbb1o1o", "o3o3uqu21o1o", "o5o322221o89", ".oo322221o9.", "..o32oo21o..", "..ooo..ooo.."])
S["cutthroat"] = ("main:#4a3a5a glow:#ff4a4a", [
"....oooo....", "...o3332o...", "..o0y00y0o..", "..o322221o..", "o9o322221o9o", "o8o322221o8o",
".oo322221oo.", "..o32oo21o..", "..ooo..ooo.."])
S["crow"] = ("main:#2a2a3a glow:#ff4a3a", [
"...ooo......", "..o332o.....", ".o3y22qqo...", ".o3222oo....", "o33222221oo.", "o3o22222211o",
".oo222211oo.", "...oo.oo...."])
S["chimneyimp"] = ("main:#4a4a52 second:#2a2433 glow:#ffa040", [
"...oooooo...", "...obbbbo...", "..oaaaaaao..", "o.o3y33y2o.o", "oao3l2l21oao", "oaao3221oaao",
".oo332221oo.", "...o3221o...", "..o21oo12o..", "..ooo..ooo.."])
S["voidling"] = ("main:#5a3a8a glow:#ff7af0", [
"....oooo....", "..oo3332oo..", ".o33333222o.", ".o33oooo21o.", "o333oyxo221o", "o333oyyo221o",
"o3333oo2221o", ".o3o3221o1o.", "o3o.o22o.o1o", ".o..o..o..o."])
S["shadeknight"] = ("main:#3a2a4a metal:#5a5470 second:#8a4ad0 glow:#d08aff", [
"....obbo....", "...o9988o...", "..o998887o..", "..o7y77y7o..", "..o888887o..", ".o98o88o87o.",
"o9o332218o7o", "o9o3q22q1o7o", "o8o322221o8o", ".oo322221oo.", "..o98oo87o..", "..ooo..ooo.."])
S["eclipsed"] = ("main:#4a2a5a glow:#ffb040", [
"...oqqqqo...", "..oq0000qo..", ".oq000000qo.", ".oq0y00y0qo.", "..oq0000qo..", ".o33oqqo11o.",
"o3o322221o1o", "o3o322221o1o", "o5o322221o5o", ".o32222221o.", ".o32222221o.", ".oooooooooo."])
S["mirehulk"] = ("main:#5a6a3a second:#8ab04a glow:#ffe060", [
"..oooooooo..", ".o33cc3221o.", "o33cy22y221o", "o3322222221o", "o32llllll21o", "oo32222221oo",
"o3o3c22c1o1o", "o3o322221o1o", "o5o32cc21o5o", ".oo322221oo.", ".o322oo221o.", ".oooo..oooo."])
S["ironcaptain"] = ("main:#3a3a5a second:#b03a3a glow:#ffa040", [
"....oqqo....", "...o9988o...", "..o998887o..", "..o7x77x7o..", "..o888887o..", ".obo9889obo.",
"obo932219obo", "obo3q22q1obo", "o8o322221o8o", ".bo322221ob.", ".bo98oo87ob.", ".oooo..oooo."])
S["stoneabbot"] = ("main:#8a8a7a glow:#7ff0ff", [
"....oooo....", "...o3332o...", "..o333221o..", "..o3y22y1o..", "..o320221o..", ".o33o22o11o.",
"o3o3y2221o1o", "o3o32y221o1o", "o3o322y21o3o", ".o32222221o.", ".o32222221o.", ".oooooooooo."])
S["enforcer"] = ("main:#4a4a3a glow:#ff4a3a", [
"....oooo....", "...o9998o...", "..o998887o..", "..o8y88y7o..", "..o7o88o7o..", ".o98o77o87o.",
"o9o322218o7o", "o9o3q22q1o7o", "o8o322221o8o", ".oo322221oo.", "..o98oo87o..", "..ooo..ooo.."])
S["herald"] = ("main:#3a8a8a glow:#ffe060", [
"oo........oo", "ollo.oo.ollo", "olllo33olllo", ".oll3yx3llo.", "..oo3yy3oo..", "...o3qq3o...",
"...oq22qo...", "....o22o....", ".....oo....."])
S["tyrant"] = ("main:#5a4a4a glow:#ffa040 halo:1", M([
"....oqo.", "...oqrqq", "..o99888", ".o998y88", ".o988888", ".o98o000", ".o988888", "o9o98888",
"o9o8oooo", "o8o8oyxx", "o8o8oxyy", "o8o88888", ".oo98888", "..o988o.", "..o9988o", "..oooooo"]))
S["rimewarden"] = ("main:#5a8ac8 glow:#dff8ff", M([
".l....oo", ".lo.o333", "..lo3222", "..o32y22", "..o22222", "..o2llll", ".o32llll", "ollllo22",
"o3o22222", "o3o22y22", "o3o22222", ".oo22222", "..o22222", "..o222o.", "..o998o.", "..ooooo."]))
S["regent"] = ("main:#6a3a9a", M([
"....oqoq", "....oqrq", "....oqqq", "...ollll", "...ol0ll", "...ollll", "...oll00", "..oqqlll",
".o3q2222", "o32q2222", "o5o22222", "o3o2222q", ".o32222q", ".o32222q", "o332222q", "oooooooo"]))
S["bogmatriarch"] = ("main:#5a8a3a second:#e87aa0 glow:#ffe060", M([
"..ooo...", ".oxyo...", ".o33oooo", "o33c2222", "o322c222", "o3oooooo", "o322jjjj", "o32jllll",
"o32jllll", "o32jllll", "o322jjjj", "oo322222", "o3oo2222", "o33o2222", "o32o2222", "oooooooo"]))
S["ashwarlord"] = ("main:#4a3a3a second:#b03a3a glow:#ffa040", M([
"9.....oo", "o9..o999", ".o9o9888", "..o9y888", "..o98888", "..o80808", ".boo9888", "bbo99888",
"bo9o8888", "bo8o88y8", "bo8o8888", "bbo98888", ".bo98888", ".bo98o..", ".bo98o..", ".ooooo.."]))
S["frozenabbot"] = ("main:#6a9ad0 glow:#dff8ff", M([
"...x.x.x", "...oxxxx", "..o32222", "..o3y222", "..o32222", "..o3llll", ".ollllll", "olllllll",
"o3olllll", "o3olllll", "o3ollllq", ".ollllll", ".ollllll", ".ollllll", "olllllll", "oooooooo"]))
S["crowking"] = ("main:#2a2a3a glow:#ff4a3a", M([
"....oqoq", "....oqqq", "...o3222", "..o32y22", "..o3222q", "...o22qq", "..o32222", ".o332222",
"o3332222", "o3o32222", "o33o2222", "o3o3o222", ".o3o3o22", "..oo3222", "...oqo..", "...oo..."]))
S["umbralsun"] = ("main:#3a2a5a glow:#e0a0ff", M([
".......q", "..q....q", "...q.ooo", "....oqqq", "...oq000", "qq.oq0y0", "...oq000", "qq.oq000",
"...oq000", "...oq0yy", "...oq000", "....oq00", "...q.oqq", "..q...oo", ".......q", "........"]))

_HUM = {0: "...q.qq.q...", 5: ".q........q."}   # a little crown and shoulder spikes
for _n in ["cultist", "knight", "hexwife", "longbowman", "lancer", "warpriest", "monk", "icearcher", "gunman",
		"shadeknight", "eclipsed", "ironcaptain", "stoneabbot", "enforcer", "mirehulk", "golem"]:
	ELITE[_n] = dict(_HUM)
ELITE.update({
	"wisp": {0: "...q.o.q....", 9: "....qooq...."},
	"bogling": {0: ".qooo..oooq.", 4: "o3qqqqqqqq1o"},
	"gnat": {7: "....qqqq...."},
	"torchimp": {2: ".qob3332boq."},
	"snowlantern": {1: "...oqrrqo...", 9: "....oqqo...."},
	"cutthroat": {0: "...qooooq..."},
	"crow": {0: "..qoooq.....", 1: ".qo332o....."},
	"chimneyimp": {1: "...oqqqqo..."},
	"voidling": {0: "...qoooq....", 9: "q..q..q..q.."},
	"herald": {5: "...oqrrqo..."},
})

# ---- 5.3b, his picks (6 Oct). These went back to their old design, remastered; the new drawing
# is kept as "<name>_new" when he chose it for the elite. Wisp and bogling: the other way round,
# the new design stays and the elite is the old one ("<name>_old").
for _n in ["gnat", "longbowman", "torchimp", "crow", "stoneabbot"]:
	S[_n + "_new"] = S[_n]
	ELITE[_n + "_new"] = ELITE.pop(_n)
S["gnat"] = ("main:#6d4140 second:#b97069 glow:#7eb552", M([
".o....", "o3o..o", "o32ooc", "o322cc", ".o32cy", "..o3cc", "...oco", "....o."]))
S["crow"] = ("main:#2e2a32 second:#4e4355 glow:#ff4a3a", M([
".o....", "o3o..o", "o32ooc", "o322cc", ".o32cy", "..o3cc", "...oco", "....o."]))
S["longbowman"] = ("main:#bdb8a9 glow:#ff5a3a", M([
"....oo", "...oll", "..olll", "..olyl", "..olll", "...ol0", "..oool", ".ollll", "olooll", ".o.olo",
"..ollo", "...oo."]))
S["torchimp"] = ("main:#df8c5f glow:#eff578", M([
".o....", "oro.oo", "orqo32", ".oq322", "..o3y2", "..o322", "...o30", "..o322", "..o3oo", "...o.."]))
S["stoneabbot"] = ("main:#9fa9b3 glow:#7ff0ff", M([
"...ooo", "..o322", ".o3lll", ".o3l0l", ".o3lll", "o32222", "o3l222", "o3l22y", "o32222", ".o322o",
".o988o", "..ooo."]))
S["regent"] = ("main:#5c3483", M([
"....o..o", "...oqooq", "...oqqqq", "...ollll", "...ol00l", "...ollll", "...olll0", "..o222ll",
".o223222", "o223322q", "o5233222", ".o233222", ".o222222", "o2222222", "o22o22o2", ".oo.oo.o"]))
S["frozenabbot"] = ("main:#a3b9ce bone:#dfeaf0 glow:#dff8ff", M([
".o......", "olo..ooo", "olloolll", ".olll222", "..ol2002", "..ol20y2", "..ol2222", ".oll2220",
"ol2ll222", "ol2l2lll", "ol2l2lqq", "ol2l2lll", ".ooo2222", "...o222o", "..o8888o", "...oooo."]))
S["wisp_old"] = ("main:#6fd3e0 second:#4d9be6", [
".....o......", "....o3o.....", "...o3l1o....", "..o3llk1o...", ".o3l0l0k1o..", ".o3lllkk1o..",
"..o3llk1o...", "...o3b1o....", "....obo.....", ".....o......"])
S["bogling_old"] = ("main:#3d7b60 second:#254744", [
"....oooo....", "...o3322o...", "..o333222o..", ".o33l22l21o.", ".o33022021o.", "o3322222221o",
"oa22222222ao", ".oaaaaaaaao.", "..oooooooo.."])
ELITE["wisp_old"] = {}
ELITE["bogling_old"] = {0: "...qrqqrq..."}
ELITE.pop("wisp"); ELITE.pop("bogling")
# foe -> the drawing its elite is made from
ELITE_SRC = {"gnat": "gnat_new", "longbowman": "longbowman_new", "torchimp": "torchimp_new",
	"crow": "crow_new", "stoneabbot": "stoneabbot_new", "wisp": "wisp_old", "bogling": "bogling_old"}
