--- Some JS-inspired functions written for Lua ---

local jsfuncs = {}

-- Merge two tables, but do not overwrite colliding keys
-- Implementation of utils-merge
function jsfuncs.merge(a, b)
	if a and b then
		for key,value in pairs(b) do
			a[key] = a[key] or b[key]
		end
	end
end

-- Implementation of Javascript's instanceof operator
function jsfuncs.instanceOf(object, constructor)
	constructor = tostring(constructor)
	local metatable = getmetatable(object)

	while true do
		if metatable == nil then
			return false
		end
		if tostring(metatable) == constructor then
			return true
		end

		metatable = getmetatable(metatable)
	end
end

return jsfuncs

