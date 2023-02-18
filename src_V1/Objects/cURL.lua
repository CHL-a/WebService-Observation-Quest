---@meta

---@class cURL @runs bash command cURL
---@field bashCommand BashCommand.object
---@field request fun(url: string, httpRequestType: string, data: string?, headers: {[string]: any}): cURL.ServerResponse
---@field get fun(url: string, data: string?, headers: {[string]: any}?): cURL.ServerResponse
---@field post fun(url: string, data: string?, headers: {[string]: any}): cURL.ServerResponse
---@field delete fun(url: string, data: string?, headers: {[string]: any}): cURL.ServerResponse
---@field bind fun(url: string): cURL.object
---@field serverResponse cURL.ServerResponse.constructor
---@field clientRequest cURL.ClientRequest.constructor

---@class cURL.object @can run commands
---@field get fun(suffix: string, data: string?, headers: {[string]: any}?): cURL.ServerResponse
---@field delete fun(suffix: string): cURL.ServerResponse
---@field post fun(suffix: string, data: string?): cURL.ServerResponse

---@class cURL.ClientRequest
---@field webPage string
---@field requestType string
---@field headers Headers
---@field httpVersion string
---@field body string?

---@class cURL.ServerResponse 
---@field body string @bodyContent
---@field headers cURL.ServerResponse.Headers
---@field statusCode number
---@field success boolean
---@field statusMessage string
---@field httpVersion string
---@field toString fun(): string

---@class cURL.ClientRequest.constructor
---@field new fun(): cURL.ClientRequest
---@field fromTCPClient fun(client: TcpServer.client): cURL.ClientRequest

---@class cURL.ServerResponse.constructor
---@field new fun(): cURL.ServerResponse
---@field fromString fun(s: string): cURL.ServerResponse

---@class cURL.ServerResponse.Headers possibly more headers
---@field Content-Length number
---@field Content-Type string

---@type cURL
local cURL = {}
local StringParser = 
	require('StringParser')

local BashCommand = 
	require('BashCommand')

---@module "Static"
local Static = require('Static')

local tempStringParser = StringParser.new''

---@type flagStruct
local tempA = {
	requestType = {realFlag = 'X'};
	showHeader = {realFlag = 'i'};
	noProgress = {realFlag = 's'};
	data = {
		realFlag = 'd';
		valueEvaluator = function (v)
			return ('\'%s\''):format(v)
		end
	};
	
	headers = {
		realFlag = 'H';
		valueEvaluator = function(v)
			local result = ''

			for a, b in next, v do
				if #result ~= 0 then
					result = result .. ' -H '
				end

				result = result .. 
					('"%s: %s"'):format(a, b)
			end

			return result
		end
	}
}

cURL.bashCommand = BashCommand.new{
	command = 'curl'; 
	flags = tempA
}

---http request
---@param url string
---@param httpType string
---@param data string?
---@param headers {[string]: string}
---@return cURL.ServerResponse
function cURL.request(url, httpType, data, headers)
	local flags = {
		requestType = httpType;
		showHeader = '';
		noProgress = ''
	}

	if data then
		flags.data = data
	end

	if headers then
		flags.headers = headers
	end

	return cURL.serverResponse.fromString(
		cURL.bashCommand.call(flags, url)
	)
end

local function factRequest(s)
	---implement a request type (check index)
	---@param u string url
	---@param data string data
	---@param headers {[string]: string}
	---@return cURL.ServerResponse
	return function (u, data, headers)
		return cURL.request(u, s, data, headers)
	end
end

cURL.get = factRequest'GET'
cURL.delete = factRequest'DELETE'
cURL.post = factRequest'POST'

---binds url to a new object (can be used for api requests)
---@param url string
---@return cURL.object
function cURL.bind(url)

	---@type cURL.object
	local object = {}

	local function factRequest(i)
		return function (suffix, data, headers)
			return cURL[i](url..suffix, data, headers)
		end
	end

	object.get = factRequest'get'
	object.delete = factRequest'delete'
	object.post = factRequest'post'

	return object
end

cURL.serverResponse = {}

---comment
---@return cURL.ServerResponse
function cURL.serverResponse.new()
	---@type cURL.ServerResponse
	local object = {}

	object.headers = {}

	-- methods
	function object.toString()
		local temp = ''
		object.headers['Content-Length'] = #object.body

		for i, v in next, object.headers do
			temp = ('%s%s:%s\n'):format(temp, i, tostring(v))
		end

		return ('%s %s %s\n%s\r\n%s'):format(
			assert(
				object.httpVersion, 
				'missing http version'
			),
			assert(
				object.statusCode,
				'missing status code'
			),
			assert(
				object.statusMessage,
				'missing status message'
			),
			assert(
				temp,
				'missing headers'
			),
			assert(
				object.body,
				'missing body'
			)
		)
	end

	return object
end

---gets server response from a whole string
---@param s string
---@return cURL.ServerResponse
function cURL.serverResponse.fromString(s)
	local object = cURL.serverResponse.new()

	tempStringParser.reset(s)

	-- first line: HTTPVERSION STATUSCODE STATUSMESSAGE
	-- http version
	local temp = tempStringParser.popUntil(' ')
	object.httpVersion = assert(temp)

	-- status code
	temp = tempStringParser.popUntil' '
	assert(temp)

	object.statusCode = assert(tonumber(temp))

	-- success
	object.success = object.statusCode == 200

	-- status code
	temp = tempStringParser.popUntil'\n'
	
	object.statusMessage = assert(temp)
	
	-- anything below this are other lines, an empty line
	-- and the body in that order, separated by line breaks
	-- headers
	while not tempStringParser.cPop('\r\n', true) do
		local index = tempStringParser.popUntil(':', true)
		assert(index)

		local value = tempStringParser.popUntil('\n')
		assert(value)

		object.headers[index] = value
	end

	-- body
	object.body = tempStringParser.content:sub(tempStringParser.i)

	return object
end

cURL.clientRequest = {}

---purposely a constructor in the case of more methods
---@return cURL.ClientRequest
function cURL.clientRequest.new()
	local object = {}
	object.headers = {}

	return object
end

---@param client TcpServer.client
---@return cURL.ClientRequest
function cURL.clientRequest.fromTCPClient(client)
	-- error('is testing')

	---@type cURL.ClientRequest
	local object = cURL.clientRequest.new()

	-- request Type
	local temp, tempA = client:receive()

	assert(not tempA and temp)

	local temp = tempStringParser.reset(temp)
		.popUntil' '
	object.requestType = assert(temp)




	-- web page

	temp = tempStringParser.popUntil' '
	object.webPage = assert(temp)

	-- http version
	object.httpVersion = tempStringParser.toEnd()

	-- headers
	local line, closed
	repeat
		line, closed = client:receive()

		assert(not closed)

		if line ~= '' then
			local index = tempStringParser.reset(line)
				.popUntil(': ')
			assert(index)
			
			object.headers[index] = tempStringParser.toEnd()
		end
	until line == '' or closed

	-- body
	if object.headers['Content-Length'] then
		object.body = client:receive(tonumber(object.headers['Content-Length']))
	end
	--[[
	while not closed do
		line, closed = client:receive()
		
		print(closed)

		object.body = object.body .. line
	end
--]]
	return object
end

return cURL;