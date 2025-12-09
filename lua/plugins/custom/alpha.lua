return {
	'goolord/alpha-nvim',
	lazy = false,
	config = function()
		local alpha = require 'alpha'
		local dashboard = require 'alpha.themes.dashboard'

		-- Load random ASCII arts
		-- Keep track of last shown ASCII art
		local last_ascii = nil
		-- load a random ASCII art
		local function load_random_ascii()
			local ascii_dir = vim.fn.stdpath 'config' .. '/lua/ascii_arts/'
			local pattern = ascii_dir .. 'ascii_art_*.lua'
			local ascii_art_files = vim.fn.glob(pattern, false, true)
			if vim.tbl_isempty(ascii_art_files) then
				return { 'Alpha' }
			end
			-- Convert file paths to module names (for require)
			local ascii_modules = {}
			for _, path in ipairs(ascii_art_files) do
				local name = path:match 'ascii_arts/([^/]+)%.lua$'
				if name then
					table.insert(ascii_modules, 'ascii_arts.' .. name)
				end
			end
			-- If only one ASCII exists, return it
			if #ascii_modules == 1 then
				last_ascii = ascii_modules[1]
				local ok, splash = pcall(require, last_ascii)
				return ok and splash or { 'Alpha' }
			end
			-- Pick a random one that isn't the same as last
			math.randomseed(os.time() + vim.loop.hrtime())
			local selected = ascii_modules[math.random(#ascii_modules)]
			while selected == last_ascii and #ascii_modules > 1 do
				selected = ascii_modules[math.random(#ascii_modules)]
			end
			last_ascii = selected
			local ok, splash = pcall(require, selected)
			return (ok and type(splash) == 'table') and splash or { 'Alpha' }
		end
		-- Function to refresh dashboard header dynamically
		local function refresh_header()
			dashboard.section.header.val = load_random_ascii()
			alpha.redraw()
		end

		-- Function to handle New File logic
		local function new_file_alpha()
			local listed = vim.fn.getbufinfo { buflisted = 1 } -- all listed buffers
			local tabs = vim.api.nvim_list_tabpages() -- all tabs
			-- If exactly one listed buffer AND one tab, delete all listed buffers and open insert mode in a new buffer
			if #listed == 1 and #tabs == 1 then
				for _, buf in ipairs(listed) do
					pcall(vim.api.nvim_buf_delete, buf.bufnr, { force = true })
				end
			end
			vim.cmd 'enew'
			vim.cmd 'startinsert'
		end
		_G.new_file_alpha = new_file_alpha

		-- Recent files button handling
		_G.open_telescope_oldfiles = function()
			vim.schedule(function()
				local keymaps = vim.api.nvim_get_keymap 'n'
				local leader = vim.g.mapleader or '\\'
				local target_key = leader .. '?'
				for _, map in ipairs(keymaps) do
					if map.lhs == target_key then
						if map.callback then
							map.callback()
						elseif map.rhs then
							vim.cmd(map.rhs)
						end
						return
					end
				end
			end)
		end

		-- Setup buttons
		dashboard.section.buttons.val = {
			-- New file
			dashboard.button('i', '  New File', '<Cmd>lua new_file_alpha()<CR>'),
			-- Recent files
			dashboard.button('<leader>?', '  Recent Files', '<Cmd>lua open_telescope_oldfiles()<CR>'),
			-- Open Neo-tree in current directory
			dashboard.button('<leader>n', '  File-tree', '<Cmd>Neotree toggle float<CR>'),
			-- Close Alpha window or quit Neovim
			dashboard.button(
				'<leader>q',
				'  Close',
				'<Cmd>lua (function() local wins = vim.api.nvim_tabpage_list_wins(0) if #wins > 1 then vim.cmd("close") else local tab_count = #vim.api.nvim_list_tabpages() if tab_count > 1 then vim.cmd("tabclose") else vim.cmd("qa!") end end end)()<CR>'
			),
		}

		-- Setup Alpha initially
		dashboard.section.header.val = load_random_ascii()
		alpha.setup(dashboard.opts)

		-- Auto-refresh header whenever Alpha is opened
		vim.api.nvim_create_autocmd('User', {
			pattern = 'AlphaReady',
			callback = function()
				refresh_header()
			end,
		})
	end,
}
