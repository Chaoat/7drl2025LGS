local CanvasStack = {}

local treeN = 1
local tree = {}

function CanvasStack.set(canvas)
	if not canvas then
		CanvasStack.reset()
	elseif treeN == 1 then
		CanvasStack.add(canvas)
		return treeN
	else
		tree[treeN] = canvas
		love.graphics.setCanvas(canvas)
		--print("canvas set")
		--CanvasStack.debugPrint()
		--Debug.printTraceback()
		return treeN
	end
end

function CanvasStack.add(canvas)
	treeN = treeN + 1
	tree[treeN] = canvas
	love.graphics.setCanvas(canvas)
	--print("canvas added")
	--CanvasStack.debugPrint()
	--Debug.printTraceback()
	return treeN
end

function CanvasStack.descend(n)
	n = n or 1
	treeN = math.max(treeN - n, 1)
	love.graphics.setCanvas(tree[treeN])
	--print("canvas descended")
	--CanvasStack.debugPrint()
	--Debug.printTraceback()
	return treeN
end

function CanvasStack.getCurrentPoint()
	return treeN
end

function CanvasStack.reset(toPoint)
	toPoint = toPoint or 1
	if toPoint > treeN then
		error("point outside range")
	end
	treeN = toPoint
	love.graphics.setCanvas(tree[treeN])
end

function CanvasStack.takeImage()
	return Misc.copyArray(tree)
end

function CanvasStack.revertToImage(stackImage)
	tree = stackImage
	treeN = #stackImage + 1
	love.graphics.setCanvas(tree[treeN])
end

function CanvasStack.debugPrint()
	print("treeN: " .. treeN)
	for i = 1, treeN do
		print(i .. ": " .. tostring(tree[i]))
	end
end

return CanvasStack