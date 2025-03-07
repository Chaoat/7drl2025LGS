local Font = require "font"
local Misc = require "misc"

local Text = {}

local textEntries = {}
do
	textEntries["deathText"] = "It was a good run. The wind in your hair, the ice water around your hull, and your hold brimming with irreplaceable goods, no trader could ask for anything better. Now it lies at the bottom, another wreck in a garden of ruins."
	textEntries["badEndText"] = "'You did the best you could' your overseer says to you, in a tone that suggests you'll never be behind a wheel again for the rest of your life, or at least your overseer's. You imagine you'll be serving as a deck hand from now on, but hey, at least you're not being served as the main course for some abyssal sea monster."
	textEntries["goodEndText"] = "Your overseer nods, a rare gesture for him. 'You did well' he says, 'perhaps you can pilot us out of here, we'll be leaving soon'. He turns his back, and returns to shouting orders in preparation for cast off, his capacity for congratulations apparently exhausted. You pivot to face the motley crew assembled behind you, the men and women you seduced with visions of riches and adventure, now face to face with the hard, stoic realities of the high seas. You shrug, and a brief smile passes their worried faces. It's a harsh life, but it still beats waiting for death in a hulking ruin."
	textEntries["bestEndText"] = "Your overseer is standing next to you, it looks like he's trying to say something, but you can't hear anything over the roar of the cargo crane lifting precious materials from your overloaded plow boat. Your assembled crew works all around you, mingled with the regulars of the Serendipity, and as they unload your spoils they flash glowing looks in your direction. This kind of haul hasn't been seen in years, and especially not under the rule of the current overseer. Awareness of this fact is written all over the worried creases of his aged face, an inverse of the beaming smile that you shoot at him. As the certainty in his future vanishes, so too does yours begin to bloom."
	
	textEntries["GenesisName"] = "The Serendipity"
	textEntries["GenesisDescription"] = "The flag ship of your trading company lies nestled into the hollowed out insides of the old office block, shielded from the deadly day time rays. Your overseer stands on the deck, gazing down upon you and the vessel so kindly lent to you for your mission, your first mission as captain, and your first mission in these strange waters.\n\nForced into dock for repairs, your company only plans to stay here a scant few hours, more than enough time to visit the locals and see what delivery and mercantile services you can offer them, perhaps even pick up some bright eyed recruits along the way.\n\nStepping into your vessel, perfectly suited to this kind of mission, with plasteel ramming plows and an engine roaring louder than a typhoon, you salute your overseer and give the command to cast off."
	
	textEntries["nitro"] = "Nitro"
	textEntries["blink"] = "Blink"
	textEntries["cannon"] = "Cannon"
	textEntries["drill"] = "Drill"
	textEntries["indestructibility"] = "Invuln"
	textEntries["drift"] = "Drift"

	--Bunker TEXT
	textEntries["bunker1"] = "South Street"
	textEntries["bunker1description"] = "Your boat drifts into the pier, the creaking wood barely holding against the rising tide.\nThe Bunker stands firm against the flood, its walls weathered but unbroken.\nWithin, survivors move with quiet purpose, bartering, repairing, preparing for another day in the drowned world.\nSafe for now, but never secure."

	textEntries["bunker2"] = "North West Cafe"
	textEntries["bunker2description"] = "Perched precariously on a small hill, this outpost is a beacon of warmth and life in this watery wasteland. The weathered sign above the entrance reads The Last Sip. You're greeted by a warm, inviting atmosphere. The air is thick with the aroma of freshly brewed coffee and a homely fireplace. Stop, rest, refuel before facing the crazy world out there again."

	textEntries["bunker3"] = "Collapsed Trade Tower"
	textEntries["bunker3description"] = "The skeletal remains of the skyscraper loom above the waves, its steel ribs twisted and rusted from decades of neglect. What was once a beacon of commerce became a crumbling tomb, its lower floors swallowed by the sea, its upper levels tilting precariously against the wind.\nYet, against all odds, the tower once again breathes with purpose. The old offices, stripped of luxury, now serve as makeshift markets, where scavengers barter over wares.\nThe world may have collapsed, but commerce endures. It always does."

	textEntries["bunker4"] = "Warehouse Depot"
	textEntries["bunker4description"] = "Rusted cranes tower above the water, silent sentinels of a bygone world.\nYour boat glides up to the dock, past half-sunken cargo containers and debris-littered piers.\nInside the warehouse, workers sort scavenged goods, marking crates, and shouting across the cavernous space."

	textEntries["bunker5"] = "Destroyed Warehouse"
	textEntries["bunker5description"] = "The Bunker stands firm against the tide, its walls weathered but unbroken. Within, survivors barter, repair, and prepare for another day in the drowned world. Safe for now, but never secure."

	textEntries["bunker6"] = "Mountain Cabin"
	textEntries["bunker6description"] = "The Bunker stands firm against the tide, its walls weathered but unbroken. Within, survivors barter, repair, and prepare for another day in the drowned world. Safe for now, but never secure."

	textEntries["bunker7"] = "North Central Plaza"
	textEntries["bunker7description"] = "The Bunker stands firm against the tide, its walls weathered but unbroken. Within, survivors barter, repair, and prepare for another day in the drowned world. Safe for now, but never secure."

	textEntries["bunker8"] = "Central Offices"
	textEntries["bunker8description"] = "The Bunker stands firm against the tide, its walls weathered but unbroken. Within, survivors barter, repair, and prepare for another day in the drowned world. Safe for now, but never secure."

	textEntries["bunker9"] = "Mountain Hotel"
	textEntries["bunker9description"] = "Your vessel approaches a rocky outcrop, the sheer cliff face rising above the waterline. A fortified bunker, clings to the mountainside like a tenacious vine. The floodwaters lap against its lower levels, but the structure stands resolute, a testament to the patchwork engineering carried out upon what might of once been a hotel."

	textEntries["bunker10"] = "State Library"
	textEntries["bunker10description"] = "Majesty still exists in this drowned city at the last library left in the known world. The marble columns shimmer with light from the water below as your boat approaches the pier. One day, some hope the knowledge contained here can bootstrap a new civilization from the wreckage. However, survivors cannot eat books, so other priorities come first. "

	textEntries["bunker11"] = "Warehouse Gatehouse"
	textEntries["bunker11description"] = "The Bunker stands firm against the tide, its walls weathered but unbroken. Within, survivors barter, repair, and prepare for another day in the drowned world. Safe for now, but never secure."

	textEntries["bunker12"] = "Survivor Trade Hub"
	textEntries["bunker12description"] = "The Bunker stands firm against the tide, its walls weathered but unbroken. Within, survivors barter, repair, and prepare for another day in the drowned world. Safe for now, but never secure."

	textEntries["bunker13"] = "Stadium"
	textEntries["bunker13description"] = "The roar of the crowd lingers in this monument to sport. The stadium's field has become a shallow flooded field used to grow the rice that feeds much of the surrounding settlements. You've heard rumors that at night smugglers ship out crates of rice wine as a side business."

	textEntries["bunker14"] = "North East Mall"
	textEntries["bunker14description"] = "The shattered facade of the once-grand shopping mall yawns before you, a concrete maw swallowing the ragged remnants of humanity. The faded shopfronts now house refugees from other cities, trying to scour together enough to make their dreams of a better world a possibility."

	textEntries["bunker15"] = "Untouched Tower"
	textEntries["bunker15description"] = "Your boat glides alongside a small office building that stands almost untouched by the devastation. The floodwaters lap gently against its base, but the reinforced glass and sturdy concrete show no signs of yielding. It's a stark anomaly in this drowned cityscape, a relic of the old world stubbornly clinging to existence."

	textEntries["bunker16"] = "Southern Hideout"
	textEntries["bunker16description"] = "The Bunker stands firm against the tide, its walls weathered but unbroken. Within, survivors barter, repair, and prepare for another day in the drowned world. Safe for now, but never secure."

	textEntries["bunker17"] = "Outskirts Lookout"
	textEntries["bunker17description"] = "The Bunker stands firm against the tide, its walls weathered but unbroken. Within, survivors barter, repair, and prepare for another day in the drowned world. Safe for now, but never secure."

	textEntries["bunkerCollapsedDescription"] = "The Bunker stands silent. Only the wind answers your arrival, whistling through empty corridors and shattered gates.\nWhat drove them away? Monsters, famine, mutiny? You cannot say.\nHad you arrived sooner, perhaps things would be different. Perhaps this place would still have voices to greet you.\n\nNothing useful remains, you feel you best depart quickly."
end

function Text.get(entryName)
	return textEntries[entryName] or "MISSING TEXT FOR: " .. entryName
end

function Text.print(text, numChars, fontSize, x, y, limit, align)
	local textLength = string.len(text)
	
	local colouredText = {}
	colouredText[1] = {1, 1, 1, 1}
	colouredText[2] = string.sub(text, 1, math.floor(numChars))
	if numChars < textLength then
		colouredText[3] = {1, 1, 1, numChars - math.floor(numChars)}
		colouredText[4] = string.sub(text, math.floor(numChars) + 1, math.floor(numChars) + 1)
		if numChars < textLength - 1 then
			colouredText[5] = {1, 1, 1, 0}
			colouredText[6] = string.sub(text, math.floor(numChars) + 2, textLength)
		end
	end
	
	Font.setFont("clacon", fontSize)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(colouredText, Misc.round(x), Misc.round(y), limit, align)
end

return Text