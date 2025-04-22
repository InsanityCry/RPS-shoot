local LevelEditor = {
    active = false,
    currentTileType = 1,
    gridSize = 32,
    camera = {x = 0, y = 0},
    mode = "tile",  -- "tile" or "player"
    playerSpawn = {x = 400, y = 300},  -- Default center of screen
    -- Add notification system
    notification = {
        text = "",
        timer = 0,
        duration = 2  -- How long the notification stays on screen
    }
}

local TileManager = require('tileManager')

function LevelEditor:init()
    self.currentLevel = TileManager:createTilemap(25, 19)  -- 800x600 divided by 32
    self.currentLevel.playerSpawn = {x = self.playerSpawn.x, y = self.playerSpawn.y}
end

function LevelEditor:toggle()
    self.active = not self.active
    if not self.active then
        -- When exiting editor mode, reset player to proper position
        resetGame()
    end
end

function LevelEditor:update(dt)
    if not self.active then return end

    -- Update notification timer
    if self.notification.timer > 0 then
        self.notification.timer = self.notification.timer - dt
    end

    local mouseX = love.mouse.getX() + self.camera.x
    local mouseY = love.mouse.getY() + self.camera.y

    if self.mode == "tile" then
        -- Handle tile placement
        if love.mouse.isDown(1) then  -- Left click
            local tileX = math.floor(mouseX / self.gridSize) + 1
            local tileY = math.floor(mouseY / self.gridSize) + 1
            
            TileManager:setTile(self.currentLevel, tileX, tileY, self.currentTileType)
        elseif love.mouse.isDown(2) then  -- Right click
            local tileX = math.floor(mouseX / self.gridSize) + 1
            local tileY = math.floor(mouseY / self.gridSize) + 1
            
            TileManager:setTile(self.currentLevel, tileX, tileY, TileManager.tileTypes.EMPTY)
        end
    elseif self.mode == "player" and love.mouse.isDown(1) then
        -- Handle player placement (snap to grid)
        local gridX = math.floor(mouseX / self.gridSize) * self.gridSize
        local gridY = math.floor(mouseY / self.gridSize) * self.gridSize
        self.currentLevel.playerSpawn = {x = gridX, y = gridY}
    end
end

function LevelEditor:draw()
    if not self.active then return end
    
    -- Draw the current level
    TileManager:drawTilemap(self.currentLevel)
    
    -- Draw grid
    love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
    for x = 0, love.graphics.getWidth(), self.gridSize do
        love.graphics.line(x, 0, x, love.graphics.getHeight())
    end
    for y = 0, love.graphics.getHeight(), self.gridSize do
        love.graphics.line(0, y, love.graphics.getWidth(), y)
    end
    
    -- Draw player spawn position
    love.graphics.setColor(0, 1, 0, 0.8)
    love.graphics.rectangle("fill", 
        self.currentLevel.playerSpawn.x, 
        self.currentLevel.playerSpawn.y, 
        20, 40)  -- Using player dimensions
    
    -- Draw UI
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Level Editor Mode: " .. self.mode, 10, 10)
    if self.mode == "tile" then
        love.graphics.print("Current Tile: " .. self.currentTileType, 10, 30)
        love.graphics.print("Left Click: Place Tile", 10, 50)
        love.graphics.print("Right Click: Remove Tile", 10, 70)
        love.graphics.print("1-4: Select Tile Type", 10, 90)
    else
        love.graphics.print("Left Click: Place Player Spawn", 10, 30)
    end
    love.graphics.print("Space: Toggle Tile/Player Mode", 10, 110)
    love.graphics.print("Ctrl+S: Save Level", 10, 130)
    love.graphics.print("Ctrl+L: Load Level", 10, 150)

    -- Draw notification if active
    if self.notification.timer > 0 then
        local alpha = math.min(1, self.notification.timer / 0.5)  -- Fade out in last 0.5 seconds
        love.graphics.setColor(0, 1, 0, alpha)
        love.graphics.print(self.notification.text, 
            love.graphics.getWidth() / 2 - 50,  -- Centered horizontally
            love.graphics.getHeight() - 50)     -- Near bottom of screen
    end
end

function LevelEditor:keypressed(key)
    if not self.active then return end
    
    if key == "space" then
        -- Toggle between tile and player placement modes
        self.mode = self.mode == "tile" and "player" or "tile"
        return
    end
    
    -- Tile selection only in tile mode
    if self.mode == "tile" and key >= "1" and key <= "4" then
        self.currentTileType = tonumber(key)
    end
    
    -- Save level
    if key == "s" and love.keyboard.isDown("lctrl", "rctrl") then
        self:saveLevel("level1.lua")
    end
    
    -- Load level
    if key == "l" and love.keyboard.isDown("lctrl", "rctrl") then
        self:loadLevel("level1.lua")
    end
end

function LevelEditor:showNotification(text)
    self.notification.text = text
    self.notification.timer = self.notification.duration
end

function LevelEditor:saveLevel(filename)
    local file = io.open(filename, "w")
    if file then
        file:write("return {\n")
        file:write(string.format("    width = %d,\n", self.currentLevel.width))
        file:write(string.format("    height = %d,\n", self.currentLevel.height))
        file:write("    playerSpawn = {\n")
        file:write(string.format("        x = %d,\n", self.currentLevel.playerSpawn.x))
        file:write(string.format("        y = %d\n", self.currentLevel.playerSpawn.y))
        file:write("    },\n")
        file:write("    data = {\n")
        
        for y = 1, self.currentLevel.height do
            file:write("        {")
            for x = 1, self.currentLevel.width do
                file:write(tostring(self.currentLevel.data[y][x]))
                if x < self.currentLevel.width then
                    file:write(", ")
                end
            end
            file:write("},\n")
        end
        
        file:write("    }\n")
        file:write("}\n")
        file:close()
        
        -- Show success notification
        self:showNotification("Level saved successfully!")
    else
        -- Show error notification
        self:showNotification("Error saving level!")
    end
end

function LevelEditor:loadLevel(filename)
    local success, chunk = pcall(love.filesystem.load, filename)
    if success and chunk then
        local levelData = chunk()
        
        -- Create a new tilemap with the loaded dimensions
        self.currentLevel = TileManager:createTilemap(levelData.width, levelData.height)
        
        -- Copy the tile data
        for y = 1, levelData.height do
            for x = 1, levelData.width do
                self.currentLevel.data[y][x] = levelData.data[y][x]
            end
        end
        
        -- Copy player spawn position
        if levelData.playerSpawn then
            self.currentLevel.playerSpawn = {
                x = levelData.playerSpawn.x,
                y = levelData.playerSpawn.y
            }
        end
        
        -- Show success notification
        self:showNotification("Level loaded successfully!")
    else
        -- Show error notification
        self:showNotification("Error loading level!")
    end
end

return LevelEditor 