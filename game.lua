local Camera = require "camera"
local World = require "world"
local Player = require "player"
local TurnCalculator = require "turnCalculator"
local EnemyProto = require "enemyProto"

local Game = {}

function Game.new()
	local game = {mainCamera = Camera.new(), player = nil, world = World.new(), turnCalculator = nil}
	
	local playerActor = World.placeActor(game.world, Player.generatePlayerActor(actor), 0, 0)
	game.player = Player.new(playerActor)
	
	--EnemyProto.spawn("debris", game.world, 3, 3)
	--EnemyProto.spawn("debris", game.world, 5, 3)
	--EnemyProto.spawn("debris", game.world, 7, 3)
	
	game.turnCalculator = TurnCalculator.new(game.world, game.player)
	
	return game
end

function Game.update(game, dt)
	World.update(game.world, dt)
	
	--Camera.move(game.mainCamera, (game.mainCamera.worldX + game.player.actor.drawX)/2, (game.mainCamera.worldY + game.player.actor.drawY)/2)
	Camera.move(game.mainCamera, game.player.actor.drawX, game.player.actor.drawY)
end

function Game.keyInput(game, key)
	if Player.keyInput(game.player, key) then
		TurnCalculator.pass(game.turnCalculator)
	end
end

function Game.mouseInput(game, screenx, screeny, button)
	local tilex, tiley = Camera.screenToTileCoords(game.mainCamera, screenx, screeny)
	if Player.clickInput(game.player, tilex, tiley, button) then
		TurnCalculator.pass(game.turnCalculator)
	end
end

function Game.draw(game)
	World.draw(game.world, game.mainCamera)
	Player.drawMovementPrediction(game.player, game.mainCamera)
	
	Camera.draw(0, 0, game.mainCamera)
end

return Game