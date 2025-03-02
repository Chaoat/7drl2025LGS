local Font = {}

local fonts = {}

function Font.getFont(fontName, fontSize)
	if not fonts[fontName] then
		fonts[fontName] = {}
	end
	
	if not fonts[fontName][fontSize] then
		fonts[fontName][fontSize] = love.graphics.newFont("fonts/" .. fontName .. ".ttf", fontSize)
		fonts[fontName][fontSize]:setFilter("nearest", "nearest")
	end
	return fonts[fontName][fontSize]
end

function Font.setFont(fontName, fontSize)
	love.graphics.setFont(Font.getFont(fontName, fontSize))
end

return Font