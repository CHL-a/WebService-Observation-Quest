---@meta

---@class Environment
---@field get fun(s: string): string
---@field set fun(i: string, v: any): Environment

local Environment = {}

---@type Static
local Static = require('Static')

---@param s string index of env variable
---@return string?
function Environment.get(s)
	-- pre
	assert(type(s) == 'string')
	
	-- main
	return os.getenv(s)
end

---@param i string index of env variable
---@param v any value of env variable
function Environment.set(i, v)
	Static.os.runBash(
		('%s=%s'):format(i, v)
	)
	return Environment
end

return Environment;