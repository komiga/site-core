
local U = require "togo.utility"
local P = require "Pickle"
local Page = require "core/Page"
local M = U.module("Core")

M.base_url = nil

function _G.trim_index(slug)
	slug = string.gsub(slug, "index%.html$", "")
	return slug
end

function _G.canonical_url(x, real)
	base = real and Site.url or M.base_url
	if type(x) == "table" and x.url then
		return trim_index(P.path(base, x.url))
	elseif U.is_type(x, "string") then
		return trim_index(P.path(base, x))
	else
		U.assert(false, "expected string or Page")
	end
end

function _G.page_title(title)
	if type(title) == "table" then
		title = title.title
	end
	if title ~= "" and title ~= Site.title then
		return title .. " - " .. Site.title
	else
		return Site.title
	end
end

function _G.trim(str)
	local _, a = string.find(str, "^%s*")
	local b, _ = string.find(str, "%s*$")
	return string.sub(str, (a or 0) + 1, (b or 0) - 1)
end

function _G.capitalize(s)
	return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
end

function _G.slugize(s)
	s = string.lower(s)
	s = string.gsub(s, "%s", "-")
	s = string.gsub(s, "[^%w%-_]", "")
	return s
end

M.time_formats = {
	iso = "%Y-%m-%dT%H:%M:%S%z",
	human_date_format = "%d %B %Y",
}

function _G.format_time(time, format)
	U.type_assert_any(time, {"number", "table"})
	U.type_assert(format, "string")

	return P.format_time(time, format)
end

function _G.format_time_human(time)
	return format_time(time, Site.human_date_format or M.time_formats.human_date_format)
end

function _G.format_time_iso(time)
	return format_time(time, M.time_formats.iso)
end

function _G.anchor_targeted(target, url, text, no_referrer)
	U.type_assert(target, "string", true)
	U.type_assert(url, "string")
	U.type_assert(text, "string")
	U.type_assert(no_referrer, "boolean", true)

	local tags = ""
	if target then
		tags = tags .. string.format([[target="_%s" ]], target)
	end
	if no_referrer then
		tags = tags .. [[rel="noreferrer" ]]
	end
	return string.format([[<a %shref="%s">%s</a>]], tags, url, text)
end

function _G.anchor(url, text, no_referrer)
	U.type_assert(url, "string")
	U.type_assert(text, "string")
	return anchor_targeted(nil, url, text, no_referrer)
end

function _G.anchor_ext(url, text, no_referrer)
	U.type_assert(url, "string")
	U.type_assert(text, "string")
	return anchor_targeted("blank", url, text, no_referrer)
end

local tw_vf = P.ValueFilter("TemplateWrapper")
:filter("minify", "boolean")

function M.group_post_collect(...)
	local groups = {...}
	return function()
		for _, group in ipairs(groups) do
			for _, v in pairs(group) do
				v:post_collect()
			end
		end
	end
end

function M.template_wrapper(source, file, destination)
	source = P.path(source, file)
	local template = P.Template(source, nil, nil)
	if template.prelude_func then
		local context = {
			minify = false,
		}
		template:prelude(context)
		tw_vf:consume(nil, context)
		if context.minify then
			local func = template.content_func
			template.content_func = function(...)
				return trim(func(...))
			end
		end
	end
	P.output(source, nil, P.FakeMedium(template))
	return true
end

function M.setup_site(f)
	U.type_assert(f, "function")
	_G.Site = {}
	f(Site)
	Site.layout = {}
	Site.pages = {}
	M.base_url = P.config.testing_mode and string.format("http://%s:%s", P.config.addr, P.config.port) or Site.url
end

function M.setup_filters()
	P.filter("core/bits", M.template_wrapper)
	P.post_collect(M.group_post_collect(
		Site.layout,
		Site.pages
	))
end

return M
