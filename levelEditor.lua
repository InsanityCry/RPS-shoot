local LevelEditor = {
    active = false,
    currentTileType = 1,
    gridSize = 32,
    camera = {x = 0, y = 0},
    mode = "tile",  -- "tile", "player" or "menu" or "enemy"
    playerSpawn = {x = 400, y = 300},  -- Default center of screen
    -- Add notification system
    notification = {
        text = "",
        timer = 0,
        duration = 2  -- How long the notification stays on screen
    },
    menuState = {
        selectedOption = 1,
        options = {},
        action = nil  -- "save", "load", "delete", or nil
    },
    levelNameInput = {
        text = "",
        active = false
    }
}

local TileManager = require('tileManager')
local LevelManager = require('levelManager')

function LevelEditor:init()
    self.currentLevel = TileManager:createTilemap(25, 19)  -- 800x600 divided by 32
    self.currentLevel.playerSpawn = {x = self.playerSpawn.x, y = self.playerSpawn.y}
    
    -- Initialize level manager
    LevelManager:init()
    
    -- Copy level1.lua to levels directory if it doesn't exist as a default level
    local exists = love.filesystem.getInfo("levels/level1.lua")
    if not exists and love.filesystem.getInfo("level1.lua") then
        local content = love.filesystem.read("level1.lua")
        if content then
            love.filesystem.write("levels/level1.lua", content)
        end
    end
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
    elseif self.mode == "enemy" then
        if love.mouse.isDown(1) then  -- Left click to place enemy
            local tileX = math.floor(mouseX / self.gridSize) + 1
            local tileY = math.floor(mouseY / self.gridSize) + 1
            
            TileManager:setTile(self.currentLevel, tileX, tileY, TileManager.tileTypes.ENEMY)
        elseif love.mouse.isDown(2) then  -- Right click to remove enemy
            local tileX = math.floor(mouseX / self.gridSize) + 1
            local tileY = math.floor(mouseY / self.gridSize) + 1
            
            -- Only remove if it's an enemy
            if TileManager:getTile(self.currentLevel, tileX, tileY) == TileManager.tileTypes.ENEMY then
                TileManager:setTile(self.currentLevel, tileX, tileY, TileManager.tileTypes.EMPTY)
            end
        end
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

    -- Draw UI for current mode
    if self.mode == "menu" then
        self:drawMenu()
    else
        -- Draw standard UI
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Level Editor Mode: " .. self.mode, 10, 10)
        
        if self.mode == "tile" then
            love.graphics.print("Current Tile: " .. self.currentTileType, 10, 30)
            love.graphics.print("Left Click: Place Tile", 10, 50)
            love.graphics.print("Right Click: Remove Tile", 10, 70)
            love.graphics.print("1-5: Select Tile Type", 10, 90)
        elseif self.mode == "player" then
            love.graphics.print("Left Click: Place Player Spawn", 10, 30)
        elseif self.mode == "enemy" then
            love.graphics.print("Left Click: Place Enemy", 10, 30)
            love.graphics.print("Right Click: Remove Enemy", 10, 50)
        end
        
        love.graphics.print("Space: Cycle Modes (Tile/Player/Enemy)", 10, 110)
        love.graphics.print("S: Save Level", 10, 130)
        love.graphics.print("L: Load Level", 10, 150)
        love.graphics.print("D: Delete Level", 10, 170)
        
        -- Show current level name if one is loaded
        if LevelManager.currentLevelName then
            love.graphics.print("Current Level: " .. LevelManager.currentLevelName, 10, 200)
        end
    end

    -- Draw notification if active
    if self.notification.timer > 0 then
        local alpha = math.min(1, self.notification.timer / 0.5)  -- Fade out in last 0.5 seconds
        love.graphics.setColor(0, 1, 0, alpha)
        love.graphics.print(self.notification.text, 
            love.graphics.getWidth() / 2 - 50,  -- Centered horizontally
            love.graphics.getHeight() - 50)     -- Near bottom of screen
    end
    
    -- Draw level name input field if active
    if self.levelNameInput.active then
        -- Draw a darkened background
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        -- Draw input box
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        local boxWidth = 300
        local boxHeight = 100
        local boxX = love.graphics.getWidth() / 2 - boxWidth / 2
        local boxY = love.graphics.getHeight() / 2 - boxHeight / 2
        love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)
        
        -- Draw border
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight)
        
        -- Draw title and input text
        local title = "Enter Level Name:"
        love.graphics.print(title, boxX + boxWidth / 2 - love.graphics.getFont():getWidth(title) / 2, boxY + 20)
        love.graphics.print(self.levelNameInput.text .. (love.timer.getTime() % 1 > 0.5 and "_" or ""), boxX + 20, boxY + 50)
        
        -- Draw instructions
        local instructions = "Press Enter to confirm, Escape to cancel"
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.print(instructions, boxX + boxWidth / 2 - love.graphics.getFont():getWidth(instructions) / 2, boxY + 75)
    end
end

function LevelEditor:drawMenu()
    -- Draw a semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw menu title
    love.graphics.setColor(1, 1, 1, 1)
    local title = self:getMenuTitle()
    love.graphics.print(title, 
        love.graphics.getWidth() / 2 - love.graphics.getFont():getWidth(title) / 2, 
        50)
    
    -- Draw menu options
    for i, option in ipairs(self.menuState.options) do
        if i == self.menuState.selectedOption then
            love.graphics.setColor(1, 1, 0, 1)  -- Highlight selected option
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        
        love.graphics.print(option, 
            love.graphics.getWidth() / 2 - love.graphics.getFont():getWidth(option) / 2, 
            100 + (i * 30))
    end
    
    -- Draw instructions
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("Arrow Keys: Navigate, Enter: Select, Escape: Back", 
        love.graphics.getWidth() / 2 - 150, 
        love.graphics.getHeight() - 50)
