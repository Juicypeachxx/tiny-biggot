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
