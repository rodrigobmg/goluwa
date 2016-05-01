local blur_shader = [[
	float sum = 0;

	vec2 blur = radius/size;

	sum += texture(self, vec2(uv.x - 4.0*blur.x*dir.x, uv.y - 4.0*blur.y*dir.y)).a * 0.0162162162;
	sum += texture(self, vec2(uv.x - 3.0*blur.x*dir.x, uv.y - 3.0*blur.y*dir.y)).a * 0.0540540541;
	sum += texture(self, vec2(uv.x - 2.0*blur.x*dir.x, uv.y - 2.0*blur.y*dir.y)).a * 0.1216216216;
	sum += texture(self, vec2(uv.x - 1.0*blur.x*dir.x, uv.y - 1.0*blur.y*dir.y)).a * 0.1945945946;

	sum += texture(self, vec2(uv.x, uv.y)).a * 0.2270270270;

	sum += texture(self, vec2(uv.x + 1.0*blur.x*dir.x, uv.y + 1.0*blur.y*dir.y)).a * 0.1945945946;
	sum += texture(self, vec2(uv.x + 2.0*blur.x*dir.x, uv.y + 2.0*blur.y*dir.y)).a * 0.1216216216;
	sum += texture(self, vec2(uv.x + 3.0*blur.x*dir.x, uv.y + 3.0*blur.y*dir.y)).a * 0.0540540541;
	sum += texture(self, vec2(uv.x + 4.0*blur.x*dir.x, uv.y + 4.0*blur.y*dir.y)).a * 0.0162162162;

	sum = pow(sum, 0.5);

	float black = -sum;
	sum -= texture(self, uv).a*4;

	return vec4(black,black,black, sum);
]]

local max = 8
local passes = {}

for i = -max, max do
	local f = i/max
	local s = math.sin(f * math.pi)
	local c = math.sin(f * math.pi)

	table.insert(passes, {source = blur_shader, vars = {dir = Vec2(c,s), radius = 0.05}, blend_mode = "additive"})
end

chathud = chathud or {}
chathud.font_modifiers = {
	["...."] = {type = "font", val = "DefaultFixed"},
	["!!!!"] = {type = "font", val = "Trebuchet24"},
	["!!!!!11"] = {type = "font", val = "DermaLarge"},
}

chathud.emote_shortucts = chathud.emote_shortucts or {
	smug = "<texture=masks/smug>",
	downs = "<texture=masks/downs>",
	saddowns = "<texture=masks/saddowns>",
	niggly = "<texture=masks/niggly>",
	colbert = "<texture=masks/colbert>",
	eli = "<texture=models/eli/eli_tex4z,4>",
	bubu = "<remember=bubu><color=1,0.3,0.2><texture=materials/hud/killicons/default.vtf,50>  <translate=0,-15><color=0.58,0.239,0.58><font=ChatFont>Bubu<color=1,1,1>:</translate></remember>",
	acchan = "<remember=acchan><translate=20,-35><scale=1,0.6><texture=http://www.theonswitch.com/wp-content/uploads/wow-speech-bubble-sidebar.png,64></scale></translate><scale=0.75,1><texture=http://img1.wikia.nocookie.net/__cb20110317001632/southparkfanon/images/a/ad/Kyle.png,64></scale></remember>",
}

chathud.tags = chathud.tags or {}

if surface.DrawFlag then
	chathud.tags.flag =
	{
		arguments = {"gb"},

		draw = function(markup, self, x,y, flag)
			surface.DrawFlag(flag, x, y - 12)
		end,
	}
end

local height_mult = pvars.Setup("cl_chathud_height_mult", 0.76)
local width_mult = pvars.Setup("cl_chathud_width_mult", 0.6)

chathud.markup =  surface.CreateMarkup()
chathud.markup:SetEditable(false)
chathud.markup:SetSelectable(false)
chathud.life_time = 20

local first = true

