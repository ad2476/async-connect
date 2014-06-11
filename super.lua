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
		status, e = pcall(function()
			path = parseUrl(req).path
			if not path then path = '/' end
			
			-- Skip this layer if the route doesn't match
			if path:lower() ~= layer.route:lower() then return Next(err) end

			c = path:sub(#layer.route+1, #layer.route+1)
			if c and '/' ~= c and '.' ~= c then return Next(err) end

			-- Call the layer handler and trim off the part of the url that matches the route
			removed = layer.route
			req.url = protohost + req.url:sub(#protohost + #removed + 1)

			-- Ensure leading slash
			if not fqdn and '/' ~= req.url:sub(1,1) then
				req.url = '/' + req.url
				slashAdded = true
			end
			
			local arity = #layer.handle
			if err then
				if arity == 4  then
					layer.handle(err, req, res, Next)
				else Next(err) end
			elseif arity < 4 then
				layer.handle(req, res, Next)	
			else Next() end
		end)
		if ~status then
			Next(e)
		end
	end
	Next()	
end

--- Listen for connections ---
function app.listen(domain, handler)
	return async.http.listen(domain, handler)
 
end

return app
