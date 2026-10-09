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

# ---- 5.3c: six rift worlds (Gaol, Brand, Neon, Streets, Fog, Burb). OV(): marks over a sprite
# ('.' keeps the pixel), for things a mirrored sprite holds in one hand.
def OV(rows, over):
    rows = list(rows)
    for r, o in over.items():
        rows[r] = "".join(c if c != '.' else g for g, c in zip(rows[r], o))
    return rows

# 18.2 THE INKLING as a hero: the ink drop grown bold, a quill for a sword, a page for a cape.
S["inkling_hero"] = ("main:#2a2a4a glow:#9ab8ff bone:#f4ecd8 wood:#c8a878", OV(M([
"......", "...ooo", "..o333", ".o3333", ".o3y03", ".o3333", "..o333", ".ol333", "ollo33", "ollo33",
".oo333", "..o32o", "..o22o", "..ooo."]), {0: ".........l..", 1: "........lo..", 2: ".......uo...", 3: "......uo....",
	4: ".....uo.....", 7: "..........ll", 8: "..........ll"}))
# 19.2 THE CAMP's people: the cook, and the visitors who come and go.
S["npc_cook"] = ("main:#c0403a bone:#f4ecd8 skin:#e0a47a wood:#7a5236", OV(M([
"..oooo", ".ollll", ".ollll", "..olll", "..o555", "..o505", "..o555", ".o33ll", "o3o3ll", "o5o3ll",
".oo3ll", "..o3lo", "..o22o", "..ooo."]), {4: "..........o.", 5: "..........wo", 6: "..........u.", 7: "..........u.",
	8: "..........u."}))
S["npc_peddler"] = ("main:#6b5a3a second:#a8705a skin:#d89a70 wood:#8a6a4a gold:#f2c94c", OV(M([
"...ooo", "..oaaa", ".oaaaa", ".oa555", "..o505", "..o555", ".o3333", "o3o333", "o5o333", ".oo333",
"..o33o", "..o22o", "..ooo."]), {3: "..........oo", 4: ".........ouw", 5: ".........uww", 6: ".........uww",
	7: ".........uww", 8: ".........uwo", 9: "..........qo"}))
S["npc_bard"] = ("main:#3f8a4a second:#c0403a skin:#e0a47a wood:#a8705a glow:#f2c94c", OV(M([
"...ooo", "..oaaa", ".oaaaa", "..o555", "..o505", "..o555", ".o3333", "o3o333", "o5o333", ".oo333",
"..o33o", "..o22o", "..ooo."]), {0: ".........y..", 1: "........yy..", 5: "........uo..", 6: ".......u....",
	7: "......uu....", 8: ".....uwwu...", 9: "....uwwu...."}))
S["npc_seer"] = ("main:#5c3483 glow:#6fd3e0", OV(M([
"...ooo", "..o333", ".o3333", ".o3000", ".o30y0", ".o3000", ".o3333", "o33333", "o33333", "o33333",
".o3333", ".o3333", "o33333", ".ooooo"]), {9: ".....oo.....", 10: "....oxyo....", 11: "....oyyo....", 12: ".....oo....."}))
S["npc_monger"] = ("main:#4a6a8a second:#3f5a6a bone:#e8e8f0 skin:#e0a47a glow:#6fd3e0", OV(M([
"...ooo", "..obbb", ".obbbb", "..o555", "..o505", "..o555", ".o33ll", "o3o3ll", "o5o3ll", ".oo3ll",
"..o3lo", "..o22o", "..ooo."]), {7: "..........oy", 8: "..........yy", 9: "..........yo"}))
S["camp_cat"] = ("main:#a8502a glow:#7ab04a", [
"............", ".o...o......", "o3o.o3o.....", "o333333o...o", "o3y33y3o..o3", "o333333oo.o3",
".o333333oo3o", "..o3333333o.", "..o3o..o3o..", "..ooo..ooo.."])
# 20.2 THE CAMP grows: the carpenter who builds it, and two more visitors.
S["npc_carpenter"] = ("main:#8a5a2a second:#c8a878 skin:#e0a47a wood:#a8705a metal:#c8ccd8", OV(M([
"...ooo", "..obbb", ".obbbb", "..o555", "..o505", "..o555", ".o3333", "o3o3uu", "o5o333", ".oo333",
"..o33o", "..o22o", "..ooo."]), {3: ".........777", 4: ".........o8o", 5: "..........u.", 6: "..........u.", 7: "..........u."}))
S["npc_gambler"] = ("main:#5a2a4a second:#2a2838 skin:#e0a47a gold:#f2c94c glow:#ffffff", OV(M([
"..oooo", ".obbbb", "obbbbb", "..o555", "..o505", "..o5qq", ".o3333", "o3o3q3", "o5o333", ".oo333",
"..o33o", "..o22o", "..ooo."]), {8: "..........oy", 9: "..........yo"}))
S["npc_tinker"] = ("main:#4a5a3a second:#8a6a4a skin:#d89a70 metal:#c8ccd8 glow:#f2c94c", OV(M([
"...ooo", "..oaaa", ".oa777", ".oa575", "..o505", "..o555", ".o3333", "o3o333", "o5o333", ".oo333",
"..o33o", "..o22o", "..ooo."]), {6: "..........o.", 7: ".........o7o", 8: ".........o8o", 9: "..........o."}))
# ---- 20.3 (his word, 8 Oct): CHAPTER IV, THE LIBRARY (STORY.md). The Stacks.
S["mothling"] = ("main:#9a8a72 second:#c8b898 glow:#f2c94c", M([
"......", "...o.o", "oo..oo", "o3o.o3", "oc3oo3", "o33oy3", "oc3o33", ".o3o22", "..o.o2", "......"]))
S["dustbunny"] = ("main:#a8a8b0 glow:#ffffff", M([
"......", "..o.o.", ".o3o3o", "o33333", "o3y033", "o33333", "o22222", ".o2222", "..oooo"]))
S["shelfmimic"] = ("main:#6a2a3a second:#f2c94c bone:#f4ecd8 glow:#ff4a3a", M([
".ooooo", "o33333", "o3cccc", "o3oyoo", "o3llll", "o30000", "o3llll", "o3cccc", "o33333", ".ooooo"]))
S["bookgolem"] = ("main:#6a4a2a second:#4d6aa8 bone:#f4ecd8 gold:#f2c94c glow:#f2c94c", M([
"...ooo", "..o333", "..o3y0", "..oooo", ".oaaaa", ".orrrr", "o3oooo", "o3cccc", "o3llll", "o3aaaa",
".oqqqq", "..o3oo", "..oo.."]))
S["cardsprite"] = ("main:#e8dcc0 second:#d8443c glow:#4d6aa8", M([
"......", "oooooo", "o3aaaa", "o33333", "o3y333", "o33333", "o3o333", "o33333", "oooooo", ".o.o.."]))
# The Reading Room.
S["shusher"] = ("main:#6a8a7a bone:#f4ecd8 glow:#c8f0ff halo:1", M([
"..oooo", ".o3333", "o33333", "o3y033", "o33333", "o333o3", "o33333", "o33333", ".o3333", ".o3o3o", "..o.o."]))
S["lampwisp"] = ("main:#2f8a4a metal:#c9a35a glow:#eaffb0", M([
"......", "...ooo", "..o333", ".o3333", "o33333", "oooooo", "...oyy", "...oyx", "....o9", "....o8", "...o98", "...ooo"]))
S["bookend"] = ("main:#8b8f9c metal:#6b6a72 glow:#f2c94c", M([
".o....", ".oo...", ".o3ooo", ".o3333", "o3yxo3", "o3yyo3", "o33o33", "o33333", "o3o3o3", "o33333", "oooooo",
"o88888", "oooooo"]))
S["pagewing"] = ("main:#f4ecd8 glow:#2a2a4a", M([
"......", "o.....", "oo....", "o3o..o", "o33oo3", "o333y3", ".o2233", "..oo23", "....oo"]))
S["spectacle"] = ("main:#c9a35a metal:#c9a35a glow:#9fe0ff", M([
"......", "......", ".oooo.", "oyyyyo", "oyxyyo", "oyyyyo", ".oooo9", "......"]))
# The Hearth.
S["cinderpage"] = ("main:#f4ecd8 bone:#c8a878 glow:#ff8a3a", M([
"......", "...y..", "..yxy.", ".oyyyo", ".o333l", "o3333l", "o3ll3l", "o3333l", ".o333o", "..oooo"]))
S["ashworm"] = ("main:#5e5a6e glow:#ff6a1a", M([
"......", "......", "..ooo.", ".o333o", "o3y333", "o33333", "o2o2o2", ".o.o.o"]))
S["pokerknight"] = ("main:#3a3850 metal:#8b8f9c glow:#ff8a3a", OV(M([
"...ooo", "..o999", ".o9888", ".o8yy8", ".o8888", "..oooo", ".o3333", "o3o333", "o3o333", "o3o333",
".oo333", "..o3oo", "..oo.."]), {2: "..........y.", 3: "..........8.", 4: "..........8.", 5: "..........8.",
	6: "..........8.", 7: "..........8."}))
S["firedog"] = ("main:#3a3a44 glow:#ff6a1a", M([
"o.....", "oo....", "o3o.oo", "o33o33", ".o3y33", ".o3333", "..o3oo", "..o300", ".o3333", "o33333", "o3o3o3", "oo.oo."]))
S["sootling"] = ("main:#2a2838 glow:#ff6a1a", M([
".o....", ".oo...", "..o3oo", "..o333", ".o3y03", ".o3333", "o3o22o", "o..o2.", "....o."]))
# The three minis.
S["overdue"] = ("main:#6a4a2a second:#d8443c bone:#f4ecd8 gold:#f2c94c metal:#8b8f9c glow:#f2c94c", M([
"....oooo", "...o3333", "..o3y0y3", "..o33333", ".ooooooo", ".oacrlac", ".oacrlac", ".oacrlac", ".oacrlac",
"o9999999", "o8888888", ".o9o..o9", ".oo...oo"]))
S["quiet"] = ("main:#24243a bone:#8b8f9c glow:#c8f0ff halo:1", M([
"....oooo", "...o3333", "..o33333", "..o3y033", "..o33333", "..o3333l", "..o3333l", ".o333333", "o3333333",
"o3333333", "o3333333", ".o333333", ".o3o3o33", "..o.o.oo"]))
S["kindling"] = ("main:#8a5a2a gold:#c9a35a glow:#ff8a3a", M([
"....y...", "...yxy.y", "..yyxyyx", "..oyyyyy", ".o3w3w3w", ".o3y03w3", ".o3w3w3w", ".oqqqqqq", ".o3w3w3w",
".o3w3w3w", "..o3w3w3", "..ooo.oo"]))
# The three guardians: THE SHELVER, THE HUSH and THE CRITIC.
S["shelver"] = ("main:#6a4a2a second:#4d6aa8 bone:#f4ecd8 gold:#f2c94c glow:#f2c94c", M([
"....oooo", "...o3333", "...o3y03", "...o3333", "oo.ooooo", "oro33333", "oroaaacc", "oo.o3333", "...orrll",
"...o3333", "..o3aacc", "..o33333", "..o3llrr", "..o33333", "..o3o..o", "..oo...o"]))
S["hush"] = ("main:#2a3a6a bone:#c8ccd8 glow:#9fe0ff halo:1", M([
".....ooo", "....o333", "...o3333", "..o33333", "..o30y00", "..o33333", "..o3333l", "..o3333l", ".o333333",
".o333333", "o3333333", "o3333333", "o3333333", "o3333333", "o3o33o33", "oo.oo.oo"]))
S["critic"] = ("main:#3a1a2a second:#d8443c bone:#f4ecd8 skin:#e0b48a glow:#f2c94c halo:1", OV(M([
"....oooo", "...o5555", "..o55555", "..o5o555", "..o55555", "..o55oo5", "...o5555", ".ollllll", "o3llllll",
"o3333333", "o3333333", "o3o33333", "o3o33333", ".oo33333", "..o33o33", "..oo..oo"]),
	{3: ".........oyo....", 4: "..........o.....", 7: "..............ao", 8: ".............ao.", 9: "............ao..",
	10: "...........ao...", 11: "..........ll...."}))
for _n in ["mothling", "dustbunny", "shelfmimic", "bookgolem", "cardsprite", "shusher", "lampwisp", "bookend",
		"pagewing", "spectacle", "cinderpage", "ashworm", "pokerknight", "firedog", "sootling"]:
	ELITE.setdefault(_n, {})
S["inmate"] = ("main:#e07a2a skin:#7ab04a", M([
"....oo", "...o66", "..o565", "..o505", "..o5l5", ".o33o5", "o3o3l2", "o3o322", "o8o322", ".oo322",
"..o32o", "..ooo."]))
S["grenadier"] = ("main:#7a5236 second:#c0403a skin:#d89a70", OV(M([
"....oo", "...obb", "..obbb", "..o505", "..o455", ".o33o5", "o3o302", "o3o322", "o5o322", ".oo322",
"..o32o", "..ooo."]), {8: "..........0o"}))
S["jailer"] = ("main:#3f6a4a second:#2a3a2a skin:#e0a47a", OV(M([
"...ooo", "..obbb", ".o0000", "..o505", "..o455", ".o33o5", "o3o3q2", "o3ouuq", "o5o322",
".oo322", "..o32o", "..ooo."]), {9: "..........q."}))
S["turnkey"] = ("main:#3f6a4a glow:#ff4a3a", OV(M([
"....oooo", "...o3222", "..o32222", "..o32y22", "..o32222", "..o320l0", ".oo33222", "o3o33222",
"o3o32q22", "o5o32222", "o3o3uuuu", ".oo32222", "..o32222", "..o322oo", "..o88o..", "..ooo..."]),
{9: "..............q.", 10: "..............qq"}))
S["graveborn"] = ("main:#5a3a7a glow:#ff4a3a", M([
"...ooo", "..olll", "..olll", "..olyl", "..ol0l", ".o33ol", "o3o322", "o3o3q2", "olo322", ".o3222",
".o3222", ".ooooo"]))
S["bandsman"] = ("main:#6a4a32 second:#c0403a skin:#d89a70", OV(M([
"...ooo", "..o988", "..o988", "..o505", "..obbb", ".o33ob", "o3o322", "o3ouuq", "o5o322", ".oo322",
"..o32o", "..ooo."]), {8: "..........9."}))
S["fiendling"] = ("main:#c03a3a second:#e8873a glow:#ffe060", M([
".c....", ".co.oo", "..oo32", "o.o3y2", "o3oo32", "o3o322", ".o3322", "..o322", "..o322", "..o32o",
"..o3o.", "..ooo."]))
S["blackknight"] = ("main:#2a2a35 metal:#4a4a58 glow:#ff4a3a", M([
"..9.oo", "..9o88", "..o988", "..o8yy", "..o888", ".o98o8", "o9o322", "o9o3q2", "o8o322", ".oo322",
"..o98o", "..ooo."]))
S["carrionknight"] = ("main:#2a2a35 metal:#4a4a58 glow:#ff4a3a", OV(M([
"......oo", ".....o98", "....o988", "....o8yy", "....o888", "...o98o8", "..o9o322", "..o9o3q2",
"..o8o322", "...oo322", "...o3222", "...o3222", "...o3222", "...o98oo", "...o88o.", "...ooo.."]),
{0: ".o..............", 1: "o9o.............", 2: "o9o.............", 3: "o9o.............", 4: "o9o.............",
 5: "o8o.............", 6: "qqqo............", 7: ".uo.............", 8: ".5o............."}))
