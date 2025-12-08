-- [[ Few useful keymaps ]]
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")
vim.keymap.set('n', 'J', 'mzJ`z')
vim.keymap.set('n', '<leader>j', '<C-d>zz', { desc = 'Scroll down and center cursor' })
vim.keymap.set('n', '<leader>k', '<C-u>zz', { desc = 'Scroll up and center cursor' })
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- [[ Replace all occurrences of word under cursor (normal) or selection (visual) ]]
-- Normal mode
vim.keymap.set('n', '<leader>F', function()
	-- Get word under cursor
	local word = vim.fn.expand '<cword>'
	if word == '' then
		return
	end
	-- Escape for literal search
	local esc_word = vim.fn.escape(word, '/\\')
	-- Count occurrences in the buffer (case-sensitive)
	local occurrences = vim.fn.searchcount({ pattern = '\\<' .. esc_word .. '\\>', maxcount = 0, exact = 1, flags = 'cn' }).total
	-- Prompt with only the count
	local replacement = vim.fn.input(string.format('Replace %d occurrences with: ', occurrences))
	if replacement == '' then
		return
	end
	-- Escape replacement
	local esc_replacement = vim.fn.escape(replacement, '\\/&')
	-- Save cursor position before substitution
	local original_pos = vim.api.nvim_win_get_cursor(0)
	-- Perform global, case-sensitive substitution
	vim.cmd(string.format('silent! %%s/\\<%s\\>/%s/g', esc_word, esc_replacement))
	-- Move cursor at the last character of the first replaced occurrence
	vim.schedule(function()
		local pattern = '\\<' .. esc_word .. '\\>'
		vim.fn.cursor(original_pos)
		vim.cmd 'silent! normal! n'
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		pcall(vim.api.nvim_win_set_cursor, 0, { row, col + #replacement + 1 })
	end)
end, { desc = 'Replace all occurrences of word under cursor', silent = true })
-- Visual mode
vim.keymap.set('x', '<leader>F', function()
	-- Exit visual mode so input() works
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
	vim.schedule(function()
		local mode = vim.fn.visualmode()
		local start_pos = vim.api.nvim_buf_get_mark(0, '<')
		local end_pos = vim.api.nvim_buf_get_mark(0, '>')
		local start_row, start_col = start_pos[1] - 1, start_pos[2]
		local end_row, end_col = end_pos[1] - 1, end_pos[2] + 1
		if mode == 'V' then
			start_col = 0
			local line = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, false)[1] or ''
			end_col = #line
		end
		local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
		if not lines or #lines == 0 then
			return
		end
		local selection = table.concat(lines, '\n')
		if selection == '' then
			return
		end
		-- Escape selection for literal search
		local esc_selection = vim.fn.escape(selection, '/\\'):gsub('\n', '\\n')
		-- Count occurrences in the buffer
		local count = vim.fn.searchcount({ pattern = esc_selection, maxcount = 0, exact = 1 }).total
		-- Show prompt with only number of occurrences
		local replacement = vim.fn.input(string.format('Replace %d occurrences with: ', count))
		if replacement == '' then
			return
		end
		local esc_replacement = vim.fn.escape(replacement, '\\/&'):gsub('\n', '\\n')
		local original_pos = { start_row + 1, start_col + 1 }
		-- Silent global substitution
		vim.cmd(string.format('silent! %%s/\\V%s/%s/g', esc_selection, esc_replacement))
		-- Move cursor at the last character of the first replaced occurrence
		vim.schedule(function()
			vim.fn.cursor(original_pos)
			vim.cmd 'silent! normal! n'
			local found_row, found_col = unpack(vim.api.nvim_win_get_cursor(0))
			-- +1 to put cursor after the last character of replacement
			pcall(vim.api.nvim_win_set_cursor, 0, { found_row, found_col + #replacement })
		end)
	end)
end, { desc = 'Replace all occurrences of selection', silent = true })

-- [[ Basic Keymaps ]]
-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- [[ Remap for dealing with word wrap ]]
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Diagnostic keymaps ]]
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>de', vim.diagnostic.open_float, { desc = 'Diagnostics: floating message' })
vim.keymap.set('n', '<leader>dq', vim.diagnostic.setloclist, { desc = 'Diagnostics: location list' })

-- [[ Custom keymaps ]]
-- [[ Neo-tree sync to current directory & toggle ]]
vim.keymap.set('n', '<leader>n', '<Cmd>cd %:p:h | Neotree toggle float<CR>')

-- [[ Terminal open ]]
-- In a new tab
vim.keymap.set('n', '<leader>tt', '<Cmd>tabnew +term<CR>i', { noremap = true, silent = true, desc = 'Open terminal in new tab' })
-- In a vertical split (bottom)
vim.keymap.set('n', '<leader>tv', '<Cmd>split | wincmd j | terminal<CR>i', { noremap = true, silent = true, desc = 'Open terminal in horizontal split' })
-- In a horizontal split (right side)
vim.keymap.set('n', '<leader>th', '<Cmd>vsplit | wincmd l | terminal<CR>i', { noremap = true, silent = true, desc = 'Open terminal in vertical split' })

-- [[ Create an empty buffer in a new tab and open Alpha ]]
vim.keymap.set('n', '<Leader>e', function()
	vim.cmd 'tabnew' -- create a new tab
	vim.cmd 'enew' -- create a new empty buffer in it
	require('alpha').start(true) -- open Alpha dashboard in this new tab
end, { noremap = true, silent = true, desc = 'Create a new tab' })

-- [[ Horizontal split with new empty buffer below ]]
vim.keymap.set('n', '<leader>sv', function()
	vim.cmd 'split' -- create horizontal split (above by default)
	vim.cmd 'wincmd j' -- move to the new split below
	vim.cmd 'enew' -- open new empty buffer
end, { desc = 'New buffer in horizontal split (below)' })

-- [[ Vertical split with new empty buffer to the right ]]
vim.keymap.set('n', '<leader>sh', function()
	vim.cmd 'vsplit' -- create vertical split (left by default)
	vim.cmd 'wincmd l' -- move to the new split to the right
	vim.cmd 'enew' -- open new empty buffer
end, { desc = 'New buffer in vertical split (right)' })

-- [[ Save buffer ]]
local sudo_password_cache = nil -- store sudo password for session
-- Helper to write file with sudo permissions
local function write_with_sudo(filename, content)
	-- Prompt for password once per session
	if not sudo_password_cache then
		local pass = vim.fn.inputsecret '[sudo] password: '
		if pass == '' or pass == nil then
			vim.notify('Save cancelled', vim.log.levels.WARN)
			return false
		end
		sudo_password_cache = pass
	end
	-- Write buffer content to sudo tee
	local sudo_cmd = string.format('sudo -S tee %s > /dev/null', vim.fn.fnameescape(filename))
	local ok = vim.fn.system(sudo_cmd, sudo_password_cache .. '\n' .. content)
	if vim.v.shell_error ~= 0 then
		vim.notify('Failed to write with sudo: ' .. ok, vim.log.levels.ERROR)
		-- clear cached password to allow retry next time
		sudo_password_cache = nil
		return false
	end
	return true
end
local function smart_save(force_save_as)
	local current_path = vim.api.nvim_buf_get_name(0)
	-- Compute default input (prefill directory + filename)
	local default_dir
	if current_path ~= '' then
		-- Use the current file's directory
		default_dir = vim.fn.fnamemodify(current_path, ':p:h') .. '/'
	else
		-- Use current working directory if no file yet
		default_dir = vim.fn.getcwd() .. '/'
	end
	local default_name = current_path ~= '' and vim.fn.fnamemodify(current_path, ':t') or ''
	local default_input = default_dir .. default_name
	-- Decide whether to ask for filename
	if current_path == '' or force_save_as then
		local filename
		local overwrite = false
		while true do
			-- Ask user for filename
			filename = vim.fn.input('Save as: ', default_input, 'file')
			if filename == '' then
				vim.notify('Save cancelled', vim.log.levels.WARN)
				return
			end
			-- Check if file already exists
			if vim.loop.fs_stat(filename) then
				local choice = vim.fn.input(string.format("File '%s' already exists! Overwrite? (y/N): ", filename))
				if choice:lower() == 'y' then
					overwrite = true
					break
				else
					default_input = filename
					print 'Choose a different filename.'
				end
			else
				break
			end
		end
		-- If Save As filename is same as current file, just write and return
		if filename == current_path then
			local write_cmd = overwrite and 'write!' or 'write'
			local ok = pcall(function()
				vim.cmd(write_cmd)
			end)
			if not ok then
				local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
				local content = table.concat(lines, '\n')
				if not write_with_sudo(filename, content) then
					return
				end
			end
			print('Saved ' .. filename)
			return
		end
		-- For no-name buffers or Save As, write and set buffer name
		if current_path == '' then
			vim.api.nvim_buf_set_name(0, filename)
			vim.cmd 'filetype detect'
			local write_cmd = 'write!'
			local ok = pcall(function()
				vim.cmd(write_cmd)
			end)
			if not ok then
				local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
				local content = table.concat(lines, '\n')
				if not write_with_sudo(filename, content) then
					return
				end
			end
			-- Clear modified flag so future saves work correctly
			vim.api.nvim_buf_set_option(0, 'modified', false)
		else
			-- Named buffer: normal Save As logic
			local write_cmd = overwrite and 'write!' or 'write'
			local ok = pcall(function()
				vim.cmd(write_cmd .. ' ' .. vim.fn.fnameescape(filename))
			end)
			if not ok then
				local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
				local content = table.concat(lines, '\n')
				if not write_with_sudo(filename, content) then
					return
				end
			end
			-- Preserve cursor position and undo history
			local old_buf = vim.api.nvim_get_current_buf()
			local cursor_pos = vim.api.nvim_win_get_cursor(0)
			local undo_history = vim.fn.getbufinfo(old_buf)[1].changedtick
			vim.cmd('edit ' .. vim.fn.fnameescape(filename))
			vim.cmd 'filetype detect'
			vim.api.nvim_win_set_cursor(0, cursor_pos)
			vim.cmd 'undojoin'
			vim.api.nvim_buf_delete(old_buf, { force = true })
		end
		print('Saved as ' .. filename)
	else
		-- Buffer already has a name, just save it
		local ok = pcall(function()
			vim.cmd 'w'
		end)
		if not ok then
			local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
			local content = table.concat(lines, '\n')
			if not write_with_sudo(current_path, content) then
				return
			end
		end
		vim.api.nvim_buf_set_option(0, 'modified', false)
		print('Saved ' .. current_path)
	end
end
-- Save current buffer
vim.keymap.set('n', '<leader>w', function()
	smart_save(false)
end, { desc = 'Save buffer' })
-- Save As a new file
vim.keymap.set('n', '<leader>W', function()
	smart_save(true)
end, { desc = 'Save As' })
-- Clear sudo password cache on exit
vim.api.nvim_create_autocmd('VimLeavePre', {
	callback = function()
		sudo_password_cache = nil
	end,
})

-- [[ Close current window ]]
-- Helper function to check how many windows show a buffer
local function buffer_window_count(bufnr)
	if not bufnr then
		bufnr = vim.api.nvim_get_current_buf()
	end
	local count = 0
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == bufnr then
			count = count + 1
		end
	end
	return count
end
-- Helper function: count listed buffers
local function listed_buffer_count()
	local count = 0
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_option(buf, 'buflisted') then
			count = count + 1
		end
	end
	return count
end
-- Helper function: check if any Alpha buffer exists anywhere
local function is_alpha_running()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) then
			local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
			local ft = vim.api.nvim_buf_get_option(buf, 'filetype')
			if buftype == 'nofile' and ft == 'alpha' then
				return true
			end
		end
	end
	return false
