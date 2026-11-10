"""The foes, people, pets and summons (206 pictures) in his bright look (22 Oct): the reference sheets
and the prompts for SpriteCook, sixteen to a 4 x 4 sheet, the foes in the order of ENEMIES in
game_data.gd, then the people and pets by name.
python3 resprite/tools/mob_sheets.py   -> resprite/spritecook/refs/mobs_mNN.png and mobs_plan.json
- H: a few words for each, so Nano Banana knows what it is redrawing. Where a name misled it (a
  "bookworm dragon" for a biting book), the second-take sheet r2 described today's picture instead
  (its prompt is in mobs_plan.json).
- Each sheet then: Nano Banana 2.1, 384 x 384, pixel, transparent, no crop, his picture and the
  champions' sheet bright_c1 as style images, the reference sheet as reference; then
  tools/sheet_add.py cuts it and fits each one at double detail."""
import json, os, re, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import plan, ROOT
H = {
"bat":"a bat","slime":"a slime blob","skeleton":"a skeleton archer","mushroom":"a walking mushroom","cultist":"a hooded cultist","imp":"a little imp","knight":"an armoured knight","ghost":"a ghost","bookwyrm":"a bookworm dragon","drowned":"a drowned sailor","golem":"a stone golem","dummy":"a training dummy","bogling":"a little bog creature","gnat":"a gnat","hexwife":"a hex witch","longbowman":"a longbow archer","lancer":"a lancer","warpriest":"a war priest","torchimp":"an imp with a torch","monk":"a monk","icearcher":"an ice archer","snowlantern":"a snow lantern spirit","gunman":"a gunman","cutthroat":"a cutthroat","crow":"a crow","chimneyimp":"a sooty chimney imp","voidling":"a small void creature","shadeknight":"a shade knight","eclipsed":"an eclipsed cultist","inkblot":"an ink blot creature","quillbat":"a quill bat","scrawler":"a scrawler","smudge":"an ink smudge","inkhound":"an ink hound","papercut":"a paper cut creature","stitcher":"a book stitcher","folio":"a living folio book","pressling":"a little printing press","pagewraith":"a page wraith","quillknight":"a quill knight","nibling":"a pen nib creature","inkmage":"an ink mage","sealwarden":"a wax seal warden","scribe":"a scribe","letterling":"a living letter","wordworm":"a word worm","definer":"a dictionary creature","thesaurus":"a thesaurus beast","commaimp":"a comma imp","asterisk":"an asterisk creature","obelus":"an obelus mark creature","ibid":"an ibid creature","citation":"a citation creature","smallprint":"a small print creature","gildling":"a gilded creature","clasp":"a book clasp creature","bookmark":"a living bookmark","spinewarden":"a book spine warden","endpaper":"a living endpaper","mothling":"a moth","dustbunny":"a dust bunny","shelfmimic":"a bookshelf mimic","bookgolem":"a book golem","cardsprite":"a playing card sprite","shusher":"a shushing librarian","lampwisp":"a lamp wisp","bookend":"a bookend golem","pagewing":"a page bird","spectacle":"a pair of floating spectacles","cinderpage":"a burning page","ashworm":"an ash worm","pokerknight":"a fire poker knight","firedog":"a fire dog","sootling":"a soot sprite","inmate":"a prison inmate","grenadier":"a grenadier","jailer":"a jailer","graveborn":"a risen corpse","bandsman":"a bandsman","fiendling":"a little fiend","blackknight":"a black knight","drone":"a flying drone","glitch":"a glitch creature","chrome":"a chrome robot","turret":"a gun turret","thug":"a thug","molotov":"a molotov thrower","copper":"a police officer","bomber":"a bomber","orderly":"a hospital orderly","crawler":"a crawler","static":"a static spark creature","tollkeeper":"a toll keeper","neighbour":"a nosy neighbour","robovac":"a robot vacuum","burglar":"a burglar","gnome":"a garden gnome","gangster":"a gangster","biker":"a biker","riotcop":"a riot cop","outlaw":"an outlaw","dynamiter":"a dynamite thrower","sharpshooter":"a sharpshooter","coyote":"a coyote","skykite":"a sky kite","gustling":"a little wind spirit","stormharpy":"a storm harpy","thunderhead":"a thundercloud creature","mirrorwing":"a mirror bird","rampartguard":"a rampart guard","sludgecrawler":"a sludge crawler","chainwarden":"a chain warden","tidecaller":"a tide caller","longpike":"a pike soldier","shellpriest":"a shell priest","dervish":"a whirling dervish","deacon":"a deacon","beltfeeder":"an ammo belt creature","beltlink":"an ammo link creature","ammomimic":"an ammo box mimic","tombspider":"a tomb spider","candlewight":"a candle wight","gargoyle":"a gargoyle","wardrummer":"a war drummer","bloodleech":"a blood leech","casingrat":"a rat","target":"a shooting target","haggler":"a haggler","scrounger":"a scrounger","cogling":"a cog creature","steamjack":"a steam robot","boltslinger":"a bolt slinger","gearhound":"a gear hound","rivetlobber":"a rivet lobber","brasswasp":"a brass wasp","frostmite":"a frost mite","rimebrute":"a frost brute","shardcaster":"an ice shard caster","frostfang":"a frost wolf","snowlobber":"a snowball thrower","raider":"a raider","goblin":"a goblin","mimic":"a chest mimic","ponysquire":"a squire on a pony","lobbyist":"a lobbyist","intern":"an intern","believer":"a believer",
"camp_cat":"a cat","npc_angler":"an angler","npc_archivist":"an archivist","npc_attendant":"an attendant","npc_bard":"a bard","npc_bartender":"a bartender","npc_bookbinder":"a bookbinder","npc_broker":"a broker","npc_carpenter":"a carpenter","npc_cook":"a cook","npc_courier":"a courier","npc_drunk":"a drunk lying down","npc_fisher":"a fisher","npc_gambler":"a gambler","npc_inkling":"an inkling","npc_mechanic":"a mechanic","npc_merchant":"a merchant","npc_monger":"a monger","npc_peddler":"a peddler","npc_pitboss":"a pit boss","npc_seer":"a seer","npc_teller":"a teller","npc_tinker":"a tinker",
"pet_biscuit":"a pet dog","pet_bramble":"a pet bramble creature","pet_cage":"a pet in a cage","pet_cindertail":"a pet fire fox","pet_glimmer":"a pet glimmer sprite","pet_gloop":"a pet slime","pet_gulp":"a pet frog","pet_hoots":"a pet owl","pet_kaboomba":"a pet bomb creature","pet_rex":"a pet little dinosaur","pet_snip":"a pet crab","pet_zappy":"a pet spark creature",
"s_bones":"a summoned skeleton","s_dragon":"a summoned little dragon","s_egg":"a summoned egg","s_fish":"a summoned fish","s_golem":"a summoned golem","s_imp":"a summoned imp","s_mimic":"a summoned mimic","s_sheep":"a summoned sheep","s_wolf":"a summoned wolf",
}
for f in ("arcane","blood","bulwark","core","demolition","edge","fortune","frost","fury","malice","pyre","shadow","storm","swarm","venom"):
    H["fam_"+f] = "a small %s familiar" % f
