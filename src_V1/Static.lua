---@meta

---@class Static
---@field math Static.math
---@field os Static.os
---@field package Static.package
---@field string Static.string
---@field table Static.table

---@class Static.math
---@field getDigit fun(n: number, base:number, i:number): number
---@field getDigits fun(n: number, base: number): number

---@class Static.os
---@field runBash fun(cmd: string, mode: string?): string

---@class Static.package
---@field set fun(i: string, v: any)

---@class Static.string
---@field compare fun(strA: string, strB: string): boolean
---@field deparseString fun(str: string, args: {stringType: string, token: string?, equalSignLength: number}): string
---@field split fun(s: string, spl: string?, isRaw: boolean?): {[number]: string}

---@class Static.table
---@field access fun(t: table, ...: any): any
---@field empty fun(t: table)
---@field flip fun(t: table): table
---@field getN fun(t: table): integer
---@field getType fun(t: table): "array" | "dictionary" | "empty" |  "mixed" | "spotty array"
---@field indexes fun(t: table): table
---@field isSugarIndex fun(str: any): boolean
---@field popQueue fun(q:table): any
---@field toString fun(t: table, lvl: integer?, depth: integer?): string?

---@type Static
local Static = {}
Static.math = {}
Static.os = {}
Static.package = {}
Static.string = {}
Static.table = {}

--[[
	Gets the position of some digit
	 * may not work with numbers with mantissas
	 * based on digit position, with the ones place representing 0, 1 representing
	   the tens place, 2 with hundreds place etc, and going backwards may go into
	   the mantissa
	
	IN: number: n
		base: base
		i: digit position
	
	Out: number
--]]
---@param n number
---@param base number? @def: 10
---@param i number
---@return number
function Static.math.getDigit(n, base, i)
	-- pre
	base = base or 10
	assert(
		type(n) == 'number' and 
		type(base) == 'number' and 
		type(i) == 'number',
		('%s=%s\n'):rep(3)
			:format(
				tostring(n), type(n),
				tostring(base), type(base),
				tostring(i), type(i)
			)
	)
	
	-- main
	return math.floor(n / (base ^ i)) % base
end

--[[
	Gets amount of digits (atm, lets assume its a natural)
	IN: number: natural: n
		number: nautral: base
	Out: number
--]]
---@param n number
---@param base number
---@return number
function Static.math.getDigits(n, base)
	-- pre
	assert(
		type(n) == 'number' and n >= 0 and n % 1 == 0 and
		type(base) == 'number' and base >= 0 and base % 1 == 0
	)
	
	-- main
	local result = 1
	
	if n > 0 then
		result = result + math.floor(math.log(n) / math.log(base))
	end
	
	return result
end

---@param cmd string @bash command for running bash commands and 
---obtaining results
---@param mode string? @Determines how the output file is read, 
---default: `*a`
---@return string shell_output
function Static.os.runBash(cmd, mode)
	-- pre
	mode = mode or '*a'
	assert(type(cmd) == 'string')
	assert(type(mode) == 'string')

	-- main
	return io.popen(cmd)
		:read(mode)
end


---Returns boolean, comparing one string with another
---@param strA string
---@param strB string
---@return boolean
function Static.string.compare(strA, strB)
	-- pre
	assert(
		type(strA) == 'string' and 
			type(strB) == 'string'
	)

	strA = tostring(strA)
	strB = tostring(strB)

	-- main
	local result = false
	local lStr = #strA > #strB and strA or strB

	for i = 1, #lStr do
		local cA = strA:sub(i, i)
		local cB = strB:sub(i, i)
		local vA = cA == '' and -1 or cA:byte()
		local vB = cB == '' and -1 or cB:byte()

		if vA ~= vB then
			result = vA < vB
			break
		end
	end

	return result
end

