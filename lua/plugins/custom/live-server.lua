return {
	'barrett-ruth/live-server.nvim',
	build = 'npm install -g live-server',
	cmd = { 'LiveServerStart', 'LiveServerStop' },
	keys = {
		{
			'<leader>ls',
			function()
				vim.cmd 'LiveServerStart'
				_G.live_server_autosave = true
				print '✓ Live server started, auto-save enabled'
			end,
			desc = 'Start Live Server',
		},
		{
			'<leader>lx',
			function()
				vim.cmd 'LiveServerStop'
				_G.live_server_autosave = false
				if _G.live_server_timer then
					_G.live_server_timer:stop()
					_G.live_server_timer = nil
				end
				print '✗ Live server stopped, auto-save disabled'
			end,
			desc = 'Stop Live Server',
		},
	},
	config = function()
		require('live-server').setup()
		_G.live_server_autosave = true
		_G.live_server_timer = nil
		vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
			pattern = { '*.html', '*.css', '*.js' },
			callback = function()
				if not _G.live_server_autosave then
					return
				end
				if _G.live_server_timer then
					_G.live_server_timer:stop()
				end
				_G.live_server_timer = vim.defer_fn(function()
					if vim.bo.modified then
						vim.cmd 'silent! write'
					end
					_G.live_server_timer = nil
				end, 200)
			end,
		})

		-- Custom commands
		vim.api.nvim_create_user_command('LiveServerAutoSaveOn', function()
			_G.live_server_autosave = true
			print '✓ Auto-save enabled'
		end, {})

		vim.api.nvim_create_user_command('LiveServerAutoSaveOff', function()
			_G.live_server_autosave = false
			if _G.live_server_timer then
				_G.live_server_timer:stop()
				_G.live_server_timer = nil
			end
			print '✗ Auto-save disabled'
		end, {})
	end,
}
