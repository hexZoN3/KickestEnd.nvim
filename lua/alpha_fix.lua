-- Manages Alpha refresh when switching and preserves ASCII art

_G.alpha_tab_ascii = {}

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
					alpha.start(true)
					return
				end

				local tab = vim.api.nvim_get_current_tabpage()

				if _G.alpha_tab_ascii[tab] then
					dashboard.section.header.val = _G.alpha_tab_ascii[tab]
				end

				vim.cmd 'enew'
				alpha.start(true)
			end)
		end
	end,
})

-- Clean
vim.api.nvim_create_autocmd('TabClosed', {
	pattern = '*',
	callback = function()
		local closed_tab = tonumber(vim.fn.expand '<afile>')
		if closed_tab then
			_G.alpha_tab_ascii[closed_tab] = nil
		end
	end,
})
