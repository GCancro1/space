local json = require("ai.vendor.json")
local StateIO = {}

-- Load state from JSON file
-- @param path string - path relative to love.filesystem.getSaveDirectory()
-- @return table|nil, string|nil - state table or nil + error message
function StateIO.load(path)
	local content = love.filesystem.read(path)
	if not content then
		return nil, "state file not found or unreadable: " .. tostring(path)
	end
	local ok, state = pcall(json.decode, content)
	if not ok then
		return nil, "invalid JSON in " .. tostring(path) .. ": " .. tostring(state)
	end
	return state
end

-- Save state to JSON file
-- @param state table - state table to save
-- @param path string - path relative to love.filesystem.getSaveDirectory()
-- @return boolean, string|nil - success, or false + error message
function StateIO.save(state, path)
	local ok, encoded = pcall(json.encode, state)
	if not ok then return false, "encode failed: " .. tostring(encoded) end
	local success, err = love.filesystem.write(path, encoded)
	if not success then return false, err or "write failed" end
	return true
end

-- Save state to JSON file via plain Lua io. Writes through the process CWD,
-- so repo-relative paths (e.g. "states/play/000_CALC.json") land in the repo
-- when the game is launched from the project root. Pcall-guarded so a missing
-- directory never errors; the parent dir is created first.
-- @param state table - state table to save
-- @param path string - filesystem path (CWD-relative)
-- @return boolean, string|nil - success, or false + error message
function StateIO.saveFs(state, path)
	local ok, encoded = pcall(json.encode, state)
	if not ok then return false, "encode failed: " .. tostring(encoded) end
	local dir = string.match(path, "^(.*)/[^/]*$")
	if dir and dir ~= "" then
		os.execute("mkdir -p " .. dir)
	end
	local ok2, f = pcall(io.open, path, "w")
	if not ok2 or not f then
		return false, "open failed: " .. tostring(f) .. " (" .. path .. ")"
	end
	local wok, werr = pcall(f.write, f, encoded)
	f:close()
	if not wok then return false, "write failed: " .. tostring(werr) end
	return true
end

-- Load state from JSON file via plain Lua io (headless use, no love).
-- @param path string - filesystem path (CWD-relative)
-- @return table|nil, string|nil - state table or nil + error message
function StateIO.loadFs(path)
	local ok, f = pcall(io.open, path, "rb")
	if not ok or not f then
		return nil, f or ("open failed: " .. tostring(f) .. " (" .. path .. ")")
	end
	local content = f:read("*a")
	f:close()
	local ok2, state = pcall(json.decode, content)
	if not ok2 then
		return nil, "invalid JSON in " .. tostring(path) .. ": " .. tostring(state)
	end
	return state
end

-- Optional: list all state files in states/ directory
function StateIO.listStates(directory)
	-- TODO: implement using love.filesystem.getDirectoryItems
	return love.filesystem.getDirectoryItems(directory)
end

return StateIO