S["drone"] = ("main:#6a7a9a second:#4a7ad0 glow:#7ff0ff", M([
"oo....", ".oo.oo", "...o99", "..o988", ".o98oy", ".o98yx", ".o9888", "..o988", "...o88", "....ob",
"....oy", "......"]))
S["glitch"] = ("main:#4a2a7a second:#ff4ad0 glow:#7ff0ff", OV(M([
"...ooo", "..o332", ".o3322", ".o3yyy", ".o3o00", ".o33o2", "o3o322", "o3ob22", "o3o322", ".oo322",
"..o32o", "..ooo."]), {3: "...........b", 7: "b..........."}))
S["chrome"] = ("main:#8a9ab0 glow:#ff6ad0", M([
"...ooo", "..o999", ".o9988", ".o98y8", ".o9888", ".oo98o", "o9o988", "o9o88y", "o8o988", ".oo988",
"..o98o", "..ooo."]))
S["turret"] = ("main:#6a7a9a glow:#7ff0ff", M([
"...ooo", "..o988", ".o98yx", ".o98yy", "..o988", "...o88", "....o8", "...o8o", "..o8o.", ".o8o..",
"o8o...", "oo...."]))
S["broker"] = ("main:#2a2a3a second:#ff6ad0 glow:#7ff0ff skin:#e0b090", M([
"....oooo", "...o3222", "..o32222", "..o3yyyy", "..o55555", "..o55550", ".o33ollb", "o33222lb",
"o3322222", "o5o32222", "o3o32222", ".oo32222", "..o32222", "..o322oo", "..o00o..", "..ooo..."]))
S["thug"] = ("main:#2a2a32 second:#ff5aa0 skin:#d89a70", M([
".....b", "....ob", "..o55b", "..o505", "..o455", ".o33o5", "o3o32l", "o3o322", "o5o322", ".oo322",
"..o88o", "..ooo."]))
S["molotov"] = ("main:#3f6a3a second:#7ac0a0 glow:#ffa040 skin:#d89a70", OV(M([
"...ooo", "..o332", ".o3322", ".o3505", ".o3455", ".o33o5", "o3o322", "o3o3uq", "o5o322", ".oo322",
"..o32o", "..ooo."]), {6: "...........y", 7: "...........b", 8: "...........b"}))
S["copper"] = ("main:#3a6ab0 second:#2a3a6a skin:#e0a47a", M([
"...ooo", "..obbq", ".o0000", "..o505", "..o455", ".o33o5", "o3o3q2", "o3o322", "o5o322", ".oo322",
"..o32o", "..ooo."]))
S["bomber"] = ("main:#d04a3a glow:#ffe060 skin:#e0a47a", M([
".....y", "....ou", "...ooo", "..o322", ".o3505", ".o3455", "o33q22", "o32222", "o32q22", ".o3222",
"..o32o", "..ooo."]))
S["mayor"] = ("main:#a03040 second:#2a2433 skin:#e0b090", OV(M([
"....oooo", "....obbb", "....obbb", "....oqqq", "..obbbbb", "...o5055", "...o4555", "...o55jj",
"..o3olll", ".o332q22", "o5o32222", "o3o32222", ".oo32222", "..o322oo", "..obbo..", "..ooo..."]),
{5: "..........q.....", 9: "...............q", 10: "...............u", 11: "...............u", 12: "...............u",
 13: "...............u", 14: "...............u"}))
S["orderly"] = ("main:#a0c8b0 second:#c0d8e8 glow:#ff4040", M([
"...ooo", "..olll", "..olll", "..ol0l", "..obbb", ".o33ob", "o3o32y", "o3o3yy", "o5o32y", ".oo322",
"..o32o", "..ooo."]))
S["crawler"] = ("main:#8a5a4a glow:#ffe060", M([
"......", "......", "......", "...ooo", "..o332", ".o3y22", "o33222", "o32222", "oo0000", "o2o2o.",
"o.o.o.", "......"]))
S["static"] = ("main:#2a2a35", M([
"..oooo", "..ol9l", "..o9l9", "..ol9l", "..oooo", "...o32", "..o322", ".o3o22", ".o.o22", "...o22",
"...o2o", "...oo."]))
S["tollkeeper"] = ("main:#3a3045 glow:#ffd060", OV(M([
"...ooo", "..o322", ".o3222", ".o30y0", ".o3000", ".o332o", "o33222", "o32222", "o32222", "o32222",
".o3222", ".ooooo"]), {8: "...........y", 9: "...........x"}))
S["rustbutcher"] = ("main:#3a3a45 second:#b03030", OV(M([
"...ooooo", "...ovvvv", "...ovv0v", "...ovvvv", "...ouvvv", "...oo555", ".o3ollll", "o33lllll",
"o3llllbl", "o5llllll", "o3lbllll", ".ollllll", "..o32222", "..o322oo", "..o000o.", "..ooooo."]),
{7: "...............9", 8: "...............9", 9: "...............9", 10: "...............u"}))
S["neighbour"] = ("main:#e07ab0 second:#c8a0d8 skin:#f0c8a0", M([
"..oqoq", "..obbb", ".obb55", ".ob909", "..o455", ".o33o5", "o3o322", "o3o322", "o5o322", ".o3222",
".o3222", ".ooooo"]))
S["robovac"] = ("main:#6a6a7a glow:#ff4a3a", M([
"......", "......", "......", "......", "......", "......", "..oooo", ".o9999", "o988y8", "o88888",
".o8888", "..oooo"]))
S["burglar"] = ("main:#2a2a35 second:#1a1a22 skin:#e0a47a", M([
"...ooo", "..obbb", "..obbb", "..o050", "..o455", ".o33o5", "o3olll", "o3o222", "o5olll", ".oo222",
"..o22o", "..ooo."]))
S["gnome"] = ("main:#3a6ab0 second:#d04040 skin:#f0c8a0", M([
".....b", "....ob", "...ocb", "..ocbb", "..o505", "..oll5", ".ollll", "o5olll", ".o3lll", ".oo322",
"..ouuo", "..ooo."]))
S["landlord"] = ("main:#d86aa8 second:#2a2433 skin:#e0b090", OV(M([
"....oooo", "...obbbb", "..obbbbb", "..o55555", "..o50555", "..o55500", "..oo5555", ".o33ollq",
"o3332222", "o5o32222", "o3o32q22", ".o332222", ".o322222", "..o322oo", "..obbo..", "..ooo..."]),
{11: "..............oq", 12: "..............qq"}))
for _n in ["inmate", "grenadier", "jailer", "graveborn", "bandsman", "blackknight", "glitch", "chrome", "thug",
		"molotov", "copper", "orderly", "tollkeeper", "neighbour", "burglar"]:
	ELITE[_n] = dict(_HUM)
for _n in ["turnkey", "carrionknight", "broker", "mayor", "rustbutcher", "landlord"]:   # 16x16 champions
	ELITE[_n] = {1: "..q..........q..", 6: "q..............q"}
ELITE.update({
	"fiendling": {0: "qc........aq"},
	"drone": {0: "qq........qq"},
	"turret": {0: "..q......q.."},
	"bomber": {2: "..qooooooq.."},
	"crawler": {3: "..qoooooq..."},
	"static": {0: ".qoooooooq.."},
	"robovac": {6: ".qoooooooqq."},
	"gnome": {3: ".qocbbbbaoq."},
})

# ---- 5.3d: Heist, Dust, Skyreach, Bastion, Cathedral.
S["gangster"] = ("main:#2a2a32 second:#c03a3a skin:#e0b090", OV(M([
"...ooo", "..o332", ".o3222", "..o505", "..o455", ".o33ol", "o3o3lb", "o3o32b", "o5o322", ".oo322",
"..o32o", "..ooo."]), {8: "..........98"}))
S["biker"] = ("main:#2a2a32 second:#c03a3a glow:#7ff0ff", M([
"...ooo", "..obbb", ".obbbb", ".oyyyy", "..obbb", ".o33o2", "o3o322", "o3o3q2", "o0o322", ".oo322",
"..o88o", "..ooo."]))
S["riotcop"] = ("main:#2a4a8a second:#1a2a5a skin:#e0a47a", OV(M([
"...ooo", "..obbb", ".obbbb", ".o0000", "..o455", ".o33o5", "o3o322", "o3o3q2", "o5o322", ".oo322",
"..o32o", "..ooo."]), {5: "oo..........", 6: "o9o.........", 7: "o9o.........", 8: "o9o.........", 9: "o8o.........",
 10: "oo.........."}))
S["kingpin"] = ("main:#c8b088 skin:#e0b090", OV(M([
"....oooo", "...o6666", "..o66555", "..o65555", "..o50555", "..o55555", "..o45555", "...oo555",
".olllllq", "ollllllq", "o5llllll", "olllllll", ".ollllll", "..ollloo", "..o00o..", "..ooo..."]),
{6: "...........uuy.."}))
S["outlaw"] = ("main:#8a6a3a second:#c0403a skin:#d89a70", OV(M([
"...ooo", "..ouvv", "ouuuuu", "..o505", "..obbb", ".o33ob", "o3o322", "o3ouuq", "o5o322", ".oo322",
"..o32o", "..ooo."]), {8: "..........9."}))
S["dynamiter"] = ("main:#3a5a9a second:#c0403a glow:#ffe060 skin:#e0a47a", OV(M([
"...ooo", "..o99y", ".o9999", "..o505", "..olll", ".ollll", "o3o322", "o3o3q2", "o5o322", ".oo322",
"..ouuo", "..ooo."]), {6: "...........y", 7: "...........b", 8: "...........b"}))
S["sharpshooter"] = ("main:#4a7a3a skin:#d89a70", OV(M([
"...ooo", "..ouvv", "ouuuuu", "..o505", "..o455", ".o33o5", "o3q3q2", "o33322", "o5o322", ".oo322",
"..o32o", "..ooo."]), {7: "..........99", 8: "..........u."}))
S["coyote"] = ("main:#8a5a32 glow:#ffe060", [
"............", "............", "............", ".o.o........", "ovovo.......", "ovvvvo......",
"o0vyvvoooooo", ".ovvvvvvvvwo", "..ovvvvvvvwo", "..ouuuuuuuo.", "..ouo..ouo..", ".oo....oo..."])
S["marshal"] = ("main:#7a5236 skin:#e0a47a", OV(M([
"....oooo", "...ouvvv", "...ouvvv", "oouuuuuu", "...o5055", "...o5555", "...o5000", "...oo555",
"..o33o22", ".o333222", "o5o32222", "o3ouuuuq", ".oo32222", "..o322oo", "..ouuo..", "..ooo..."]),
{9: "......q........."}))
S["skykite"] = ("main:#a8c8f0 second:#d04040 glow:#ff4a3a", OV(M([
".....o", "....o3", "...o33", "..o332", ".o332y", "o3332y", ".o3322", "..o322", "...o32", "....o3",
".....o", "......"]), {10: "......o.....", 11: ".......bb..."}))
S["gustling"] = ("main:#8ab8e0 bone:#e0f0ff", OV(M([
"......", "...ooo", "..olll", ".ollll", "oll0ll", "olllll", ".olll0", "..olll", "...ooo", "......",
"......", "......"]), {9: "....o.o.....", 10: ".....oo....."}))
S["stormharpy"] = ("main:#8a5ad0 skin:#e0a47a", M([
"......", "...ooo", "..o322", "o.o505", "lloo55", ".ollo3", "..olo3", "...o32", "...o32", "...oqo",
"..oqo.", "......"]))
S["thunderhead"] = ("main:#6a6a80 glow:#ffe060", OV(M([
"......", "...ooo", "..o333", ".o3322", "o33222", "o32y22", "o32222", ".o2222", "..oooo", "......",
"......", "......"]), {9: ".....yx.....", 10: "......y.....", 11: ".....y......"}))
S["mirrorwing"] = ("main:#6fd3e0 glow:#ffffff", M([
"oo....", "o3o...", "o33o..", "o3x3oo", ".o33o2", "..oo32", ".o33o2", "o3x3oo", "o33o..", "oo....",
"......", "......"]))
S["galewarden"] = ("main:#4a7ad0", M([
"l.....oo", "llo..o99", "lllo.o88", "llllo8yy", ".llloo88", "..lo9888", "...o9322", "..o9o322",
"..o8o3q2", "..o5o322", "...oo322", "...o3222", "...o3222", "...o98oo", "...o88o.", "...ooo.."]))
S["squallheron"] = ("main:#a0c0e0 second:#4a7ad0 bone:#f0f4f8", [
"........ooo.....", ".......olllo....", ".......ol0lqqqo.", ".......olllooo..", "........olko....",
"........olko....", ".......ollko....", "...ooooollko....", "..oblllllllko...", ".obbllllllkko...",
"obbblllllkko....", ".obbbllllko.....", "..oobbbkko......", ".....oqo........", ".....oqo........",
"....oqqqo......."])
S["rampartguard"] = ("main:#4a6a4a skin:#7ab04a", OV(M([
"...ooo", "..o998", "..o988", "..o505", "..o455", ".o33o5", "o3o322", "o3o3q2", "o5o322", ".oo322",
"..o32o", "..ooo."]), {5: ".........ooo", 6: "..........99", 7: "..........99", 8: "..........99", 9: "..........88",
 10: ".........ooo"}))
