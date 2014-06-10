--- Contains the "add" class which is used by connect.lua as "super" ---

local parseUrl = require 'lhttp_parser'.parseUrl

local app = {} -- the object that will be merged with app

-- Analogous to connect.use() -> app:use()
function app.use(self, route, fn)
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

function app.handle(self, req, res, out)
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
	
end

return app
