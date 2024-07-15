local M = {}

-- Default configuration
M.config = {
	close_key = "q", -- Default key to close buffer/window
}

-- Function to safely close buffer, window, or exit Vim
local function close_buffer_or_window_or_exit()
	local current_buf = vim.api.nvim_get_current_buf()
	local current_win = vim.api.nvim_get_current_win()
	local listed_buffers = vim.tbl_filter(function(b)
		return vim.api.nvim_buf_get_option(b, "buflisted")
	end, vim.api.nvim_list_bufs())

	-- Function to safely close buffer
	local function close_buffer()
		local wins = vim.fn.getbufinfo(current_buf)[1].windows
		if #wins > 1 then
			-- If the buffer is displayed in multiple windows, only close it in the current window
			vim.api.nvim_win_call(current_win, function()
				vim.cmd("bn")
			end)
		else
			-- Find the next buffer to switch to
			local next_buf = vim.fn.bufnr("#")
			if next_buf == -1 or not vim.api.nvim_buf_is_valid(next_buf) then
				next_buf = vim.fn.bufnr(vim.fn.getbufinfo({ buflisted = 1 })[2].name)
			end

			-- Switch to the next buffer in all windows showing the current buffer
			for _, win in ipairs(wins) do
				vim.api.nvim_win_set_buf(win, next_buf)
			end
		end

		-- Now close the buffer
		local ok, err = pcall(vim.cmd, "bdelete " .. current_buf)
		if not ok then
			vim.notify("Failed to close buffer: " .. err, vim.log.levels.ERROR)
		end
	end

	-- Function to exit Vim
	local function exit_vim()
		vim.cmd("quit")
	end

	-- Check if current buffer is empty
	local is_current_buffer_empty = vim.fn.empty(vim.fn.expand("%")) == 1 and vim.bo.buftype == ""

	if #listed_buffers == 1 then
		-- If this is the last buffer, exit Vim
		exit_vim()
	elseif is_current_buffer_empty then
		-- If the current buffer is empty, close the current window
		local ok, err = pcall(vim.api.nvim_win_close, 0, false)
		if not ok then
			vim.notify("Failed to close window: " .. err, vim.log.levels.ERROR)
		end
	elseif #listed_buffers > 1 then
		-- If there are multiple buffers, close the current one
		close_buffer()
	else
		-- This condition should not be reached, but just in case
		exit_vim()
	end
end

-- Function to set up the key mapping for a buffer
local function setup_buffer_mapping(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	-- Check if the buffer is a normal file buffer
	local buf_type = vim.api.nvim_buf_get_option(bufnr, "buftype")
	if buf_type == "" then -- Empty string means it's a normal file buffer
		vim.api.nvim_buf_set_keymap(bufnr, "n", M.config.close_key, "", {
			callback = close_buffer_or_window_or_exit,
			noremap = true,
			silent = true,
		})
	end
end

-- Function to set up autocommands
local function setup_autocommands()
	vim.api.nvim_create_autocmd({ "BufEnter", "BufAdd" }, {
		group = vim.api.nvim_create_augroup("BufferCloserMapping", { clear = true }),
		callback = function(ev)
			setup_buffer_mapping(ev.buf)
		end,
	})
end

-- Function to set up the plugin
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	setup_autocommands()
	-- Set up mapping for the current buffer
	setup_buffer_mapping()
end

return M