S["sludgecrawler"] = ("main:#5a8a3a second:#2a4a2a glow:#ff4a3a", M([
"......", "......", "......", "......", "......", "...ooo", "..o3c2", ".o3y22", "o33c22", "o32222",
"oo0oo0", "o.o.o."]))
S["chainwarden"] = ("main:#7a7a8a glow:#ff4a3a", [r + e for r, e in zip(M([
"...ooo", "..o322", ".o3222", ".o30y0", ".o3000", ".o33o2", "o3o322", "o3o322", "o5o322", ".oo322",
"..o32o", "..ooo."]), [".", ".", ".", ".", ".", ".", ".", "o", "9", "8", "9", "o"])])
S["tidecaller"] = ("main:#3a5aa0 skin:#5a9a5a glow:#7ff0ff", OV(M([
"..ooo.", ".o5y5o", ".o5555", ".o5ooo", "..o555", ".o33o5", "o3o322", "o3o3q2", "o5o322", ".o3222",
".o3222", ".ooooo"]), {0: "...........y", 1: "...........u", 2: "...........u", 3: "...........u",
 4: "...........u", 5: "...........u", 6: "...........u", 7: "...........u"}))
S["longpike"] = ("main:#c0a040 skin:#d89a70", OV(M([
"...ooo", "..o998", "o99888", "..o505", "..o455", ".o33o5", "o3o323", "o3o232", "o5o322", ".oo322",
"..o32o", "..ooo."]), {0: "...........9", 1: "...........8", 2: "...........u", 3: "...........u", 4: "...........u",
 5: "...........u", 6: "...........u", 7: "...........u", 8: "...........5", 9: "...........u", 10: "...........u"}))
S["rotking"] = ("main:#4a8a4a second:#8a6a3a", M([
"....oqoq", "....oqqq", "..o32222", ".o32y222", ".o322222", ".o3ooooo", ".o322b22", "..o32222",
".o988888", "o5o98888", "o8o88q88", ".oo98888", "..o98888", "..o988oo", "..o88o..", "..ooo..."]))
S["tidecaptain"] = ("main:#6a4a32 second:#2a2433 skin:#6a9a5a glow:#ffe060", M([
"...ooooo", ".obbbbbb", "..obbbbb", "...o5555", "...o5y55", "...o5555", "....o555", "..o33o22",
".o333q22", "o5o33222", "o3o32222", ".oo32222", "..o32222", "..o322oo", "..o00o..", "..ooo..."]))
S["shellpriest"] = ("main:#b03030 skin:#e0a47a", [r + e for r, e in zip(M([
"...ooo", "..o332", ".o3322", ".o3505", ".o3455", ".o33o5", "o3o3q2", "o3o322", "o5o322", ".o3222",
".o3222", ".ooooo"]), ["...", "...", "...", "...", "...", "...", "...", "ooo", "989", "u..", "...", "..."])])
S["dervish"] = ("main:#c03a3a skin:#d89a70", M([
"....oo", "...o32", "...o32", "..o505", "..o455", "o55o32", ".oo332", "..o322", ".o3222", "o33222",
"oqqqqq", ".ooooo"]))
S["deacon"] = ("main:#c8b088 skin:#e0a47a", M([
"...qqq", "..q...", "...ooo", "..olll", "..ol05", ".ollo5", "olllll", "olllql", "o5llqq", ".ollql",
".ollll", ".ooooo"]))
S["beltfeeder"] = ("main:#7a6a5a glow:#ff4a3a", M([
"......", "......", ".ooooo", ".o9888", ".o98y8", ".o9888", ".oqrqr", ".o0000", ".oqrqr", ".o9888",
".o8o..", ".oo..."]))
S["beltlink"] = ("main:#7a6a5a", M([
"......", "......", "......", "......", "......", "......", "....oo", "...oqr", "...oqq", "..o8qq",
"...o88", "...oo."]))
S["ammomimic"] = ("main:#8a5a32 glow:#ff4a3a", M([
"......", "......", "......", ".ooooo", ".ouuuu", ".ouuuq", ".o0l0l", ".o00y0", ".ol0l0", ".ouuuu",
".ouuuu", ".ooooo"]))
S["highcaliber"] = ("main:#b03030 skin:#e0a47a", OV(M([
"......oo", ".....oqr", "....oqrq", "....oqqq", "....o505", "....o455", "...o33o5", "..o3o322",
"..o3o3q2", "..o5o322", "...oo322", "...o3222", "...o3222", "...o322o", "...o00o.", "...ooo.."]),
{9: "............9999", 10: "............88.."}))
S["bellringer"] = ("main:#5a2a7a", OV(M([
"....oooo", "...o3322", "..o33222", "..o3l0ll", "..o3llll", "..o30l0l", ".o33o222", "o3332222",
"o3o32222", "o5o32222", ".oo32222", ".o322222", ".o322222", ".o322222", "o3222222", "oooooooo"]),
{10: ".............oo.", 11: "............oqqo", 12: "...........oqrqo", 13: "...........ooooo"}))
S["stormcrown"] = ("main:#5a5a78 glow:#7ff0ff", OV(M([
"........oqoq", "........oqrq", "......oooooo", "....oo333322", "...o33333222", "..o333222222",
".o3332222222", ".o3322yy2222", "o33322yy2222", "o33222222222", "o33222200000", "o33222200000",
"o33222222222", ".o3322222222", ".o2222222222", "..oooooooooo", "............", "............",
"............", "............", "............", "............", "............", "............"]),
{16: "....y..............y....", 17: "...yx..............xy...", 18: "....y..............y....",
 19: "...y................y...", 20: "..y..................y.."}))
S["bilgehydra"] = ("main:#4a8a5a second:#3a7ab0 glow:#ffe060", M([
"..........oo", "..oo.....o33", ".o33o...o3y2", "o3y22o..o322", "o3222o..o322", ".o000o..o300",
"..o22o..o322", "..o32o..o322", "...o32o.o322", "....o32oo322", "....oo32o322", "....oo332222",
"...o33222222", "..o332222222", "..o3222c2222", ".o3322222222", ".o3222222c22", "o33222222222",
"o32222222222", "obbbbbbbbbbb", "obcbbbbcbbbb", ".obbbbbbbbbb", "..oooooooooo", "............"]))

def _organ():
    W, H = 41, 28
    g = [["."] * W for _ in range(H)]
    def put(x, y, c):
        if 0 <= x < W and 0 <= y < H:
            g[y][x] = c
    # brass pipes, tallest in the middle, mirrored
    for px, top in [(2, 7), (5, 5), (8, 3), (11, 2), (14, 1), (17, 0)]:
        for x0 in (px, W - 2 - px):
            for y in range(top, 11):
                put(x0 - 1, y, "o"); put(x0 + 2, y, "o")
                put(x0, y, "r" if y > top else "o"); put(x0 + 1, y, "q" if y > top else "o")
            put(x0, top + 2, "0"); put(x0 + 1, top + 2, "0")
    for y in range(0, 11):   # the centre pipe
        for x in (19, 20, 21):
            put(x, y, "o" if y == 0 else ("r" if x == 19 else "q" if x == 20 else "p"))
        put(18, y, "o"); put(22, y, "o")
    put(19, 2, "0"); put(20, 2, "0"); put(21, 2, "0")
    # the wooden case
    for y in range(10, 26):
        for x in range(0, W):
            edge = x == 0 or x == W - 1 or y == 10 or y == 25
            put(x, y, "o" if edge else ("w" if x < 3 else "u" if x > W - 4 else "v"))
    for x in range(1, W - 1):
        put(x, 11, "q"); put(x, 24, "q")
    # eyes: two glowing slits
    for ex in (9, 27):
        for x in range(ex, ex + 5):
            put(x, 14, "o"); put(x, 16, "o"); put(x, 15, "y" if ex + 1 <= x <= ex + 3 else "x")
        put(ex - 1, 15, "o"); put(ex + 5, 15, "o")
    # the keyboard mouth
    for x in range(6, W - 6):
        put(x, 18, "o"); put(x, 22, "o")
        for y in (19, 20, 21):
            put(x, y, "l" if (x % 3) else "0")
        if x % 3 == 0:
            put(x, 21, "l")
    for y in range(18, 23):
        put(5, y, "o"); put(W - 6, y, "o")
    # feet
    for fx in (4, W - 9):
        for x in range(fx, fx + 5):
            put(x, 26, "o" if x in (fx, fx + 4) else "u"); put(x, 27, "o")
    return ["".join(r) for r in g]
S["brassorgan"] = ("main:#6a4a2a glow:#ff4a3a", _organ())

for _n in ["gangster", "biker", "riotcop", "outlaw", "dynamiter", "sharpshooter", "rampartguard", "tidecaller",
		"longpike", "dervish", "deacon"]:
	ELITE[_n] = dict(_HUM)
ELITE["chainwarden"] = {0: "...q.qq.q....", 5: ".q........q.."}
ELITE["shellpriest"] = {0: "...q.qq.q......", 5: ".q........q...."}
for _n in ["kingpin", "marshal", "galewarden", "rotking", "highcaliber"]:
	ELITE[_n] = {1: "..q..........q..", 6: "q..............q"}
ELITE.update({
	"coyote": {3: ".q.q........"},
	"skykite": {0: "....q..q...."},
	"gustling": {1: "..qoooooq..."},
	"stormharpy": {1: "..qoooooq..."},
	"thunderhead": {1: "..qoooooq..."},
	"mirrorwing": {0: "qq........qq"},
	"sludgecrawler": {5: "..qoooooq..."},
	"beltfeeder": {2: "qoooooooooq."},
	"beltlink": {6: "...qoooq...."},
	"ammomimic": {3: "qoooooooooq."},
})
for _n in ["squallheron", "tidecaptain", "bellringer"]:   # rift minis have elites too
	ELITE[_n] = {1: "..q..........q..", 6: "q..............q"}

# ---- 5.3e: the special ones. Rex is his own dog, drawn from his photos: never redesigned, only
# recoloured into the look (REMASTER, from the originals kept in tools/art/src/).
REMASTER = ["rex", "rex_lie"]
S["dummy"] = ("main:#8a6a3a", M([
"...ooo", "..ovvv", "..ov0v", "..ovvv", "...ouu", "ouuuvv", "oooovv", "...ovv", "...ovv", "....ou",
"....ou", "....ou", "...ouu", "..oooo"]))
S["target"] = ("main:#c03a3a second:#c03a3a", M([
"...ooo", "..obbb", ".oblll", ".oblbb", ".oblbq", ".oblbq", ".oblbb", ".oblll", "..obbb", "...ooo",
".....u", ".....u", "....ou", "...ooo"]))
S["tombspider"] = ("main:#4a2a5a glow:#ff4a3a", M([
"......", "......", "o.....", ".o..oo", "..oo33", "ooo3y2", "..o322", "ooo322", ".o.o32", "o...oo",
"......", "......"]))
S["candlewight"] = ("main:#c8b088 bone:#f0e8d0 glow:#ffd060 halo:1", M([
".....y", "....yx", "....oy", "...oll", "..ol0l", "..olll", "..oll0", ".ollll", "..olll", "..olll",
".oqqqq", "..oooo"]))
S["gargoyle"] = ("main:#8a8a9a glow:#ff4a3a", [
"o..o....o..o", "oo.oo..oo.oo", "o3oo3333oo1o", "o33oy22yo11o", "o332o22o211o", ".o33o00o11o.",
"..oo3221oo..", "..o322221o..", ".o3o3221o1o.", ".o3o3221o1o.", ".oo.o21o.oo.", "..oooooooo.."])
S["wardrummer"] = ("main:#6a4a32 skin:#7ab04a", M([
"...ooo", "..o655", "o.o555", "..o505", "..o5l5", ".o33o5", "o3o322", "o3oqqq", "o5ovvv", "o3ovvv",
".ooqqq", "..ooo."]))
S["bloodleech"] = ("main:#a02a3a", M([
"......", "......", "......", "...ooo", "..o332", ".o3322", "o33o00", "o32o00", "o32222", ".o3222",
"..oooo", "......"]))
S["casingrat"] = ("main:#7a7a8a second:#e09090 glow:#ff4a3a", M([
"......", "......", "......", ".oo...", "o3o.oo", "o33o32", ".o3y22", "..o32b", ".o3322", "o3o322",
".ooqqq", "..o.o."]))
S["scrounger"] = ("main:#8a8a9a second:#e09090 skin:#e0a0a0 glow:#ffe060", OV(M([
"...ooo", "..ouvv", ".ouvvv", ".ou8y8", "..o332", "...o3b", "o3ouvv", "o3ovvv", "o5ovvv", ".oovvv",
"..o32o", "..ooo."]), {9: "...........b"}))
S["goblin"] = ("main:#6a4a32 skin:#6ab04a", OV(M([
"......", "...ooo", "oo.o55", "o5o555", ".oo505", "..o4ll", ".o33o5", "o3o322", "o5o322", ".oo322",
"..o32o", "..ooo."]), {7: "..........oq", 8: "..........qq", 9: "..........qo"}))
S["mimic"] = ("main:#8a5a32 second:#c03a3a glow:#ffe060", M([
"......", "......", ".ooooo", ".owvvv", ".oqqqq", ".ol0l0", ".o0y00", ".o000b", ".ol0l0", ".ovvvv",
".oqqqq", ".ooooo"]))
S["shadow"] = ("main:#2a1a3a glow:#c08aff", M([
"....oo", "...o32", "..o322", "..o3y2", "..o322", "..o322", "...o32", "o3o322", "o3o322", "o3o322",
".oo322", "..o32o", "..o32o", "..ooo."]))
S["haggler"] = ("main:#6a3a7a second:#c0803a skin:#c08a5a", M([
"...ooooo", "..o33332", ".o333322", "o3qqqqqq", "o2222222", "...o5055", "...o5555", "...o5jjj",
"..o3jjjj", ".o3c3222", "o5o32c22", "o3o3c222", ".oo32222", "..o322oo", "..ouuo..", "..ooo..."]))
S["holycow"] = ("main:#c8c0b0 second:#f0a0b0 glow:#ffd84a", M([
"...qqqqq", "..q.....", ".l.ooooo", ".loll0ll", "..ol0lll", "..olllll", "..olbbbb", "..olb0bb",
"...obbbb", ".ollll0l", "olll0lll", "ol00llll", "olllllll", ".ollllbb", ".o0o.o0o", ".ooo.ooo"]))
S["judge"] = ("main:#e8b84a", OV(M([
"......oo", ".....oqr", "l...oqqq", "ll..oq0q", "lll.oqqq", "lllloooq", ".llollll", "..olllql",
"..olllll", "..olllll", "..olllll", "..ollqll", ".ollllll", ".ollllll", "olllllll", "oooooooo"]),
{8: "o9o.............", 9: "9.9.............", 10: "q.q.............", 11: "qqq............."}))
S["cinderking"] = ("main:#b03030 metal:#4a3a3a skin:#c04030 glow:#ffa040", M([
"..y..y.y", "...oqyqy", "...oqqqq", "..o32222", "..o32y22", "..o32222", "..o320xx", ".o98o322",
"o98o3222", "o8o322y2", "o5o32222", ".oo32222", "..o32222", "..o988oo", "..o88o..", "..ooo..."]))
S["unwritten"] = ("main:#1a1420 bone:#f4ecd8 glow:#e0e0ff", [
"......oooo......", ".....oll00o.....", "....olll000o....", "...ollll0000o...", "...ol0ll00y0o...",
"...ollll0000o...", "...olll0l000o...", "..ollll000000o..", ".ollllll000000o.", "olllllll0000000o",
"olllllll0000000o", ".ollllll000000o.", ".ollllll000000o.", "olllllll0000000o", "olllllll0000000o",
"oo.oo.oooo.oo.oo"])
for _n in ["wardrummer", "scrounger", "goblin"]:
	ELITE[_n] = dict(_HUM)
