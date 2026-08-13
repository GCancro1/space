local json = require("ai.vendor.json")
local StateIO = {}

-- Load state from JSON file
-- @param path string - path relative to love.filesystem.getSaveDirectory()
-- @return table|nil, string|nil - state table or nil + error message
function StateIO.load(path)
	local content = love.filesystem.read(path)
	if not content then
		return nil, error("state file is empty")
	end
    local state = json.decode(content)
    return state
end

-- Save state to JSON file
-- @param state table - state table to save
-- @param path string - path relative to love.filesystem.getSaveDirectory()
-- @return boolean, string|nil - success, or false + error message
function StateIO.save(state, path)
	-- TODO: implement
	-- 1. json.encode(state)
	-- 2. love.filesystem.write(path, encoded)
	-- 3. return true/false, error
end

-- Optional: list all state files in states/ directory
function StateIO.listStates()
	-- TODO: implement using love.filesystem.getDirectoryItems
    return love.filesystem.getDirectoryItems()
end

return StateIO
