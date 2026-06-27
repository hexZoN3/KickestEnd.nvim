return {
	-- Fuzzy Finder (files, lsp, etc)
	'nvim-telescope/telescope.nvim',
	branch = '0.1.x',
	dependencies = {
		'nvim-lua/plenary.nvim',
		-- Fuzzy Finder Algorithm which requires local dependencies to be built.
		-- Only load if `make` is available. Make sure you have the system
		-- requirements installed.
		{
			'nvim-telescope/telescope-fzf-native.nvim',
			-- NOTE: If you are having trouble with this installation,
			--       refer to the README for telescope-fzf-native for more instructions.
			build = 'make',
			cond = function()
				return vim.fn.executable 'make' == 1
			end,
		},
	},

	-- Lazy-load Telescope when needed
	cmd = { 'Telescope', 'LiveGrepGitRoot' },
	keys = {
		{ '<leader>sf', desc = '[S]earch [F]iles' },
		{ '<leader>?', desc = '[?] Find recently opened files' },
		{ '<leader><leader>', desc = 'Switch to Open Buffers' },
		{ '<leader>/', desc = '[/] Fuzzily search in current buffer' },
		{ '<leader>s/', desc = '[S]earch [/] in Open Files' },
		{ '<leader>ss', desc = '[S]earch [S]elect Telescope' },
		{ '<leader>gf', desc = 'Search [G]it [F]iles' },
		{ '<leader>si', desc = '[S]earch [I]nfo' },
		{ '<leader>sw', desc = '[S]earch current [W]ord' },
		{ '<leader>sg', desc = '[S]earch by [G]rep' },
		{ '<leader>sG', desc = '[S]earch by [G]rep on Git Root' },
		{ '<leader>sd', desc = '[S]earch [D]iagnostics' },
		{ '<leader>sr', desc = '[S]earch [R]esume' },
	},

	config = function()
		-- [[ Configure Telescope ]]
		-- See `:help telescope` and `:help telescope.setup()`
		require('telescope').setup {
			defaults = {
				initial_mode = 'normal',
				mappings = {
					i = {
						['<C-u>'] = false,
						['<C-d>'] = false,
					},
					n = {
						-- disable ESC
						['<ESC>'] = false,
					},
				},
			},
		}
		-- Enable telescope fzf native, if installed
		pcall(require('telescope').load_extension, 'fzf')

		-- smart_open function for Telescope to check if the current tab has an empty "No Name" buffer. If it has, it replaces the empty buffer and open a file in the same tab
		local actions = require 'telescope.actions'
		local action_state = require 'telescope.actions.state'

		local function smart_open(prompt_bufnr)
			local entry = action_state.get_selected_entry()
			if not entry then
				return
			end
			local path = entry.path or entry.filename
			if not path then
				return
			end
			if prompt_bufnr and vim.api.nvim_buf_is_valid(prompt_bufnr) then
				pcall(actions.close, prompt_bufnr)
			end
			-- If file is already open → jump to it
			local tabpages = vim.api.nvim_list_tabpages()
			for _, tab in ipairs(tabpages) do
				for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
					local buf = vim.api.nvim_win_get_buf(win)
					if vim.api.nvim_buf_get_name(buf) == path then
						vim.api.nvim_set_current_tabpage(tab) -- jump to tab
						vim.api.nvim_set_current_win(win) -- jump to window
						return
					end
				end
			end
			-- If current tab has an empty "No Name" buffer → reuse it
			local wins = vim.api.nvim_tabpage_list_wins(0)
			for _, win in ipairs(wins) do
				local buf = vim.api.nvim_win_get_buf(win)
				local name = vim.api.nvim_buf_get_name(buf)
				local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
				local modified = vim.api.nvim_buf_get_option(buf, 'modified')
				local ft = vim.api.nvim_buf_get_option(buf, 'filetype')
				-- PATCH: also treat Alpha dashboard buffer as empty
				if (name == '' and buftype == '' and not modified) or ft == 'alpha' then
					vim.api.nvim_set_current_win(win)
					-- DELETE Alpha buffer contents if it's Alpha
					if ft == 'alpha' then
						vim.api.nvim_buf_set_option(buf, 'modifiable', true)
						vim.api.nvim_buf_set_lines(buf, 0, -1, false, {}) -- clear contents
						vim.api.nvim_buf_set_option(buf, 'buftype', '')
						vim.api.nvim_buf_set_option(buf, 'modified', false)
					end
					-- Now open the file in this window
					vim.cmd('edit! ' .. vim.fn.fnameescape(path)) -- note the !

					-- Restore normal buffer/window options after opening a file
					local normal_win_opts = {
						number = true, -- enable line numbers
						relativenumber = true, -- enable relative line numbers
						signcolumn = 'yes', -- show sign column
						cursorline = false, -- no cursorline by default
						foldenable = true, -- enable folds
						wrap = true, -- line wrap
						spell = false, -- disable spell
					}
					local win = vim.api.nvim_get_current_win()
					for opt, val in pairs(normal_win_opts) do
						vim.api.nvim_win_set_option(win, opt, val)
					end
					return
				end
			end
			-- Otherwise → open in a new tab
			vim.cmd('tabnew ' .. vim.fn.fnameescape(path))
		end

		-- Split option in Telescope file picker with smart_open
		local function smart_open_split(prompt_bufnr, split_type)
			local entry = action_state.get_selected_entry()
			if not entry then
				return
			end
			local path = entry.path or entry.filename
			if not path then
				return
			end
			if prompt_bufnr and vim.api.nvim_buf_is_valid(prompt_bufnr) then
				pcall(actions.close, prompt_bufnr)
			end
			-- Check if file is already open
			local open_tab, open_win
			for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
				for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
					local buf = vim.api.nvim_win_get_buf(win)
					if vim.api.nvim_buf_get_name(buf) == path then
						open_tab = tab
						open_win = win
						break
					end
				end
				if open_tab then
					break
				end
			end
			if open_tab then
				local choice = vim.fn.confirm('File is already open in a tab. Open split here anyway?', '&Yes\n&No', 2)
				if choice ~= 1 then
					-- User chose No → jump to the tab where file is open
					vim.api.nvim_set_current_tabpage(open_tab)
					vim.api.nvim_set_current_win(open_win)
					return
				end
				-- Else user chose Yes → continue to open split in current tab
			end
			-- Open in split
			if split_type == 'v' then
				-- horizontal → always below
				vim.cmd('belowright split ' .. vim.fn.fnameescape(path))
			elseif split_type == 'h' then
				-- vertical → always right
				vim.cmd('vertical rightbelow split ' .. vim.fn.fnameescape(path))
			end
		end

		-- Telescope keymaps for using Smart Open
		-- <leader>sf for find files
		vim.keymap.set('n', '<leader>sf', function()
			require('telescope.builtin').find_files {
				attach_mappings = function(_, map)
					map('n', 'q', actions.close)
					map('i', '<CR>', function(prompt_bufnr)
						smart_open(prompt_bufnr)
					end)
					map('n', '<CR>', function(prompt_bufnr)
						smart_open(prompt_bufnr)
					end)
					-- Horizontal split with 'h'
					map('n', 'h', function(prompt_bufnr)
						smart_open_split(prompt_bufnr, 'h')
					end)
					-- Vertical split with 'v'
					map('n', 'v', function(prompt_bufnr)
						smart_open_split(prompt_bufnr, 'v')
					end)
					return true
				end,
			}
		end, { desc = '[S]earch [F]iles' })

		-- <leader>? for old files
		vim.keymap.set('n', '<leader>?', function()
			require('telescope.builtin').oldfiles {
				attach_mappings = function(_, map)
					map('n', 'q', actions.close)
					map('i', '<CR>', function(prompt_bufnr)
						smart_open(prompt_bufnr)
					end)
					map('n', '<CR>', function(prompt_bufnr)
						smart_open(prompt_bufnr)
					end)
					-- Horizontal split with 'h'
					map('n', 'h', function(prompt_bufnr)
						smart_open_split(prompt_bufnr, 'h')
					end)
					-- Vertical split with 'v'
					map('n', 'v', function(prompt_bufnr)
						smart_open_split(prompt_bufnr, 'v')
					end)
					return true
				end,
			}
		end, { desc = '[?] Find recently opened files' })

		-- Current buffers for Telescope (switch to already open buffer)
		vim.keymap.set('n', '<leader><leader>', function()
			require('telescope.builtin').buffers {
				attach_mappings = function(_, map)
					map('n', 'q', actions.close)
					map('i', '<CR>', function(prompt_bufnr)
						smart_open(prompt_bufnr)
					end)
					map('n', '<CR>', function(prompt_bufnr)
						smart_open(prompt_bufnr)
					end)
					map('n', 'h', function(prompt_bufnr)
						smart_open_split(prompt_bufnr, 'h')
					end)
					map('n', 'v', function(prompt_bufnr)
						smart_open_split(prompt_bufnr, 'v')
					end)
					return true
				end,
			}
		end, { desc = 'Switch to Open Buffers' })

		-- Telescope live_grep in git root
		-- Function to find the git root directory based on the current buffer's path
		local function find_git_root()
			-- Use the current buffer's path as the starting point for the git search
			local current_file = vim.api.nvim_buf_get_name(0)
			local current_dir
			local cwd = vim.fn.getcwd()
			-- If the buffer is not associated with a file, return nil
			if current_file == '' then
				current_dir = cwd
			else
				-- Extract the directory from the current file's path
				current_dir = vim.fn.fnamemodify(current_file, ':h')
			end
			-- Find the Git root directory from the current file's path
			local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')[1]
			if vim.v.shell_error ~= 0 then
				print 'Not a git repository. Searching on current working directory'
				return cwd
			end
			return git_root
		end

		-- Custom live_grep function to search in git root
		local function live_grep_git_root()
			local git_root = find_git_root()
			if git_root then
				require('telescope.builtin').live_grep {
					search_dirs = { git_root },
				}
			end
		end
		vim.api.nvim_create_user_command('LiveGrepGitRoot', live_grep_git_root, {})

		-- See `:help telescope.builtin`
		vim.keymap.set('n', '<leader>/', function()
			-- You can pass additional configuration to telescope to change theme, layout, etc.
			require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
				winblend = 10,
				previewer = false,
				attach_mappings = function(prompt_bufnr, map)
					map('n', 'q', actions.close)
					return true
				end,
			})
		end, { desc = '[/] Fuzzily search in current buffer' })

		local function telescope_live_grep_open_files()
			require('telescope.builtin').live_grep {
				grep_open_files = true,
				prompt_title = 'Live Grep in Open Files',
			}
		end
		vim.keymap.set('n', '<leader>s/', telescope_live_grep_open_files, { desc = '[S]earch [/] in Open Files' })

		vim.keymap.set('n', '<leader>ss', require('telescope.builtin').builtin, { desc = '[S]earch [S]elect Telescope' })
		vim.keymap.set('n', '<leader>gf', function()
			local is_git_dir = vim.fn.system('git rev-parse --is-inside-work-tree'):gsub('%s+', '') == 'true'
			if not is_git_dir then
				vim.notify('Not a git repository', vim.log.levels.WARN, { title = 'Telescope Git Files' })
				return
			end
			require('telescope.builtin').git_files {
				attach_mappings = function(_, map)
					map('n', 'q', actions.close)
					map('i', '<CR>', smart_open)
					map('n', '<CR>', smart_open)
					return true
				end,
			}
		end, { desc = 'Search [G]it [F]iles' })

		vim.keymap.set('n', '<leader>si', require('telescope.builtin').help_tags, { desc = '[S]earch [I]nfo' })
		vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
		vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
		vim.keymap.set('n', '<leader>sG', ':LiveGrepGitRoot<cr>', { desc = '[S]earch by [G]rep on Git Root' })
		vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
		vim.keymap.set('n', '<leader>sr', require('telescope.builtin').resume, { desc = '[S]earch [R]esume' })
	end,
}