---returns lua deparsed string
---@param str string
---@param args {stringType: string, token: string?, equalSignLength: number}
---@return string
function Static.string.deparseString(str, args)
	-- pre
	assert(type(str) == 'string', 'bad arg #1, not string')
	assert(type(args) == 'table', 'bad arg #2, not table')
	local typeArgs = Static.table.getType(args);
	assert(typeArgs == 'dictionary', 'bad arg #2, not dictionary, got' .. typeArgs)
	local stringType = args.stringType
	assert(stringType == 'single' or stringType == 'multiLined', 'arg2.stringType is invalid, got' .. tostring(stringType))

	if stringType == 'single' then
		local token = args.token
		assert(token == '"' or token == "'", 'bad token')
		args.beginToken = token
		args.endToken = token
	elseif stringType == 'multiLined' then
		local equalSignLength = args.equalSignLength or 0

		assert(type(equalSignLength) == 'number', 'got bad type for equalsignlength')
		assert(equalSignLength >= 0, 'equalSignLength out of range, smaller than 0')
		assert(equalSignLength % 1 == 0, 'not an integer')

		args.beginToken = '[' .. ('='):rep(equalSignLength) .. '['
		args.endToken =   ']' .. ('='):rep(equalSignLength) .. ']'
	else
		error'how'
	end

	-- main
	local result = args.beginToken

	for i = 1, #str do
		local char = str:sub(i, i)

		if stringType == 'single' then
			char = 
				char == args.beginToken and '\\' .. args.beginToken or -- ', "
				char == '\n' 			and '\\n' 					or -- \n
				char == '\\' 			and '\\\\'					or -- \
				char
		elseif stringType == 'multiLined' then
			-- this v
			-- ]====]
			if char == ']' and str:sub(i - #args.beginToken + 1, i) == args.endToken then
				char = '\\]'
			end
		end

		result = result .. char
	end

	result = result .. args.endToken

	return result
end

---split
---@param s string
---@param spl string?
---@param isRaw boolean?
function Static.string.split(s, spl, isRaw)
	-- main
	local result = {}

	if not spl or #spl == 0 then
		for i = 1, #s do
			table.insert(result, s:sub(i, i))
		end
	else
		local a = 1
		repeat
			local b, c = s:find(spl, a, isRaw)

			if b then
				table.insert(result, s:sub(a, b - 1))
				a = c + 1
			end
		until not b

		table.insert(result, s:sub(a))
	end

	return result
end

--[[
	needs a better name, access any table of any dimension, with 
	the correct amount of arguments
]]
---@param t table
---@param ... any
---@return any
function Static.table.access(t, ...)
	local result = t;

	for i = 1, select('#', ...) do
		result = result[select(i, ...)]
		if not result then
			break
		end
	end

	return result
end

---Empties a table
---@param t table
function Static.table.empty(t)
	for i in next, t do
		t[i] = nil
	end
end

--[[
	flips table
	
	IN: table
	OUT: table
]]
---@param t table
---@return table
function Static.table.flip(t)
	-- pre
	assert(type(t) == 'table')
	
	-- main
	local result = {}
	
	for i, v in next, t do
		result[v] = i
	end
	
	return result
end

-- same as table.getn
---@param t table
---@return integer
function Static.table.getN(t)
	-- pre
	assert(type(t) == 'table')

	-- main
	local result = 0

	for _ in next, t do
		result = result + 1
	end

	return result
end

-- can return "array", "dictionary", "empty", "mixed" or "spotty array"
---@param t table
---@return "array" | "dictionary" | "empty" |  "mixed" | "spotty array"
function Static.table.getType(t)
	assert(type(t) == 'table', 'BAD ARGUMENT: '.. debug.traceback())

	local result

	local stringIndexed = false
	local numberIndexed = false

	local iterations = 0

	for i in next, t do
		iterations = iterations + 1
		local typeI = type(i)

		if not stringIndexed and typeI == 'string'then
			stringIndexed = true
		elseif not numberIndexed and typeI == 'number'then
			numberIndexed = true
		end

		if numberIndexed and stringIndexed then
			-- both true, we got what we came for, break
			break
		end
	end

	-- assign result
	--[[
	result = 
		result or
		numberIndexed and (
			stringIndexed and 'mixed' or 
			#t == iterations and 'array' or
			'spotty array'
			) or 
		stringIndexed and 'dictionary' or 
		'empty'
	--]]

	-- same as ^
	if not result then
		if numberIndexed then
			if stringIndexed then
				result = 'mixed'
			elseif #t == iterations then
				result = 'array'
			else
				result = 'spotty array'
			end
		elseif stringIndexed then
			result = 'dictionary'
		else
			result = 'empty'
		end
	end

	assert(result, 'some how not met, nIndexed=' .. tostring(numberIndexed) .. ',sIndexed=' .. tostring(stringIndexed))

	return result
end

-- gets indexes of a given table
---@param t table
---@return table
function Static.table.indexes(t)
	-- pre
	assert(type(t) == 'table')

	-- main
	local result = {}

	for i in next, t do
		table.insert(result, i)
	end

	return result
end

-- checks if targeted string is considered a sugar index
---@param str any
---@return boolean
function Static.table.isSugarIndex(str)
	-- pre
	assert(type(str) == 'string')

	-- main
	local result = 
		str:sub(1, 1):match('[%a_]') and (
		str:sub(2):match('[%w_]') or str:sub(2) == '')

	return (not not result)
end

---pops queue
---@param q table
---@return any
function Static.table.popQueue(q)
	-- pre
	assert(type(q) == 'table')
	
	return table.remove(q, 1)
end

-- displays content inside of the table
---@param t table
---@param lvl integer?
---@param depth integer?
---@return string?
function Static.table.toString(t, lvl, depth)
	-- pre
	depth = depth or 10
	assert(type(t) == 'table', 't not table')
	assert(type(depth) == 'number', 'depth not number')

	if depth <= 0 then return end
	lvl = lvl or 1
	assert(type(lvl) == 'number' and lvl >= 1)

	-- main
	local result = '{'

	local iterationRan = false

	local tableType = Static.table.getType(t)
	local iterations = Static.table.getN(t)
	local currentIteration = 0

	local resultSections = {}

	for i,v in next, t do
		local ivStruct = {
			index = '';
			value = nil;
			precedingWhitespace = nil;
			separator = nil;
		}

		currentIteration = currentIteration + 1

		if not iterationRan then
			iterationRan = true
		end

		local tabs = (' '):rep(lvl * 4)
		--local section = '\n' .. tabs
		ivStruct.precedingWhitespace = '\n' .. tabs

		-- handle indexes
		if tableType ~= 'array' then
			local isSugarIndex = type(i) == 'string' and 
				Static.table.isSugarIndex(i)

			-- availble for indexes that comply with lua's sugar syntax for indexes

			if not isSugarIndex then -- possible bracket indication
				ivStruct.index = ivStruct.index .. '['
			end

			ivStruct.index = ivStruct.index .. (
				(isSugarIndex or type(i) == 'number') and 
					tostring(i) or 
					Static.string.deparseString(i, {
						stringType = 'single';
						token = "'"
					}
				)
			)

			if not isSugarIndex then
				ivStruct.index = ivStruct.index .. ']'
			end

			--section = section .. ' = '
		end
		-- handle values

		local metatable = type(v) == 'table' and getmetatable(v)
		local tostringMeta = metatable and metatable.__tostring and metatable.__tostring()

		ivStruct.value = 
			type(v) == 'string' 
				and Static.string.deparseString(v, {
					stringType = v:match('[\n\t]') and 'multiLined' or 'single';
					token = "'"
				}) 
			or type(v) == 'table' 
				and (
					tostringMeta 
						and table.concat(
							---TODO: make split a static func
							tostringMeta:split('\n'),
							'\n' .. tabs
						) 
			or Static.table.toString(v, lvl + 1, depth - 1) 
			or '(ended recursion, depth limit reached)'
		) or 
			tostring(v)

		-- concat
		--section = section .. pri ntedValues .. 
		ivStruct.separator = (
			currentIteration == iterations and '' or
				tableType == 'array' and ',' or 
				';'
		)

		--result = result .. section

		table.insert(resultSections, ivStruct)
	end

	-- finallize and return
	if iterationRan then
		if tableType ~= 'array' then
			table.sort(resultSections, function (structA, structB)
				return Static.string.compare(structA.index, structB.index)
			end)
		end
		local sections = ''

		for _, v in next, resultSections do
			sections = sections .. 
				v.precedingWhitespace .. 
				v.index .. 
				(tableType ~= 'array' and ' = ' or '') .. 
				v.value .. 
				v.separator
		end

		result = result .. 
			sections .. 
			'\n' .. 
			(' '):rep((lvl - 1) * 4)
	end

	result = result ..  '}'
	return result

end

return Static;