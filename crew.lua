local Letter = require "letter"
local Actor = require "actor"
local Misc = require "misc"

local Crew = {}

local crewDefinitions = {}
do
	local function newCrewDef(name, letter, posEffect, posEffectDescription, negEffect, negEffectDescription)
		--posEffect(player)
		--negEffect(player)
		local crewDef = {name = name, letter = letter, 
			posEffect = posEffect, posEffectDescription = posEffectDescription, 
			negEffect = negEffect, negEffectDescription = negEffectDescription}
		crewDefinitions[name] = crewDef
	end
	
	newCrewDef("Trucker", Letter.newFromLetter("T", {1, 1, 1, 1}), 
	function(player)
		player.turnRate = player.turnRate + 1
	end, "+1 turn speed",
	function(player)
		player.turnRate = player.turnRate - 1
	end, "-1 turn speed")
	
	newCrewDef("Engineer", Letter.newFromLetter("E", {1, 1, 1, 1}), 
	function(player)
		player.acceleration = player.acceleration + 1
	end, "+1 acceleration",
	function(player)
		player.acceleration = player.acceleration - 1
	end, "-1 acceleration")
	
	newCrewDef("Mathematician", Letter.newFromLetter("M", {1, 1, 1, 1}), 
	function(player)
		player.deceleration = player.deceleration + 1
	end, "+1 deceleration",
	function(player)
		player.deceleration = player.deceleration - 1
	end, "-1 deceleration")
	
	newCrewDef("Carpenter", Letter.newFromLetter("C", {1, 1, 1, 1}), 
	function(player)
		Actor.changeMaxHealth(player.actor, 5)
	end, "+5 health",
	function(player)
		Actor.changeMaxHealth(player.actor, -5)
	end, "-5 health")
	
	newCrewDef("Stocker", Letter.newFromLetter("S", {1, 1, 1, 1}), 
	function(player)
		player.inventory.cargoLimit = player.inventory.cargoLimit + 1
	end, "+1 max cargo",
	function(player)
		player.inventory.cargoLimit = player.inventory.cargoLimit - 1
	end, "-1 max cargo")
	
	newCrewDef("Brewer", Letter.newFromLetter("B", {1, 1, 1, 1}), 
	function(player)
		player.maxFuel = player.maxFuel + 20
	end, "+20 max fuel",
	function(player)
		player.maxFuel = player.maxFuel - 20
	end, "-20 max fuel")
	
	newCrewDef("Novelist", Letter.newFromLetter("N", {1, 1, 1, 1}), 
	function(player)
	end, "praise",
	function(player)
	end, "scorn")
end

function Crew.drawSymbol(crew, drawX, drawY, tileWidth, tileHeight)
	local letter = crew.letter
	Letter.draw(letter, drawX, drawY, tileWidth, tileHeight)
end

function Crew.new(class, origin)
	local crewDef = crewDefinitions[class]
	local crew = {class = class, origin = origin, originLink = nil, letter = Letter.copy(crewDef.letter), crewDef = crewDef, happiness = 0}
	return crew
end

function Crew.tick(crew, player)
	if crew.happiness == 0 then
		if crew.originLink.hasReceived then
			crew.happiness = 1
			crew.crewDef.posEffect(player)
			crew.letter.tint = {0, 1, 0, 1}
		elseif crew.originLink.dead then
			crew.happiness = -1
			crew.crewDef.negEffect(player)
			crew.letter.tint = {1, 0, 0, 1}
		end
	end
end

function Crew.getName(crew)
	return crew.class .. " from " .. crew.origin
end

return Crew