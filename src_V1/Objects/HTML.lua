---@meta

--| Classes
---@class HTML
---@field tag fun(tn: string?): HTML.tag
---@field tagsK HTML.tagsK
---@field tags HTML.tags
---@field tagCollection fun(...: HTML.tag): HTML.tagCollection
---@field collections HTML.collections

---@class HTML.tag
---@field attributes {[string]: string}
---@field type HTML.tag.type
---@field collection HTML.tagCollection
---@field setAttribute fun(i: string, v: string): HTML.tag
---@field addChild fun(c: HTML.tag.child): HTML.tag
---@field addChildren fun(...: HTML.tag.child): HTML.tag
---@field setType fun(type: HTML.tag.type): HTML.tag
---@field setTagName fun(tn: string): HTML.tag
---@field toString fun(indent: integer?): HTML.tag

---@alias HTML.tag.child string | HTML.tag

---@alias HTML.tag.type "nested" | "singular"

---@class HTML.tag.constructor.argument
---@field tagName string
---@field type HTML.tag.type

---@class HTML.tagCollection
---@field children {[number]: HTML.tag.child}
---@field addChild fun(c: HTML.tag.child): HTML.tagCollection
---@field addChildren fun(...: HTML.tag.child): HTML.tagCollection
---@field reset fun(... : HTML.tag.child): HTML.tagCollection
---@field toString fun(indent: integer?): string

--- Tag constants
---@class HTML.tagsK
---@field docHeader HTML.tag

--- Tag Classes
---@class HTML.tags
---@field title fun(s: string): HTML.tags.title

---@class HTML.tags.title : HTML.tag
---@field setTitle fun(title: string): HTML.tags.title

--- Tag Collection Classes
---@class HTML.collections
---@field root fun(...: HTML.tag): HTML.collection.root
---@field discordURLEmbed fun(title: string, description: string, image: string): HTML.collection.discordURLEmbed

---@class HTML.collection.root : HTML.tagCollection

---@class HTML.collection.discordURLEmbed: HTML.tagCollection
---@field setTitle fun(s: string): HTML.collection.discordURLEmbed
---@field setDescription fun(d: string): HTML.collection.discordURLEmbed
---@field setImage fun(i: string): HTML.collection.discordURLEmbed

---@type HTML
local HTML = {}
local Static = require('Static')

---returns html tag superclass
---@param tagName string?
---@return HTML.tag
function HTML.tag(tagName)
	---@type HTML.tag
	local object = {}

	object.attributes = {}
	object.type = "nested"
	object.collection = HTML.tagCollection()

	---sets attribute
	---@param i string
	---@param v string
	---@return HTML.tag
	object.setAttribute = function(i, v)
		object.attributes[i] = v
		return object
	end

	---sets child
	---@param c HTML.tag | string
	---@return HTML.tag
	object.addChild = function(c)
		object.collection.addChild(c)
		return object
	end

	---sets children
	---@param ... HTML.tag | string
	---@return HTML.tag
	object.addChildren = function (...)
		for i = 1, select("#", ...) do
			object.addChild(select(i, ...))
		end
		return object
	end

	---tag name
	---@param n string
	---@return HTML.tag
	object.setTagName = function(n)
		tagName = n
		return object
	end

	---sets type, nested or singular
	---@param s HTML.tag.type
	---@return HTML.tag
	object.setType = function(s)
		object.type = s
		return object
	end

	---return html content
	---@param indent integer
	---@return string
	object.toString = function(indent)
		indent = indent or 0
		-- indent, <, and tag name
		local result = ('%s<%s'):format(
			('\t'):rep(indent),
			tagName
		)

		-- attributes
		for i, v in next, object.attributes do
			result = result
				.. (' %s="%s"'):format(i, v)
		end
		
		-- /
		if object.type == 'nested' and 
			#object.collection.children == 0 then
			result = result .. '/'
		end

		-- >
		result = result .. '>'
		
		if object.type == 'nested' and
			#object.collection.children ~= 0 then

			local allStrings = true
			for _, v in next, object.collection.children do
				if type(v) ~= 'string' then
					allStrings = false
					break
				end
			end

			if not allStrings then
				result = result .. '\n'
			end

			result = result .. object.collection.toString(indent + 1)
			

			result = result .. ('</%s>\n'):format(
				tagName
			)
		end

		return result
	end

	return object.setTagName(tagName or 'NOTAGNAME')
