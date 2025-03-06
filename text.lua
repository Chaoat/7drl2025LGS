local Font = require "font"
local Misc = require "misc"

local Text = {}

local textEntries = {}
do
	textEntries["deathText"] = "It was a good run. The wind in your hair, the ice water around your hull, and your hold brimming with irreplaceable goods, no trader could ask for anything better. Now it lies at the bottom, another wreck in a garden of ruins."
	textEntries["badEndText"] = "'You did the best you could' your overseer says to you, in a tone that suggests you'll never be behind a wheel again for the rest of your life, or at least your overseer's. You imagine you'll be serving as a deck hand from now on, but hey, at least you're not being served as the main course for some abyssal sea monster."
	
	textEntries["GenesisName"] = "The Serendipity"
	textEntries["GenesisDescription"] = "The flag ship of your trading company lies nestled into the hollowed out insides of the old office block, shielded from the deadly day time rays. Your overseer stands on the deck, gazing down upon you and the vessel so kindly lent to you for your mission, your first mission as captain, and your first mission in these strange waters.\n\nForced into dock for repairs, your company only plans to stay here a scant few hours, more than enough time to visit the locals and see what delivery and mercantile services you can offer them, perhaps even pick up some bright eyed recruits along the way.\n\nStepping into your vessel, perfectly suited to this kind of mission, with plasteel ramming plows and an engine roaring louder than a typhoon, you salute your overseer and give the command to cast off."
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