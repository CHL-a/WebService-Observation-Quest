---@class Database @responsible for saving and loading data, 
--- this was modeled by replit so this interface is subject to change
---@field get fun(str: string): string @get value
--- from database
---@field set fun(str: string, v: any):Database @sets 
--- value from database
---@field delete fun(str: string): Database @deletes entry
---@field list fun(term: string): string @returns list of keys in database

-- (We need generic improvements btw)

---@class Stream<A>:{value:{[number]:A},get:fun(i:integer):A,append:fun(...:A): Stream<A>}

return nil;