end
-- Helper function: toggle Undotree to preserve undo history for root-protected files
local function toggle_undotree_twice(callback)
	local filename = vim.api.nvim_buf_get_name(0)
	if filename ~= '' and vim.fn.filereadable(filename) == 1 and vim.fn.filewritable(filename) == 0 then
		if vim.fn.exists ':UndotreeToggle' == 2 then
			vim.cmd 'UndotreeToggle'
			vim.defer_fn(function()
				vim.cmd 'UndotreeToggle'
				if callback then
					vim.defer_fn(callback, 50)
				end
			end, 50)
		elseif callback then
			callback()
		end
	else
		if callback then
			callback()
		end
	end
end
-- Main function
local function close_window(mode)
	local bufnr = vim.api.nvim_get_current_buf()
	local modified = vim.bo.modified
	local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype') -- detect terminal buffer
	local win_count = buffer_window_count(bufnr)
	local total_listed = listed_buffer_count()
	-- Function to perform the actual closing logic
	local function perform_close()
		-- Handle terminal buffers separately
		if buftype == 'terminal' then
			if win_count > 1 then
				vim.cmd 'close'
			else
				vim.api.nvim_buf_delete(bufnr, { force = true })
			end
			return
		end
		-- Special case: only 1 listed buffer but an Alpha dashboard exists somewhere
		if total_listed == 1 and is_alpha_running() then
			vim.cmd 'close'
			return
		end
		-- Special case: last listed buffer in last window
		if total_listed == 1 and win_count == 1 then
			if modified and mode ~= 'save' then
				vim.cmd 'qa!'
			else
				vim.cmd 'qa'
			end
			return
		end
		-- Close logic
		if win_count > 1 then
			vim.cmd 'close'
		else
			if modified and mode ~= 'save' then
				vim.cmd 'bwipeout!' -- discard changes
			else
				vim.cmd 'bdelete'
			end
		end
	end
	-- Function to handle save/discard/cancel for modified buffers
	local function save_if_needed(callback)
		if not modified then
			-- Toggle Undotree for write-protected files
			toggle_undotree_twice(callback)
			return
		end
		-- Returns true if save succeeded, false if cancelled
		local function save_file()
			local filename = vim.api.nvim_buf_get_name(bufnr)
			if filename == '' then
				-- Ask user for filename
				local input_name = vim.fn.input('Save as: ', '', 'file')
				if input_name == '' then
					vim.notify('Save cancelled', vim.log.levels.WARN)
					return false
				end
				vim.api.nvim_buf_set_name(bufnr, input_name)
				filename = input_name
			end
			-- Try normal write first
			local ok, err = pcall(function()
				vim.cmd 'write'
			end)
			if not ok then
				-- Fallback to sudo write using your helper
				local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
				local content = table.concat(lines, '\n')
				if not write_with_sudo(filename, content) then
					return false
				end
			end
			-- Mark buffer as unmodified
			vim.api.nvim_buf_set_option(bufnr, 'modified', false)
			return true
		end
		if mode == 'save' then
			if save_file() then
				toggle_undotree_twice(callback)
			end
		elseif mode == 'discard' then
			toggle_undotree_twice(callback)
		else
			-- Ask user
			local choice = vim.fn.input 'Buffer modified! Save (y), Discard (n), Cancel (any other key)? '
			if choice:lower() == 'y' then
				if save_file() then
					toggle_undotree_twice(callback)
				else
					vim.notify('Save cancelled', vim.log.levels.WARN)
				end
			elseif choice:lower() == 'n' then
				toggle_undotree_twice(callback)
			else
				print 'Quit cancelled'
			end
		end
	end
	-- Start save/discard/cancel workflow
	save_if_needed(perform_close)
