
local U = require "togo.utility"
local P = require "Pickle"
local Core = require "core/Core"
local Page = require "core/Page"
local NavItem = require "core/NavItem"
local M = U.module("Section")

M.tpl_url = [[<a target="_blank" href="%s">%s</a>]]
M.tpl_ref = [[<span class="para-ref" id="%s"><a href="#%s"></a></span>]]
M.tpl_content = [[<h%d>%s%s</h%d>]]

function M.make(page, name, text, nav_text, url, id, level, add_nav, pre_text, post_text)
	U.type_assert(page, Page, true)
	U.type_assert(name, "string")
	U.type_assert(text, "string")
	U.type_assert(nav_text, "string", true)
	U.type_assert(url, "string", true)
	U.type_assert_any(id, {"boolean", "string"}, true)
	level = U.optional(U.type_assert(level, "number", true), 1)
	U.type_assert(add_nav, "boolean", true)
	pre_text = U.type_assert(pre_text, "string", true) or ""
	post_text = U.type_assert(post_text, "string", true) or ""

	if not U.is_type(id, "boolean") then
		id = id or slugize(name)
	end
	nav_text = pre_text .. (nav_text or text) .. post_text
	if add_nav then
		table.insert(page.nav, NavItem(nav_text, nil, "#" .. id))
	end

	if url then
		text = string.format(M.tpl_url, url, text)
	end
	text = pre_text .. text .. post_text
	local content = id and string.format(M.tpl_ref, id, id) or ""
	return string.format(M.tpl_content, level, text, content, level)
end

return M
