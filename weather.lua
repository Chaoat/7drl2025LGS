local Camera = require "camera"

local Weather = {}

function Weather.new(map)
	local weather = {map = map}
	return weather
end
local waveShader = love.graphics.newShader [[
	extern float angle;
	extern float magnitude;
	//extern float frequency;
	extern float timer;
	//
	extern vec2 tileSize;
	extern vec2 waveMapSize;
	
	vec4 effect(vec4 colour, Image image, vec2 texture_coords, vec2 pixel_coords)
    {
		//float angle = 0.3;
		//float magnitude = 0;
		//float frequency = 1;
		//
		//vec2 tileCoords = vec2((texture_coords.x*waveMapSize.x)/tileSize.x, (texture_coords.y*waveMapSize.y)/tileSize.y);
		//float mag = sqrt(pow(tileCoords.x, 2) + pow(tileCoords.y, 2));
		//float coordsAngle = atan(tileCoords.y, tileCoords.x);
		//float proj = mag*cos((angle - coordsAngle));
		//
		//float waveSize = magnitude*cos(frequency*(proj + timer));
		//
		//vec2 tileShift = vec2(waveSize*cos(angle),
		//					  waveSize*sin(angle));
		//
		////vec2 texCoords = vec2(ceil((pixShift.x + texture_coords.x*waveMapSize.x)/tileCoords.x)*tileCoords.x/waveMapSize.x, 
		////					  ceil((pixShift.y + texture_coords.y*waveMapSize.y)/tileCoords.y)*tileCoords.y/waveMapSize.y);
		//
		//tileCoords = tileCoords + tileShift;
		//
		////vec2 texShift = vec2(ceil(tileCoords.x),
		////					 ceil(tileCoords.y));
		////
		////vec2 texCoords = vec2(texture_coords.x + texShift.x,
		////					  texture_coords.y + texShift.y);
		//
		//texCoords = vec2(tileCoords)
		//
		//colour[0] = waveSize;
		//colour[2] = timer;
		//
		//vec4 pixel = colour*Texel(image, texCoords);
		
		//float angle = 0.4;
		//float magnitude = 1;
		
		vec2 tileCoords = vec2((texture_coords.x*waveMapSize.x)/tileSize.x, (texture_coords.y*waveMapSize.y)/tileSize.y);
		
		float mag = sqrt(pow(tileCoords.x, 2) + pow(tileCoords.y, 2));
		float coordsAngle = atan(tileCoords.y, tileCoords.x);
		float proj = mag*cos((angle - coordsAngle));
		
		float capMag = magnitude*cos(proj + timer);
		vec2 capCoords = vec2(ceil(tileCoords.x + capMag*cos(angle)),
							  ceil(tileCoords.y + capMag*sin(angle)));
							  
		mag = sqrt(pow(capCoords.x, 2) + pow(capCoords.y, 2));
		coordsAngle = atan(capCoords.y, capCoords.x);
		proj = mag*cos((angle - coordsAngle));
		
		float waveSize = magnitude*cos(proj);
		
		tileCoords.x = tileCoords.x + waveSize*cos(angle);
		tileCoords.y = tileCoords.y + waveSize*sin(angle);
		
		vec2 texCoords = vec2((tileCoords.x*tileSize.x)/waveMapSize.x, (tileCoords.y*tileSize.y)/waveMapSize.y);
		vec4 pixel = colour*Texel(image, texCoords);
		
		pixel = pixel + 0.2*waveSize*vec4(1, 1, 1, 0);
		
		return pixel;
	}
]]

function Weather.draw(weather, camera)
	local drawX, drawY = Camera.worldToDrawCoords(weather.map.cellCornerX, weather.map.cellCornerY, camera)
	
	waveShader:send("angle", math.pi/4)
	waveShader:send("magnitude", 0)
	--waveShader:send("frequency", 1)
	waveShader:send("timer", GLOBALAnimationClock)
	waveShader:send("tileSize", {weather.map.waveCamera.tileWidth, weather.map.waveCamera.tileHeight})
	waveShader:send("waveMapSize", {weather.map.waveCamera.cameraWidth, weather.map.waveCamera.cameraHeight})
	
	love.graphics.setShader(waveShader)
	Camera.draw(drawX, drawY, weather.map.waveCamera)
	love.graphics.setShader()
end

return Weather