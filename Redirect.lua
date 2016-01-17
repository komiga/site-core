
local U = require "togo.utility"
local P = require "Pickle"
local M = U.module("Redirect")

U.class(M)

local tpl = P.Template(nil, [[
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta http-equiv="refresh" content="0;url={! C.destination !}">
	<link rel="canonical" href="{! C.destination !}" />

	<title>(redirect)</title>
</head>
<body>
	<p>This is an automatic-redirect page. If you aren't redirected by some kind of Web 6.0 conspiracy, it's supposed to take you here:</p>

	<a href="{! C.destination !}">{{ C.destination }}</a>
</body>
</html>
]])

function M:__init(source, destination)
	U.type_assert(source, "string")
	U.type_assert(destination, "string")
	self.source = source
	self.destination = destination
end

function M:post_collect()
end

function M:write(source, destination, _)
	return tpl:write(source, destination, self)
end

function M:replace(repl, o, op)
	if self.source ~= repl.source or self.destination ~= repl.destination then
		P.replace_fields(self, repl)
		return true
	end
	return false
end

function M:data(o)
	return tpl:data(o)
end

return M
