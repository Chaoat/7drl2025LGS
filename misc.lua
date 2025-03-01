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

return Misc