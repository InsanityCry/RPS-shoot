local LevelManager = {
    levelsDirectory = "levels/",
    currentLevelName = nil
}

local TileManager = require('tileManager')

-- Initialize the level manager
function LevelManager:init()
    -- Create levels directory if it doesn't exist
    love.filesystem.createDirectory(self.levelsDirectory)
end

-- Get a list of all available levels
function LevelManager:listLevels()
    local levels = {}
    local items = love.filesystem.getDirectoryItems(self.levelsDirectory)
    
    for _, item in ipairs(items) do
        if item:match("%.lua$") then
            -- Remove the .lua extension
            local levelName = item:gsub("%.lua$", "")
            table.insert(levels, levelName)
        end
    end
    
    return levels
end

-- Save a level with a given name
function LevelManager:saveLevel(levelData, levelName)
    -- Create the full path
    local filename = self.levelsDirectory .. levelName .. ".lua"
    
    local file, errorMsg = io.open(filename, "w")
    if file then
        file:write("return {\n")
        file:write(string.format("    width = %d,\n", levelData.width))
        file:write(string.format("    height = %d,\n", levelData.height))
        file:write("    playerSpawn = {\n")
        file:write(string.format("        x = %d,\n", levelData.playerSpawn.x))
        file:write(string.format("        y = %d\n", levelData.playerSpawn.y))
        file:write("    },\n")
        file:write("    data = {\n")
        
        for y = 1, levelData.height do
            file:write("        {")
            for x = 1, levelData.width do
                file:write(tostring(levelData.data[y][x]))
                if x < levelData.width then
                    file:write(", ")
                end
            end
            file:write("},\n")
        end
        
        file:write("    }\n")
        file:write("}\n")
        file:close()
        
        self.currentLevelName = levelName
        return true, "Level saved successfully!"
    else
        return false, "Error saving level: " .. (errorMsg or "Unknown error")
    end
end

-- Load a level by name
function LevelManager:loadLevel(levelName)
    local filename = self.levelsDirectory .. levelName .. ".lua"
    
    -- First check if the file exists
    local exists = love.filesystem.getInfo(filename)
    if not exists then
        return false, "Level file not found: " .. levelName
    end
    
    local success, chunk = pcall(love.filesystem.load, filename)
    if success and chunk then
        local levelData = chunk()
        
        -- Create a new tilemap with the loaded dimensions
        local level = TileManager:createTilemap(levelData.width, levelData.height)
        
        -- Copy the tile data
        for y = 1, levelData.height do
            for x = 1, levelData.width do
                if levelData.data[y] and levelData.data[y][x] then
                    level.data[y][x] = levelData.data[y][x]
                end
            end
        end
        
        -- Copy player spawn position
        if levelData.playerSpawn then
            level.playerSpawn = {
                x = levelData.playerSpawn.x,
                y = levelData.playerSpawn.y
            }
        end
        
        self.currentLevelName = levelName
        return true, level
    else
        return false, "Error loading level: " .. (chunk or "Unknown error")
    end
end

-- Delete a level
function LevelManager:deleteLevel(levelName)
    local filename = self.levelsDirectory .. levelName .. ".lua"
    local success, errorMsg = love.filesystem.remove(filename)
    
    if success then
        if self.currentLevelName == levelName then
            self.currentLevelName = nil
        end
        return true, "Level deleted successfully!"
    else
        return false, "Error deleting level: " .. (errorMsg or "Unknown error")
    end
end

return LevelManager 