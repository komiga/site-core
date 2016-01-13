
local U = require "togo.utility"
local P = require "Pickle"
local M = U.module("NavItem")

U.class(M)

local tpl = P.Template(nil, [[
{% if not C.url then %}
<li><span class="nav-item bold{% if C.class then %} {{ C.class }}{% end %}">{% if C.text then %}{{ C.text }}{% else %}:{% end %}</span></li>
{% else %}
<li><a class="nav-item link{% if string.sub(C.url, 1, 1) ~= '#' then %} bold{% end %}{% if C.class then %} {{ C.class }}{% end %}"{% if C.title then %} title="{{ C.title }}"{% end %} href="{{ C.url }}">{% if C.icon then %}<img class="nav-item-icon{% if C.icon_class then %} {{ C.icon_class }}{% end %}" src="/images/icons/{{ C.icon }}" alt="{{ C.title }}"/>{% end %}{% if C.text then %}{{ C.text }}{% end %}</a></li>
{% end %}]])

function M:__init(text, title, url, icon, icon_class, class)
	self.text = U.type_assert(text, "string", true)
	self.title = U.type_assert(title, "string", true)
	self.url = U.type_assert(url, "string", true)
	self.icon = U.type_assert(icon, "string", true)
	self.icon_class = U.type_assert(icon_class, "string", true)
	self.class = U.type_assert(class, "string", true)
end

function M:__tostring()
	return tpl:content(self)
end

return M
