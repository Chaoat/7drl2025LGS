local Score = {}

local currentScore = 0
function Score.update(game)
	currentScore = -game.turnCalculator.currentTurn
	for i = 1, #game.world.bunkers do
		local bunker = game.world.bunkers[i]
		if bunker.hasReceived then
			currentScore = currentScore + 100
		else
			currentScore = currentScore - 50
		end
	end
end

function Score.get()
	return currentScore
end

return Score