-- Command: :UpdateKickestEnd
-- Safely updates KickestEnd.nvim config to the latest commit on origin/master

vim.api.nvim_create_user_command('UpdateKickestEnd', function()
	local config_path = vim.fn.expand '~/.config/nvim'

	-- Ensure this is a git repo
	if vim.fn.isdirectory(config_path .. '/.git') == 0 then
		vim.notify('Not a git repository: ' .. config_path, vim.log.levels.ERROR)
		return
	end

	-- Fetch latest changes from remote
	vim.notify('Fetching latest changes from GitHub...', vim.log.levels.INFO)
	vim.fn.system { 'git', '-C', config_path, 'fetch', '--all' }
	if vim.v.shell_error ~= 0 then
		vim.notify('Git fetch failed.', vim.log.levels.ERROR)
		return
	end

	-- Check for local modifications or untracked files
	local status = vim.fn.systemlist { 'git', '-C', config_path, 'status', '--porcelain' }
	local dirty = #status > 0

	-- Check if current HEAD is up-to-date with origin/master
	local head = vim.fn.systemlist({ 'git', '-C', config_path, 'rev-parse', 'HEAD' })[1]
	local origin_master = vim.fn.systemlist({ 'git', '-C', config_path, 'rev-parse', 'origin/master' })[1]
	local is_uptodate = (head == origin_master)

	-- Check for local commits not yet pushed to origin/master -- a
	local ahead_count = tonumber(vim.fn.systemlist({ 'git', '-C', config_path, 'rev-list', '--count', 'origin/master..HEAD' })[1]) or 0
	local has_unpushed_commits = ahead_count > 0

	-- Skip update if nothing to do
	if not dirty and is_uptodate then
		vim.notify('KickestEnd.nvim is already up-to-date with origin/master.', vim.log.levels.INFO)
		return
	end

	-- If there are local changes, untracked files, or unpushed commits, confirm overwrite
	if dirty or has_unpushed_commits then
		local prompt = dirty and 'Local changes or new files detected! Overwrite and delete them? (y/N): '
			or string.format('%d local commit(s) not on origin/master will be lost! Continue? (y/N): ', ahead_count)
		local answer = vim.fn.input(prompt)
		if answer:lower() ~= 'y' then
			vim.notify('Update cancelled to preserve your modifications.', vim.log.levels.WARN)
			return
		end

		-- Add line break before the discard message
		vim.notify('\nDiscarding all local changes and untracked files...', vim.log.levels.WARN)
		vim.fn.system { 'git', '-C', config_path, 'reset', '--hard' }
		vim.fn.system { 'git', '-C', config_path, 'clean', '-fdx' }
	end

	-- Reset to latest commit
	vim.notify('Resetting to latest commit on origin/master...', vim.log.levels.INFO)
	local reset = vim.fn.systemlist { 'git', '-C', config_path, 'reset', '--hard', 'origin/master' }
	if vim.v.shell_error ~= 0 then
		vim.notify('Git reset failed:\n' .. table.concat(reset, '\n'), vim.log.levels.ERROR)
		return
	end

	vim.notify('KickestEnd.nvim successfully updated and fully reset to origin/master!', vim.log.levels.INFO)
	vim.notify('Please restart Neovim for all changes to take effect.', vim.log.levels.WARN)
end, { desc = 'Completely reset and update KickestEnd.nvim config from origin/master' })
