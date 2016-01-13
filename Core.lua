
local U = require "togo.utility"
local P = require "Pickle"
local Page = require "core/Page"
local M = U.module("Core")

local function trim_index(slug)
	slug = string.gsub(slug, "index%.html$", "")
	return slug
end

M.base_url = nil

function M.canonical_url(x)
	if type(x) == "table" and x.url then
		return trim_index(P.path(M.base_url, x.url))
	elseif U.is_type(x, "string") then
		return trim_index(P.path(M.base_url, x))
	else
		U.assert(false, "expected string or Page")
	end
end

function M.page_title(title)
	if type(title) == "table" then
		title = title.title
	end
	if title ~= "" and title ~= Site.title then
		return title .. " - " .. Site.title
	else
		return Site.title
	end
end

function M.trim(str)
	local _, a = string.find(str, '^%s*')
	local b = string.find(str, '%s*$')
	return string.sub(str, (a or 0) + 1, (b or 0) - 1)
end

function M.capitalize(s)
	return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
end

function M.format_time(time, format)
	U.type_assert(time, "number")
	U.type_assert(time, "string")

	return os.date(format, time)
end

function M.format_time_human(time)
	return M.format_time(time, Site.human_date_format)
end

function M.format_time_iso(time)
	return M.format_time(time, "%FT%H:%M:%S%:z")
end

local tw_vf = P.ValueFilter("TemplateWrapper")
:filter("minify", "boolean")

function M.filter_post_collect(...)
	local groups = {...}
	return function(_, _, _)
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
				return M.trim(func(...))
			end
		end
	end
	P.output(source, nil, P.FakeMedium(template))
	return true
end

function M.setup_site(f)
	U.type_assert(f, "function")
	_G.Site = {}
	setfenv(f, Site)
	f()
	Site.layout = {}
	Site.pages = {}
	M.base_url = P.config.testing_mode and string.format("http://%s:%s", P.config.addr, P.config.port) or Site.url
end

function M.setup_filters()
	P.filter("core/bits", M.template_wrapper)
	P.filter(M.filter_post_collect(
		Site.layout,
		Site.pages
	))
end

_G.canonical_url = M.canonical_url
_G.page_title = M.page_title
_G.trim = M.trim
_G.capitalize = M.capitalize
_G.format_time = M.format_time
_G.format_time_human = M.format_time_human
_G.format_time_iso = M.format_time_iso

return M
