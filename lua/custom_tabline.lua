-- Custom native-looking tabline that matches Kanagawa theme
-- This module creates a fixed-width, scrollable tabline that
local M = {}

local max_visible_tabs = 8 -- maximum number of tabs visible at once
local tab_offset = 1

function M.tabline()
	local current_tab = vim.fn.tabpagenr()
	local tab_count = vim.fn.tabpagenr '$'
	local win_width = vim.o.columns
	local tab_width = math.floor(win_width / max_visible_tabs) -- FIXED width

	local tabs = {}
	for i = 1, tab_count do
		local buflist = vim.fn.tabpagebuflist(i)
		local winnr = vim.fn.tabpagewinnr(i)
		local bufname = vim.fn.bufname(buflist[winnr])
		if bufname == '' then
			bufname = '[No Name]'
		end
		local modified = vim.fn.getbufvar(buflist[winnr], '&mod') == 1 and ' ●' or ''
		local label = i .. ': ' .. vim.fn.fnamemodify(bufname, ':t') .. modified

		-- truncate/pad to fixed tab_width
		if vim.fn.strwidth(label) > tab_width - 2 then
			while vim.fn.strwidth(label) > tab_width - 3 and #label > 0 do
				label = label:sub(1, -2)
			end
			label = label .. '…'
		end
		label = label .. string.rep(' ', tab_width - vim.fn.strwidth(label))

		tabs[i] = (i == current_tab and '%#TabLineSel#' or '%#TabLine#') .. label
	end

	-- scrolling logic to keep active tab visible
	local start_index = tab_offset
	if current_tab < start_index then
		start_index = current_tab
	elseif current_tab >= start_index + max_visible_tabs then
		start_index = current_tab - max_visible_tabs + 1
	end
	tab_offset = start_index

	-- select visible tabs
	local visible_tabs = {}
	for i = start_index, math.min(start_index + max_visible_tabs - 1, tab_count) do
		table.insert(visible_tabs, tabs[i])
	end

	-- scrolling arrows
	local left_arrow = start_index > 1 and '< ' or '  '
	local right_arrow = start_index + max_visible_tabs - 1 < tab_count and ' >' or '  '

	return '%#TabLine#' .. left_arrow .. table.concat(visible_tabs, '') .. right_arrow .. '%#TabLineFill#'
end

-- adjust offset if tabs are closed
vim.api.nvim_create_autocmd({ 'TabClosed' }, {
	callback = function()
		local tab_count = vim.fn.tabpagenr '$'
		if tab_offset > tab_count then
			tab_offset = math.max(tab_count - max_visible_tabs + 1, 1)
		end
	end,
})

return M