groups,_,_ = plan()
src=open(ROOT+'/tiny_biggot_godot/scripts/data/game_data.gd').read()
i=src.index('const ENEMIES := {'); j=src.index('const ALT_GUARDIANS', i)
order=[]
for s in re.findall(r'"sprite":\s*"([^"]+)"', src[i:j]):
    if s not in order: order.append(s)
foes=[n for n in order if n in groups['foes']]+[n for n in groups['foes'] if n not in order]
names=foes+sorted(groups['people and pets'])
missing=[n for n in names if n not in H]
assert not missing, missing
sheets=[names[k:k+16] for k in range(0,len(names),16)]
out={}
for idx, cells in enumerate(sheets, 1):
    key='m%02d'%idx
    while len(cells) < 16: cells = cells + ['-']
    ref=ROOT+'/resprite/spritecook/refs/mobs_%s.png'%key
    os.makedirs(os.path.dirname(ref), exist_ok=True)
    subprocess.run(['python3', ROOT+'/resprite/tools/sheet_ref.py', ref, '4']+cells, check=True, capture_output=True)
    n=sum(1 for c in cells if c!='-')
    rows=[]
    for r in range(4):
        row=[H[c] for c in cells[r*4:r*4+4] if c!='-']
        if row: rows.append(('Row %d, left to right: ' % (r+1) if r==0 else 'Row %d: ' % (r+1)) + '; '.join(row) + '.')
    lead = ('A sprite sheet of %d different little game characters in a 4 by 4 grid, redrawn from the reference sheet' % n) + \
        ('' if n==16 else '; only the first %d places are used and the rest stay empty' % n) + \
        '. Every one stays in its own place in the grid and keeps its shape, colours, pose and the way it faces. '
    tail=' Each a clean, bright, colourful pixel art game sprite in exactly the look of the style guide, with clear empty space between them. No text, no labels, no frames, no background, no floor.'
    out[key]={'cells':cells,'ref':os.path.relpath(ref, ROOT),'prompt':lead+' '.join(rows)+tail}
path=os.path.join(ROOT,'resprite','spritecook','refs','mobs_plan.json')
done=json.load(open(path)) if os.path.exists(path) else {}   # keeps the SpriteCook ids of sheets made
for k, v in out.items():
    done.setdefault(k, {}).update(v)
with open(path,'w') as f:
    json.dump(done, f, indent=1)
    f.write('\n')
print(len(names), 'mobs in', len(out), 'sheets')
