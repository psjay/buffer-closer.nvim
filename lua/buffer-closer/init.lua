local M = {}
M.enabled = true

-- Default configuration
M.config = {
	close_key = "q", -- Default key to close buffer/window
}

-- Function to safely close buffer, window, or exit Vim
local function close_buffer_or_window_or_exit()
	local current_buf = vim.api.nvim_get_current_buf()
	local current_win = vim.api.nvim_get_current_win()
	local windows_with_buffer = vim.fn.win_findbuf(current_buf)
	-- Function to count visible windows
	local function count_visible_windows()
		local count = 0
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_config(win).relative == "" then
				count = count + 1
			end
		end
		return count
	end

	-- If the buffer is displayed in multiple visible windows, close only the current window
	if #windows_with_buffer > 1 then
		if count_visible_windows() > 1 then
			vim.api.nvim_win_close(current_win, false)
			return
		end
	end

	local listed_buffers = vim.tbl_filter(function(b)
		return vim.bo[b].buflisted and vim.api.nvim_buf_is_valid(b)
	end, vim.api.nvim_list_bufs())

	-- Function to find the next valid buffer
	local function find_next_buffer()
		local alternate = vim.fn.bufnr("#")
		if alternate ~= -1 and vim.api.nvim_buf_is_valid(alternate) and vim.bo[alternate].buflisted then
			return alternate
		end

		-- Get buffer history
		local buffer_history = {}
		for i = 1, vim.fn.bufnr("$") do
			if vim.api.nvim_buf_is_valid(i) and vim.bo[i].buflisted then
				table.insert(buffer_history, { bufnr = i, lastused = vim.fn.getbufinfo(i)[1].lastused })
			end
		end

		-- Sort buffers by last used time
		table.sort(buffer_history, function(a, b)
			return a.lastused > b.lastused
		end)

		-- Find the most recently used buffer that's not the current one
		for _, buf in ipairs(buffer_history) do
			if buf.bufnr ~= current_buf then
				return buf.bufnr
			end
		end

		return nil
	end

	-- Function to safely close buffer
	local function close_buffer()
		-- local wins = vim.fn.getbufinfo(current_buf)[1].windows
		local next_buf = find_next_buffer()
		if next_buf then
			vim.api.nvim_win_set_buf(current_win, next_buf)
		else
			vim.cmd("enew")
		end

		-- Now close the buffer
		local ok, err = pcall(function()
			vim.cmd("bdelete " .. current_buf)
		end)
		if (not ok) and vim.bo[current_buf].buflisted then
			vim.api.nvim_win_set_buf(current_win, current_buf)
			vim.notify("Failed to close buffer: " .. err, vim.log.levels.WARN)
		end
	end

	-- Function to exit Vim
	local function exit_vim()
		vim.cmd("quitall")
	end

	if #listed_buffers > 1 then
		close_buffer()
	else
		exit_vim()
	end
end

-- Function to set up the key mapping for a buffer
local function setup_buffer_mapping(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local buf_type = vim.bo[bufnr].buftype
	local buf_listed = vim.bo[bufnr].buflisted
	if buf_type == "" and buf_listed then
		vim.api.nvim_buf_set_keymap(bufnr, "n", M.config.close_key, "", {
			callback = function()
				if M.enabled then
					close_buffer_or_window_or_exit()
				else
					-- Execute the default behavior when plugin is disabled
					local default_action = vim.api.nvim_replace_termcodes(M.config.close_key, true, false, true)
					vim.api.nvim_feedkeys(default_action, "n", false)
				end
			end,
			noremap = true,
			silent = true,
			desc = "Close or quit",
		})
	end
end

-- Function to set up autocommands
local function setup_autocommands()
	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		group = vim.api.nvim_create_augroup("BufferCloserMapping", { clear = true }),
		callback = function(ev)
			setup_buffer_mapping(ev.buf)
		end,
	})
end

-- Add these new functions
local function disable_plugin()
	M.enabled = false
	vim.notify("Buffer Closer disabled.", vim.log.levels.INFO)
end

local function enable_plugin()
	M.enabled = true
	vim.notify("Buffer Closer enabled.", vim.log.levels.INFO)
end

-- Function to set up the plugin
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	setup_autocommands()
	-- Set up mapping for the current buffer
	setup_buffer_mapping()
	-- Add user commands
	vim.api.nvim_create_user_command("BuffClsDisable", disable_plugin, {})
	vim.api.nvim_create_user_command("BuffClsEnable", enable_plugin, {})
end

return M
