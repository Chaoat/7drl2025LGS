local Crew = {}

function Crew.new(class, origin)
	local crew = {class = class, origin = origin}
	return crew
end

return Crew