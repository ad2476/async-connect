---                        Middleware library for async                           ---
--- Implementation of Connect for Node.js (https://github.com/senchalabs/connect) ---

local async = require 'async'
local super = require 'super'
local jshelper = require 'helpers'	

-- Create a new async-connect server
-- Returns a function
function createServer()
	function app(request, response, Next)
		app:handle(request, response, Next)
	end
	
	jshelper.merge(app, super)
	-- TODO: Implement connect's merge of ap and EventEmitter.prototype
	app.route='/'
	app.stack = []
	
	return app
end

return createServer