end
-- Keymaps
vim.keymap.set('n', '<leader>q', function()
	close_window()
end, { desc = 'Close window' })
vim.keymap.set('n', '<leader>qy', function()
	close_window 'save'
end, { desc = 'Save & quit current window' })
vim.keymap.set('n', '<leader>qn', function()
	close_window 'discard'
end, { desc = 'Discard changes in current window & quit' })

-- [[ Close Neovim ]]
-- Function to close Neovim, discarding all unsaved changes if confirmed
local function close_nvim_with_prompt()
	-- Get list of all listed buffers
	local buffers = vim.fn.getbufinfo { buflisted = 1 }
	-- Check for unsaved buffers
	local unsaved_buffers = {}
	for _, buf in ipairs(buffers) do
		if buf.changed == 1 then
			table.insert(unsaved_buffers, buf)
		end
	end
	if #unsaved_buffers == 0 then
		-- No unsaved buffers, just quit
		vim.cmd 'qa!'
		return
	end
	-- Ask user whether to discard changes and quit
	local answer = vim.fn.input 'You have unsaved changes. Discard all changes and quit? (y/n): '
	if answer:lower() == 'y' then
		-- Discard all changes and quit
		vim.cmd 'qa!'
	else
		-- Cancel quitting
		print 'Cancelled closing Neovim.'
	end
