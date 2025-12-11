vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- keymaps.lua
require 'keymaps'

-- Copy custom snippets from custom_friendly_snippets folder
require 'replace_with_custom_snippets'

-- :UpdateKickestEnd command to safely update KickestEnd.nvim config from origin/master
require 'update_kickestend'

-- Load yank notification with line counts
require 'yank_notification'

-- [[ Install `lazy.nvim` plugin manager ]]
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system {
		'git',
		'clone',
		'--filter=blob:none',
		'https://github.com/folke/lazy.nvim.git',
		'--branch=stable', -- latest stable release
		lazypath,
	}
end
vim.opt.rtp:prepend(lazypath)

-- [[ Configure plugins ]]
-- NOTE: Here is where you install your plugins.
--  You can configure plugins using the `config` key.
--  You can also configure plugins after the setup call,
--    as they will be available in your neovim runtime.

-- Disables which-key healthcheck notifications
do
	local orig_notify = vim.notify
	vim.notify = function(msg, ...)
		if type(msg) == 'string' and msg:match 'which%-key' then
			return -- ignore WhichKey health messages
		end
		return orig_notify(msg, ...)
	end
end

require('lazy').setup({
	-- Useful plugin to show you pending keybinds.
	{ 'folke/which-key.nvim', event = 'VeryLazy', opts = {} },

	-- Git related plugins
	{
		'tpope/vim-fugitive',
		cmd = { 'Git', 'G', 'Gdiffsplit', 'Gread', 'Gwrite', 'Ggrep', 'GMove', 'GDelete', 'GBrowse' },
		dependencies = { 'tpope/vim-rhubarb' },
	},

	{ -- NOTE: This is where your plugins related to LSP can be installed.
		-- LSP Configuration & Plugins
		'neovim/nvim-lspconfig',
		event = { 'BufReadPre', 'BufNewFile' },
		dependencies = {
			-- Automatically install LSPs to stdpath for neovim
			'williamboman/mason.nvim',
			'williamboman/mason-lspconfig.nvim',

			-- Conform
			{
				'stevearc/conform.nvim',
				opts = {
					formatters_by_ft = {
						lua = { 'stylua' },
						python = { 'isort', 'yapf' },
						javascript = {
							'prettierd',
						},
						typescript = {
							'prettierd',
						},
						typescriptreact = {
							'prettierd',
						},
						css = {
							'prettierd',
						},
						html = {
							'prettierd',
						},
						json = {
							'prettierd',
						},
						c = {
							'clang-format',
						},
						cpp = {
							'clang-format',
						},
						bash = { 'shfmt' },
						rust = { 'rustfmt' },
					},
					format_on_save = {
						timeout_ms = 500,
						lsp_format = 'fallback',
					},
				},
				-- format without saving
				vim.keymap.set('n', '<leader>f', function()
					require('conform').format { async = true }
				end, { desc = 'Format buffer' }),
			},

			-- Install formatters automatically
			{
				'zapling/mason-conform.nvim',
				dependencies = { 'williamboman/mason.nvim', 'stevearc/conform.nvim' },
				config = function()
					require('mason-conform').setup {
						ensure_installed = true, -- auto-install all formatters listed in Conform
					}
				end,
			},
			-- Useful status updates for LSP
			-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
			{ 'j-hui/fidget.nvim', opts = {} },

			-- Additional lua configuration, makes nvim stuff amazing!
			'folke/neodev.nvim',
		},
	},
	{ -- Autocompletion
		'hrsh7th/nvim-cmp',
		event = 'InsertEnter',
		dependencies = {
			-- Snippet Engine & its associated nvim-cmp source
			'L3MON4D3/LuaSnip',
			dependencies = { 'rafamadriz/friendly-snippets' },
			'saadparwaiz1/cmp_luasnip',
			-- Adds LSP completion capabilities
			'hrsh7th/cmp-nvim-lsp',
			'hrsh7th/cmp-path',
			-- Adds a number of user-friendly snippets
			'rafamadriz/friendly-snippets',
		},
	},

	{
		-- Adds git related signs to the gutter, as well as utilities for managing changes
		'lewis6991/gitsigns.nvim',
		event = 'BufReadPre',
		opts = {
			-- See `:help gitsigns.txt`
			signs = {
				add = { text = '+' },
				change = { text = '~' },
				delete = { text = '_' },
				topdelete = { text = '‾' },
				changedelete = { text = '~' },
			},
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map({ 'n', 'v' }, ']c', function()
					if vim.wo.diff then
						return ']c'
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return '<Ignore>'
				end, { expr = true, desc = 'Jump to next hunk' })

				map({ 'n', 'v' }, '[c', function()
					if vim.wo.diff then
						return '[c'
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return '<Ignore>'
				end, { expr = true, desc = 'Jump to previous hunk' })

				-- Actions
				-- visual mode
				map('v', '<leader>hs', function()
					gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
				end, { desc = 'stage git hunk' })
				map('v', '<leader>hr', function()
					gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
				end, { desc = 'reset git hunk' })
				-- normal mode
				map('n', '<leader>hs', gs.stage_hunk, { desc = 'git stage hunk' })
				map('n', '<leader>hr', gs.reset_hunk, { desc = 'git reset hunk' })
				map('n', '<leader>hS', gs.stage_buffer, { desc = 'git Stage buffer' })
				map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
				map('n', '<leader>hR', gs.reset_buffer, { desc = 'git Reset buffer' })
				map('n', '<leader>hp', gs.preview_hunk, { desc = 'preview git hunk' })
				map('n', '<leader>hb', function()
					gs.blame_line { full = false }
				end, { desc = 'git blame line' })
				map('n', '<leader>hd', gs.diffthis, { desc = 'git diff against index' })
				map('n', '<leader>hD', function()
					gs.diffthis '~'
				end, { desc = 'git diff against last commit' })

				-- Toggles
				map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = 'toggle git blame line' })
				map('n', '<leader>td', gs.toggle_deleted, { desc = 'toggle git show deleted' })

				-- Text object
				map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'select git hunk' })
			end,
		},
	},
	{
		--kanagawa colorscheme
		'rebelot/kanagawa.nvim',
		lazy = false,
		priority = 1000,
		opts = {},
	},
	{
		-- Set lualine as statusline
		'nvim-lualine/lualine.nvim',
		-- See `:help lualine.txt`
		opts = {
			options = {
				icons_enabled = true,
				component_separators = '|',
				section_separators = '',
			},
		},
	},
	{
		-- Add indentation guides even on blank lines
		'lukas-reineke/indent-blankline.nvim',
		-- Enable `lukas-reineke/indent-blankline.nvim`
		-- See `:help ibl`
		main = 'ibl',
		event = 'BufReadPre',
		opts = {},
	},
	-- "gc" to comment visual regions/lines
	{ 'numToStr/Comment.nvim', event = 'BufReadPre', opts = {} },
	{
		-- Highlight, edit, and navigate code
		'nvim-treesitter/nvim-treesitter',
		dependencies = {
			'nvim-treesitter/nvim-treesitter-textobjects',
		},
		build = ':TSUpdate',
	},
	{ --Autopairs
		'windwp/nvim-autopairs',
		event = 'InsertEnter',
		config = true,
		-- use opts = {} for passing setup options
		-- this is equalent to setup({}) function
	},

	-- NOTE: Next Step on Your Neovim Journey: Add/Configure additional "plugins" for kickstart
	--       These are some example plugins that I've included in the kickstart repository.
	--       Uncomment any of the lines below to enable them.
	require 'plugins.kickstart.autoformat',
	--require 'plugins.kickstart.debug'

	-- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/plugins/custom/*.lua`
	--    You can use this folder to prevent any conflicts with this init.lua if you're interested in keeping
	--    up-to-date with whatever is in the kickstart repo.
	--    Uncomment the following line and add your plugins to `lua/plugins/custom/*.lua` to get going.
	--    For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins
	{ import = 'plugins.custom' },
}, {})

-- [[ Setting options ]]
-- See `:help vim.o`

-- Line wrap
vim.opt.wrap = true

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.opt.number = true

-- Relative line number
vim.opt.relativenumber = true

-- Enable mouse mode
vim.o.mouse = ''

-- Always keep a distance of the cursor to the top and bottom of the screen
vim.opt.scrolloff = 8

-- Sync clipboard between OS and Neovim.
--  See `:help 'clipboard'`
-- vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- Tabs and indentation
vim.o.expandtab = false -- use spaces instead of tabs
vim.o.shiftwidth = 4 -- number of spaces for autoindent
vim.o.softtabstop = 0 -- number of spaces per Tab in insert mode
vim.o.tabstop = 4 -- number of spaces a Tab counts for
vim.o.smartindent = true -- auto-indent new lines

-- [[ Change current directory to the path if specified and open Neo-tree there ]]
vim.api.nvim_create_autocmd('VimEnter', {
	callback = function(data)
		local is_directory = vim.fn.isdirectory(data.file) == 1
		if not is_directory then
			return
		end
		local buf = vim.api.nvim_get_current_buf()
		if vim.api.nvim_buf_get_name(buf) == '' and vim.api.nvim_buf_line_count(buf) == 1 then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
		vim.defer_fn(function()
			require('neo-tree.command').execute { action = 'show', dir = data.file }
		end, 50)
	end,
})

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = '*',
})

-- [[ Theme ]]
require('kanagawa').setup { transparent = true }
vim.cmd [[colorscheme kanagawa]]

-- [[ Custom native-looking tabline ]]
vim.o.showtabline = 1
local custom_tabline = require 'custom_tabline'
vim.o.tabline = '%!v:lua.require("custom_tabline").tabline()'

-- [[ Auto-create config files for formatters ]]
require('formatters_auto_config').setup()

-- [[ Auto-clear command line messages on most user actions and on pressing ESC ]]
require('message_auto_clear').setup()

-- [[ When a file is deleted externally, rename all its buffers to "[file]: file removed" ]]
require 'buffer_deleted'

-- [[ Pastebin ]]
require('pastebin').setup()

-- [[ Refresh Alpha when switching to a tab to replace breakage ]]
require 'alpha_fix'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
