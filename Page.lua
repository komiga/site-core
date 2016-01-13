
local U = require "togo.utility"
local P = require "Pickle"
local Layout = require "core/Layout"
local NavItem = require "core/NavItem"
local M = U.module("Page")

U.class(M)

local page_vf = P.ValueFilter("Page")
:filter("layout", {"string", Layout})
:filter("sitemap", "boolean")
:filter("md_disabled", "boolean")
:filter("title", "string")
:filter("url", "string")
:filter("nav", "table", function(_, value)
	for _, item in pairs(value) do
		if not U.is_instance(item, NavItem) then
			return nil, string.format(
				"child is not a NavItem: %s (of type %s)",
				item, U.type_class(item)
			)
		end
	end
	return value
end)

function M:__init(source, file, destination)
	source = P.path(source, file)
	self.template = P.Template(source, nil, nil)

	local prelude = {
		layout = nil,
		sitemap = true,
		md_disabled = false,
		title = "",
		url = P.path(file),
		nav = {},
	}
	self.template:prelude(prelude)
	page_vf:consume(self, prelude)

	Site.pages[self.url] = self
	P.output(source, P.path(destination, self.url), self, self)
end

function M:post_collect()
	if self.layout then
		local layout = Layout.find(self.layout)
		self.template.layout = layout.template
	end
end

function M:write(source, destination, _)
	return self.template:write(source, destination, self)
end

function M:replace(repl, o, op)
	Site.pages[self.url] = nil
	P.replace_fields(self, repl)
	Site.pages[self.url] = self
	return true
end

function M:data(o)
	return self.template:data(o)
end

return M