end
vim.keymap.set('n', '<leader>qa', close_nvim_with_prompt, { noremap = true, silent = true, desc = 'Quit Neovim' })

-- [[ Switch below/right split windows ]]
vim.keymap.set('n', '<leader><Tab>', '<C-W><C-W>')

-- [[ Switch above/left split windows ]]
vim.keymap.set('n', '<Tab>', '<C-W>W')

-- [[ Select all ]]
vim.keymap.set('n', '<leader>ll', 'ggVG', { desc = 'Select all' })

-- [[ Select all and copy to clipboard ]]
vim.keymap.set('n', '<leader>lY', function()
	-- Get all lines from the buffer
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local content = table.concat(lines, '\n')
	-- Set to system clipboard
	vim.fn.setreg('+', content)
	vim.fn.setreg('*', content)
	-- Highlight the full buffer
	local ns = vim.api.nvim_create_namespace 'custom_yank_highlight'
	local hl_group = vim.g.highlightedyank_highlight_group or 'IncSearch'
	local end_row = #lines - 1
	local end_col = #lines[#lines]
	vim.highlight.range(
		0, -- bufnr
		ns,
		hl_group,
		{ 0, 0 }, -- start at beginning
		{ end_row, end_col }, -- end at last line's end
		{ inclusive = true }
	)
	-- Clear highlight after delay
	vim.defer_fn(function()
		vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	end, 200)
	-- Notify
	vim.schedule(function()
		vim.notify('Copied all to clipboard', vim.log.levels.INFO)
	end)
end, { desc = 'Copy all to clipboard' })

