local Misc = {}

function Misc.round(n)
	return math.floor(n + 0.5)
end

function Misc.binaryInsert(array, element, comparator)
	--comparator(a, b) return 1 if a > b, -1 if a < b, 0 if a = b
	local positionFound = false
	local start = 1
	local finish = #array
	local checkingI = math.floor((start + finish)/2)
	
	while positionFound == false do
		if start > finish then
			checkingI = finish + 1
			positionFound = true
		elseif finish < start then
			checkingI = start
			positionFound = true
		else
			local comparison = comparator(element, array[checkingI])
			if comparison == 1 then
				start = checkingI + 1
				checkingI = math.ceil((checkingI + finish)/2)
			elseif comparison == -1 then
				finish = checkingI - 1
				checkingI = math.floor((checkingI + start)/2)
			else
				positionFound = true
			end
		end
	end
	
	table.insert(array, checkingI, element)
end

function Misc.orthogDistance(x1, y1, x2, y2)
	return math.max(math.abs(x1 - x2), math.abs(y1 - y2))
end

function Misc.orthogPointFrom(x, y, dist, angle)
	local multAngle = (angle + math.pi/4)%(math.pi/2) - math.pi/4
	
	local distMultiple = 1/math.cos(multAngle)
	
	local returnX = x + distMultiple*dist*math.cos(angle)
	local returnY = y + distMultiple*dist*math.sin(angle)
	
	return returnX, returnY
end

function Misc.orthogLineBetween(x1, y1, x2, y2)
	local dist = Misc.round(Misc.orthogDistance(x1, y1, x2, y2))
	local angle = math.atan2(y2 - y1, x2 - x1)
	
	local coords = {}
	for i = 0, dist do
		local xCoord, yCoord = Misc.orthogPointFrom(x1, y1, i, angle)
		table.insert(coords, {Misc.round(xCoord), Misc.round(yCoord)})
	end
	return coords
end

function Misc.differenceBetweenAngles(a1, a2)
	a1 = a1%(2*math.pi)
	a2 = a2%(2*math.pi)
	if math.abs(a2 - a1) <= math.pi then
		return a2 - a1
	elseif math.abs(a2 - a1 - 2*math.pi) <= math.pi then
		return a2 - a1 - 2*math.pi
	elseif math.abs(a2 - a1 + 2*math.pi) <= math.pi then
		return a2 - a1 + 2*math.pi
	end
end

function Misc.randomFromList(list)
	local randChoice = math.ceil(math.random()*#list)
	return list[randChoice], randChoice
end

function Misc.moveTowardsNumber(current, target, decreaseAmount, increaseAmount)
	if target > current then
		return math.min(target, current + increaseAmount)
	elseif target < current then
		return math.max(target, current + decreaseAmount)
	end
	return current
end

function Misc.multiplyColours(c1, c2)
	--print(c1[1] .. ":" .. c1[2] .. ":" .. c1[3] .. ":" .. c1[4])
	--print(c2[1] .. ":" .. c2[2] .. ":" .. c2[3] .. ":" .. c2[4])
	return {c1[1]*c2[1], c1[2]*c2[2], c1[3]*c2[3], c1[4]*c2[4]}
end

function Misc.addColours(c1, c2)
	return {c1[1] + c2[1], c1[2] + c2[2], c1[3] + c2[3], c1[4] + c2[4]}
end

return Misc