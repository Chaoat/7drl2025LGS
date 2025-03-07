local Camera = require "camera"
local Misc = require "misc"

local Weather = {}

function Weather.new(map)
	local weather = {map = map}
	return weather
end
local waveShader = love.graphics.newShader [[
	extern vec2 tileSize;
	extern vec2 waveMapSize;
	extern int maxDist;
	extern float timer;
	
	float PI = 3.141592;
	
	vec4 effect(vec4 colour, Image image, vec2 texture_coords, vec2 pixel_coords)
    {
		vec4 pix = Texel(image, texture_coords);
		if (pix[3] == 0 || pix == vec4(0, 0, 0, 1))
		{
			return vec4(0, 0, 0, 0);
		}
	
		vec2 texTileSize = vec2(tileSize.x/waveMapSize.x, tileSize.y/waveMapSize.y);
		
		float dist = maxDist + 1.0f;
		for (int x = -maxDist; x <= maxDist; x++)
		{
			for (int y = -maxDist; y <= maxDist; y++)
			{
				vec4 oPix = Texel(image, texture_coords + vec2(x*texTileSize.x, y*texTileSize.y));
				if (oPix == vec4(0, 0, 0, 1))
				{
					dist = floor(min(dist, max(abs(x), abs(y))));
				}
			}
		}
		
		float distFactor = dist/maxDist;
		float bloom = 0.5*sin(pow(mod(timer + distFactor, 1), 0.8) * PI);
		
		float distMult = 1.0f - dist/(maxDist + 1.0f);
		float distAddition = 0.3f*distMult;
		
		return (pix + (distAddition + bloom*distMult)*vec4(1, 1, 1, 1));
	}
]]

function Weather.draw(weather, camera)
	local drawX, drawY = Camera.worldToDrawCoords(weather.map.cellCornerX, weather.map.cellCornerY, camera)
	
	waveShader:send("tileSize", {weather.map.waveCamera.tileWidth, weather.map.waveCamera.tileHeight})
	waveShader:send("waveMapSize", {weather.map.waveCamera.cameraWidth, weather.map.waveCamera.cameraHeight})
	waveShader:send("maxDist", 3)
	waveShader:send("timer", GLOBALAnimationClock%1)
	
	love.graphics.setShader(waveShader)
	Camera.draw(Misc.round(drawX), Misc.round(drawY), weather.map.waveCamera)
	love.graphics.setShader()
end

return Weather