end

---returns collection
---@param ... HTML.tag | string
---@return HTML.tagCollection
function HTML.tagCollection(...)
	---@type HTML.tagCollection
	local object = {}

	object.children = {}

	---adds child
	---@param c HTML.tag.child
	---@return HTML.tagCollection
	object.addChild = function (c)
		table.insert(object.children, c)
		return object
	end

	---adds children
	---@param ... HTML.tag.child
	---@return HTML.tagCollection
	object.addChildren = function (...)
		for i = 1, select('#',...)do
			object.addChild(select(i,...))
		end
		return object
	end
	
	---resets children
	---@param ... HTML.tag.child
	---@return HTML.tagCollection
	object.reset = function(...)
		Static.table.empty(object.children)
		return object.addChildren(...)
	end

	---returns string
	---@param indent integer?
	---@return string
	object.toString = function(indent)
		-- pre
		indent = indent or 0

		-- main
		local result = ''

		local allNested = true

		for _, value in next, object.children do
			if type(value) == 'string' then
				allNested = false
				break
			end
		end

		for _, value in next, object.children do
			result = result .. (
					type(value) == 'string'
						and value
						or value.toString(
							indent
						)
				)

			if allNested then
				result = result .. '\n'
			end
		end

		return result
	end

	return object.addChildren(...)
end

---constructor
---@param struct HTML.tag.constructor.argument
function loadHTMLTAG(struct)
	-- main
	local result = HTML.tag(struct.tagName)
		.setType(struct.type or 'nested')

	return result
end

HTML.tagsK = {
	docHeader = loadHTMLTAG {
		tagName = '!DOCTYPE html';
		type = 'singular'
	};
}

HTML.tags = {
	---@param s string title
	---@return HTML.tags.title
	title = function(s)
		local object = HTML.tag 'title'
		
		---sets website title
		---@param t string
		---@return HTML.tags.title
		object.setTitle = function(t)
			object.collection.reset(t)
			---@cast object HTML.tags.title
			return object
		end

		---@cast object HTML.tags.title
		return object.setTitle(s)
	end
}

HTML.collections = {
	---root collection
	---@param ... HTML.tag
	---@return HTML.tagCollection
	root = function (...)
		return HTML.tagCollection(
			HTML.tagsK.docHeader,
			...
		)
	end;

	---discord url embed
	---@param t string
	---@param d string
	---@param i string
	---@return HTML.collection.discordURLEmbed
	discordURLEmbed = function(t, d, i)
		local titleTag = HTML.tag 'meta'
			.setAttribute('property', 'og:title')
		local descriptionTag = HTML.tag 'meta'
			.setAttribute('property', 'og:description')
		local imageTag = HTML.tag 'meta'
			.setAttribute('property', 'og:image')
		local object = HTML.tagCollection(
			titleTag,
			descriptionTag,
			imageTag,
			-- temp
			HTML.tag('meta')
				.setAttribute('content', '#000508')
				.setAttribute('data-react-helmet', 'true')
				.setAttribute('name', 'theme-color')
		)

		---sets title
		---@param t string
		---@return HTML.collection.discordURLEmbed
		object.setTitle = function (t)
			titleTag.setAttribute('content', t)
			---@cast object HTML.collection.discordURLEmbed
			return object
		end

		---sets description
		---@param d string
		---@return HTML.collection.discordURLEmbed
		object.setDescription = function (d)
			descriptionTag.setAttribute('content', d)
			---@cast object HTML.collection.discordURLEmbed
			return object
		end
		
		---sets image
		---@param i string
		---@return HTML.collection.discordURLEmbed
		object.setImage = function (i)
			imageTag.setAttribute('content', i)
			---@cast object HTML.collection.discordURLEmbed
			return object
		end
		---@cast object HTML.collection.discordURLEmbed
		return object.setDescription(d)
			.setImage(i)
			.setTitle(t)
	end
}

return HTML