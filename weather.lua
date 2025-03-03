local Camera = require "camera"

local Weather = {}

function Weather.new(map)
	local weather = {map = map}
	return weather
end
local waveShader = love.graphics.newShader [[
	//extern float angle;
	//extern float magnitude;
	//extern float frequency;
	extern float timer;
	
	extern vec2 tileSize;
	extern vec2 waveMapSize;
	
	vec4 effect(vec4 colour, Image image, vec2 texture_coords, vec2 pixel_coords)
    {
		float angle = 0.3;
		float magnitude = 1;
		float frequency = 1;
		
		vec2 tileCoords = vec2(ceil((texture_coords.x*waveMapSize.x)/tileSize.x), ceil((texture_coords.y*waveMapSize.y)/tileSize.y));
		float mag = sqrt(pow(tileCoords.x, 2) + pow(tileCoords.y, 2));
		float coordsAngle = atan(tileCoords.y, tileCoords.x);
		float proj = mag*cos((angle - coordsAngle));
		
		float waveSize = magnitude*cos(frequency*(proj + timer));
		
		vec2 pixShift = vec2(tileSize.x*waveSize*cos(angle),
							 tileSize.y*waveSize*sin(angle));
		
		vec2 texCoords = vec2(texture_coords.x + pixShift.x/waveMapSize.x, texture_coords.y + pixShift.y/waveMapSize.y);
		
		vec4 pixel = colour*Texel(image, texCoords);
		
		return pixel;
	}
]]

function Weather.draw(weather, camera)
	local drawX, drawY = Camera.worldToDrawCoords(weather.map.cellCornerX, weather.map.cellCornerY, camera)
	
	--waveShader:send("angle", 0)
	--waveShader:send("magnitude", 1)
	--waveShader:send("frequency", 1)
	waveShader:send("timer", GLOBALAnimationClock)
	waveShader:send("tileSize", {weather.map.waveCamera.tileWidth, weather.map.waveCamera.tileHeight})
	waveShader:send("waveMapSize", {weather.map.waveCamera.cameraWidth, weather.map.waveCamera.cameraHeight})
	
	love.graphics.setShader(waveShader)
	Camera.draw(drawX, drawY, weather.map.waveCamera)
	love.graphics.setShader()
end

return Weather