local Crew = {}

function Crew.new(class, origin)
	local crew = {class = class, origin = origin}
	return crew
end

function Crew.getName(crew)
	return crew.class .. " from " .. crew.origin
end

return Crew