ELITE["haggler"] = {1: "..q..........q..", 6: "q..............q"}
ELITE.update({
	"tombspider": {3: "qo..oooo..oq"},
	"candlewight": {10: "qoqqqqqqqqoq"},
	"gargoyle": {0: "q..o....o..q"},
	"bloodleech": {3: "..qooooooq.."},
	"casingrat": {3: "qoo......ooq"},
	"mimic": {2: "qooooooooooq"},
	"shadow": {0: "...q.oo.q..."},
	"dummy": {0: "..qoooooq..."},
	"target": {0: "..qoooooq..."},
})

# ---- 5.3c, his picks (6 Oct). Old design kept, pixel for pixel, recoloured (REMASTER); for drone
# and chrome the elite is the new drawing, for the rest the elite is the old design too.
for _n in ["drone", "chrome"]:
	S[_n + "_new"] = S.pop(_n)
	ELITE[_n + "_new"] = ELITE.pop(_n)
	ELITE_SRC[_n] = _n + "_new"
REMASTER_ELITE = ["turret", "copper", "robovac", "burglar", "gnome", "turnkey", "carrionknight"]
for _n in REMASTER_ELITE:
	S.pop(_n); ELITE.pop(_n, None)
REMASTER += ["drone", "chrome"] + REMASTER_ELITE
GENTLE = ["rex", "rex_lie"]   # his dog: the lightest touch

# ---- 5.3d, his picks (6 Oct): old design kept for both the foe and its elite.
for _n in ["sludgecrawler", "kingpin", "marshal", "galewarden", "tidecaptain"]:
	S.pop(_n); ELITE.pop(_n, None)
	REMASTER.append(_n); REMASTER_ELITE.append(_n)
ELITE["squallheron"] = {0: "........qrq....."}

# ---- 5.3e, his picks (6 Oct): old design kept (recoloured); dummy and goblin for their elites too.
for _n in ["dummy", "goblin", "holycow", "cinderking"]:
	S.pop(_n); ELITE.pop(_n, None)
	REMASTER.append(_n)
REMASTER_ELITE += ["dummy", "goblin"]

# ---- His ask (6 Oct): the town and shop people remodelled before the stage-5 IPA. Hero rows
# (12x14): head 0-6, body 7-10, legs 11, feet 12, ground 13.
S["npc_attendant"] = ("main:#3a4a7a second:#c0403a skin:#f0c8a0", M([
"..oooo", "..olll", "..ovvv", "..ov55", "..o505", "..o455", "...o55", "o5olbl", "o5oblb", "o5olbl",
".oo322", "..o32o", "..o00o", "..ooo."]))
S["npc_bartender"] = ("main:#2a2a35 second:#c0403a skin:#e0b090", M([
"...ooo", "..o000", "..o055", "..o505", "..o5jj", "..o455", "...olb", "o5o0ll", "o5o0ll", "o5o0ll",
".oo322", "..o32o", "..o00o", "..ooo."]))
S["npc_broker"] = ("main:#6a3a7a skin:#d89a70", OV(M([
"...ooo", "..ouvv", "ouuuuu", "..o505", "..o455", "..o455", "...o55", "o3o3q2", "o3o322", "o5o3q2",
".oo322", "..o32o", "..ouuo", "..ooo."]), {3: "...00.......", 4: ".........q.."}))
S["npc_courier"] = ("main:#3f7a4a second:#c0403a skin:#c88a5a", M([
"...ooo", "..obbb", ".obbbb", "..o555", "..o505", "..o455", "...o55", "o3o3u2", "o3o32u", "o5o322",
".oo322", "..o88o", "..ouuo", "..ooo."]))
S["npc_drunk"] = ("main:#6a4a3a second:#5a8a4a skin:#e0a47a", [
"..............", "..............", "..............", "..oooo........", ".o0005oooooooo", ".o0555o3322uuo",
".oo55oo2221uuo", "..ooooooooooo.", "......ocbo....", ".......oo....."])
S["npc_fisher"] = ("main:#e0b030 second:#3a7ab0 skin:#e0a47a", [
".............u", ".............u", "....oooo.....u", "...o3332o...u.", ".o33333221o.u.", "...o5055o...u.",
"...ojjjjo..u..", ".o33ojjo11ou..", "o3o322221o5u..", "o3o3q2q21o....", "o5o322221o....", ".oo322221oo...",
"..o32oo21o....", "..ouuoouuo....", "..ooo..ooo....", "..bbbbbbbbbb.."])
S["npc_mechanic"] = ("main:#3a6ab0 second:#e8873a skin:#d89a70", OV(M([
"...ooo", "..obbb", ".obbbb", "..o555", "..o505", "..o455", "...o55", "o5o3q2", "o5o322", "o8o322",
".oo322", "..o32o", "..o00o", "..ooo."]), {5: "........0..."}))
S["npc_merchant"] = ("main:#3f7a4a second:#c0403a skin:#e0a47a", OV(M([
"...ooo", "..o332", "o33322", "..o555", "..o505", "..o5jj", "...o55", "o5ovvq", "o5ovvv", "o5ouvv",
".oovvv", "..o32o", "..ouuo", "..ooo."]), {0: "........b...", 1: ".........b.."}))
S["npc_pitboss"] = ("main:#2a2a35 skin:#e0b090", M([
"...ooo", "..o000", "..o055", "..o555", "..o500", "..o455", "...o55", "o3o3lq", "o3o322", "o5o322",
".oo322", "..o32o", "..o00o", "..ooo."]))
S["npc_teller"] = ("main:#7a3a4a second:#3f8a5a skin:#f0c8a0", M([
"...ooo", "..ovvv", ".obbbb", "..o555", "..o909", "..o455", "...o55", "o5o3ll", "obo32l", "o5o322",
".oo322", "..o32o", "..o00o", "..ooo."]))
# His picks (6 Oct): the broker keeps its old design (recoloured from src/rooms); a better drunk:
# flat on his back, belly up, red nose, stubble, closed eyes, bottle on the floor by his hand.
S.pop("npc_broker")
S["npc_drunk"] = ("main:#c8b890 second:#4a9a5a glow:#e04040 skin:#e0a47a", [
"..........y...", "..oooo....yx..", ".ouvvuo..ooo..", ".ov555ooo333o.", ".o5005o333322o", ".o5yy5o322222o",
".ojjj5o322221o", "..o5ooooo22uuo", ".ocbbco...ouuo", "..oooo....ooo."])
def _lying(stand):   # a standing sprite turned a quarter left: head on the left, flat on the floor
    W = len(stand[0])
    return ["".join(row[x] for row in stand) for x in reversed(range(W))]
S["npc_drunk"] = ("main:#c8b890 second:#4a9a5a glow:#e04040 skin:#e0a47a", OV(_lying([
"...oooo...", "..ouvvuo..", ".ov5555vo.", ".o505505o.", ".o55yy55o.", ".ojjjjjjo.", "..ojjjjo..",
"o5o3222o5o", "o5o3222o5o", ".oo3222oo.", ".o322221o.", "..o2oo1o..", "..ouoouo..", "..oo..oo.."]),
{0: ".......ocbbo..", 1: "........oo...."}))

# His ask (6 Oct): Brazil's human robber, a wasteland raider: scavenged hood, glowing goggles, a rust
# scarf over the mouth, spiked shoulder pads, a pipe.
S["raider"] = ("main:#8a7a5a second:#a04a2a glow:#ffa040 skin:#d89a70", OV(M([
"...ooo", "..ovvv", ".ovvvv", ".ov8y8", "..obbb", ".o98ob", "o3o322", "o3ouuq", "o5o322", ".oo322",
"..o32o", "..ooo."]), {8: "..........9."}))
ELITE["raider"] = dict(_HUM)

# ---- 6.4 (his ask, 6 Oct): THE CLOCKWORK SPIRE, its champion and guardian, THE CLOCKMAKER, and the
# clockwork weapons.
S["cogling"] = ("main:#8a6a3a glow:#ff4a3a", M([
"...o.o", "..oqqq", ".oqrqq", "oqro00", "oqq0yx", "oqq0yy", "oqro00", ".oqqqq", "..oqqq", "...o.o",
"......", "......"]))
S["steamjack"] = ("main:#8a6a4a glow:#ffa040", M([
"....oo", "....o8", "..o988", ".o98y8", ".o9888", "o9o988", "o9o8yx", "o8o8yy", "o8o988", ".oo988",
"..o98o", "..ooo."]))
S["boltslinger"] = ("main:#3a6a7a glow:#7ff0ff", OV(M([
"...ooo", "..o999", "..o9yy", "..o888", "...o88", ".o98o3", "o9o322", "o9o3q2", "o8o322", ".oo322",
"..o98o", "..ooo."]), {8: "..........99"}))
S["gearhound"] = ("main:#8a6a3a glow:#ff4a3a", [
"............", "............", "............", ".o.o........", "oqoqo.......", "oqqqqo......",
"o0qyqqoooooo", ".oqq9q9q9qpo", "..oqqqqqqqpo", "..o8o..o8o..", "..o8o..o8o..", ".oo....oo..."])
S["rivetlobber"] = ("main:#7a5a3a glow:#ffa040 skin:#d89a70", OV(M([
"...ooo", "..o888", "..o800", "..o80y", "..o888", ".o33o5", "o3ouvv", "o3ovvv", "o5ovvv", ".oovvv",
"..o32o", "..ooo."]), {4: ".........qq."}))
S["brasswasp"] = ("main:#2a2a35 glow:#ff4a3a", M([
"oo....", "llo.oo", ".lloqq", "..oqy0", "..o0q0", "..oq0q", "...o0q", "....oq", ".....9", "......"]))
S["foreman"] = ("main:#3a5a9a second:#e8873a skin:#d89a70", OV(M([
"....oooo", "...oqrrq", "..oqqqqq", ".opppppp", "...o5555", "...o5055", "...o5jjj", "...oo555",
".o33bblb", "o333bbbb", "o5o3bbbb", "o3o3bblb", ".oo32222", "..o322oo", "..ouuo..", "..ooo..."]),
{9: "..............o9", 10: "...............9", 11: "...............8"}))
S["greatengine"] = ("main:#6a4a2a glow:#ffa040", M([
"..oo..oo", "..o9..o9", "..o8oo88", ".oqqqqqq", "oq9yy9q8", "oq9999q8", "oqqqqqqq", "o88o0xxx",
"o88o0xyy", "o88o0000", "oqqqqqqq", "o9o98888", "o9o98888", "o8o98888", ".o9888o.", ".ooooo.."]))
S["clockmaker"] = ("main:#6a4a3a second:#2a2433 bone:#c8c8d0 glow:#fff07a skin:#e0a47a", OV(M([
"...ooo", "...obb", ".o0000", "..oj55", "..o505", "..o5jj", "...ojj", "o5o3q2", "o3o322", "o5o322",
".oo322", "..o32o", "..o00o", "..ooo."]), {4: "......9y9..."}))
S["w_gearwound"] = ("main:#6b4a2a", [
"............", "....ooo.....", "...oqrqo....", ".ooooqoooooo", "o9999999999o", ".oooouvoooo.",
"....ouvo....", "....ouuo....", ".....oo.....", "............", "............", "............"])
S["w_pendulum"] = ("main:#6b4a2a", [
"o...........", ".8..........", "..8.........", "...8........", "....8.......", ".....8......",
"......ooo...", ".....o999o..", ".....o9889o.", "......o98o..", ".......oo...", "............"])
S["w_springlance"] = ("main:#6b4a2a", [
"..........o9", ".........o9o", "........o9o.", ".......oqo..", "......oqqo..", ".....oqo....",
"....ouo.....", "...ouo......", "..ouo.......", ".ouo........", "ouo.........", "oo.........."])
S["w_cogthrower"] = ("main:#6b4a2a", [
"....oooo....", "..oo.qq.oo..", "..oqqqqqqo..", ".oqqo99oqqo.", "oqqo9..9oqqo", "oqqo9..9oqqo",
".oqqo99oqqo.", "..oqqqqqqo..", "..oo.qq.oo..", "....oooo....", "............", "............"])
S["w_steamcannon"] = ("main:#6b4a2a", [
"..........ll", ".........lkl", "........ooo.", "ooooooooo9o.", "o999999999o.", "o888888888o.",
"ooouuoooooo.", "..ouuo......", "..ouuo......", "..oooo......", "............", "............"])
S["w_chronoblade"] = ("main:#6b4a2a glow:#fff07a", [
"...........o", "..........o9", ".........o9o", "........o9o.", ".......o9o..", "......o9o...",
".oo..o9o....", "oqrqo9o.....", "oqyqo.......", "oqqqo.......", "..ouo.......", ".ouo........"])
S["w_tickbomb"] = ("main:#c0403a glow:#ffe060", [
".....oo.....", ".....o9o....", "....oyxo....", "...oo99oo...", "..o333332o..", ".o33lll22o..",
".o3llol22o..", ".o33lll22o..", "..o33222o...", "...o1111o...", "....oooo....", "............"])
S["w_escapement"] = ("main:#6b4a2a", [
"............", "............", "............", "oooooooooooo", "o9999999999o", "ouuuuuqoooo.",
"ouuuuoqo....", ".oooo.o.....", "............", "............", "............", "............"])
S["w_enginecore"] = ("main:#6b4a2a glow:#ffa040 halo:1", [
"........ooo.", ".......oyxyo", "......oyxxyo", ".......oyyo.", "......ouo...", ".....ouo....",
"....ouo.....", "...ouo......", "..ouo.......", ".ouo........", "ouo.........", "oo.........."])
S["g_foremanhat"] = ("main:#e8873a", [
"............", "....oooo....", "...oqrrqo...", "..oqrrqqqo..", "..oqqqqqpo..", ".oqqqqqqqpo.",
"oppppppppppo", "oooooooooooo", "............", "............", "............", "............"])
for _n in ["steamjack", "boltslinger", "rivetlobber"]:
	ELITE[_n] = dict(_HUM)
