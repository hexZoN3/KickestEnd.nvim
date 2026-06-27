-- When a file is deleted externally, rename all its buffers to "[file]: file removed"

local M = {}

-- List of buffer names or filetypes to skip (UndoTree, Neo-tree, etc.)
local skip_buffers = { 'undotree', 'neo-tree' }

-- Helper function to determine if a buffer should be skipped in future
local function should_skip(buf)
	if not vim.api.nvim_buf_is_valid(buf) then
		return true
	end

	local bufname = vim.api.nvim_buf_get_name(buf)
	local ft = vim.api.nvim_buf_get_option(buf, 'filetype')
	local listed = vim.api.nvim_buf_get_option(buf, 'buflisted')
	local modifiable = vim.api.nvim_buf_get_option(buf, 'modifiable')

	-- Skip empty, unlisted, or unmodifiable buffers (usually floating windows)
	if bufname == '' or not listed or not modifiable then
		return true
	end

	-- Skip directories if spefified with the nvim command
	local stat = vim.loop.fs_stat(bufname)
	if stat and stat.type == 'directory' then
		return true
	end

	-- Skip known plugin filetypes
	for _, v in ipairs(skip_buffers) do
		if ft == v or bufname:match(v) then
			return true
		end
	end

	return false
end

-- Detect deleted files and rename their buffers
local function rename_deleted_buffers()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) and not should_skip(buf) then
			local bufname = vim.api.nvim_buf_get_name(buf)

			if bufname ~= '' and vim.fn.filereadable(bufname) == 0 then
				-- Skip buffers for files that have never been written (new files),
				-- regardless of whether they have unsaved (modified) content
				local ftime = vim.fn.getftime(bufname)
				if ftime == -1 then
					goto continue
				end

				local filename = vim.fn.fnamemodify(bufname, ':t')
				local new_name = string.format('[%s]: file removed', filename)

				-- Skip if already renamed
				if not vim.api.nvim_buf_get_name(buf):match 'file removed' then
					-- Ensure no other buffer already has this name
					local exists = false
					for _, b in ipairs(vim.api.nvim_list_bufs()) do
						if vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_get_name(b) == new_name then
							exists = true
							break
						end
					end

					if not exists then
						-- Temporarily unlist so renaming works cleanly
						vim.api.nvim_buf_set_option(buf, 'buflisted', false)
						vim.api.nvim_buf_set_name(buf, new_name)
						vim.api.nvim_buf_set_option(buf, 'buflisted', true)
					end
				end
			end
		end
		::continue::
	end
end

-- Trigger both on focus and buffer entry
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
	callback = function()
		local buf = vim.api.nvim_get_current_buf()
		if should_skip(buf) then
			return
		end
		-- Force Neovim to check external changes
		vim.cmd 'checktime'
		rename_deleted_buffers()
	end,
})

return M
