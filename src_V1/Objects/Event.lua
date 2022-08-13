---@meta

---@class Event.connection
---@field disconnect fun(): nil @disconnects connection

---@class Event.object<A...>
---@field connect fun(func: fun(A...)): Event.connection
--- returns a connection, provided function is invoked
---@field once fun(func: fun(A...)): Event.connection 
--- returns a connection, provided function is invoked once
---@field wait fun(): ...

---@class Event.package<A...>
---@field id number
---@field queue {number: any}
---@field event Event.object<...>
---@field insert fun(a: any, a: any): nil
---@field fire fun(...: any): nil

---@class Event
---@field new fun(): Event.package<...>

---@type Event
local Event = {}

---@generic A...
function Event.new()
	
	local object
	local queue= {}
	
	object = {
		id = 0;
		queue = queue;
		
		incrementId = function()
			local result = object.id
			object.id = object.id + 1
			return result
		end;

		event = {
			connect = function(f)
				-- pre
				assert(type(f) == 'function')

				-- main
				local id = object.incrementId()
				object.insert('connect', f)
				
				return {
					disconnect = function()
						for i, v in next, object.queue do
							if v.f == f and v.id == id then
								table.remove(object.queue, i)
								return
							end
						end
						
						error('disconnected already initiated')
					end,
				}
			end,
			wait = function()
				object.incrementId()
				local thread = coroutine.running()
				object.insert('wait', function(...)
					coroutine.resume(thread, ...)
				end)
				
				return coroutine.yield(thread)
			end,
			once = function(f)
				-- pre
				assert(type(f) == 'function')

				-- main
				local id = object.incrementId()
				object.insert('once', f)

				return {
					disconnect = function()
						for i, v in next, object.queue do
							if v.f == f and v.id == id then
								table.remove(object.queue, i)
								break
							end
						end

						error('disconnected already initiated')
					end,
				}
			end,
		};
		fire = function(...)
			local i = 1;
			
			while i <= #object.queue do
				local v = object.queue[i]
				
				v.f(...)
				if v.subject ~= 'connect' then
					table.remove(object.queue, i)
					i = i - 1
				end
				
				i = i - 1
			end
		end,
		insert = function(ev, f)
			-- pre
			assert(
				(ev == 'wait' or ev == 'connect' or ev == 'once')
				and type(f) == 'function'
			)
			
			-- main
			table.insert(queue, {
				subject = ev;
				f = f;
				id = object.id
			})
		end
	}
	
	return object
end

return Event;