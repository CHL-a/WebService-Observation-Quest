---@version 5.1

local oldRequire = require

---returns and loads code, this function is modified, I would like
---some documentation on why some leaf files (any lua file that
---does not require another lua file, aka, leaf)
---@param path string
function require(path)
	local pathA = ('%s.lua'):format(
		path:gsub('%.', '/')
	)
	local pathB = 'src_V1/Objects/' .. pathA

	local result = loadfile(pathA)
		or loadfile(pathB)
		
	if result then
		result = result()
	else
		result = oldRequire(path)
	end

	return result
end

-- load static
package.loaded.Static = dofile'src_V1/Static.lua'

-- post: run main
require('src_V1.main')

return true;