ELITE.update({
	"cogling": {0: "..q......q.."},
	"gearhound": {3: ".q.q........"},
	"brasswasp": {0: "qq........qq"},
	"foreman": {1: "..q..........q..", 6: "q..............q"},
})

# ---- 7.3 (his word "All", 6 Oct): THE RIMEFROST HOLLOWS, its champion and guardian, and their drops.
S["frostmite"] = ("main:#7ab8e0 glow:#e8fbff", M([
"o.....", "o3o..o", ".o3oo3", ".o33y3", "..o333", "..o220", "...o2o", "....o.", "......", "......"]))
S["rimebrute"] = ("main:#6a8aa8 glow:#bff4ff", M([
"...ooo", "..o333", ".o33y0", ".o3333", "oo3o33", "o3o322", "o3o322", "o2o322", ".oo222", "..o2oo",
"..o2o.", "..ooo."]))
S["shardcaster"] = ("main:#3a5a8a glow:#7ff0ff", OV(M([
"....oo", "...o33", "..o333", "..o0y0", "..o000", ".o33o3", "o3o322", "o3o322", "o3o322", ".oo322",
"..o32o", "..ooo."]), {0: "..........y.", 1: ".........yxy", 2: "..........9.", 3: "..........9.", 4: "..........9."}))
S["frostfang"] = ("main:#a8bccc glow:#7ff0ff bone:#e8f4ff", [
"............", "............", "............", ".o.o........", "o3o3o.......", "o3333o......",
"o0y33ooooooo", ".o33232323lo", "..o3333333lo", "..o2o..o2o..", "..o2o..o2o..", ".oo....oo..."])
S["snowlobber"] = ("main:#d8e8f4 glow:#7ff0ff skin:#9ab0c8 bone:#ffffff", OV(M([
"...ooo", "..o333", "..o355", "..o35y", "..o333", ".o33o5", "o3ouvv", "o3ovvv", "o5ovvv", ".oovvv",
"..o32o", "..ooo."]), {4: ".........ll."}))
S["glimmerwisp"] = ("main:#6fb8e8 glow:#dff8ff halo:1", M([
"....o.", "...oyo", "..oyxy", ".oy3xx", ".oy303", "..oy33", "...oy3", "....oy", ".....o", "......"]))
S["hoarknight"] = ("main:#4a6a9a glow:#8fe8ff", M([
"......oo", ".....o99", "....o998", "...o9888", "...o0yy0", "...o8888", "..oo9888", ".o99o888",
"o9993322", "o9o33322", "o8o3xx22", "o8o33222", ".oo32222", "..o322oo", "..o99o..", "..ooo..."]))
S["glacialmaw"] = ("main:#5a8ab8 glow:#bff4ff bone:#e8f4ff", M([
"..o...oo", ".o3o.o33", ".o33o333", "o3333333", "o33yx333", "o3333333", "o2oooooo", "o2ojkojk",
"o20000x0", "o2000000", "o2ojkojk", "o2oooooo", "o2222222", ".o122222", "..o11111", "...ooooo"]))
S["w_glacierheart"] = ("main:#5a7a9a glow:#8fe8ff halo:1", [
"........ooo.", ".......oyxyo", "......oyxxyo", ".......oyyo.", "......o9o...", ".....o9o....",
"....o9o.....", "...o9o......", "..o9o.......", ".o9o........", "o9o.........", "oo.........."])
S["g_hoarhelm"] = ("main:#8fb8d8 glow:#7ff0ff", [
"............", "..o..oo..o..", ".o9oo99oo9o.", ".o99999999o.", ".o98888889o.", ".o8oyooyo8o.",
".o88888888o.", ".o8o8888o8o.", "..oo8888oo..", "....oooo....", "............", "............"])
for _n in ["rimebrute", "shardcaster", "snowlobber"]:
	ELITE[_n] = dict(_HUM)
ELITE.update({
	"frostmite": {0: ".q........q."},
	"frostfang": {3: ".q.q........"},
	"glimmerwisp": {0: "q..........q"},
	"hoarknight": {0: ".....q....q.....", 7: "q..............q"},
})

# ---- 8.1 (his ask, 6 Oct): the four alignment icons (stars, shrines, the HUD, coloured text).
S["al_good"] = ("main:#e8b030 glow:#fff3b0", M([
"....o.", ".o..o3", "..oo33", "..o3yy", "oo33yx", "..o3yy", "..oo33", ".o..o3", "....o.", "......"]))
S["al_evil"] = ("main:#b8302a glow:#ffb040 bone:#e8dcc8", M([
"o.....", "ojo...", ".ojooo", "..olll", "..ol0y", "..olll", "...olk", "...oko", "....oo", "......"]))
S["al_law"] = ("main:#4ab8c8 glow:#c8f8ff", M([
".....y", "o33333", "3....3", "3....3", "333..3", ".3...3", ".....3", "...333", "......", "......"]))
S["al_chaos"] = ("main:#7a3ab0 glow:#e0a8ff", [
"............", "...oooooo...", "..o333333o..", ".o3oooooo3o.", ".o3o3333o3o.", ".o3o3oyo3o..",
".o3o3o.o3o..", ".o3o33oo3o..", ".o3oooo33o..", "..o33333oo..", "...ooooo....", "............"])

# ---- 9.3 (his ask, 6 Oct, from another game's boss roster: ideas only, original designs): the
# second guardians and their drops.
S["admiral"] = ("main:#8a6a4a second:#2a3a7a skin:#c8a080 bone:#f4ecd8 glow:#ffffff", M([
"....oooo", "...obbbb", "..obbbqb", ".ooooooo", "..o33333", ".o3y0333", ".o333322", "o3335555",
"o33o5o55", "o3ojo355", ".oojbbbb", ".obbbqbb", "o3bbbbbb", "o3obbbqb", ".oobbbbb", "..oooooo"]))
S["golemking"] = ("main:#7a7f8c glow:#ffb040", M([
"..q.q.q.", "..qqqqqq", "..oooooo", ".o333333", ".o30x333", ".o333333", "oo222222", "o33o2222",
"o33o2y22", "o22o2222", "o22o2222", ".oo22222", "..o222oo", "..o22o..", ".o222o..", ".ooooo.."]))
S["archmage"] = ("main:#3a4a9a glow:#7ff0ff bone:#e8e8f0", M([
".......o", "......o3", ".....o33", "....o333", "...o3333", "..oooooo", "...o0y00", "...ollll",
"..olllll", ".o33olll", "o333olll", "o3o32222", "o3o32xx2", ".oo32222", "..o32222", "..oooooo"]))
S["phoenix"] = ("main:#e8873a second:#d8443c glow:#fff07a", M([
"......oo", ".....oyx", "o...o3yy", "oo..o333", "o3o.o303", "o33oo333", ".o33o333", ".o333333",
"..o33333", "...oaaa3", "..oaa3aa", ".oaa.oa3", "oaa..oa.", "oa...o..", "o.......", "........"]))
S["wyrm"] = ("main:#c8d8e8 glow:#7ff0ff bone:#ffffff", M([
"o.......", "o3o.....", ".o3o..oo", ".o33oo33", "..o33333", "o.o3y033", "o3o33333", "o33o3333",
"o333o222", ".o33o2ll", "..o3o2l2", "...o3222", "...o3333", "..o33oo3", "..o3o..o", "..oo...."]))
S["chainfiend"] = ("main:#a8282a glow:#ffb040 bone:#e8dcc8", M([
"o.......", "jo......", "jjo..ooo", ".jjoo333", "..o33333", "..o3x033", "..o33333", "..oo3l3l",
"oo9o3333", "o9o33333", "o8o32222", "o9o32222", ".oo32222", "..o322oo", "..o32o..", "..ooo..."]))
S["seraph"] = ("main:#f4ecd8 skin:#f0c8a0 glow:#fff07a halo:1", M([
"....qqqq", "...q....", "o...qqqq", "3o...ooo", "33o.o555", "o33o5y55", ".o33o555", "o333o333",
"33333o33", ".o333o33", "o333o333", "33o.o3q3", "o...o333", "....o333", "....o3oo", "....oo.."]))
S["w_archstaff"] = ("main:#6b4a2a glow:#7ff0ff halo:1", [
"........ooo.", ".......oyxyo", "......oyxxyo", ".......oyyo.", "......ouo...", ".....ouo....",
"....ouo.....", "...ouo......", "..ouo.......", ".ouo........", "ouo.........", "oo.........."])
S["w_wyrmfang"] = ("main:#c8e0f0 glow:#7ff0ff", [
"...........o", "..........o3", ".........o3o", "........o3o.", ".......o3o..", "......o3o...",
".oo..o3o....", "o99oo3o.....", "o9yo3o......", "o99oo.......", "..ouo.......", ".ouo........"])
S["w_seraphlance"] = ("main:#f4ecd8 glow:#fff07a halo:1", [
"..........yo", ".........y3o", "........o3o.", ".......o3o..", "......oqo...", ".....oqo....",
"....o3o.....", "...o3o......", "..o3o.......", ".oqo........", "oqo.........", "oo.........."])
# 20.3: Chapter IV's guardian drops.
S["g_shelversarm"] = ("main:#8a5a2a second:#4d6aa8 glow:#f2c94c", [
"............", "....oooo....", "...o3333o...", "..o3o33o3o..", "..o333333o..", "..o333333o..",
"..oaaaaaao..", "..oa3y3aao..", "..oaaaaaao..", "...o3333o...", "...o3333o...", "....oooo...."])
S["w_hushbell"] = ("main:#2a3a6a wood:#6b4a2a glow:#9fe0ff halo:1", [
".....oo.....", "....ouuo....", ".....oo.....", "....o33o....", "...o3333o...", "..o333333o..",
"..o333333o..", ".o33333333o.", ".oyyyyyyyyo.", "..oooooooo..", ".....oo.....", ".....yy....."])
S["w_redpen"] = ("main:#d8443c gold:#f2c94c glow:#ff3a2a", [
"..........oo", ".........o3o", "........o33o", ".......o33o.", "......o33o..", ".....o33o...",
"....o33o....", "...oqqo.....", "..oqqo......", "..oqo.......", ".oyo........", ".o.........."])
# 12.4: Chapter II's guardian drops.
S["w_inkspout"] = ("main:#2a2a4a glow:#9ab8ff", [
"........ooo.", ".......o3y3o", "......o333yo", ".......o33o.", "......ouo...", ".....ouo....",
"....ouo.....", "...ouo......", "..ouo.......", ".ouo........", "ouo.........", "oo.........."])
S["w_authorspen"] = ("main:#f4ecd8 second:#2a2a4a glow:#f2c94c halo:1", [
"..........oo", ".........o3o", "........o33o", ".......o33o.", "......o33o..", ".....o33o...",
"....o33o....", "...oyyo.....", "..obbo......", "..obo.......", ".oyo........", ".o.........."])
S["g_binderthread"] = ("main:#c8a878 glow:#d8443c", [
"............", "....oooo....", "...o3333o...", "..o3o..o3o..", "..o3o..o3o..", "..o3o..o3o..",
"...o3oo3o...", "....o33o....", "....oyyo....", ".....oo.....", "............", "............"])
S["g_blackbar"] = ("main:#16141c glow:#ff3a4a bone:#e8e8f0", [
"............", "............", "............", "oooooooooooo", "o3333333333o", "o33y3333y33o",
"o3333333333o", "oooooooooooo", "............", "............", "............", "............"])
S["g_admiralhat"] = ("second:#2a3a7a", [
"............", "............", "...oooooo...", "..obbbbbbo..", ".obbbqqbbbo.", "obbbbqqbbbbo",
"oooooooooooo", "............", "............", "............", "............", "............"])
S["g_golemplate"] = ("main:#7a7f8c glow:#ffb040", [
"............", "..oo....oo..", ".o33oooo33o.", ".o33333333o.", "..o333333o..", "..o33y333o..",
"..o333333o..", "..o333333o..", "..o222222o..", "...oooooo...", "............", "............"])
S["g_phoenixplume"] = ("main:#e8873a glow:#fff07a", [
"........oo..", ".......o3yo.", "......o33yo.", ".....o333o..", "....o333o...", "...o333o....",
"..o333o.....", "..o33o......", ".o3oo.......", ".oo.........", "o...........", "............"])
S["g_fiendchains"] = ("main:#a8282a", [
"............", ".o99.o99.o9.", "o9oo9oo9oo9o", ".o99.o99.o9.", "............", "..oooooooo..",
".o33333333o.", ".o32222223o.", ".o33333333o.", "..oooooooo..", "............", "............"])

# ---- 10.2 (his ask, 6 Oct): the frog of THE FROG POND (with a tiny crown, of course).
S["frog"] = ("main:#4fae46 glow:#ffffff bone:#f4ecd8", M([
"....q.", "....qq", ".ooo..", "o3y0oo", "o3333o", "o3222o", ".o222o", "o3o22o", "oo.ooo", "......"]))

# ---- 10.3 (his ask, 6 Oct, from his trailer clips: ideas only): four new heroes and their weapons.
S["minstrel"] = ("main:#3a8a5a second:#a33a3a skin:#e0a47a bone:#f4ecd8", OV(M([
"...ooo", "..obbb", ".obbbb", "..o555", "..o505", "..o555", "...o55", "o3o333", "o3o3uv", "o5o3uv",
".oo333", "..o32o", "..o00o", "..ooo."]), {1: "........ll.."}))
S["jester"] = ("main:#7a3ab0 second:#f2c94c skin:#f0d0b0 bone:#ffffff", M([
"q....o", "oao.oa", ".oaaaa", "..o555", "..o505", "..o555", "...ojj", "o3oaa3", "o3o3a3", "o5oa3a",
".oo3a3", "..oa3o", "..o00o", "..ooo."]))
S["berserker"] = ("main:#8a3a2a skin:#d89a70 bone:#e8dcc8", M([
"o.....", "jo.ooo", "ojo999", "..o999", "..o505", "..o555", ".ollll", "o3olll", "o3o322", "o5o322",
"o5o322", ".oo322", "..o32o", "..ooo."]))
S["forsaken"] = ("main:#5a5560 glow:#c8c8d0", M([
"...ooo", "..o888", ".o8888", ".o8o00", ".o8o0y", ".o8o00", ".o8888", "o8o877", "o5o877", "o5o878",
".oo877", "..o87o", "..o00o", "..ooo."]))
S["w_lute"] = ("main:#8a5a2a", [
"..........oo", ".........o9o", "........o9o.", ".......ouo..", "......ouo...", "..ooooouo...",
".ouuuuuuo...", "ouvvo0vuo...", "ouv000vuo...", "ouvvo0vuo...", ".ouuuuuo....", "..ooooo....."])
S["w_jugglepins"] = ("main:#f4ecd8 second:#d8443c", [
"....o.......", "...obo......", "...o3o..o...", "..o333o.obo.", "..o333o.o3o.", "...o3o.o333o",
"...o3o.o333o", "...obo..o3o.", "....o...o3o.", "........obo.", ".........o..", "............"])
S["w_greataxe"] = ("main:#8a8f9c", [
"....ooo.....", "..oo999oo...", ".o9999999o..", "o99998ooo...", "o9998uo.....", ".o98uo......",
"..ouo.......", ".ouo........", "ouo.........", "uo..........", "o...........", "............"])
S["w_rustyshiv"] = ("main:#8a6a4a", [
"............", "..........o.", ".........o7o", "........o7o.", ".......o7o..", "......o7o...",
".....o7o....", "..o.o7o.....", "...ouo......", "..ouo.o.....", ".ouo........", ".oo........."])

