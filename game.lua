local Camera = require "camera"
local World = require "world"
local Player = require "player"
local TurnCalculator = require "turnCalculator"
local EnemyProto = require "enemyProto"
local Menu = require "menu"
local RandomGen = require "randomGen"
local Map = require "map"

local Game = {}

local function blackBack(opacity)
	return function(x, y, width, height, timeChange)
		love.graphics.setColor(0, 0, 0, opacity)
		love.graphics.rectangle("fill", x, y, width, height)
	end
end

local function generateInterface(world, player, camera)
	local menu = Menu.new(nil)
	
	local screen = Menu.screen.new("main", nil)
	
	local sideBar = Menu.screen.new("side", blackBack(0.7))
	
	local toolElements = {
	Menu.element.toolView(Menu.position.dynamicSize(0, 0, 1, 20), player, world, "nitro", "activateNitro"),
	Menu.element.toolView(Menu.position.dynamicSize(0, 0, 1, 20), player, world, "blink", "activateBlink"),
	}
	
	Menu.screen.addElement(sideBar, Menu.element.verticalList(Menu.position.dynamicCenter(0.5, -200, 180, 180), true, nil, 0, false, toolElements, nil, false))
	Menu.screen.addElement(sideBar, Menu.element.cargoHold(Menu.position.dynamicSize(10, -450, -10, -210), player))
	Menu.screen.addElement(sideBar, Menu.element.crewHold(Menu.position.dynamicSize(10, -700, -10, -460), player))
	
	Menu.screen.addElement(sideBar, Menu.element.actorHealth(Menu.position.dynamicSize(10, 10, -10, 25), player.actor))
	Menu.screen.addElement(sideBar, Menu.element.playerFuel(Menu.position.dynamicSize(10, 30, -10, 45), player))
	
	Menu.screen.addElement(screen, Menu.element.screen(Menu.position.dynamicSize(-200, 0, 1, 1), true, sideBar))
	Menu.screen.addElement(screen, Menu.element.bunkerView(Menu.position.dynamicSize(10, 10, 500, 400), player, camera))
	Menu.addScreen(menu, screen)
	
	return menu
end

function Game.new()
	local game = {mainCamera = Camera.new(), player = nil, currentPlayerCellX = -10, currentPlayerCellY = -10, cellGrid = {}, gridWidth = 0, gridHeight = 0, interface = nil, world = World.new(), turnCalculator = nil}
	
	local playerActor = World.placeActor(game.world, Player.generatePlayerActor(actor), 0, 0)
	game.player = Player.new(playerActor)
	
	local mapWidth, mapHeight = Map.getSize(game.world.map)
	game.gridWidth = math.ceil(mapWidth/(game.world.map.cellWidth))
	game.gridHeight = math.ceil(mapHeight/(game.world.map.cellHeight))
	
	for x = 0, game.gridWidth do
		game.cellGrid[x] = {}
		for y = 0, game.gridHeight do
			game.cellGrid[x][y] = false
		end
	end
	
	Game.updatePlayerCellPos(game)
	
	Map.redrawCells(game.world.map, game.player.actor.x, game.player.actor.y)
	
	--EnemyProto.spawn("debris", game.world, 3, 3)
	--EnemyProto.spawn("debris", game.world, 5, 3)
	--EnemyProto.spawn("debris", game.world, 7, 3)
	
	game.turnCalculator = TurnCalculator.new(game.world, game.player)
	
	game.interface = generateInterface(game.world, game.player, game.mainCamera)
	
	return game
end

function Game.resize(game, w, h)
	Camera.resize(game.mainCamera, w, h)
end

function Game.update(game, dt)
	World.update(game.world, dt)
	
	--Camera.move(game.mainCamera, (game.mainCamera.worldX + game.player.actor.drawX)/2, (game.mainCamera.worldY + game.player.actor.drawY)/2)
	Camera.trackPlayer(game.mainCamera, game.player)
end

function Game.keyInput(game, key)
	if Player.keyInput(game.player, game.world, key) then
		TurnCalculator.pass(game.turnCalculator)
		Game.updatePlayerCellPos(game)
	end
end

function Game.updatePlayerCellPos(game)
	local world = game.world
	local player = game.player
	
	local cellWidth = world.map.cellWidth
	local cellHeight = world.map.cellHeight
	
	local cellX = math.floor(player.actor.x/cellWidth)
	local cellY = math.floor(player.actor.y/cellHeight)
	
	if game.currentPlayerCellX ~= cellX or game.currentPlayerCellY ~= cellY then
		game.currentPlayerCellX = cellX
		game.currentPlayerCellY = cellY
		
		for x = 0, game.gridWidth do
			for y = 0, game.gridHeight do
				local shouldBeActive = math.abs(x - cellX) <= 1 and math.abs(y - cellY) <= 1
				local currentlyActive = game.cellGrid[x][y]
				
				if currentlyActive == false and shouldBeActive == true then
					RandomGen.fillAreaWithEnemies(world, 1, x*world.map.cellWidth, y*world.map.cellWidth, (x + 1)*world.map.cellHeight, (y + 1)*world.map.cellHeight)
				end
				
				game.cellGrid[x][y] = shouldBeActive
			end
		end
	end
end

function Game.mouseInput(game, screenx, screeny, button)
	if Menu.click(game.interface, screenx, screeny, button) == false then
		local tilex, tiley = Camera.screenToTileCoords(game.mainCamera, screenx, screeny)
		if Player.clickInput(game.player, tilex, tiley, button) then
			TurnCalculator.pass(game.turnCalculator)
		end
	end
end

function Game.draw(game)
	World.draw(game.world, game.mainCamera)
	Player.drawMovementPrediction(game.player, game.mainCamera)
	Player.drawCursor(game.player, game.mainCamera)
	
	Camera.draw(0, 0, game.mainCamera)
	Camera.clear(game.mainCamera)
	
	local width, height, flags = love.window.getMode()
	Menu.draw(game.interface, 0, 0, width, height)
end

return Game