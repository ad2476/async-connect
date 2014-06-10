---                        Middleware library for async                           ---
--- Implementation of Connect for Node.js (https://github.com/senchalabs/connect) ---

local async = require 'async'
local parseUrl = require 'lhttp_parser'.parseUrl

local proto = {} -- the object that will be merged with app

-- Merge two tables, but do not overwrite colliding keys
-- Implementation of utils-merge
function merge(a, b)
	if a and b then
		for key,value in pairs(b) do
			a[key] = a[key] or b[key]
		end
	end
end

-- Implementation of Javascript's instanceof operator
function instanceOf(object, constructor)
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

-- Analogous to connect.use() -> proto:use()
function proto.use(self, route, fn)
	-- Default is to route to '/'
	if type(route) ~= 'string' then
		fn = route
		route = '/'
	end

	-- wrap sub-apps
	if type(fn.handle) == 'function' then
		server = fn
		server.route = route
		fn = function(request, response, Next)
			server.handle(request, response, Next)
		end
	end

	-- TODO: Implement connect's wrapping of vanilla http.Servers for Async and Lua
	-- No idea how to do this currently, so leaving it out

	-- Strip trailing slash
	if route[#route - 1] == '/' then
		route = route:sub(1, #route-1)
	end

	table.insert(self.stack, {route=route, handle=fn})

	return self
end

function proto.handle(self, req, res, out)
	local stack = self.stack
	local search = 1+string.find(req.url, '?')
	local pathlength = search-1 or #req.url
	local fqdn = 1 + string.find(req.url:sub(1, pathlength), '://')
	local protohost = fqdn and req.url:sub(1, string.find(req.url, '/', 2+fqdn)) or ''
	local removed = ''
	local slashAdded = false
	local index = 1

	-- TODO: Figure out a final function handler à la connect
	
	function Next(err)
		local layer, path, c
		
		if slashAdded then
			req.url = req.url:sub(2)
		end
		
		req.url = protohost + removed + req.url:sub(#protohost)
		-- TODO: Something like req.originalUrl = req.originalUrl || req.url -> in Lua
		removed = ''

		index=index+1
		layer = stack[index]

		-- All done!
		if ~layer then
			-- TODO: done(err)
			return
		end

	-- A bunch of stuff is inside a try...catch statement in Connect's JS code
	-- No idea how to make a try...catch block in Lua - there's pcall but that's for individual functions...
	-- TODO: Finish proto.handle()
		

-- Create a new middleware server
-- Returns a function
function createServer()
	function app(request, response, Next)
		app:handle(request, response, Next)
	end
	
	merge(app, proto)
	-- TODO: Implement connect's merge of ap and EventEmitter.prototype
	app.route='/'
	app.stack = []
	
	return app
end

-- createServer() is the 'module' we 'export' when used by require('middleware')
return createServer

