local M = {}

M.upload_url = 'https://user:pass@upload.freedoms4.top/index.php'
M.auth = 'user:pass'

-- Generate random filename
local function random_name(len)
	local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
	local name = {}
	math.randomseed(os.time() + vim.loop.hrtime())
	for i = 1, len do
		local idx = math.random(#chars)
		name[#name + 1] = chars:sub(idx, idx)
	end
	return table.concat(name)
end

function M.upload(text)
	local fname = random_name(12) .. '.txt'
	local form_field = string.format('file=@-;filename=%s', fname)

	local cmd = {
		'curl',
		'-s',
		'--user',
		M.auth,
		'--form',
		form_field,
		M.upload_url,
	}

	local output = vim.fn.system(cmd, text)

	if vim.v.shell_error ~= 0 then
		vim.notify('[Pastebin] Upload failed:\n' .. output, vim.log.levels.ERROR)
		return nil
	end

	local url = output:match "https?://[%w%-%._~:/%?#%[%]@%%&+='*,]+"
	if not url then
		vim.notify('[Pastebin] No URL found.\nServer replied:\n' .. output, vim.log.levels.ERROR)
		return nil
	end

	-- Clipboard
	vim.fn.setreg('+', url)
	vim.fn.setreg('*', url)

	vim.notify(string.format('[Pastebin]\nURL copied:\n%s', url), vim.log.levels.INFO)

	return url
end

function M.pastebin_cmd()
	local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
	M.upload(text)
end

function M.setup()
	vim.api.nvim_create_user_command('Pastebin', M.pastebin_cmd, {})
end

return M