# ---- 10.4 (his ask, 6 Oct): flails: one picture, six metals.
_FLAIL = [
"......o.....", ".....o9o.o..", "....o999o9o.", "...o99y999o.", "....o9999o..", ".....o99o...",
"......8.....", ".....8......", "....8.......", "..ouo.......", ".ouo........", "oo.........."]
for _n, _c in [("w_flail", "#8b8f9c"), ("w_flail_rare", "#6fa0d0"), ("w_flail_frost", "#9ad8f0"),
		("w_flail_ember", "#e8873a"), ("w_flail_storm", "#4d9be6"), ("w_flail_skull", "#e8dcc8")]:
	S[_n] = ("main:#6b4a2a metal:%s glow:#ffffff" % _c, _FLAIL)

# ---- 11.2 (his ask, 6 Oct): the aura relics: one halo, six colours.
_HALO = [
"............", "....oooo....", "..oo9999oo..", ".o99oooo99o.", ".o9o....o9o.", "o9o..yy..o9o",
"o9o..yy..o9o", ".o9o....o9o.", ".o99oooo99o.", "..oo9999oo..", "....oooo....", "............"]
for _n, _c in [("relic_halo_ember", "#e8873a"), ("relic_halo_frost", "#6fd3e0"), ("relic_halo_venom", "#b8e05a"),
		("relic_halo_storm", "#4d9be6"), ("relic_halo_gravity", "#a35bd6"), ("relic_halo_sun", "#f2c94c")]:
	S[_n] = ("metal:%s glow:#ffffff" % _c, _HALO)

# ---- 11.2: GLOOM and prism items.
S["w_duskblade"] = ("main:#3a2a5a glow:#c08aff", [
"...........o", "..........ob", ".........obo", "........obo.", ".......obo..", "......obo...",
".oo..obo....", "oaaooyo.....", "oayao.......", "oaaao.......", "..ouo.......", ".ouo........"])
S["w_prismfan"] = ("main:#8a6aa8 glow:#ffffff", [
"........y..y", ".......y..y.", "..oooo.yyy..", ".o3333oyy...", ".o3y33oo....", ".o3333o.....",
"..oooo......", "...ouo......", "...ouo......", "..ouo.......", ".ouo........", "oo.........."])
S["w_spectrum"] = ("main:#c8a8f0 glow:#fff07a halo:1", [
"..y...y...y.", "...y..y..y..", "....y.y.y...", "..oooooooo..", ".o3333333yo.", ".o3y33y33yo.",
"..oooooooo..", "....ouo.....", "....ouo.....", "...ouo......", "..ouo.......", ".oo........."])
S["relic_gloomlantern"] = ("main:#3a2a5a glow:#c08aff", [
"....oooo....", "....o..o....", "...oooooo...", "..o3yyyy3o..", "..o3yxxy3o..", "..o3yxxy3o..",
"..o3yyyy3o..", "...oooooo...", "....o33o....", "....oooo....", "............", "............"])
S["relic_nightfall"] = ("main:#2a2040 glow:#c08aff", [
"............", "....oooo....", "..oo3333oo..", ".o3333333yo.", ".o33333yyo..", "o3333yyo....",
"o3333yo.....", ".o3333yyo...", ".o333333yyo.", "..oo3333oo..", "....oooo....", "............"])

# ---- 12.1 (his ask, 6 Oct: story and new NPCs): THE ARCHIVIST, an old ghost of a librarian with a
# lantern of ink-light and a book under his arm.
S["npc_archivist"] = ("main:#5a6a8a glow:#c8f0ff bone:#e8e8f0 wood:#6b4a2a", OV(M([
"...ooo", "..o333", ".o3333", ".o30y0", ".o3333", "..olll", "...oll", "o3o333", "o3ouvv", "o3ouvv",
".oo333", "..o33o", "..o33o", "..ooo."]), {6: "..........y.", 7: ".........oyo", 8: "..........o."}))

# 12.2: THE INKLING, a drop of ink that got loose from the page (a quill stuck in its head), and
# THE BOOKBINDER, a stitched paper woman with a needle and thread.
S["npc_inkling"] = ("main:#2a2a4a glow:#9ab8ff bone:#f4ecd8", OV(M([
"......", "......", "...ooo", "..o333", ".o3333", ".o3y03", ".o3333", "o33333", "o32222", ".o2222",
"..oooo"]), {0: "......l.....", 1: "......lo....", 2: ".......l...."}))
S["npc_bookbinder"] = ("main:#a8885a glow:#d8443c bone:#f4ecd8 wood:#6b4a2a", OV(M([
"...ooo", "..o999", ".o9888", ".o80y0", ".o8888", "..oooo", "..o333", "o3ollv", "o3ollv", "o3ollv",
".oo333", "..o33o", "..o33o", "..ooo."]), {6: ".........l..", 7: ".........yl.", 8: "..........l."}))

# ---- 12.2 (his ask, 6 Oct: a story chapter): CHAPTER II, THE MARGINS. Ink, paper and quills.
# The Inkwell.
S["inkblot"] = ("main:#2a2a4a glow:#9ab8ff", M([
"......", "...ooo", "..o333", ".o3333", ".o3y03", "o33333", "o32222", "o22222", ".oo2o2", "...o.o"]))
S["quillbat"] = ("main:#4d6aa8 glow:#ffffff bone:#f4ecd8", M([
"l.....", "lo..o.", ".lo.o3", "..oo3y", "..o333", "...o22", "....o2", "......"]))
S["scrawler"] = ("main:#3a3a5a glow:#9ab8ff bone:#f4ecd8", OV(M([
"...ooo", "..o333", "..o3y0", "..o333", ".o33o3", "o3o322", "o3o322", "o3o322", ".oo322", "..o32o",
"..o00o", "..ooo."]), {5: "..........ll", 6: "..........lo"}))
S["smudge"] = ("main:#5a5a7a glow:#c8d8ff", M([
"...ooo", "..o333", ".o3333", ".o3y03", ".o3333", "o33333", "o32222", "o2o2o2", ".o.o.o", "......"]))
S["inkhound"] = ("main:#2a2a4a glow:#9ab8ff", [
"............", "............", ".o.o........", "o3o3o.......", "o3333o......", "o0y33ooooooo",
".o33232323oo", "..o3333333o.", "..o2o..o2o..", "..o2o..o2o..", ".oo....oo...", "............"])
S["inkwidow"] = ("main:#3a2a5a glow:#c08aff bone:#f4ecd8", M([
"....oooo", "...o3333", "..o33333", "..o30y03", "..o33333", "o.o3llll", "3o.o3333", "o33o3333",
".o33o222", "..o3o222", ".o3oo222", "o3o.o222", "3o..o22o", "o...oooo"]))
# The Bindery.
S["papercut"] = ("main:#e8e0d0 glow:#d8443c", M([
".....o", "....ol", "...oll", "..olly", ".ollll", "olllll", ".ooool", "....oo"]))
S["stitcher"] = ("main:#c8a878 glow:#d8443c", M([
"...ooo", "..o333", ".o3y33", ".o3333", "oo3o33", "o3o3l3", "o3o3l2", "o2o322", ".oo2l2", "..o2oo",
"..o2o.", "..ooo."]))
S["folio"] = ("main:#a8885a bone:#f4ecd8 glow:#ffffff", M([
"oooooo", "o3333o", "o3llll", "o3ly0l", "o3llll", "o3llll", "o3llll", "oooooo", "......", "......"]))
S["pressling"] = ("main:#8a6a4a bone:#f4ecd8 glow:#ffb040", OV(M([
"...ooo", "..o999", "..o888", "..o8y8", "..o888", ".o33o3", "o3o322", "o3o322", "o5o322", ".oo322",
"..o32o", "..ooo."]), {4: ".........ll."}))
S["pagewraith"] = ("main:#e8e0d0 glow:#9ab8ff halo:1", M([
"....o.", "...oll", "..olll", ".olly0", ".ollll", "..olll", "..ol.l", "...o.o", "......", "......"]))
S["bindingpress"] = ("main:#6b4a2a glow:#ffb040", M([
"oooooooo", "o9999999", "o8888888", "oooooooo", "..o33333", "..o3y033", "..o33333", "oo333333",
"o3o32222", "o3o32222", "o3o3o222", ".oo3o222", "..o3oo22", "..oooooo"]))
# The Quill Spire.
S["quillknight"] = ("main:#4a4a6a glow:#9ab8ff bone:#f4ecd8", OV(M([
"....oo", "...o99", "..o998", "..o0y0", "..o888", ".o98o8", "o9o332", "o9o3q2", "o8o322", ".oo322",
"..o98o", "..ooo."]), {0: "..........l.", 1: "..........l.", 2: "..........l."}))
S["nibling"] = ("main:#f2c94c glow:#2a2a4a", M([
"......", "....oo", "...o33", "..o3y3", "..o333", "...o3o", "....o.", "......"]))
S["inkmage"] = ("main:#3a2a5a glow:#c08aff", M([
".....o", "....o3", "...o33", "..o333", ".ooooo", "..o0y0", "..o000", ".o33o3", "o3o322", "o3o3x2",
".oo322", "..o32o", "..ooo."]))
S["sealwarden"] = ("main:#8a2a33 glow:#ffb040 gold:#f2c94c", M([
"...ooo", "..oqqq", "..o333", "..o3y3", "..o333", ".o33o3", "o3o3qq", "o3o3qr", "o3o322", ".oo322",
"..o32o", "..ooo."]))
S["scribe"] = ("main:#c8a878 skin:#e0a47a glow:#2a2a4a", M([
"...ooo", "..o333", ".o3333", "..o555", "..o5y5", "..o555", ".o33o3", "o3o322", "o3o322", ".oo322",
"..o32o", "..ooo."]))
S["headscribe"] = ("main:#f2c94c second:#3a2a5a skin:#e0a47a glow:#ffffff", M([
"......oo", ".....o33", "....o333", "...oaaaa", "...o5555", "...o5y55", "...o5555", "..oo3333",
".o33o333", "o333o222", "o3o3o2a2", ".oo3o222", "..o32222", "..oooooo"]))
# The guardians.
S["inkleviathan"] = ("main:#2a2a4a glow:#9ab8ff bone:#f4ecd8", M([
"........", "..o..ooo", ".o3oo333", ".o333333", "o3333y03", "o3333333", "o3oooooo", "o3oljolj",
"o3o0000x", "o3oljolj", "o3oooooo", "o3332222", ".o222222", "o2o2o2o2", "o.o.o.o.", "........"]))
S["thebinder"] = ("main:#c8a878 glow:#d8443c bone:#f4ecd8", M([
"...ooooo", "..o33333", ".o333333", ".o3y0333", ".o333333", "..olllll", "..ollll9", "oooooooo",
"o3333333", "o3o3llll", "o3o3l9ll", "o3o3llll", ".oo32222", "..o32222", "..o3oo22", "..ooo..."]))
S["author"] = ("main:#f4ecd8 second:#2a2a4a skin:#e0a47a glow:#f2c94c bone:#ffffff halo:1", OV(M([
"....oooo", "...oaaaa", "..oaaaaa", "..o55555", "..o5y055", "..o55555", "...olll5", ".ooolll3",
"o3333333", "o3o33333", "o3o3qq33", "o3o33333", ".oo33333", "..o33333", "..o333oo", "..oooo.."]),
{0: "...............y", 1: "..............yo", 2: ".............oo.", 3: "............oo..", 4: "...........oo..."}))
# 12.3: THE REDACTOR, the hidden one: a tall shape in black, a white bar where its face should be,
# a long black stroke (its pen of erasing) held across it. And the TORN PAGE it fears.
S["redactor"] = ("main:#16141c second:#e8e8f0 glow:#ff3a4a bone:#ffffff", OV(M([
"....oooo", "...o3333", "..o33333", "..oaaaaa", "..oaaaaa", "..o333y3", "...o3333", ".ooo3333",
"o3333333", "o3o33333", "o3o33333", "o3o33333", ".oo33333", "..o33333", "..o333oo", "..oooo.."]),
{7: "o...............", 8: "oo..............", 9: ".oo.............", 10: "..oo............", 11: "...oo..........."}))
S["tornpage"] = ("main:#f4ecd8 glow:#d8443c", [
"............", "..ooooooo...", "..o3333333o.", "..o3llll33o.", "..o333333o..", "..o3lll33o..",
"..o33333o...", "..o3ll333o..", "..o333333o..", "..o3y3333o..", "..oo.ooooo..", "............"])

