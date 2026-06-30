return {
	{
		'neovim/nvim-lspconfig',
		dependencies = {
			'williamboman/mason.nvim',
			'williamboman/mason-lspconfig.nvim',
			'j-hui/fidget.nvim',
			'folke/neodev.nvim',
			'hrsh7th/nvim-cmp',
			'L3MON4D3/LuaSnip',
			'saadparwaiz1/cmp_luasnip',
			'hrsh7th/cmp-nvim-lsp',
			'hrsh7th/cmp-path',
		},
		config = function()
			-- [[ Configure LSP ]]
			--  This function gets run when an LSP connects to a particular buffer.
			local on_attach = function(_, bufnr)
				-- NOTE: Remember that lua is a real programming language, and as such it is possible
				-- to define small helper and utility functions so you don't have to repeat yourself
				-- many times.
				-- In this case, we create a function that lets us more easily define mappings specific
				-- for LSP related items. It sets the mode, buffer and description for us each time.
				local nmap = function(keys, func, desc)
					if desc then
						desc = 'LSP: ' .. desc
					end

					vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
				end
				nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
				nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

				nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
				nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
				nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
				nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
				nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
				nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
				-- See `:help K` for why this keymap
				nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
				nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')
				-- Lesser used LSP functionality
				nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
				nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
				nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
				nmap('<leader>wl', function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end, '[W]orkspace [L]ist Folders')
				-- Create a command `:Format` local to the buffer using Conform
				vim.api.nvim_buf_create_user_command(bufnr, 'Format', function()
					require('conform').format { bufnr = bufnr }
				end, { desc = 'Format current buffer with Conform' })
			end
			-- document existing key chains
			require('which-key').register {
				['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
				['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
				['<leader>g'] = { name = '[G]it', _ = 'which_key_ignore' },
				['<leader>h'] = { name = 'Git [H]unk', _ = 'which_key_ignore' },
				['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
				['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
				['<leader>t'] = { name = '[T]oggle', _ = 'which_key_ignore' },
				['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
			}
			-- register which-key VISUAL mode
			-- required for visual <leader>hs (hunk stage) to work
			require('which-key').register({
				['<leader>'] = { name = 'VISUAL <leader>' },
				['<leader>h'] = { 'Git [H]unk' },
			}, { mode = 'v' })
			-- mason-lspconfig requires that these setup functions are called in this order
			-- before setting up the servers.
			require('mason').setup()
			require('mason-lspconfig').setup()
			-- Enable the following language servers
			--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
			--  Add any additional override configuration in the following tables. They will be passed to
			--  the `settings` field of the server config. You must look up that documentation yourself.
			--  If you want to override the default filetypes that your language server will attach to you can
			--  define the property 'filetypes' to the map in question.
			local servers = {
				-- clangd = {},
				-- gopls = {},
				-- pyright = {},
				-- rust_analyzer = {},
				-- tsserver = {},
				-- html = { filetypes = { 'html', 'twig', 'hbs'} },

				lua_ls = {
					Lua = {
						workspace = { checkThirdParty = false },
						telemetry = { enable = false },
						-- NOTE: toggle below to ignore Lua_LS's noisy `missing-fields` warnings
						-- diagnostics = { disable = { 'missing-fields' } },
					},
				},
			}
			-- Setup neovim lua configuration
			require('neodev').setup()
			-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
			-- Ensure the servers above are installed
			local mason_lspconfig = require 'mason-lspconfig'
			mason_lspconfig.setup {
				ensure_installed = vim.tbl_keys(servers),
				handlers = {
					function(server_name)
						require('lspconfig')[server_name].setup {
							capabilities = capabilities,
							on_attach = on_attach,
							settings = servers[server_name],
							filetypes = (servers[server_name] or {}).filetypes,
						}
					end,
				},
			}
			-- [[ Configure nvim-cmp ]]
			-- See `:help cmp`
			local cmp = require 'cmp'
			local luasnip = require 'luasnip'
			require('luasnip.loaders.from_vscode').lazy_load()
			do
				local parser = require 'luasnip.util.parser'
				local custom_dir = vim.fn.stdpath 'config' .. '/custom_friendly_snippets'
				local handle = vim.loop.fs_scandir(custom_dir)
				if handle then
					while true do
						local name, ftype = vim.loop.fs_scandir_next(handle)
						if not name then
							break
						end
						if ftype == 'file' and name:match '%.json$' then
							local filetype = name:gsub('%.json$', '')
							local lines_ok, lines = pcall(vim.fn.readfile, custom_dir .. '/' .. name)
							if lines_ok then
								local decode_ok, data = pcall(vim.json.decode, table.concat(lines, '\n'))
								if decode_ok and type(data) == 'table' then
									local snippets = {}
									for snip_name, snip in pairs(data) do
										local prefixes = type(snip.prefix) == 'table' and snip.prefix or { snip.prefix }
										local body = type(snip.body) == 'table' and table.concat(snip.body, '\n') or snip.body
										for _, prefix in ipairs(prefixes) do
											local parse_ok, parsed =
												pcall(parser.parse_snippet, { trig = prefix, name = snip_name, desc = snip.description }, body)
											if parse_ok then
												table.insert(snippets, parsed)
											end
										end
									end
									luasnip.add_snippets(filetype, snippets, { default_priority = 2000 })
								else
									vim.notify('Failed to decode custom snippet file: ' .. name, vim.log.levels.ERROR)
								end
							else
								vim.notify('Failed to read custom snippet file: ' .. name, vim.log.levels.ERROR)
							end
						end
					end
				end
			end
			luasnip.config.setup {}
			cmp.setup {
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = {
					completeopt = 'menu,menuone,noinsert',
				},
				mapping = cmp.mapping.preset.insert {
					['<C-n>'] = cmp.mapping.select_next_item(),
					['<C-p>'] = cmp.mapping.select_prev_item(),
					['<C-d>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete {},
					['<CR>'] = cmp.mapping.confirm {
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					},
					['<Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { 'i', 's' }),
					['<S-Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { 'i', 's' }),
				},
				sources = {
					{ name = 'nvim_lsp' },
					{ name = 'luasnip' },
					{ name = 'path' },
				},
			}
		end,
	},
}