end

function LevelEditor:getMenuTitle()
    if self.menuState.action == "save" then
        return "Save Level"
    elseif self.menuState.action == "load" then
        return "Load Level"
    elseif self.menuState.action == "delete" then
        return "Delete Level"
    else
        return "Level Menu"
    end
end

function LevelEditor:keypressed(key)
    if not self.active then return end
    
    -- Handle level name input if active
    if self.levelNameInput.active then
        if key == "return" or key == "kpenter" then
            -- Confirm input
            self:confirmLevelNameInput()
        elseif key == "escape" then
            -- Cancel input
            self.levelNameInput.active = false
            self.levelNameInput.text = ""
        elseif key == "backspace" then
            -- Remove last character
            self.levelNameInput.text = string.sub(self.levelNameInput.text, 1, -2)
        end
        return
    end
    
    -- Handle menu mode
    if self.mode == "menu" then
        if key == "escape" then
            -- Exit menu
            self.mode = "tile"
            return
        elseif key == "up" then
            -- Move selection up
            self.menuState.selectedOption = math.max(1, self.menuState.selectedOption - 1)
            return
        elseif key == "down" then
            -- Move selection down
            self.menuState.selectedOption = math.min(#self.menuState.options, self.menuState.selectedOption + 1)
            return
        elseif key == "return" or key == "kpenter" then
            -- Select option
            self:selectMenuOption()
            return
        end
    else
        -- Toggle between tile, player placement, and enemy placement modes
        if key == "space" then
            if self.mode == "tile" then
                self.mode = "player"
            elseif self.mode == "player" then
                self.mode = "enemy"
            else
                self.mode = "tile"
            end
            return
        end
        
        -- Tile selection only in tile mode
        if self.mode == "tile" and key >= "1" and key <= "5" then
            self.currentTileType = tonumber(key)
            return
        end
        
        -- Save level
        if key == "s" then
            self:showSaveMenu()
            return
        end
        
        -- Load level
        if key == "l" then
            self:showLoadMenu()
            return
        end
        
        -- Delete level
        if key == "d" then
            self:showDeleteMenu()
            return
        end
    end
end

function LevelEditor:textinput(text)
    if self.levelNameInput.active then
        -- Only allow alphanumeric characters, underscore, and hyphen
        if text:match("[%w_-]") then
            self.levelNameInput.text = self.levelNameInput.text .. text
        end
    end
end

function LevelEditor:showSaveMenu()
    self.mode = "menu"
    self.menuState.action = "save"
    self.menuState.selectedOption = 1
    
    -- Get existing levels
    local levels = LevelManager:listLevels()
    table.insert(levels, 1, "New Level...")
    
    self.menuState.options = levels
end

function LevelEditor:showLoadMenu()
    self.mode = "menu"
    self.menuState.action = "load"
    self.menuState.selectedOption = 1
    
    -- Get existing levels
    local levels = LevelManager:listLevels()
    if #levels == 0 then
        self:showNotification("No levels found!")
        self.mode = "tile"  -- Return to tile mode
    else
        self.menuState.options = levels
    end
end

function LevelEditor:showDeleteMenu()
    self.mode = "menu"
    self.menuState.action = "delete"
    self.menuState.selectedOption = 1
    
    -- Get existing levels
    local levels = LevelManager:listLevels()
    if #levels == 0 then
        self:showNotification("No levels found!")
        self.mode = "tile"  -- Return to tile mode
    else
        self.menuState.options = levels
    end
end

function LevelEditor:selectMenuOption()
    local selectedOption = self.menuState.options[self.menuState.selectedOption]
    
    if self.menuState.action == "save" then
        if selectedOption == "New Level..." then
            -- Show input for new level name
            self.levelNameInput.active = true
            self.levelNameInput.text = ""
        else
            -- Save to existing level
            local success, message = LevelManager:saveLevel(self.currentLevel, selectedOption)
            self:showNotification(message)
            self.mode = "tile"  -- Return to tile mode
        end
    elseif self.menuState.action == "load" then
        -- Load selected level
        local success, result = LevelManager:loadLevel(selectedOption)
        if success then
            self.currentLevel = result
            self:showNotification("Level loaded: " .. selectedOption)
        else
            self:showNotification(result)
        end
        self.mode = "tile"  -- Return to tile mode
    elseif self.menuState.action == "delete" then
        -- Delete selected level
        local success, message = LevelManager:deleteLevel(selectedOption)
        self:showNotification(message)
        self.mode = "tile"  -- Return to tile mode
    end
end

function LevelEditor:confirmLevelNameInput()
    if self.levelNameInput.text == "" then
        self:showNotification("Level name cannot be empty!")
        return
    end
    
    -- Check if level already exists
    local levels = LevelManager:listLevels()
    for _, level in ipairs(levels) do
        if level == self.levelNameInput.text then
            self:showNotification("Level name already exists!")
            return
        end
    end
    
    -- Save level with new name
    local success, message = LevelManager:saveLevel(self.currentLevel, self.levelNameInput.text)
    self:showNotification(message)
    
    -- Reset and return to tile mode
    self.levelNameInput.active = false
    self.levelNameInput.text = ""
    self.mode = "tile"
end

function LevelEditor:showNotification(text)
    self.notification.text = text
    self.notification.timer = self.notification.duration
end

return LevelEditor 