# ---- 14.4 (his ask, 7 Oct): CHAPTER III, THE APPENDIX. Letters, footnotes and the cover.
# The Glossary.
S["letterling"] = ("main:#e8e0d0 glow:#4d9be6", M([
"......", "..oooo", ".o3333", ".o3oo3", ".o3y03", ".o3333", ".o3oo3", ".o3oo3", "..o..o", "......"]))
S["wordworm"] = ("main:#4d6aa8 glow:#f4ecd8", [
"............", "............", "............", "....oooo....", "...o3333o...", "..o3y3333oo.",
".o3333l3l33o", ".o33l3l33l3o", "..oooooooooo", "............", "............", "............"])
S["definer"] = ("main:#2b4f8a glow:#f4ecd8 bone:#f4ecd8", OV(M([
"...ooo", "..o333", ".o3333", ".o3y03", ".o3333", "..oooo", ".o3333", "o3o3ll", "o3o3ll", ".oo333",
"..o33o", "..ooo."]), {7: "..........lo", 8: "..........lo"}))
S["thesaurus"] = ("main:#5a3a2a glow:#4d9be6 bone:#f4ecd8", M([
"oooooo", "o33333", "o3llll", "o3l0y0", "o3llll", "o3llll", "o3llll", "o33333", "oooooo", ".o2o..",
".o2o..", ".oo..."]))
S["commaimp"] = ("main:#16141c glow:#e8e0d0", M([
"......", "...ooo", "..o333", "..o3y3", "..o333", "...o33", "....o3", "...o3o", "..oo..", "......"]))
S["lexicant"] = ("main:#2b4f8a glow:#f2c94c bone:#f4ecd8", M([
"....oooo", "...o3333", "..o33333", "..o3y0y3", "..o33333", "...ollll", ".oooll3l", "o3333333",
"o3ollll3", "o3ol33l3", "o3ollll3", ".oo33333", "..o33333", "..o3oo33", "..oo..oo"]))
S["lexicon"] = ("main:#2b4f8a second:#f4ecd8 glow:#f2c94c bone:#f4ecd8", M([
"..o.o..o", ".olo.ol.", "..ooooo.", ".o333333", "o3333333", "o33y0333", "o3333333", "o3llllll",
"o3l3l3l3", "o3llllll", "o3l3l3l3", ".o333333", "..o33333", ".o2o.o2o", "o2o...o2", "o.o...o."]))
# The Footnotes.
S["asterisk"] = ("main:#f2c94c glow:#ffffff", M([
"......", ".....o", "..o.o3", "...o33", "..oo3y", ".o3333", "..oo3y", "...o33", "..o.o3", ".....o"]))
S["obelus"] = ("main:#8a6a4a glow:#f4ecd8", M([
".....o", "....o3", "....o3", "..ooo3", ".o333y", "..ooo3", "....o3", "....o3", "....o3", "...ooo"]))
S["ibid"] = ("main:#c8c0e0 glow:#4d9be6", M([
"...ooo", "..o333", ".o3333", ".o3y03", ".o3333", ".o3333", ".o3333", "o33333", "o3o3o3", ".o.o.o"]))
S["citation"] = ("main:#5a4a3a second:#c8a878 glow:#f4ecd8", M([
"...ooo", "..o999", ".o9888", ".o80y0", ".o8888", "..oooo", ".o3333", "o3o333", "o3o3a3", ".oo333",
"..o3oo", "..oo.."]))
S["smallprint"] = ("main:#3a3028 glow:#f4ecd8", M([
"......", "......", "......", "...ooo", "..o333", ".o3y03", ".o3333", ".o2222", "..oooo", "......"]))
S["fineprint"] = ("main:#3a3028 glow:#f2c94c bone:#f4ecd8", M([
"....oooo", "...o3333", "..o33333", "..o3y0y3", "..o33333", ".ollllll", "o3l3l3l3", "o3llllll",
"o3l3l3l3", "o3llllll", ".o333333", "..o33333", "..o3oo33", "..oo..oo"]))
S["erratum"] = ("main:#d8443c second:#f4ecd8 glow:#ffffff bone:#f4ecd8", M([
"........", "...oooo.", "..o3333o", ".o33333o", "o33y0333", "o3333333", "o333oooo", "o33o.ooo",
".o33o333", "..o33333", "...o3333", "...o3333", "..o3oo33", ".o33o.o3", ".oooo.oo", "........"]))
# The Cover.
S["gildling"] = ("main:#f2c94c glow:#d8443c", M([
"l.....", "lo..o.", ".lo.o3", "..oo3y", "..o333", "...o22", "....o2", "......"]))
S["clasp"] = ("main:#c9a35a glow:#d8443c", M([
"oooooo", "o33333", "o3oooo", "o3o..o", "o3o.oy", "o3o..o", "o3oooo", "o33333", "oooooo", ".o2o..",
".o2o..", ".oo..."]))
S["bookmark"] = ("main:#d8443c glow:#f2c94c", M([
"..oooo", "..o333", "..o333", "..o3y3", "..o333", "..o333", "..o333", "..o333", "..o3o3", "..oo.o"]))
S["spinewarden"] = ("main:#6a2a2a second:#f2c94c glow:#f2c94c", M([
"...ooo", "..o999", ".o9888", ".o8y08", ".o8888", "..oooo", ".o3333", "o3oaa3", "o3o333", "o3oaa3",
".oo333", "..o3oo", "..oo.."]))
S["endpaper"] = ("main:#8a3a5a glow:#f4ecd8 bone:#f4ecd8", M([
"oooooo", "o3l3l3", "o3l3l3", "o3ly0l", "o3l3l3", "o3l3l3", "o3l3l3", "oooooo", "......", "......"]))
S["colophon"] = ("main:#6a2a2a second:#f2c94c glow:#f2c94c bone:#f4ecd8", M([
"....oaao", "...oaaaa", "..o33333", "..o3y0y3", "..o33333", "...ollll", ".oooaaaa", "o3333333",
"o3oaaaa3", "o3o33333", "o3oaaaa3", ".oo33333", "..o33333", "..o3oo33", "..oo..oo"]))
# THE READER: the one who has been reading all along. Round spectacles, a hand turning a page.
S["reader"] = ("main:#e0a47a second:#2a2a4a glow:#f2c94c bone:#f4ecd8 halo:1", M([
"...ooooo", "..oaaaaa", ".oaaaaaa", ".o555555", "o5555555", "oooooo55", "o0yy0o55", "oo00ooo5",
"o5555555", ".o555555", ".o55oooo", "..o55555", "...ooooo", "..ollll3", ".olllll3", "olllll33"]))
for _n in ["letterling", "wordworm", "definer", "thesaurus", "commaimp", "asterisk", "obelus", "ibid", "citation",
		"smallprint", "gildling", "clasp", "bookmark", "spinewarden", "endpaper"]:
	ELITE.setdefault(_n, {})

# ---- 15.2 (his ask, 7 Oct: "make fishing better"): every fish of fishing.gd, and THE ANGLER.
_FISH = ["............", "....oooo....", "..oo3333o.oo", ".o3y33333o3o", "o3332222o33o", ".o22222o.o3o",
	"..ooooo...oo", "............"]
_EEL = ["............", "......o.....", ".ooooo3oooo.", "o3y33333333o", "o2222222222o", ".ooooo2oooo.",
	"............", "............"]
_KOI = ["..o.........", ".o3o.oooo...", "..oo33333o.o", ".o3y333333oo", "o33332222o3o", ".o222222o.o3",
	"..oo3oooo..o", "...o3o......"]
_BIG = ["................", "...o.oooooo.....", "..o3o333333oo.oo", ".o33y33333333o3o", "o333333322223o33",
	"oll322222222o.o3", ".oo3o2222222o.o3", "..o.ooooooooo..o", "................"]
_BOOT = ["............", "....oooo....", "....o33o....", "....o33o....", "....o33o....", "..ooo33o....",
	".o3333332o..", ".oooooooooo."]
_SCROLL = ["............", ".oooooooooo.", "o3llllllll3o", ".ol2l2l2llo.", ".ollllllllo.", ".ol2l2l2l2o.",
	"o3llllllll3o", ".oooooooooo."]
for _id, _pal, _g in [
		("mudfin", "main:#7a5236 glow:#f2c94c", _FISH), ("bonecarp", "main:#d9d0b4 glow:#d8443c", _FISH),
		("glimmer", "main:#6fd3e0 glow:#ffffff", _FISH), ("crypteel", "main:#5c3483 glow:#c8f0ff", _EEL),
		("embertrout", "main:#e8873a glow:#fff07a", _FISH), ("gloompike", "main:#3a3850 glow:#c08aff", _EEL),
		("inkfish", "main:#2a2a4a glow:#9ab8ff", _FISH), ("pagepike", "main:#f4ecd8 glow:#2a2a4a", _EEL),
		("goldcarp", "main:#f2c94c glow:#ffffff", _KOI), ("armorbass", "main:#8b8f9c glow:#6fd3e0", _FISH),
		("moonkoi", "main:#c8f0ff glow:#e86fb4", _KOI), ("oldone", "main:#3f7a5a glow:#f2c94c bone:#d9d0b4", _BIG),
		("oldboot", "main:#4e4a5e", _BOOT), ("soddenscroll", "main:#8a6a4a bone:#d9d0b4", _SCROLL)]:
	S["fish_" + _id] = (_pal, _g)
S["npc_angler"] = ("main:#3f6a8a second:#d8b45a skin:#e0a47a wood:#7a5236 glow:#ffffff", OV(M([
"..oooo", ".oaaaa", "oaaaaa", "..o555", "..o505", "..o555", "..olll", ".o3333", "o3o333", "o5o333",
".oo333", "..o33o", "..o22o", "..ooo."]), {0: "..........o.", 1: "..........uo", 2: ".........uo.", 3: "........uo..",
	4: ".......uo...", 5: "......uo....", 6: ".....uo....."}))

for _n in ["inkblot", "quillbat", "scrawler", "smudge", "inkhound", "papercut", "stitcher", "folio", "pressling",
		"pagewraith", "quillknight", "nibling", "inkmage", "sealwarden", "scribe"]:
	ELITE.setdefault(_n, {})

# ---- Stage 23 THE SPELLBOOK (his word, 8 Oct): the twenty magic weapons' icons (spells.gd).
S["w_pocketvoid"] = ("main:#4a2a6a wood:#4a3050 glow:#c070ff", [
"....3..oyyo.", "......oy00yo", "...3..oy00yo", ".......oyyo.", "......ouo..3", ".....ouo....",
"....ouo.....", "...ouo......", "..ouo.......", ".ouo........", "ouo.........", "oo.........."])
S["w_eventhorizon"] = ("main:#2a1a3a wood:#3a2a4a gold:#f2c94c glow:#d890ff", [
"......oyyo..", ".....oy00yo.", "...xyy0000yx", ".....oy00yo.", "......oyyo..", ".....oqo....",
"....ouo.....", "...ouo......", "..oqo.......", ".ouo........", "ouo.........", "oo.........."])
S["w_emberwyrm"] = ("main:#e8573a wood:#5a3a2a glow:#ffd040", [
"........ooo.", ".......o33yo", "......o3322o", ".......oo2o.", "......o2o...", ".....o2uo...",
"....ouo2o...", "...o2uoo....", "..ouo2o.....", ".ouooo......", "ouo.........", "oo.........."])
S["w_rimeserpent"] = ("main:#9fd8f0 glow:#2a4a8a", [
"......ooo...", ".....o33yo..", ".....o332o..", "......o3o...", "...ooooo3o..", "..o3333332o.",
".o3oooooo2o.", ".o33333322o.", "o3oooooooo2o", "o3333333222o", ".oooooooooo.", "............"])
S["w_cometscepter"] = ("main:#c8643c gold:#f2c94c glow:#ffc040 halo:1", [
"..........yy", ".........yy.", "......ooyy..", ".....oxxyo..", ".....oxxxo..", "......ooo...",
".....oqo....", "....o2o.....", "...o2o......", "..o2o.......", ".oqo........", ".oo........."])
S["w_starfallen"] = ("main:#e86fb4 gold:#f2c94c glow:#fff07a", [
"x.......o...", ".y.....oyo..", "..y..ooyxyoo", "......oyyyo.", "x....oyoyo..", ".y..o2ooo...",
"..yo2o......", "...o2o......", "..o2o.......", ".oqo........", "o2o.........", "oo.........."])
S["w_runechalk"] = ("main:#e8e0d0 glow:#ff6fc8", [
".yy.......oo", "y..y.....oxo", "y..y....o3yo", ".yy....o33o.", "......o33o..", ".....o33o...",
"....o32o....", "...o32o.....", "..o32o......", ".o22o.......", ".ooo........", "............"])
S["w_sundersigil"] = ("main:#5a2a6a bone:#e8dcc8 glow:#ff4a6a halo:1", [
"............", "..oooooooo..", ".o22222222o.", ".o222yy222o.", ".o22y22y22o.", ".o2y2yy2y2o.",
".o22y22y22o.", ".o222yy222o.", ".o22222222o.", ".ollllllllo.", "..oooooooo..", "............"])
S["w_dancingsteel"] = ("main:#c8f0ff metal:#d8f4ff glow:#7ff0ff", [
"........x..o", ".......x..o9", "......x..o9o", ".....x..o9o.", "....x..o9o..", "...x..o9o...",
".oo..o9o....", "o99oo9o.....", "o9yo9o......", "o99oo.......", "..ouo.......", ".ouo........"])
S["w_thousandedges"] = ("main:#c8f0ff metal:#e8f4ff glow:#9fd8ff", [
"..x........o", ".x........o9", "x..x.....o9o", "..x.....o9o.", ".x.....o9o..", "......o9o.x.",
".oo..o9o.x..", "o99oo9o.x...", "o9yo9o......", "o99oo.......", "..ouo.......", ".ouo........"])
S["w_stopwatch"] = ("main:#e8f0f8 gold:#d8a838 glow:#3a4a8a", [
"....ooo.....", "....oqo.....", "..oooqooo...", ".oq33333qo..", "oq333y333qo.", "oq333y333qo.",
"oq333yyy3qo.", "oq3333333qo.", ".oq33333qo..", "..ooqqqoo...", "....ooo.....", "............"])
S["w_aeonglass"] = ("main:#c8e8f8 gold:#f2c94c glow:#ffd860 halo:1", [
".oooooooooo.", ".oqqqqqqqqo.", "..o3yyyy3o..", "...o3yy3o...", "....o33o....", "....oyyo....",
"...o3333o...", "..o33yy33o..", "..oyyyyyyo..", ".oqqqqqqqqo.", ".oooooooooo.", "............"])
S["w_kaleidoscope"] = ("main:#ff5a3a second:#4d8be6 skin:#6fd84a gold:#c8a040 glow:#ffffff halo:1", [
".........oo.", "..3.....o3bo", ".......o5x3o", "....b.oqqoo.", ".5...oqqo...", "....oqqo....",
"...oqqo.....", "..oqqo......", ".oqqo.......", ".oqo........", ".oo.........", "............"])
S["w_fractalcrown"] = ("gold:#f2c94c glow:#8cf0e0", [
"............", "............", ".x...xx...x.", "oyo.oyyo.oyo", "oqo.oqqo.oqo", "oqqoqqqqoqqo",
"oqqqqyyqqqqo", "oqqyqqqqyqqo", "oqqqqqqqqqqo", "oppppppppppo", "oooooooooooo", "............"])
S["w_cloudherd"] = ("main:#c8d0e0 wood:#7a5236 glow:#fff07a", [
".ooo....ooo.", "o333oo.ouuuo", "o33333oouoou", ".oooooy..oou", "....y...ouo.", "...y...ouo..",
"......ouo...", ".....ouo....", "....ouo.....", "...ouo......", "..ouo.......", "..oo........"])
S["w_tempestcore"] = ("main:#8aa0c8 glow:#e8f8ff", [
"............", "oooooooooooo", "o3333yyy333o", ".oyy33333yo.", "..o33yyy3o..", "...oyy33o...",
"....o3yo....", ".....o3o....", "....o3o.....", ".....o3o....", ".....oo.....", "............"])
S["w_pinballwand"] = ("main:#e86fb4 gold:#f2c94c glow:#fff07a", [
"..y......oo.", "........oxyo", "....y...oyyo", ".........oo.", "......oqo...", ".....o2o....",
"....o2o.....", "...o2o......", "..o2o.......", ".oqo........", "o2o.........", "oo.........."])
S["w_orrery"] = ("main:#4a3a6a second:#4d8be6 gold:#f2c94c glow:#fff07a wood:#6b4a2a halo:1", [
"....b.......", "...qqqqqq...", ".qq..oo..qq.", "q...oyyo...q", "q..oyxxyo..q", ".qqoyxxyoqq.",
"...qqyyqq..b", ".....oo.....", ".....uu.....", "....ouuo....", "...oooooo...", "............"])
S["w_wildsurge"] = ("main:#ff5a3a second:#4d8be6 skin:#6fd84a gold:#f2c94c wood:#5a3a2a glow:#ffffff", [
"..3....b....", "......oyo..5", ".q...oyxyo..", "......oyo.q.", ".....ouo....", "....ouo..b..",
"....ouuo....", ".....ouo....", "....ouo.....", "...ouo......", "..ouo.......", "..oo........"])
S["w_chaoscodex"] = ("main:#5a1a4a second:#4d8be6 skin:#6fd84a gold:#f2c94c bone:#f4ecd8 glow:#ff3a6a", [
"...3....b...", ".q....5.....", "....y...q.3.", "..b...3.....", "......y..5..", ".oo......oo.",
"olloo..oollo", "ol00lool00lo", "olllloollllo", "o2222oo2222o", ".oooo..oooo.", "............"])

