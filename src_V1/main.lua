--run code below
local Static = require('Static')
local WebServer = require('WebServer')
	.new()
local cURL = require('cURL')


-- sample:
-- let our domain be `https://google.com`

-- client sent http request to home, being `google.com`
WebServer.onRequest('/', 'GET', function (client, req, res)
	res.success = true
	res.statusCode = 200
	res.statusMessage = 'OK'
	res.headers.connection = 'close'
	res.body = 'Main page'
end) -- * returned the same object, 

-- client sent http request to webpage foo, which is `google.com/foo`
.onRequest('/foo', 'GET', function (client, req, res)
	res.success = true
	res.statusCode = 200
	res.statusMessage = 'OK'
	res.headers.connection = 'close'
	res.body = 'the foo page, welcome'
end)
-- the bar page
.onRequest('/bar', 'POST', function (client, req, res)
	print(Static.table.toString(req))

	res.success = true
	res.statusCode = 200
	res.statusMessage = 'OK'
	res.headers.connection = 'close'
	res.body = 'the bar page, welcome'
end)


-- client sent http request to an invalid webpage
--[[
	At the moment, the client connection should always close, but 
	this part is custom so you can actually reroute the client to another webpage if desired
--]]
.onInvalidRequest(function (client, req, res)

	res.statusCode = 404
	res.statusMessage = 'Bad request'
	res.headers.connection = 'close'
	res.body = 'bad request idk'

end)

-- always last step
.launch()