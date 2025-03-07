local Font = require "font"
local Misc = require "misc"

local Text = {}

local textEntries = {}
do
	textEntries["deathText"] = "It was a good run. The wind in your hair, the ice water around your hull, and your hold brimming with irreplaceable goods, no trader could ask for anything better. Now it lies at the bottom, another wreck in a garden of ruins."
	textEntries["badEndText"] = "'You did the best you could' your overseer says to you, in a tone that suggests you'll never be behind a wheel again for the rest of your life, or at least your overseer's. You imagine you'll be serving as a deck hand from now on, but hey, at least you're not being served as the main course for some abyssal sea monster."
	
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
	textEntries["bunker1description"] = "TODO"

	textEntries["bunker2"] = "North West Cafe"
	textEntries["bunker2description"] = "TODO"

	textEntries["bunker3"] = "Collapsed Trade Tower"
	textEntries["bunker3description"] = "The skeletal remains of the skyscraper loom above the waves, its steel ribs twisted and rusted from decades of neglect. What was once a beacon of commerce became a crumbling tomb, its lower floors swallowed by the sea, its upper levels tilting precariously against the wind.\nYet, against all odds, the tower once again breathes with purpose. The old offices, stripped of luxury, now serve as makeshift markets, where scavengers barter over wares.\nThe world may have collapsed, but commerce endures. It always does."

	textEntries["bunker4"] = "Warehouse Depot"
	textEntries["bunker4description"] = "TODO"

	textEntries["bunker5"] = "Destroyed Warehouse"
	textEntries["bunker5description"] = "TODO"

	textEntries["bunker6"] = "Mountain Cabin"
	textEntries["bunker6description"] = "TODO"

	textEntries["bunker7"] = "North Central Plaza"
	textEntries["bunker7description"] = "TODO"

	textEntries["bunker8"] = "Central Offices"
	textEntries["bunker8description"] = "TODO"

	textEntries["bunker9"] = "Mountain Hotel"
	textEntries["bunker9description"] = "TODO"

	textEntries["bunker10"] = "State Library"
	textEntries["bunker10description"] = "TODO"

	textEntries["bunker11"] = "Warehouse Gatehouse"
	textEntries["bunker11description"] = "TODO"

	textEntries["bunker12"] = "Survivor Trade Hub"
	textEntries["bunker12description"] = "TODO"

	textEntries["bunker13"] = "Stadium"
	textEntries["bunker13description"] = ""

	textEntries["bunker14"] = "North East Mall"
	textEntries["bunker14description"] = ""

	textEntries["bunker15"] = "Untouched Tower"
	textEntries["bunker15description"] = ""

	textEntries["bunker16"] = "Southern Hideout"
	textEntries["bunker16description"] = ""

	textEntries["bunker17"] = "Outskirts Lookout"
	textEntries["bunker17description"] = ""

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