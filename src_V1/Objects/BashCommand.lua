---@meta

---@class BashCommand
---@field new fun(arg: BashCommand.argument): BashCommand.object

---@class BashCommand.object
---@field command string @represents the prefix of a command
---@field run fun(str: string): string @runs command directly
---@field call fun(flags: {[string]: string}?, ...: any): string 
--- calls command with converted arguments, since all commands are --- different, expect overloading this function in particular

---@class BashCommand.argument
---@field command string bash command, is prefix
---@field flags {string: flagStruct}? 
---represents the flags when running a command, it is optional here

---@type BashCommand
local BashCommand = {}

local Static = require('Static')

---@alias flagStruct {realFlag: string, valueEvaluator?: fun(a: any): string}
---@param arg BashCommand.argument @dictionary, field command is 
--- mandatory
---@return BashCommand.object
function BashCommand.new(arg)
	-- pre
	assert(arg, debug.traceback())

	---@type BashCommand.object
	local object = {}

	object.command = arg.command
	object.run = function(args)
		local command = ('%s %s'):format(object.command, args)

		return Static.os.runBash(command)
	end
	
	local temp = arg

	object.call = function(flags, ...)
		-- wtf? param arg was nil
		local arg = temp
		local subResult = ''

		local args = {...}

		if not (arg.flags and type(flags) == 'table') then
			table.insert(args, flags)
		else
			for i, v in next, flags do
				---@type flagStruct
				local flagStruct = arg.flags[i]
				
				subResult = ('%s -%s %s'):format(
					subResult,
					flagStruct.realFlag,
					flagStruct.valueEvaluator
						and flagStruct.valueEvaluator(v)
						or v
				)
			end
		end

		return object.run(
			('%s %s'):format(
				subResult,
				table.concat(args, ' ')
			)
		)
	end

	return object
end

return BashCommand;