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

	---
	-- Finds the next buffer to jump to after closing the current one.
	-- Priority: 1. Alternate buffer (#), 2. Most recently used, 3. Next listed buffer (as per :bnext)
	--
	-- @return integer|nil The buffer number to jump to, or nil if none is found.
	--
	local function find_next_buffer()
	    local current_buf = vim.api.nvim_get_current_buf()

	    -- We'll create our own list of valid, listed buffers to work with.
	    -- This is more robust than relying on a potentially external `listed_buffers` variable.
	    local listed_buffers = vim.tbl_filter(
		function(buf) return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted end,
		vim.api.nvim_list_bufs()
	    )

	    -- Priority 1: First, try the alternate buffer (#)
	    local alternate = vim.fn.bufnr("#")
	    if alternate ~= -1 and alternate ~= current_buf and vim.api.nvim_buf_is_valid(alternate) and vim.bo[alternate].buflisted then
		return alternate
	    end

	    -- Priority 2: Then, try the most recently used buffer
	    local mru_buf = nil
	    local max_lastused = 0
	    for _, buf in ipairs(listed_buffers) do
		if buf ~= current_buf then
		    local info = vim.fn.getbufinfo(buf)
		    -- getbufinfo returns a list, so we check if it's not empty.
		    if #info > 0 and info[1].lastused > max_lastused then
			max_lastused = info[1].lastused
			mru_buf = buf
		    end
		end
	    end

	    if mru_buf then
		return mru_buf
	    end

	    -- Priority 3 (NEW): Finally, if no alternate or MRU buffer is found,
	    -- jump to the next listed buffer in numerical order, wrapping around.
	    -- This mimics the behavior of :bnext.
	    
	    -- Sort the listed buffer numbers
	    table.sort(listed_buffers)

	    -- Find the current buffer's position in the sorted list
	    local next_buf_nr = nil
	    for i, buf_nr in ipairs(listed_buffers) do
		if buf_nr == current_buf then
		    -- Check if there's a buffer after the current one in the list
		    if i < #listed_buffers then
			next_buf_nr = listed_buffers[i + 1]
		    else
			-- If we are at the end, wrap around to the first buffer
			next_buf_nr = listed_buffers[1]
		    end
		    break -- Exit the loop once we find our position
		end
	    end
	    
	    -- Return the found buffer number (or nil if the list is empty/only contains the current buffer)
	    return next_buf_nr
	end
	-- Function to safely close buffer
	local function close_buffer()
		local next_buf = find_next_buffer()

		if next_buf then
			-- Try to switch to the next buffer first
			local ok = pcall(vim.api.nvim_win_set_buf, current_win, next_buf)
			if not ok then
				vim.notify("Failed to switch to next buffer", vim.log.levels.WARN)
				return
			end
		else
			vim.cmd("enew")
		end

		-- Now try to close the buffer
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

	-- Check if the key is already mapped
	local mappings = vim.api.nvim_buf_get_keymap(bufnr, "n")
	for _, map in ipairs(mappings) do
		if map.lhs == M.config.close_key then
			return
		end
	end

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
	})
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
	vim.api.nvim_create_user_command("BuffCls", close_buffer_or_window_or_exit, {})
end

return M