function chathud.AddText(...)

	if first then
		chathud.font = surface.CreateFont({
			path = "Roboto",
			fallback = surface.GetDefaultFont(),
			size = 16,
			padding = 8,
			shade = passes,
			shadow = 1,
		})

		for _, v in pairs(vfs.Find("textures/silkicons/")) do
			chathud.emote_shortucts[v:gsub("(%.png)$","")] = "<texture=textures/silkicons/" .. v .. ",16>"
		end
		first = nil
	end

	local args = {}

	for _, v in pairs({...}) do
		local t = typex(v)
		if t == "client" then
			table.insert(args, v:GetUniqueColor())
			table.insert(args, v:GetNick())
			table.insert(args, ColorBytes(255, 255, 255, 255))
		elseif t == "string" then

			if v == ": sh" or v == "sh" or v:find("%ssh%s") then
				chathud.markup:TagPanic()
			end

			v = v:gsub("<remember=(.-)>(.-)</remember>", function(key, val)
				chathud.emote_shortucts[key] = val
			end)

			v = v:gsub("(:[%a%d]-:)", function(str)
				str = str:sub(2, -2)
				if chathud.emote_shortucts[str] then
					return chathud.emote_shortucts[str]
				end
			end)

			v = v:gsub("\\n", "\n")
			v = v:gsub("\\t", "\t")

			for pattern, font in pairs(chathud.font_modifiers) do
				if v:find(pattern, nil, true) then
					table.insert(args, #args-1, font)
				end
			end

			table.insert(args, v)
		else
			table.insert(args, v)
		end
	end

	event.Call("ChatAddText", args)

	local markup = chathud.markup

	markup:BeginLifeTime(chathud.life_time)
		-- this will make everything added here get removed after said life time
		markup:AddFont(chathud.font) -- also reset the font just in case
		markup:AddTable(args, true)
		markup:AddTagStopper()
		markup:AddString("\n")
	markup:EndLifeTime()

	markup:SetMaxWidth(surface.GetSize() * width_mult:Get())

	for k,v in pairs(chathud.tags) do
		markup.tags[k] = v
	end
end

function chathud.Draw()
	local markup = chathud.markup

	local _, h = surface.GetSize()
	local x, y = 30, h * height_mult:Get()

	y = y - markup.height

	surface.PushMatrix(x,y)
		markup:Update()
		markup:Draw()
	surface.PopMatrix()
end

function chathud.MouseInput(button, press, x, y)
	chathud.markup:OnMouseInput(button, press, x, y)
end

event.AddListener("Chat", "chathud", function(name, str, client)

	if render.IsGBufferReady() then
		event.AddListener("DrawHUD", "chathud", function()
			chathud.Draw()
		end)
		event.RemoveListener("PreDrawMenu", "chathud")
	else
		event.AddListener("PreDrawMenu", "chathud", function()
			chathud.Draw()
		end)
		event.RemoveListener("DrawHUD", "chathud")
	end

	event.AddListener("MouseInput", "chathud", function(button, press)
		chathud.MouseInput(button, press, window.GetMousePosition():Unpack())
	end)

	local tbl = chat.AddTimeStamp()

	if client:IsValid() then
		table.insert(tbl, client:GetUniqueColor())
	end

	table.insert(tbl, name)
	table.insert(tbl, Color(1,1,1,1))
	table.insert(tbl, ": ")
	table.insert(tbl, str)
	chathud.AddText(unpack(tbl))
end)

if RELOAD then
	chathud.AddText("hello world")
end

local emotes = {
	"2",
	"3arc",
	"47",
	"5star",
	"8bitheart",
	"8bomb",
	"9mm",
	"a",
	"aaf",
	"abomb",
	"abuskull",
	"accepted",
	"ada",
	"adamantine",
	"advent",
	"after",
	"agathacross",
	"agathalion",
	"ai_boost",
	"ai_fuel",
	"ai_gyro",
	"ai_repair",
	"aim",
	"airforce",
	"airstrike",
	"akuma",
	"alchemy",
	"alert",
	"alien",
	"alien2",
	"alienlogo",
	"alientarget",
	"allied",
	"alliedbridge",
	"alliedstar",
	"altis",
	"alyx",
	"amarr",
	"ambition",
	"amethystdust",
	"ammo",
	"anchor",
	"andmyaxe",
	"andy",
	"angered",
	"angry",
	"angrysword",
	"angrytiger",
	"angrytitan",
	"anhel",
	"animal_instincts",
	"animalbones",
	"ankh",
	"annamask",
	"antipho",
	"antipiracy",
	"apafrog",
	"apollo",
	"apothekineticist",
	"apteka",
	"aquaman",
	"ares",
	"argus",
	"arkfall",
	"arms",
	"army",
	"arrow",
	"arrows",
	"arson",
	"as",
	"assassin",
	"assist",
	"attacker",
	"audioreel",
	"august",
	"avengers",
	"avoid",
	"awesome",
	"axe",
	"axesword",
	"axis",
	"axisfountain",
	"azra",
	"azumi",
	"b",
	"b1",
	"baby",
	"badbeans",
	"baddie",
	"badge",
	"bag",
	"bagofgold",
	"bakal",
	"balkancross",
	"ball",
	"ballista",
	"ballistic",
	"balloon",
	"balloonicorn",
	"baloon",
	"bandit",
	"bang",
	"barreloffun",
	"bass",
	"batman",
	"batteringram",
	"bcube",
	"bear",
	"bearded",
	"beat",
	"beatmeat",
	"beer",
	"beginners",
	"beholder",
	"berry",
	"berserk",
	"berserker",
	"bff",
	"bflower",
	"bh",
	"bigbang",
	"bighead",
	"bigheart",
	"bigkiss",
	"bigship",
	"bigsmile",
	"billyhatcher",
	"bird",
	"birds",
	"bit_zombie",
	"black",
	"blacklotus",
	"blackmagic",
	"blacksheep",
	"bladeship",
	"blaser",
	"blast",
	"blech",
	"blocked",
	"blood",
	"bloodangel",
	"bloodman",
	"bloodsplat",
	"bloody",
	"blowfish",
	"blue",
	"bluegem",
	"bluemagic",
	"bluewizard",
	"boat",
	"bolt",
	"bomb",
	"bombproof",
	"boneleton",
	"bones",
	"boomboom",
	"boomer",
	"boot",
	"borderlands2",
	"bow",
	"box",
	"boxwagon",
	"boyking",
	"braddock",
	"brand",
	"break",
	"breaks",
	"brew",
	"brig",
	"bro",
	"brutus",
	"bryda",
	"bryhild",
	"bsod",
	"btiki",
	"bucco",
	"buffalooflies",
	"bug",
	"building",
	"bullet",
	"bullets",
	"burger",
	"burgertime",
	"burn",
	"bus",
	"butcher",
	"butterfly",
	"c",
	"cage",
	"caldari",
	"calltoarms",
	"camel",
	"cammy",
	"candy",
	"cannon",
	"cannonball",
	"capitaldome",
	"capitalist",
	"car",
	"carley",
	"carrot",
	"cashbag",
	"cashsplash",
	"catapult",
	"catapultic",
	"catnap",
	"catnip",
	"cavalry",
	"ccknight",
	"ccskull",
	"celestia",
	"cgv",
	"ch",
	"chains",
	"chainsaw",
	"challenger",
	"champ",
	"charger",
	"charlie",
	"charm",
	"check",
	"checklist",
	"cheepy",
	"cheerful",
	"chef",
	"cherries",
	"chester",
	"chicken",
	"chinatsu",
	"chinesedragon",
	"choco",
	"chocolate",
	"choke",
	"chris",
	"chunli",
	"citadel",
	"claygear",
	"cleaver",
	"clementine",
	"clements",
	"cleric",
	"clericcheering",
	"clocktime",
	"closetgamer",
	"clot",
	"clothes",
	"clover",
	"clown",
	"cluck",
	"clunk",
	"coach",
	"coach2",
	"cocktail",
	"coddog",
	"codknife",
	"coffee",
	"cogs",
	"cogwheel",
	"coin",
	"coindlc",
	"collectible",
	"colony",
	"column",
	"comet",
	"commander",
	"commandervideo",
	"commandgirlvideo",
	"commando",
	"companion",
	"compy",
	"concretedonkey",
	"cone",
	"coneanimal",
	"confused",
	"conquistador",
	"content",
	"conwayfacepalm",
	"conwayheadscratch",
	"conwaypunch",
	"conwayshrug",
	"cookie",
	"cool",
	"coolsam",
	"coop",
	"core",
	"cornucopia",
	"corpus",
	"counting",
	"cow",
	"cowboyhat",
	"crafting",
	"cranewagon",
	"cranium",
	"crate",
	"credits",
	"creep",
	"critical",
	"crossbones",
	"crossedblades",
	"crossh",
	"crow",
	"crown",
	"crowned",
	"crucifix",
	"crystal",
	"crystals",
	"cs_axe",
	"cs_crown",
	"cs_knight",
	"cs_sword",
	"cs_viking",
	"csat",
	"csgoa",
	"csgoanarchist",
	"csgob",
	"csgocross",
	"csgoct",
	"csgoglobe",
	"csgogun",
	"csgohelmet",
	"csgoskull",
	"csgostar",
	"csgox",
	"cthulhu",
	"cthulhuship",
	"cu",
	"curious",
	"currency",
	"curry",
	"cuteteddy",
	"cybereye",
	"cybervision",
	"cyborg",
	"cyclops",
	"d",
	"d2antimage",
	"d2axe",
	"d2bloodseeker",
	"d2brewmaster",
	"d2invoker",
	"d2lonedruid",
	"d2naturesprophet",
	"d2puck",
	"d2rubick",
	"d2tidehunter",
	"dalhousie",
	"dallas",
	"daperdillo",
	"dark",
	"darkgiant",
	"darkophelia",
	"darkpda",
	"darn",
	"dashforth",
	"dashstache",
	"datadisk",
	"dauros",
	"dead",
	"deadhead",
	"deadmanshead",
	"deadskull",
	"deal",
	"dealwithit",
	"death",
	"deathamulet",
	"decomonkey",
	"deer",
	"dejo",
	"delos",
	"delta",
	"demoneye",
	"demoticon",
	"derp",
	"derpy",
	"detonate",
	"deuce",
	"devil",
	"deviledegg",
	"devilskiss",
	"devitsy",
	"dewey",
	"dewgrim",
	"dewstare",
	"dggun",
	"dgjug",
	"dglogo",
	"dgrasp",
	"dgwalker",
	"diadem",
	"diamond",
	"diamonddust",
	"diaxe",
	"die",
	"died",
	"dignity",
	"dino",
	"dinocoffee",
	"dipaddle",
	"diplomacy",
	"diplomat",
	"dirtblock",
	"displash",
	"divekick",
	"divine",
	"diwrench",
	"dizombie",
	"djskully",
	"dlskull",
	"dmitry",
	"dodcp",
	"dog",
	"dogen",
	"dogface",
	"doll",
	"dollars",
	"dollseye",
	"domination",
	"doorchip",
	"dosh",
	"dossenus",
	"doubleaxe",
	"doug",
	"doviculus",
	"draculala",
	"dragon2",
	"dragonskull",
	"drakonix",
	"dredmorninja",
	"drifter",
	"droid",
	"drone",
	"drop",
	"dropmic",
	"drownerbrain",
	"druid",
	"dsfight",
	"dsham",
	"dshound",
	"dsmagic",
	"dssmallbird",
	"dstools",
	"dswilson",
	"dswilsonscared",
	"ducttape",
	"duke",
	"dyer",
	"dynamite",
	"eagle",
	"eagle_eye",
	"eagleeye",
	"eddie",
	"ee",
	"efferdan",
	"egg",
	"eh",
	"eldhrimnir",
	"eli",
	"elite",
	"embermage",
	"emblem",
	"empire",
	"endregateeth",
	"eng",
	"engi",
	"engine",
	"engineer",
	"enraged",
	"ent",
	"ermahgerd",
	"essenceofdeath",
	"essenceofwater",
	"ethereal",
	"evil",
	"evileye",
	"evilskull",
	"excalibur",
	"excite",
	"explosive",
	"extrastrongcoffee",
	"eye",
	"eye_tv",
	"eyeroll",
	"eyeterror",
	"f",
	"f1_bat",
	"f1_crown",
	"f1_egg",
	"f1_shield",
	"f1_skull",
	"f117",
	"f2_angry",
	"f2_goblet",
	"f2_happy",
	"f2_key",
	"f2_sad",
	"f2_shield",
	"f2_skull",
	"f2_suprised",
	"f2_unsure",
	"face",
	"facepunch",
	"faerie",
	"faewing",
	"fahi",
	"falkwreath",
	"famicart",
	"fan",
	"farthing",
	"fastfood",
	"fasttravel",
	"fate",
	"fear",
	"federation",
	"fenrir",
	"fervus",
	"ff",
	"fhappy",
	"fhtagn",
	"fia",
	"fierce",
	"fighter",
	"filiahat",
	"fire",
	"firebaby",
	"firebomb",
	"fireslime",
	"first_kill",
	"first_star",
	"fish",
	"fishbun",
	"fishing",
	"fishy",
	"fist",
	"fix",
	"flag",
	"flags",
	"flamen",
	"flammable",
	"flash",
	"fleur",
	"fleur_de_lys",
	"floater",
	"floppy",
	"flower",
	"flyn",
	"fmad",
	"footprint",
	"foresee",
	"forgetful",
	"forgician",
	"fphat",
	"fprose",
	"fragile",
	"fraud",
	"freesia",
	"freezing",
	"friendship",
	"frigate",
	"frigideer",
	"frog",
	"froggy",
	"frown",
	"fsad",
	"fscared",
	"fsgren",
	"fsmg",
	"fsrocket",
	"fsshield",
	"fsshot",
	"fssnipe",
	"ftired",
	"ftlhuman",
	"ftlmantis",
	"ftlrebel",
	"ftlslug",
	"ftlzoltan",
	"fuelcan",
	"furious",
	"fury",
	"fuschia",
	"fusebomb",
	"fyeah",
	"g",
	"galaxy",
	"gale",
	"gallente",
	"galley",
	"gambler",
	"gambling",
	"gandalf",
	"gaper",
	"gas",
	"gascan",
	"gasgiant",
	"gasmask",
	"gcblue",
	"gcbrick",
	"gcdirt",
	"gcgrass",
	"gchardwood",
	"gciknife",
	"gclava",
	"gcleaves",
	"gcred",
	"gctree",
	"gcwindow",
	"gear",
	"geerhead",
	"geldoffon",
	"gem",
	"gems",
	"genestealer",
	"gent",
	"german",
	"geron",
	"gflower",
	"gg",
	"ghlol",
	"ghsmile",
	"gib",
	"gift",
	"giga",
	"gildrei_alt",
	"glove",
	"glow",
	"gman",
	"gmbomb",
	"gmod",
	"goalastonished",
	"goalhappy",
	"goalinsecure",
	"goalsad",
	"goalscared",
	"goalsmile",
	"goblin",
	"goblinking",
	"godmode",
	"goggles",
	"gokigen",
	"gold",
	"gold_element",
	"goldbars",
	"goldcoin",
	"golden",
	"goldengun",
	"goldidol",
	"goldsmile",
	"goldstack",
	"gollum",
	"goodie",
	"gopher",
	"gordon",
	"gorge",
	"government",
	"grab",
	"grabby",
	"grave",
	"gravestone",
	"gravon",
	"greateye",
	"green",
	"greenlantern",
	"greenmagic",
	"greenslime",
	"greenwizard",
	"grenade",
	"grenadier",
	"grimp",
	"grimpii",
	"grimpiii",
	"grimreaper",
	"grin",
	"grineer",
	"grinsam",
	"grom",
	"groove",
	"groucho",
	"grr",
	"grumgog",
	"gs_angry",
	"gs_annoyed",
	"gs_bubblegum",
	"gs_catchme",
	"gs_cautious",
	"gs_derp",
	"gs_evil",
	"gs_gaze",
	"gs_happy",
	"gs_joy",
	"gs_lol",
	"gs_owned",
	"gs_sad",
	"gs_shuriken",
	"gs_stomped",
	"gs_unimpressed",
	"guard",
	"guardian",
	"gulltoppr",
	"gun",
	"gunner",
	"gunslinger",
	"guristas",
	"gym",
	"halloweener",
	"hammerheadsnark",
	"handprint",
	"handprintleft",
	"handprintright",
	"hands",
	"hangingcontroller",
	"hank",
	"hanzosshadow",
	"happiness",
	"happy",
	"happymeat",
	"happyrob",
	"happytom",
	"harmony",
	"harvester",
	"harvey",
	"hat",
	"hatchet",
	"hatman",
	"hattime",
	"head",
	"headcrab",
	"headshot",
	"headstone",
	"health",
	"heart",
	"hee",
	"heimdall",
	"helia",
	"helm",
	"helmet",
	"helmeted",
	"hemblem",
	"hercules",
	"hex",
	"highfive",
	"hittheroad",
	"hmm",
	"hoji_angry",
	"hoji_fury",
	"hoji_sad",
	"hoji_smile",
	"hoji_surprised",
	"holdline",
	"homers",
	"homewrecker",
	"honkhonk",
	"honored",
	"horned",
	"horns",
	"horse",
	"horsearmor",
	"horseshead",
	"horseshoe",
	"horzine",
	"hourglass",
	"house",
	"hoxton",
	"hpirate",
	"hship",
	"hskull",
	"huey",
	"hungry",
	"hunter",
	"hurt",
	"hydra",
	"hyper",
	"hypercube",
	"ice",
	"icon",
	"idea",
	"idol",
	"ii",
	"illuminati",
	"imachamp",
	"imprison",
	"income",
	"infected",
	"infectedobserver",
	"infectedparty",
	"infinitoad",
	"ins",
	"insanegasmask",
	"insfist",
	"instagib",
	"insurgent",
	"ironcross",
	"ironfist",
	"is2",
	"iseeyou",
	"island",
	"jacomo",
	"jake",
	"james",
	"jarate",
	"jarhead",
	"jd2angry",
	"jd2cake",
	"jd2chick",
	"jd2happy",
	"jd2shock",
	"jdcircle",
	"jdflower",
	"jdhat",
	"jdhex",
	"jdstar",
	"jericho",
	"jerry",
	"jester",
	"jewel",
	"jim",
	"jin",
	"jove",
	"jrmelchkin",
	"juan",
	"jug",
	"kaboom",
	"kairo",
	"kairorings",
	"kap40",
	"keim",
	"ken",
	"kenny",
	"ketta",
	"keys",
	"khappy",
	"kickthem",
	"kill",
	"killenemy",
	"killmaster",
	"king",
	"kingsword",
	"kitteh",
	"kneelingbow",
	"knight",
	"knightshield",
	"koh",
	"koi",
	"koin",
	"krolm",
	"ksad",
	"kscared",
	"kship",
	"ksmiley",
	"kungfusam",
	"kurimuzon",
	"kurimuzon2",
	"kv",
	"kvplanet",
	"labman",
	"ladybug",
	"lampoff",
	"lander",
	"laroche",
	"laser",
	"lasercat",
	"launchpad",
	"lcrown",
	"leaf",
	"lee",
	"legitimacy",
	"leon",
	"lethosdream",
	"letsgo",
	"lev",
	"levelup",
	"leviathan",
	"libertine",
	"life",
	"light",
	"lightbulb",
	"lighthouse",
	"lightning",
	"lilguppy",
	"lili",
	"lion",
	"listine",
	"lizard",
	"loadercoveringface",
	"locktime",
	"logwagon",
	"lol",
	"lonestar",
	"longhaul",
	"loot",
	"lord",
	"loss",
	"lotus",
	"lotusflower",
	"louie",
	"love",
	"lp33",
	"lp3l",
	"lp3p",
	"luca",
	"luchamask",
	"luck",
	"lugh",
	"lumbermancer",
	"lunargiant",
	"lunatica",
	"lunchtime",
	"lustbottle",
	"luvgaze",
	"m",
	"mac",
	"macface",
	"madtom",
	"mage",
	"magiccrystal",
	"maihome",
	"mailedfist",
	"manny",
	"manticore",
	"markarth",
	"markos",
	"marksman",
	"marquis",
	"mars",
	"marsdog",
	"marsmole",
	"martini",
	"mary",
	"mask",
	"masked",
	"masoneagle",
	"masonfist",
	"mast",
	"maternitydoll",
	"mattock",
	"maxwell",
	"mbablob",
	"mbachill",
	"mbadrink",
	"mbafood",
	"mbapigout",
	"mcamulet",
	"mceye",
	"mchand",
	"mcheart",
	"mcmouth",
	"mcpixel",
	"meat",
	"meatboy",
	"meatcleaver",
	"meaty",
	"meatytears",
	"mecury",
	"med",
	"medal",
	"medicon",
	"medkit",
	"medpack",
	"megabomb",
	"melchkin",
	"melody",
	"melon",
	"menace",
	"meowric",
	"merc",
	"metro",
	"milkwagon",
	"milla",
	"mindcontrol",
	"mine",
	"miner",
	"minmatar",
	"mirage",
	"mirrormoon",
	"mirrorsmile",
	"missing",
	"missioncount",
	"misterx",
	"mitra",
	"mixtape",
	"miyabi",
	"mk",
	"mkb",
	"mmep_e",
	"mmep_m",
	"mmep_p",
	"mmmdonut",
	"mole",
	"molotov",
	"money",
	"monomakh",
	"monster",
	"moon",
	"morale",
	"morry",
	"mortis",
	"mount",
	"mrfoster",
	"msfortune",
	"multi",
	"musicnote",
	"mute",
	"nametag",
	"nato",
	"navvie",
	"navy",
	"nekkerheart",
	"neutral",
	"newsword",
	"nights",
	"ninja",
	"ninjabear",
	"nogo",
	"noitubird",
	"noituchimp",
	"noitulove",
	"noitusmart",
	"nomad",
	"nomnom",
	"nonmovingship",
	"normal",
	"notebook",
	"notepad",
	"notime",
	"nuclear",
	"nuke",
	"nuri",
	"nutcracker",
	"observersad",
	"officer",
	"offside",
	"offspring",
	"ogoa",
	"ohnoblue",
	"oldfuse",
	"oldmusicbox",
	"oldschool",
	"oneeye",
	"onering",
	"oneshotonekill",
	"oni",
	"onlooker",
	"onlyleft",
	"ooh",
	"ophelia",
	"orb",
	"orbitallaser",
	"order",
	"original_assassin",
	"orochi",
	"otan",
	"outcast",
	"outlander",
	"overkill",
	"owl",
	"p",
	"p2aperture",
	"p2blue",
	"p2chell",
	"p2cube",
	"p2orange",
	"p2turret",
	"p2wheatley",
	"pact",
	"page",
	"paladin",
	"palmtree",
	"pandashocked",
	"pandastunned",
	"pangoat",
	"pappas",
	"parachute",
	"paranormal",
	"parts",
	"pbomb",
	"pda",
	"pdw",
	"pecs",
	"penguinsrock",
	"penny",
	"pentagram",
	"pentak",
	"perp",
	"perseverance",
	"pettyhat",
	"pewpew",
	"physgun",
	"pick",
	"pig",
	"pigface",
	"pill",
	"pilot",
	"pineapplegrenade",
	"pinkdeath",
	"pinkflower",
	"pinkheart",
	"pipebomb",
	"piranha",
	"pirate",
	"pixeldead",
	"pixelzombie",
	"pixus",
	"pizza",
	"pizzaslice",
	"pjcoin",
	"pjgem",
	"pjheart",
	"pjkaboom",
	"pjskull",
	"plane",
	"planeswalker",
	"planet",
	"platinum",
	"player",
	"plumber",
	"policetape",
	"poop",
	"pope",
	"pork_bun",
	"porridge",
	"portal",
	"possession",
	"postcardb",
	"postcardf",
	"pot",
	"potplant",
	"power",
	"powercube",
	"powersword",
	"preach",
	"primed",
	"prince",
	"prisoner",
	"profgenki",
	"profit",
	"proposal",
	"protozoid",
	"psi",
	"punch",
	"puzzlemaxwell",
	"pwghost",
	"pwgold",
	"pwhip",
	"pwship",
	"pwskull",
	"pwsword",
	"pyramid",
	"questionmark",
	"quick",
	"rabbit",
	"racefuel",
	"racetrophy",
	"radbot",
	"radio",
	"rage",
	"rainbow",
	"rainbowfart",
	"rank",
	"rasta",
	"raven",
	"rayne",
	"raz",
	"reaper",
	"rebel",
	"rebellion",
	"recharge",
	"reclusivecowboy",
	"red",
	"redcard",
	"redleaf",
	"redmagic",
	"redorb",
	"redrose",
	"redskull",
	"redstar",
	"redwizard",
	"reinforce",
	"remedy",
	"retreat",
	"reusapple",
	"reuschicken",
	"reusgreed",
	"reusocean",
	"reusrock",
	"revolverbullet",
	"rflower",
	"ria",
	"riches",
	"riflesword",
	"riften",
	"rings",
	"rip",
	"ripdammo",
	"ripdhealth",
	"ripdskull",
	"rise",
	"roar",
	"robodance",
	"robot",
	"robotloveskitty",
	"robotube",
	"rocket",
	"rogue",
	"roguechallenge",
	"roguechicken",
	"rogueincoming",
	"roguemimic",
	"roguemoneybags",
	"roomkey",
	"rooster",
	"rottenegg",
	"rover",
	"roy",
	"royalty",
	"rtfb",
	"rtiki",
	"rubber",
	"rubber_duck",
	"rufushurt",
	"rufusjoking",
	"rufussad",
	"rufusscared",
	"rufusserious",
	"rufussmile",
	"run",
	"rune",
	"runner",
	"ryohazuki",
	"ryu",
	"saboteur",
	"sad",
	"sadcyclops",
	"sadja",
	"sadpanda",
	"safe_house",
	"sage",
	"sallet",
	"salt",
	"salty",
	"sammich",
	"sana",
	"sasha",
	"satellite",
	"saturn",
	"saucer",
	"saxondragon",
	"scampwick",
	"scaredkid",
	"scaredtom",
	"scouthead",
	"screamcone",
	"screamer",
	"scroll",
	"scrooge",
	"scythe",
	"sdbomb",
	"sdfood",
	"sdpipe",
	"sdprod",
	"sdres",
	"sectoid",
	"security",
	"seed",
	"seele",
	"selva",
	"sense",
	"sentry",
	"serioussam",
	"serum",
	"sfhappy",
	"sfsad",
	"sfsmile",
	"sfsmug",
	"sfsurprise",
	"shadow",
	"sheep",
	"shen",
	"sheridan",
	"sheriffsbadge",
	"sherry",
	"shield",
	"shields",
	"ship",
	"shipping",
	"shockjockey",
	"shodan",
	"shooter",
	"shopkeeper",
	"shoppingspree",
	"shouted",
	"shovel",
	"shynie",
	"si",
	"sidmeiersacepatrolace",
	"sidmeiersacepatrolcaptain",
	"sidmeiersacepatrolfighter",
	"sidmeiersacepatrolmissionleader",
	"sidmeiersacepatrolsquadleader",
	"siege",
	"siegrune",
	"silverdollar",
	"skeletonwolf",
	"skull",
	"skullbomb",
	"skulleton",
	"skullheart",
	"skulls",
	"skullwrath",
	"skullz",
	"skunk",
	"skyecute",
	"skyelaugh",
	"skyeooh",
	"skyesad",
	"skyesmile",
	"slak",
	"slash",
	"slayer",
	"sleep",
	"slime",
	"slothteddy",
	"slyninja",
	"sm",
	"smartphone",
	"smartsam",
	"smelltree",
	"smile",
	"smugrob",
	"snack",
	"snaggletooth",
	"snail",
	"snake",
	"sniper",
	"sniperbullet",
	"snooze",
	"snowman",
	"soccerball",
	"socialpolicy",
	"solar",
	"soldier",
	"solitude",
	"soviet",
	"spaceduck",
	"spacefacehappy",
	"spacehelmet",
	"spaceinvader",
	"spacemonster",
	"spacepony",
	"spatula",
	"spazdreaming",
	"spazdunno",
	"spazhorror",
	"spaztears",
	"spazterror",
	"spazwinky",
	"spectra",
	"spectraii",
	"speedcola",
	"spelunky",
	"spg2anarchy",
	"spg2bomb",
	"spg2devil",
	"spg2skull",
	"spg2wolf",
	"sphere",
	"spider",
	"spidey",
	"spikehair",
	"spirallove",
	"spiraltroll",
	"spirit",
	"spiritboard",
	"splash",
	"splitskull",
	"sprintcup",
	"spy",
	"spycon",
	"spying",
	"squirtheh",
	"squirtmeh",
	"squirtooh",
	"squirtyay",
	"sr4",
	"sr4eagle",
	"sr4fleurdelis",
	"sr4paul",
	"sr4sunglasses",
	"srank",
	"srfrag",
	"sriabelle",
	"ss",
	"ss13axe",
	"ss13blood",
	"ss13brain",
	"ss13down",
	"ss13drill",
	"ss13guts",
	"ss13hammer",
	"ss13head",
	"ss13heart",
	"ss13ok",
	"ss2heart",
	"ssz",
	"staff",
	"starbacon",
	"starconf",
	"starite",
	"starus",
	"steady_aim",
	"steak",
	"steamwings",
	"steerme",
	"steggy",
	"stick",
	"stickman",
	"sticky",
	"stockcar",
	"stop",
	"strawberry",
	"strength",
	"strikeit",
	"strongest",
	"stunned",
	"stunner",
	"sugarskull",
	"suit",
	"sun",
	"superman",
	"supersonic",
	"surprise",
	"surprisemaxwell",
	"surrender",
	"survivalist",
	"survivor",
	"sw3datastorage",
	"sw3eavedev",
	"sw3epod",
	"sw3epodred",
	"sw3precartbat",
	"sw3precskull",
	"swapperorb",
	"sweat",
	"sword",
	"swords",
	"tactician",
	"talon",
	"tammy",
	"tank",
	"tap",
	"tape",
	"taperecorder",
	"target",
	"tballed",
	"tbpangry",
	"tbpblush",
	"tbpbook",
	"tbpgloomy",
	"tbphappy",
	"tbpsad",
	"tbpsleep",
	"tbptongue",
	"tbpwink",
	"tbpwtf",
	"tec",
	"technozoologicalist",
	"teleport",
	"telina",
	"templars",
	"terminator",
	"terran",
	"terraria",
	"tetley",
	"tetrobot",
	"thebat",
	"thebee",
	"thebomb",
	"thebureaualien",
	"thebureaueagle",
	"thed",
	"thedragon",
	"theeye",
	"thefish",
	"theholyhandgrenade",
	"thejetpack",
	"thekid",
	"theladybug",
	"theorder",
	"therival",
	"therooster",
	"theshark",
	"theskunk",
	"thesniper",
	"thetommyspecial",
	"theworm",
	"thief",
	"thoughtful",
	"throwingknife",
	"thug",
	"thumbs",
	"thumbsup",
	"thumbup",
	"tie",
	"tiger",
	"timeperiod",
	"tina",
	"tipheal",
	"tire",
	"titanattacks",
	"tl2engineer",
	"toadstool",
	"tokitori",
	"tom",
	"tombstone",
	"tomcat",
	"tommygun",
	"tooth",
	"tophat",
	"tornbanner",
	"toxictitan",
	"tp",
	"tractor",
	"tradingcard",
	"tradingcardfoil",
	"train1",
	"train2",
	"train3",
	"tram",
	"treasure",
	"treble",
	"tree",
	"triad",
	"triangle",
	"tribe",
	"trilogo",
	"trinity",
	"trolley",
	"trolleybus",
	"trolol",
	"trophies",
	"trophy",
	"troutslap",
	"tsalogo",
	"tsfmarine",
	"tunacan",
	"tutu",
	"tw",
	"twammo",
	"twbuh",
	"twplus",
	"twshield",
	"twteamblue",
	"twteamrandom",
	"twteamred",
	"twtimer",
	"ufo",
	"uggo",
	"ultratron",
	"umad",
	"umbrella",
	"une",
	"unicorn",
	"upgrade",
	"uplum",
	"uranium",
	"ursula",
	"use",
	"ut2004adrenaline",
	"ut2004flak",
	"ut2004health",
	"ut2004shield",
	"ut2004udamage",
	"vahlen",
	"vampire",
	"vasari",
	"vascar",
	"vaultkey",
	"venomousspider",
	"victoria",
	"viking",
	"virility",
	"vlad",
	"vs",
	"w",
	"wagon",
	"walker",
	"wanderer",
	"warband",
	"warhorse",
	"warlord",
	"warmage",
	"warplate1",
	"warplate2",
	"warrior",
	"wasted",
	"watcher",
	"watchman",
	"watchyou",
	"wcube",
	"weapon",
	"weed",
	"welder",
	"welderspark",
	"wheel",
	"whine",
	"whiskeybottle",
	"whistle",
	"white",
	"whitemagic",
	"whiterabbit",
	"whiterose",
	"whiterun",
	"whitesheep",
	"windhelm",
	"wink",
	"witch",
	"wizard",
	"wolf",
	"wolfguy",
	"wonderwoman",
	"wood",
	"woot",
	"worker",
	"world",
	"wow",
	"wrench",
	"wrenna",
	"wrynhappy",
	"wrynscared",
	"wurmi",
	"wvarrow",
	"wvclosed",
	"wvtalk",
	"wvturn",
	"wvwait",
	"wvwarning",
	"xbone",
	"xerxes",
	"xmen",
	"xp",
	"xx",
	"xxx",
	"y",
	"yawn",
	"yellowcard",
	"yellowwizard",
	"young",
	"zelemir",
	"zeppelin",
	"zero",
	"zerog",
	"zombie",
	"zombiebrain",
	"zombiehead",
	"zombieheart",
	"zombieskull",
	"zz",
	"zzacid",
	"zzcarniplant",
	"zzenergy",
	"zztime",
	"zztrophy",
	"zzz",
}

for k,v in pairs(emotes) do
	chathud.emote_shortucts[v] =  "<texture=http://cdn.steamcommunity.com/economy/emoticon/" .. v .. ">"
end

local emotes = {
	"+1",
	"100",
	"1234",
	"8ball",
	"a",
	"ab",
	"abc",
	"abcd",
	"accept",
	"aerial_tramway",
	"airplane",
	"alarm_clock",
	"alien",
	"ambulance",
	"anchor",
	"angel",
	"anger",
	"angry",
	"anguished",
	"ant",
	"apple",
	"aquarius",
	"aries",
	"arrow_backward",
	"arrow_double_down",
	"arrow_double_up",
	"arrow_down",
	"arrow_down_small",
	"arrow_forward",
	"arrow_heading_down",
	"arrow_heading_up",
	"arrow_left",
	"arrow_lower_left",
	"arrow_lower_right",
	"arrow_right",
	"arrow_right_hook",
	"arrow_up",
	"arrow_up_down",
	"arrow_up_small",
	"arrow_upper_left",
	"arrow_upper_right",
	"arrows_clockwise",
	"arrows_counterclockwise",
	"art",
	"articulated_lorry",
	"astonished",
	"atm",
	"b",
	"baby",
	"baby_bottle",
	"baby_chick",
	"baby_symbol",
	"baggage_claim",
	"balloon",
	"ballot_box_with_check",
	"bamboo",
	"banana",
	"bangbang",
	"bank",
	"bar_chart",
	"barber",
	"baseball",
	"basketball",
	"bath",
	"bathtub",
	"battery",
	"bear",
	"beer",
	"beers",
	"beetle",
	"beginner",
	"bell",
	"bento",
	"bicyclist",
	"bike",
	"bikini",
	"bird",
	"birthday",
	"black_circle",
	"black_joker",
	"black_nib",
	"black_square",
	"black_square_button",
	"blossom",
	"blowfish",
	"blue_book",
	"blue_car",
	"blue_heart",
	"blush",
	"boar",
	"boat",
	"bomb",
	"book",
	"bookmark",
	"bookmark_tabs",
	"books",
	"boom",
	"boot",
	"bouquet",
	"bow",
	"bowling",
	"bowtie",
	"boy",
	"bread",
	"bride_with_veil",
	"bridge_at_night",
	"briefcase",
	"broken_heart",
	"bug",
	"bulb",
	"bullettrain_front",
	"bullettrain_side",
	"bus",
	"busstop",
	"bust_in_silhouette",
	"busts_in_silhouette",
	"cactus",
	"cake",
	"calendar",
	"calling",
	"camel",
	"camera",
	"cancer",
	"candy",
	"capital_abcd",
	"capricorn",
	"car",
	"card_index",
	"carousel_horse",
	"cat",
	"cat2",
	"cd",
	"chart",
	"chart_with_downwards_trend",
	"chart_with_upwards_trend",
	"checkered_flag",
	"cherries",
	"cherry_blossom",
	"chestnut",
	"chicken",
	"children_crossing",
	"chocolate_bar",
	"christmas_tree",
	"church",
	"cinema",
	"circus_tent",
	"city_sunrise",
	"city_sunset",
	"cl",
	"clap",
	"clapper",
	"clipboard",
	"clock1",
	"clock10",
	"clock1030",
	"clock11",
	"clock1130",
	"clock12",
	"clock1230",
	"clock130",
	"clock2",
	"clock230",
	"clock3",
	"clock330",
	"clock4",
	"clock430",
	"clock5",
	"clock530",
	"clock6",
	"clock630",
	"clock7",
	"clock730",
	"clock8",
	"clock830",
	"clock9",
	"clock930",
	"closed_book",
	"closed_lock_with_key",
	"closed_umbrella",
	"cloud",
	"clubs",
	"cn",
	"cocktail",
	"coffee",
	"cold_sweat",
	"collision",
	"computer",
	"confetti_ball",
	"confounded",
	"confused",
	"congratulations",
	"construction",
	"construction_worker",
	"convenience_store",
	"cookie",
	"cool",
	"cop",
	"copyright",
	"corn",
	"couple",
	"couple_with_heart",
	"couplekiss",
	"cow",
	"cow2",
	"credit_card",
	"crocodile",
	"crossed_flags",
	"crown",
	"cry",
	"crying_cat_face",
	"crystal_ball",
	"cupid",
	"curly_loop",
	"currency_exchange",
	"curry",
	"custard",
	"customs",
	"cyclone",
	"dancer",
	"dancers",
	"dango",
	"dart",
	"dash",
	"date",
	"de",
	"deciduous_tree",
	"department_store",
	"diamond_shape_with_a_dot_inside",
	"diamonds",
	"disappointed",
	"dizzy",
	"dizzy_face",
	"do_not_litter",
	"dog",
	"dog2",
	"dollar",
	"dolls",
	"dolphin",
	"door",
	"doughnut",
	"dragon",
	"dragon_face",
	"dress",
	"dromedary_camel",
	"droplet",
	"dvd",
	"e",
	"ear",
	"ear_of_rice",
	"earth_africa",
	"earth_americas",
	"earth_asia",
	"egg",
	"eggplant",
	"eight",
	"eight_pointed_black_star",
	"eight_spoked_asterisk",
	"electric_plug",
	"elephant",
	"email",
	"end",
	"envelope",
	"es",
	"euro",
	"european_castle",
	"european_post_office",
	"evergreen_tree",
	"exclamation",
	"expressionless",
	"eyeglasses",
	"eyes",
	"facepunch",
	"factory",
	"fallen_leaf",
	"family",
	"fast_forward",
	"fax",
	"fearful",
	"feelsgood",
	"feet",
	"ferris_wheel",
	"file_folder",
	"finnadie",
	"fire",
	"fire_engine",
	"fireworks",
	"first_quarter_moon",
	"first_quarter_moon_with_face",
	"fish",
	"fish_cake",
	"fishing_pole_and_fish",
	"fist",
	"five",
	"flags",
	"flashlight",
	"floppy_disk",
	"flower_playing_cards",
	"flushed",
	"foggy",
	"football",
	"fork_and_knife",
	"fountain",
	"four",
	"four_leaf_clover",
	"fr",
	"free",
	"fried_shrimp",
	"fries",
	"frog",
	"frowning",
	"fu",
	"fuelpump",
	"full_moon",
	"full_moon_with_face",
	"game_die",
	"gb",
	"gem",
	"gemini",
	"ghost",
	"gift",
	"gift_heart",
	"girl",
	"globe_with_meridians",
	"goat",
	"goberserk",
	"godmode",
	"golf",
	"grapes",
	"green_apple",
	"green_book",
	"green_heart",
	"grey_exclamation",
	"grey_question",
	"grimacing",
	"grin",
	"grinning",
	"guardsman",
	"guitar",
	"gun",
	"haircut",
	"hamburger",
	"hammer",
	"hamster",
	"hand",
	"handbag",
	"hankey",
	"hash",
	"hatched_chick",
	"hatching_chick",
	"headphones",
	"hear_no_evil",
	"heart",
	"heart_decoration",
	"heart_eyes",
	"heart_eyes_cat",
	"heartbeat",
	"heartpulse",
	"hearts",
	"heavy_check_mark",
	"heavy_division_sign",
	"heavy_dollar_sign",
	"heavy_exclamation_mark",
	"heavy_minus_sign",
	"heavy_multiplication_x",
	"heavy_plus_sign",
	"helicopter",
	"herb",
	"hibiscus",
	"high_brightness",
	"high_heel",
	"hocho",
	"honey_pot",
	"honeybee",
	"horse",
	"horse_racing",
	"hospital",
	"hotel",
	"hotsprings",
	"hourglass",
	"hourglass_flowing_sand",
	"house",
	"house_with_garden",
	"hurtrealbad",
	"hushed",
	"ice_cream",
	"icecream",
	"id",
	"ideograph_advantage",
	"imp",
	"inbox_tray",
	"incoming_envelope",
	"information_desk_person",
	"information_source",
	"innocent",
	"interrobang",
	"iphone",
	"it",
	"izakaya_lantern",
	"jack_o_lantern",
	"japan",
	"japanese_castle",
	"japanese_goblin",
	"japanese_ogre",
	"jeans",
	"joy",
	"joy_cat",
	"jp",
	"key",
	"keycap_ten",
	"kimono",
	"kiss",
	"kissing",
	"kissing_cat",
	"kissing_closed_eyes",
	"kissing_face",
	"kissing_heart",
	"kissing_smiling_eyes",
	"koala",
	"koko",
	"kr",
	"large_blue_circle",
	"large_blue_diamond",
	"large_orange_diamond",
	"last_quarter_moon",
	"last_quarter_moon_with_face",
	"laughing",
	"leaves",
	"ledger",
	"left_luggage",
	"left_right_arrow",
	"leftwards_arrow_with_hook",
	"lemon",
	"leo",
	"leopard",
	"libra",
	"light_rail",
	"link",
	"lips",
	"lipstick",
	"lock",
	"lock_with_ink_pen",
	"lollipop",
	"loop",
	"loudspeaker",
	"love_hotel",
	"love_letter",
	"low_brightness",
	"m",
	"mag",
	"mag_right",
	"mahjong",
	"mailbox",
	"mailbox_closed",
	"mailbox_with_mail",
	"mailbox_with_no_mail",
	"man",
	"man_with_gua_pi_mao",
	"man_with_turban",
	"mans_shoe",
	"maple_leaf",
	"mask",
	"massage",
	"meat_on_bone",
	"mega",
	"melon",
	"memo",
	"mens",
	"metal",
	"metro",
	"microphone",
	"microscope",
	"milky_way",
	"minibus",
	"minidisc",
	"mobile_phone_off",
	"money_with_wings",
	"moneybag",
	"monkey",
	"monkey_face",
	"monorail",
	"moon",
	"mortar_board",
	"mount_fuji",
	"mountain_bicyclist",
	"mountain_cableway",
	"mountain_railway",
	"mouse",
	"mouse2",
	"movie_camera",
	"moyai",
	"muscle",
	"mushroom",
	"musical_keyboard",
	"musical_note",
	"musical_score",
	"mute",
	"nail_care",
	"name_badge",
	"neckbeard",
	"necktie",
	"negative_squared_cross_mark",
	"neutral_face",
	"new",
	"new_moon",
	"new_moon_with_face",
	"newspaper",
	"ng",
	"nine",
	"no_bell",
	"no_bicycles",
	"no_entry",
	"no_entry_sign",
	"no_good",
	"no_mobile_phones",
	"no_mouth",
	"no_pedestrians",
	"no_smoking",
	"non",
	"nose",
	"notebook",
	"notebook_with_decorative_cover",
	"notes",
	"nut_and_bolt",
	"o",
	"o2",
	"ocean",
	"octocat",
	"octopus",
	"oden",
	"office",
	"ok",
	"ok_hand",
	"ok_woman",
	"older_man",
	"older_woman",
	"on",
	"oncoming_automobile",
	"oncoming_bus",
	"oncoming_police_car",
	"oncoming_taxi",
	"one",
	"open_file_folder",
	"open_hands",
	"open_mouth",
	"ophiuchus",
	"orange_book",
	"outbox_tray",
	"ox",
	"page_facing_up",
	"page_with_curl",
	"pager",
	"palm_tree",
	"panda_face",
	"paperclip",
	"parking",
	"part_alternation_mark",
	"partly_sunny",
	"passport_control",
	"paw_prints",
	"peach",
	"pear",
	"pencil",
	"pencil2",
	"penguin",
	"pensive",
	"performing_arts",
	"persevere",
	"person_frowning",
	"person_with_blond_hair",
	"person_with_pouting_face",
	"phone",
	"pig",
	"pig2",
	"pig_nose",
	"pill",
	"pineapple",
	"pisces",
	"pizza",
	"point_down",
	"point_left",
	"point_right",
	"point_up",
	"point_up_2",
	"police_car",
	"poodle",
	"poop",
	"post_office",
	"postal_horn",
	"postbox",
	"potable_water",
	"pouch",
	"poultry_leg",
	"pound",
	"pouting_cat",
	"pray",
	"princess",
	"punch",
	"purple_heart",
	"purse",
	"pushpin",
	"put_litter_in_its_place",
	"question",
	"rabbit",
	"rabbit2",
	"racehorse",
	"radio",
	"radio_button",
	"rage",
	"rage1",
	"rage2",
	"rage3",
	"rage4",
	"railway_car",
	"rainbow",
	"raised_hand",
	"raised_hands",
	"ram",
	"ramen",
	"rat",
	"readme",
	"recycle",
	"red_car",
	"red_circle",
	"registered",
	"relaxed",
	"relieved",
	"repeat",
	"repeat_one",
	"restroom",
	"revolving_hearts",
	"rewind",
	"ribbon",
	"rice",
	"rice_ball",
	"rice_cracker",
	"rice_scene",
	"ring",
	"rocket",
	"roller_coaster",
	"rooster",
	"rose",
	"rotating_light",
	"round_pushpin",
	"rowboat",
	"ru",
	"rugby_football",
	"runner",
	"running",
	"running_shirt_with_sash",
	"sa",
	"sagittarius",
	"sailboat",
	"sake",
	"sandal",
	"santa",
	"satellite",
	"satisfied",
	"saxophone",
	"school",
	"school_satchel",
	"scissors",
	"scorpius",
	"scream",
	"scream_cat",
	"scroll",
	"seat",
	"secret",
	"see_no_evil",
	"seedling",
	"seven",
	"shaved_ice",
	"sheep",
	"shell",
	"ship",
	"shipit",
	"shirt",
	"shit",
	"shoe",
	"shower",
	"signal_strength",
	"six",
	"six_pointed_star",
	"ski",
	"skull",
	"sleeping",
	"sleepy",
	"slot_machine",
	"small_blue_diamond",
	"small_orange_diamond",
	"small_red_triangle",
	"small_red_triangle_down",
	"smile",
	"smile_cat",
	"smiley",
	"smiley_cat",
	"smiling_imp",
	"smirk",
	"smirk_cat",
	"smoking",
	"snail",
	"snake",
	"snowboarder",
	"snowflake",
	"snowman",
	"sob",
	"soccer",
	"soon",
	"sos",
	"sound",
	"space_invader",
	"spades",
	"spaghetti",
	"sparkler",
	"sparkles",
	"sparkling_heart",
	"speak_no_evil",
	"speaker",
	"speech_balloon",
	"speedboat",
	"squirrel",
	"star",
	"star2",
	"stars",
	"station",
	"statue_of_liberty",
	"steam_locomotive",
	"stew",
	"straight_ruler",
	"strawberry",
	"stuck_out_tongue",
	"stuck_out_tongue_closed_eyes",
	"stuck_out_tongue_winking_eye",
	"sun_with_face",
	"sunflower",
	"sunglasses",
	"sunny",
	"sunrise",
	"sunrise_over_mountains",
	"surfer",
	"sushi",
	"suspect",
	"suspension_railway",
	"sweat",
	"sweat_drops",
	"sweat_smile",
	"sweet_potato",
	"swimmer",
	"symbols",
	"syringe",
	"tada",
	"tanabata_tree",
	"tangerine",
	"taurus",
	"taxi",
	"tea",
	"telephone",
	"telephone_receiver",
	"telescope",
	"tennis",
	"tent",
	"thought_balloon",
	"three",
	"thumbsdown",
	"thumbsup",
	"ticket",
	"tiger",
	"tiger2",
	"tired_face",
	"tm",
	"toilet",
	"tokyo_tower",
	"tomato",
	"tongue",
	"top",
	"tophat",
	"tractor",
	"traffic_light",
	"train",
	"train2",
	"tram",
	"triangular_flag_on_post",
	"triangular_ruler",
	"trident",
	"triumph",
	"trolleybus",
	"trollface",
	"trophy",
	"tropical_drink",
	"tropical_fish",
	"truck",
	"trumpet",
	"tshirt",
	"tulip",
	"turtle",
	"tv",
	"twisted_rightwards_arrows",
	"two",
	"two_hearts",
	"two_men_holding_hands",
	"two_women_holding_hands",
	"u5272",
	"u5408",
	"u55b6",
	"u6307",
	"u6708",
	"u6709",
	"u6e80",
	"u7121",
	"u7533",
	"u7981",
	"u7a7a",
	"uk",
	"umbrella",
	"unamused",
	"underage",
	"unlock",
	"up",
	"us",
	"v",
	"vertical_traffic_light",
	"vhs",
	"vibration_mode",
	"video_camera",
	"video_game",
	"violin",
	"virgo",
	"volcano",
	"vs",
	"walking",
	"waning_crescent_moon",
	"waning_gibbous_moon",
	"warning",
	"watch",
	"water_buffalo",
	"watermelon",
	"wave",
	"wavy_dash",
	"waxing_crescent_moon",
	"waxing_gibbous_moon",
	"wc",
	"weary",
	"wedding",
	"whale",
	"whale2",
	"wheelchair",
	"white_check_mark",
	"white_circle",
	"white_flower",
	"white_square",
	"white_square_button",
	"wind_chime",
	"wine_glass",
	"wink",
	"wolf",
	"woman",
	"womans_clothes",
	"womans_hat",
	"womens",
	"worried",
	"wrench",
	"x",
	"yellow_heart",
	"yen",
	"yum",
	"zap",
	"zero",
	"zzz",
}
for k,v in pairs(emotes) do
	chathud.emote_shortucts[v] =  "<texture=https://assets-cdn.github.com/images/icons/emoji/" .. v .. ".png>"
end