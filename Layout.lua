
local U = require "togo.utility"
local P = require "Pickle"
local M = U.module("Layout")

U.class(M)

local layout_vf = P.ValueFilter("Layout")
:filter("name", "string")
:filter("layout", {"string", M})

function M.find(given)
	if U.is_type(given, "string") then
		local layout = Site.layout[given]
		if not layout then
			P.error("layout '%s' does not exist", given)
		end
		return layout
	else
		return U.type_assert(given, M)
	end
end

function M:__init(source, file, destination)
	source = P.path(source, file)
	self.template = P.Template(source, nil, nil)

	layout_vf:consume(self, {
		name = string.match(file, "^(.*).html$") or file,
		layout = nil,
	})

	local prelude = {}
	self.template:prelude(prelude)
	layout_vf:consume(self, prelude)

	Site.layout[self.name] = self
	P.output(source, nil, P.FakeMedium(self))
end

function M:post_collect()
	if self.layout then
		local layout = M.find(self.layout)
		self.template.layout = layout.template
	end
end

function M:replace(repl, o, op)
	Site.layout[self.name] = nil
	P.replace_fields(self, repl)
	Site.layout[self.name] = self
	return true
end

return M