-- [[ Copy to clipboard ]]
-- Normal mode: copy current line
vim.keymap.set('n', 'Y', function()
	local line = vim.api.nvim_get_current_line()
	-- Copy to system clipboard
	vim.fn.setreg('+', line)
	vim.fn.setreg('*', line)
	-- Use user-defined highlight group or fallback to 'IncSearch'
	local hl_group = vim.g.highlightedyank_highlight_group or 'IncSearch'
	-- Highlight the line
	local ns = vim.api.nvim_create_namespace 'custom_yank_highlight'
	local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	vim.highlight.range(
		0, -- bufnr
		ns, -- namespace
		hl_group, -- highlight group (dynamic)
		{ row, 0 }, -- start pos
		{ row, #line }, -- end pos
		{ inclusive = true }
	)
	-- Clear highlight after short delay
	vim.defer_fn(function()
		vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	end, 200)
	-- Notification
	vim.schedule(function()
		vim.notify('Copied line to clipboard', vim.log.levels.INFO)
	end)
end, { desc = 'Copy current line to clipboard' })
-- Visual mode: copy selection, trim trailing newline if needed
vim.keymap.set('x', 'Y', function()
	vim.cmd 'normal! y'
	require('copy_to_clipboard_fix').trim_clipboard()
end, { noremap = true, silent = true })

-- [[ Inline Paste ]]
local function paste_register(regname, before_cursor, is_clipboard)
	local content_lines = vim.fn.getreg(regname, 1, true)
	if vim.tbl_isempty(content_lines) then
		return
	end
	local mode = vim.fn.mode()
	local line_count = #content_lines
	-- Visual Mode: replace selection
	if mode == 'v' or mode == 'V' or mode == '\22' then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
		vim.schedule(function()
			local start_pos = vim.api.nvim_buf_get_mark(0, '<')
			local end_pos = vim.api.nvim_buf_get_mark(0, '>')
			local start_row, start_col = start_pos[1] - 1, start_pos[2]
			local end_row, end_col = end_pos[1] - 1, end_pos[2]
			local visual_mode = vim.fn.visualmode()
			if visual_mode == 'V' then
				start_col = 0
				local line = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, false)[1] or ''
				end_col = #line
			else
				end_col = end_col + 1
			end
			vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, content_lines)
			local last_line_text = tostring(content_lines[#content_lines] or '')
			local last_line = start_row + #content_lines - 1
			local last_col = #last_line_text
			if visual_mode == 'v' then
				pcall(vim.api.nvim_win_set_cursor, 0, { start_row + 1, start_col + #last_line_text })
			else
				pcall(vim.api.nvim_win_set_cursor, 0, { last_line + 1, last_col })
			end
		end)
	else
		-- Normal Mode
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		row = row - 1
		local current_line = vim.api.nvim_get_current_line()
		if #content_lines == 1 then
			-- Single-line inline paste
			local insert_col = before_cursor and col or col + 1
			local new_line = current_line:sub(1, insert_col) .. content_lines[1] .. current_line:sub(insert_col + 1)
			vim.api.nvim_set_current_line(new_line)
			vim.api.nvim_win_set_cursor(0, { row + 1, insert_col + #content_lines[1] })
		else
			-- Multi-line paste
			local before = current_line:sub(1, col)
			local after = current_line:sub(col + 1)
			local to_insert = vim.deepcopy(content_lines)
			to_insert[1] = before .. to_insert[1]
			to_insert[#to_insert] = to_insert[#to_insert] .. after
			vim.api.nvim_buf_set_lines(0, row, row + 1, false, to_insert)
			vim.api.nvim_win_set_cursor(0, { row + #to_insert, #to_insert[#to_insert] - #after })
		end
	end
	-- Notify
	vim.defer_fn(function()
		local plural = line_count > 1 and 's' or ''
		local text = is_clipboard and 'pasted from clipboard' or 'pasted'
		vim.notify(line_count .. ' line' .. plural .. ' ' .. text, vim.log.levels.INFO)
	end, 0)
end
-- Keymaps
-- Clipboard
vim.keymap.set('n', '<leader>P', function()
	paste_register('+', true, true)
end, { desc = 'Paste from clipboard before cursor' })
vim.keymap.set('x', '<leader>P', function()
	paste_register('+', nil, true)
end, { desc = 'Paste clipboard over selection' })
-- Neovim yanks
vim.keymap.set('n', '<leader>p', function()
	paste_register('"', true)
end, { desc = 'Paste yanks before cursor inline' })
vim.keymap.set('x', '<leader>p', function()
	paste_register '"'
end, { desc = 'Paste yanks over selection' })

-- [[ Redo ]]
vim.keymap.set('n', 'U', '<C-r>')

-- [[ Smart open a file path, reusing empty buffers or tabs if possible ]]
local function smart_open_file(path)
	if not path or path == '' then
		return
	end
	path = vim.fn.fnamemodify(path, ':p') -- make absolute
	-- 1. If file is already open → jump to it
	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.api.nvim_buf_get_name(buf) == path then
				vim.api.nvim_set_current_tabpage(tab)
				vim.api.nvim_set_current_win(win)
				return
			end
		end
	end
	-- 2. If current tab has an empty "No Name" buffer → reuse it
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local buf = vim.api.nvim_win_get_buf(win)
		local name = vim.api.nvim_buf_get_name(buf)
		local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
		local modified = vim.api.nvim_buf_get_option(buf, 'modified')
		if name == '' and buftype == '' and not modified then
			vim.api.nvim_set_current_win(win)
			vim.cmd('edit ' .. vim.fn.fnameescape(path))
			return
		end
	end
	-- 3. Otherwise → open in a new tab
	vim.cmd('tabedit ' .. vim.fn.fnameescape(path))
end

-- [[ Remap gf to use smart_open_file ]]
vim.keymap.set('n', 'gf', function()
	local path = vim.fn.expand '<cfile>' -- get file under cursor
	smart_open_file(path)
end, { desc = 'Smart gf: open file under cursor in new tab or reuse buffer' })

-- [[ Remap double q to exit insert/visual/terminal modes ]]
local double_q_timeout = 400
local q_timer = nil
local q_pending = false
local function send_keys(keys)
	return vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'n', false)
end
local function q_double_escape()
	if q_timer then
		q_timer:stop()
		q_timer:close()
		q_timer = nil
		q_pending = false
		local mode = vim.api.nvim_get_mode().mode
		if mode:match '[iIcR]' then
			return vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
		elseif mode:match '[vV\x16]' then
			return vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
		elseif mode:match 't' then
			return vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, false, true)
		else
			return ''
		end
	else
		q_pending = true
		q_timer = vim.loop.new_timer()
		q_timer:start(
			double_q_timeout,
			0,
			vim.schedule_wrap(function()
				send_keys 'q'
				q_timer:stop()
				q_timer:close()
				q_timer = nil
				q_pending = false
			end)
		)
		return ''
	end
end
local function flush_pending_q_before(ch)
	if q_pending then
		q_timer:stop()
		q_timer:close()
		q_timer = nil
		q_pending = false
		send_keys('q' .. ch)
		return true
	end
	return false
end
for i = 32, 126 do
	local ch = string.char(i)
	if ch ~= 'q' then
		vim.keymap.set({ 'i', 't' }, ch, function()
			if flush_pending_q_before(ch) then
				return ''
			end
			return ch
		end, { noremap = true, expr = true, silent = true })
	end
end
vim.keymap.set({ 'i', 'v', 't' }, 'q', q_double_escape, { noremap = true, expr = true, silent = true })
