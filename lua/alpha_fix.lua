-- Manages Alpha refresh when switching and preserves ASCII art
-- Temporarily unlist other buffers so alpha.start(true) isn't skipped
-- when other tabs have real files open, then restore them after.
-- Also bypass argc()>0, which alpha's own should_skip_alpha() checks
-- first -- this stays true for the whole session if nvim was launched
-- as `nvim file.txt`, blocking alpha.start(true) everywhere afterward.

_G.alpha_tab_ascii = {}

local function force_alpha_start()
	local alpha_loaded, alpha = pcall(require, 'alpha')
	if not alpha_loaded then
		return
	end

	local curbuf = vim.api.nvim_get_current_buf()
	local restore = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if buf ~= curbuf and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, 'buflisted') then
			table.insert(restore, buf)
			vim.api.nvim_buf_set_option(buf, 'buflisted', false)
		end
	end

	local orig_argc = vim.fn.argc
	vim.fn.argc = function(...)
		return 0
	end
	local ok = pcall(alpha.start, true)
	vim.fn.argc = orig_argc
	if not ok then
		vim.notify('Failed to start Alpha', vim.log.levels.ERROR)
	end

	for _, buf in ipairs(restore) do
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_set_option(buf, 'buflisted', true)
		end
	end
end
_G.force_alpha_start = force_alpha_start

local last_tab_count = #vim.api.nvim_list_tabpages()

-- Save ASCII art
vim.api.nvim_create_autocmd('TabLeave', {
	pattern = '*',
	callback = function()
		local buf = vim.api.nvim_get_current_buf()
		local buftype = vim.api.nvim_buf_get_option(buf, 'filetype')
		if buftype == 'alpha' then
			local dashboard_loaded, dashboard = pcall(require, 'alpha.themes.dashboard')
			if dashboard_loaded then
				local tab = vim.api.nvim_get_current_tabpage()
				-- Save the current ASCII for this tab
				_G.alpha_tab_ascii[tab] = vim.deepcopy(dashboard.section.header.val)
			end
		end
	end,
})

-- Refresh Alpha when switching to a tab with Alpha buffer
vim.api.nvim_create_autocmd('TabEnter', {
	pattern = '*',
	callback = function()
		local current_tab_count = #vim.api.nvim_list_tabpages()

		if current_tab_count > last_tab_count then
			last_tab_count = current_tab_count
			return
		end

		last_tab_count = current_tab_count

		local buf = vim.api.nvim_get_current_buf()
		local buftype = vim.api.nvim_buf_get_option(buf, 'filetype')
		if buftype == 'alpha' then
			vim.schedule(function()
				local alpha_loaded, alpha = pcall(require, 'alpha')
				if not alpha_loaded then
					return
				end

				local dashboard_loaded, dashboard = pcall(require, 'alpha.themes.dashboard')
				if not dashboard_loaded then
					vim.cmd 'enew'
					force_alpha_start()
					return
				end

				local tab = vim.api.nvim_get_current_tabpage()

				if _G.alpha_tab_ascii[tab] then
					dashboard.section.header.val = _G.alpha_tab_ascii[tab]
				end

				vim.cmd 'enew'
				force_alpha_start()
			end)
		end
	end,
})

-- Clean
vim.api.nvim_create_autocmd('TabClosed', {
	pattern = '*',
	callback = function()
		local live_tabs = {}
		for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
			live_tabs[tab] = true
		end
		for cached_tab, _ in pairs(_G.alpha_tab_ascii) do
			if not live_tabs[cached_tab] then
				_G.alpha_tab_ascii[cached_tab] = nil
			end
		end
	end,
})