# ---- Stage 25 (his word, 9 Oct): new magic and melee weapons, recoloured from the shapes above.
for _n, _pal, _from in [
	("moonwell", "main:#2a3a6a wood:#3a2a4a glow:#9fe0ff", "w_pocketvoid"),
	("hydrarod", "main:#8cd85a wood:#4a3a2a glow:#ff6a3a", "w_emberwyrm"),
	("skyfall", "main:#8a6a4a gold:#f2c94c glow:#ff8a3a halo:1", "w_cometscepter"),
	("stormsigil", "main:#c8e0ff glow:#fff07a", "w_runechalk"),
	("timewarp", "main:#c8f0ff gold:#8fd8ff glow:#2a4a8a", "w_stopwatch"),
	("rainbowstaff", "main:#ff5a3a second:#6fd84a skin:#4d8be6 gold:#f2c94c glow:#ffffff halo:1", "w_kaleidoscope"),
	("skybreaker", "main:#5a6a8a glow:#fff07a", "w_tempestcore"),
	("luckystar", "main:#f2c94c gold:#e8873a glow:#ffffff", "w_pinballwand"),
	("stormfire", "main:#6b4a2a glow:#ffb040 halo:1", "w_archstaff"),
	("thunderfang", "main:#c8d8ff metal:#e8f0ff glow:#fff07a halo:1", "w_wyrmfang"),
	("frostbrand", "main:#9fd8f0 metal:#c8f0ff glow:#ffffff", "w_wyrmfang"),
	("voidscythe", "main:#5c3483 metal:#a35bd6 glow:#e8c8ff", "w_greataxe"),
	("emberpike", "main:#e8873a glow:#fff07a halo:1", "w_seraphlance"),
	("quakehammer", "main:#8a6a4a metal:#6a5a4a", "w_greataxe"),
	("serpentlash", "main:#6fd84a wood:#3a5a2a glow:#d8443c", "w_emberwyrm"),
	("twinfangs", "main:#d8443c metal:#e8e8f0", "w_rustyshiv"),
	("giantsbane", "main:#c8a060 metal:#8a7a6a", "w_greataxe"),
	("steamblade", "main:#e8c8b0 metal:#f4ecd8 glow:#ff8a5a", "w_dancingsteel"),
]:
	S["w_" + _n] = (_pal, S[_from][1])

# ---- Stage 27 (his word, 9 Oct): MYTHIC weapons and armor (red-gold glow), more weapons; recolours, one new boot.
S["g_voidstriders"] = ("main:#3a2a5a second:#a35bd6 glow:#e8c8ff halo:1", [
"............", "............", "...oooo.....", "...o23o.....", "...o23o.....", "...o23o.....",
"...o23oooo..", "...o2333yoo.", "..o2222222o.", "..oaaaaaaaao", "..oooooooooo", "............"])
for _n, _pal, _from in [
	("worldender", "main:#8a2a33 metal:#c8a060 glow:#ff3a4a halo:1", "w_steamcannon"),
	("dawnbow", "main:#f2c94c wood:#fff07a glow:#ffffff halo:1", "w_repeater"),
	("eternityedge", "main:#c8f0ff metal:#ffffff glow:#ff3a4a halo:1", "w_wyrmfang"),
	("abyssstaff", "main:#1a1028 wood:#5c3483 glow:#ff3a4a halo:1", "w_eventhorizon"),
	("dragonlance", "main:#d8443c glow:#ffd040 halo:1", "w_seraphlance"),
	("thunderking", "main:#2b4f8a gold:#f2c94c glow:#fff07a halo:1", "w_archstaff"),
	("starshell", "main:#8a6a4a metal:#c8a060 glow:#ff8a3a", "w_tickbomb"),
	("frostfoam", "main:#9fd8f0 metal:#c8f0ff glow:#ffffff", "w_cogthrower"),
	("runedeck", "main:#3a1a5a bone:#f4ecd8 glow:#ff6fc8", "w_chaoscodex"),
	("spectralrepeater", "main:#c8f0ff metal:#e8f4ff glow:#7ff0ff", "w_escapement"),
	("viperbow", "main:#4fae46 wood:#2f6b3a glow:#b8e05a", "w_repeater"),
	("voidhammer", "main:#3a2a5a metal:#a35bd6", "w_greataxe"),
]:
	S["w_" + _n] = (_pal, S[_from][1])
for _n, _pal, _from in [
	("stormcrown", "main:#f2c94c second:#2b4f8a glow:#fff07a halo:1", "g_admiralhat"),
	("eternalaegis", "main:#c8d8f0 glow:#ff3a4a halo:1", "g_golemplate"),
	("makergauntlets", "main:#c8a060 glow:#ff3a4a", "g_fiendchains"),
	("elementring", "main:#ff5a3a glow:#6fd84a halo:1", "g_binderthread"),
	("phoenixheart", "main:#e8873a glow:#ff3a4a halo:1", "g_phoenixplume"),
	("firststar", "main:#fff07a glow:#ffffff halo:1", "g_shelversarm"),
]:
	S["g_" + _n] = (_pal, S[_from][1])

# Stage 31 THE TOYBOX: the new weapons' icons (12x12).
S["w_landshark"] = ("main:#6a7c8c second:#3a8ad0", [
"............", "......o.....", ".....o3o....", "....o33o....", "...o332o....", "..o3322o....",
".o33222o....", "o3322222ooo.", "oooooooooooo", "cbacbacbacba", ".bacbacbacb.", "............"])
S["w_twisterfan"] = ("main:#c8ccd8", [
"oooooooooooo", "o3333333333o", ".oo222222oo.", "..o333333o..", "...o2222o...", "...o3333o...",
"....o22o....", "....o33o....", ".....o2o....", ".....o3o....", "......o.....", "............"])
S["w_discostaff"] = ("metal:#c8d0e0 wood:#8a5a3a glow:#ff6fc8", [
"....oooo....", "...o9898o...", "..o898989o..", "..o989x98o..", "..o898989o..", "...o9898o...",
"....oooo....", ".....ou.....", ".....ou.....", ".....ou.....", ".....ou.....", ".....oo....."])
S["w_steelyoyo"] = ("metal:#c8d0e0 glow:#ff4a5a", [
"o...........", ".o..........", "..o.........", "...o........", "....o.......", ".....oooo...",
"....o7889o..", "...o789998o.", "...o78x987o.", "...o789998o.", "....o7889o..", ".....oooo..."])
S["w_portalgun"] = ("second:#a35bd6 metal:#b8c0d0 glow:#7ff0c8", [
"............", "..oooo......", ".oa..ao.....", "oa.xx.ao....", "oa.xx.aooooo", ".oa..ao7888o",
"..oooo78888o", "......ooo8oo", "........o8o.", "........o8o.", "........ooo.", "............"])
S["w_sawlauncher"] = ("metal:#c8d0e0", [
".....oo.....", "..o.o99o.o..", ".o9o9889o9o.", "..o888888o..", ".o88800888o.", "o9880..0889o",
"o9880..0889o", ".o88800888o.", "..o888888o..", ".o9o9889o9o.", "..o.o99o.o..", ".....oo....."])
S["w_voodoodoll"] = ("main:#b08a5a bone:#e8dcc8 metal:#e0e0e8", [
"....oooo....", "...o3333o...", "..o303303o..", "..o333333o..", "...o3ll3o.9.", "..oo3333oo9.",
".o33333333o.", ".o3o3333o3o.", "..oo3ll3oo..", "...o3oo3o...", "...o3o.o3o..", "...oo...oo.."])
S["w_skyanvil"] = ("metal:#8b8f9c", [
"............", "............", "oooooooooooo", "o9999999998o", "o8888888888o", ".oo88888ooo.",
"...o888o....", "...o777o....", "..o77777o...", ".o7777777o..", ".ooooooooo..", "............"])
S["w_megalodon"] = ("main:#5a6a7a bone:#f4ecd8 halo:1 glow:#d8443c", [
"............", "...ooooooo..", "..o3333333o.", ".o33033333oo", "o3333333oljo", "o333333o....",
"o333333o....", "o3333333oljo", ".o33333333oo", "..o3333333o.", "...ooooooo..", "............"])
S["w_sharknado"] = ("main:#c8ccd8 second:#5a6a7a halo:1 glow:#7ff0ff", [
"oooooooooooo", "o3323333233o", ".oo2o22o2oo.", "..o3o33o3o..", "...o2o22o...", "...o3333o.o.",
"....o22o.oao", "....o33ooaao", ".....o2ooaao", ".....o3o.oo.", "......o.....", "............"])
S["w_twinyoyos"] = ("metal:#c8d0e0 glow:#7ff0ff", [
"o..........o", ".o........o.", "..o......o..", "..o......o..", ".ooo....ooo.", "o787o..o787o",
"o8x8o..o8x8o", "o787o..o787o", ".ooo....ooo.", "............", "............", "............"])
S["w_grandpiano"] = ("bone:#f4ecd8 halo:1 glow:#f2c94c", [
"............", ".oooooo.....", "o000000oo...", "o00000000o..", "o000000000o.", "oooooooooooo",
"olololololol", "oooooooooooo", ".o.......o..", ".o.......o..", ".oo......oo.", "............"])
S["w_fishslapper"] = ("main:#6fb0d0 glow:#c8f0ff", [
"............", "............", "........o...", "..oooo.o3o..", ".o3333o333o.", "o3033333333o",
"o3333333333o", ".o3333o333o.", "..oooo.o3o..", "........o...", "............", "............"])
S["w_rubberchicken"] = ("main:#f2d84a second:#d8443c gold:#e8873a", [
"..ooo.......", ".oaao.......", ".o30o.......", "oqqoo.......", ".o3o........", ".o33o.......",
"..o33o......", "..o333oooo..", "...o333333o.", "....o3333o..", ".....oooo...", "............"])
S["w_confetticannon"] = ("metal:#b8a070 wood:#8a5a3a second:#e86fb4 main:#6fd84a glow:#6fc8ff", [
"x..a....3...", "..3..x..a...", "a...3...x...", "oooo........", "o777ooooooo.", "o7888888887o",
"o7888888887o", "o777ooouuuoo", "oooo..ouuuo.", "......ouuo..", "......ooo...", "............"])
S["w_pinatastick"] = ("main:#f2c94c second:#e86fb4 wood:#8a5a3a", [
"....oooo....", "...oa3c3o...", "..oa3c3a3o..", "..o3c3a3co..", "..oc3a3c3o..", "...o3c3ao...",
"....oooo....", ".....ou.....", ".....ou.....", ".....ou.....", ".....ou.....", ".....oo....."])
S["w_stormjar"] = ("wood:#8a5a3a metal:#e8f0f8 glow:#c8e8ff halo:1", [
"...oooooo...", "...ouuuuo...", "..oooooooo..", ".oyyyyyyyyo.", ".oy999999yo.", ".oyy9999yyo.",
".oyyy99yyyo.", ".oyyy99yyyo.", ".oyyyy9yyyo.", ".oyyyyyyyyo.", "..oooooooo..", "............"])
S["w_smithsrevenge"] = ("metal:#8b8f9c wood:#8a5a3a halo:1 glow:#ff8a3a", [
"............", ".ooooooooo..", ".o9999999o..", ".o8888888o..", ".ooooouooo..", ".....ouo....",
".....ouo....", ".....ouo....", ".....ouo....", ".....ouo....", ".....ooo....", "............"])
S["w_partyhorn"] = ("main:#f2c94c second:#e86fb4 glow:#6fc8ff", [
"............", "o...........", "oo..........", "oaoo........", "oa3aoo......", "oa3a3aoo....",
"oa3a3a3aooo.", "oa3a3aoo..ox", "oa3aoo....x.", "oaoo......x.", "oo..........", "o..........."])
for _n, _pal, _from in [
	("discoinferno", "metal:#ffb050 wood:#8a3a2a glow:#ff4a2a halo:1", "w_discostaff"),
	("gatecannon", "second:#5a2a7a metal:#4e4a5e glow:#d86fff halo:1", "w_portalgun"),
	("hungrysaws", "metal:#e8a0a0", "w_sawlauncher"),
	("buzzblade", "metal:#f2c94c", "w_sawlauncher"),
	("doomdoll", "main:#5a3a6a bone:#d8443c metal:#f2c94c halo:1 glow:#a35bd6", "w_voodoodoll"),
	("cursedcrossbow", "main:#4a2a5a glow:#a35bd6", "w_repeater"),
	("portalbow", "main:#a35bd6 wood:#7ff0c8 glow:#ffffff halo:1", "w_dawnbow"),
]:
	S["w_" + _n] = (_pal, S[_from][1])
