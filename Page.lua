
local U = require "togo.utility"
local P = require "Pickle"
local Layout = require "core/Layout"
local NavItem = require "core/NavItem"
local M = U.module("Page")

U.class(M)

local page_vf = P.ValueFilter("Page")
:filter("layout", {"string", Layout})
:filter("file", "string")
:filter("page_source", "string")
:filter("sitemap", "boolean")
:filter("md_disabled", "boolean")
:filter("url", "string")
:filter("title", "string")
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

function M.compose(vf, bucket, values)
	U.type_assert(vf, P.ValueFilter)
	U.type_assert(bucket, "table", true)
	U.type_assert(values, "table", true)
	return function(source, file, destination)
		return M(source, file, destination, vf, bucket, values)
	end
end

function M:__init(source, file, destination, vf, bucket, values)
	source = P.path(source, file)
	self.section_stack = {}
	self.template = P.Template(source, nil, nil, function(...)
		if #self.section_stack ~= 0 then
			P.error("%d unclosed sections at end of page: %s", #self.section_stack, source)
		end
	end)

	vf = vf or page_vf
	vf:consume(self, {
		layout = nil,
		file = "/" .. file,
		page_source = source,
		sitemap = true,
		md_disabled = false,
		url = "/" .. file,
		title = "",
		nav = {},
	}, page_vf)
	if values then
		vf:consume(self, values, page_vf)
	end
	local prelude = {}
	self.template:prelude(prelude)
	vf:consume(self, prelude, page_vf)

	self.nav_base = #self.nav
	self.bucket = bucket or Site.pages
	self.bucket[self.url] = self
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
	self.bucket[self.url] = nil
	P.replace_fields(self, repl)
	self.bucket[self.url] = self
	return true
end

function M:data(o)
	while self.nav_base < #self.nav do
		table.remove(self.nav)
	end
	return self.template:data(o)
end

return M
