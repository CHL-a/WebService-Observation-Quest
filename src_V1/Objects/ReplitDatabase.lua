---@meta

---@class ReplitDataBase : Database
---@field url string
---@field cURLBinded cURL.object

---@type ReplitDataBase
local ReplitDataBase = {}

---@type Static
local Static = require('Static')

local cURL = require('cURL')
local Environment = require('Environment')

ReplitDataBase.url = assert(
	Environment.get('REPLIT_DB_URL')
)

assert(
	ReplitDataBase.url:sub(1,5) == 'https', 
	ReplitDataBase.url
)

ReplitDataBase.cURLBinded = cURL.bind(ReplitDataBase.url)

---gets data from database
---@param i string
---@return string
function ReplitDataBase.get(i)
	local requestStruct = 
		ReplitDataBase.cURLBinded.get('/' .. i)

	assert(
		requestStruct.statusCode == 200,
		requestStruct.statusMessage
	)

	return requestStruct.body
end

---returns availble indexes from database containing `term` prefix
---@param term string
---@return string
function ReplitDataBase.list(term)
	local requestStruct = 
		ReplitDataBase.cURLBinded.get('?prefix='..term)

	assert(
		requestStruct.statusCode == 200, 
		requestStruct.statusMessage
	)

	return requestStruct.body
end

---sets data
---@param i string
---@param v string
---@return ReplitDataBase
function ReplitDataBase.set(i, v)
	ReplitDataBase.cURLBinded.post('', i .. '=' .. v)

	return ReplitDataBase
end

---deletes data
---@param i string
---@return ReplitDataBase
function ReplitDataBase.delete(i)
	ReplitDataBase.cURLBinded.delete('/'..i)

	return ReplitDataBase
end

return ReplitDataBase;