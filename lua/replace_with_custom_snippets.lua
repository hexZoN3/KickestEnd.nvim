local uv = vim.loop
local home = uv.os_homedir()
-- Detect OS and base path of friendly-snippets
local function get_friendly_snippets_base_path()
	local os_name = uv.os_uname().sysname
	if os_name == 'Windows_NT' then
		return home .. '\\.local\\share\\nvim\\lazy\\friendly-snippets\\snippets\\'
	else
		return home .. '/.local/share/nvim/lazy/friendly-snippets/snippets/'
	end
end
local target_base = get_friendly_snippets_base_path()
local custom_snippets_dir = vim.fn.stdpath 'config' .. '/custom_friendly_snippets/'
-- Read all files in custom_snippets_dir
local function get_custom_snippet_files()
	local handle = uv.fs_scandir(custom_snippets_dir)
	if not handle then
		vim.notify('Custom snippets folder not found: ' .. custom_snippets_dir, vim.log.levels.ERROR)
		return {}
	end
	local files = {}
	while true do
		local name, type = uv.fs_scandir_next(handle)
		if not name then
			break
		end
		if type == 'file' then
			table.insert(files, name)
		end
	end
	return files
end
-- Replace each snippet file
local function replace_snippets()
	local files = get_custom_snippet_files()
	for _, filename in ipairs(files) do
		local source_path = custom_snippets_dir .. filename
		local target_path = target_base .. filename
		local source_file = io.open(source_path, 'r')
		if not source_file then
			vim.notify('Failed to read: ' .. source_path, vim.log.levels.ERROR)
			goto continue
		end
		local source_content = source_file:read '*a'
		source_file:close()
		-- Read target content (if exists)
		local target_content = ''
		local target_file = io.open(target_path, 'r')
		if target_file then
			target_content = target_file:read '*a'
			target_file:close()
		end
		-- Only update if different
		if source_content ~= target_content then
			-- Create backup if not exists
			local backup_path = target_path .. '.bak'
			if not uv.fs_stat(backup_path) and target_content ~= '' then
				local backup_file = io.open(backup_path, 'w')
				if backup_file then
					backup_file:write(target_content)
					backup_file:close()
				else
					vim.notify('Failed to create backup: ' .. backup_path, vim.log.levels.ERROR)
				end
			end

			local output = io.open(target_path, 'w')
			if output then
				output:write(source_content)
				output:close()
				vim.notify('Updated snippet: ' .. filename, vim.log.levels.INFO)
			else
				vim.notify('Failed to write: ' .. target_path, vim.log.levels.ERROR)
			end
		end
		::continue::
	end
end
replace_snippets()
