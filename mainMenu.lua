local MainMenu = {
    active = true,
    selectedOption = 1,
    options = {"Play Default Level", "Select Level", "Level Editor", "Quit"},
    levelSelectionActive = false,
    levelList = {},
    selectedLevel = 1
}

local LevelManager = require('levelManager')
local LevelEditor = require('levelEditor')
local EnemyManager = require('enemyManager')

function MainMenu:init()
    -- Initialize level manager to get available levels
    LevelManager:init()
    self:refreshLevelList()
end

function MainMenu:refreshLevelList()
    self.levelList = LevelManager:listLevels()
    self.selectedLevel = 1
end

function MainMenu:update(dt)
    if not self.active then return end
    
    -- Nothing to update in the menu for now
end

function MainMenu:draw()
    if not self.active then return end
    
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    if self.levelSelectionActive then
        -- Draw level selection
        love.graphics.print("Select Level:", 
            love.graphics.getWidth() / 2 - love.graphics.getFont():getWidth("Select Level:") / 2, 
            150)
        
        if #self.levelList == 0 then
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("No levels found! Create some in the Level Editor.", 
                love.graphics.getWidth() / 2 - 150, 
                200)
            
            love.graphics.print("Press Escape to go back", 
                love.graphics.getWidth() / 2 - 100, 
                love.graphics.getHeight() - 50)
        else
            for i, level in ipairs(self.levelList) do
                if i == self.selectedLevel then
                    love.graphics.setColor(1, 1, 0)  -- Highlight selected level
                else
                    love.graphics.setColor(1, 1, 1)
                end
                
                love.graphics.print(level, 
                    love.graphics.getWidth() / 2 - love.graphics.getFont():getWidth(level) / 2, 
                    180 + (i * 30))
            end
            
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("Arrow Keys: Navigate, Enter: Select, Escape: Back", 
                love.graphics.getWidth() / 2 - 150, 
                love.graphics.getHeight() - 50)
        end
    else
        -- Draw main menu options
        for i, option in ipairs(self.options) do
            if i == self.selectedOption then
                love.graphics.setColor(1, 1, 0)  -- Highlight selected option
            else
                love.graphics.setColor(1, 1, 1)
            end
            
            love.graphics.print(option, 
                love.graphics.getWidth() / 2 - love.graphics.getFont():getWidth(option) / 2, 
                150 + (i * 40))
        end
        
        -- Draw instructions
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("Arrow Keys: Navigate, Enter: Select", 
            love.graphics.getWidth() / 2 - 120, 
            love.graphics.getHeight() - 50)
    end
end

function MainMenu:keypressed(key)
    if not self.active then return end
    
    if self.levelSelectionActive then
        if key == "up" then
            self.selectedLevel = math.max(1, self.selectedLevel - 1)
        elseif key == "down" then
            self.selectedLevel = math.min(#self.levelList, self.selectedLevel + 1)
        elseif key == "return" or key == "kpenter" then
            if #self.levelList > 0 then
                -- Load the selected level
                local levelName = self.levelList[self.selectedLevel]
                local success, level = LevelManager:loadLevel(levelName)
                
                if success then
                    -- Set the level in the LevelEditor
                    LevelEditor.currentLevel = level
                    
                    -- Initialize enemies
                    EnemyManager:initFromLevel(level)
                    
                    -- Exit the menu
                    self.active = false
                    self.levelSelectionActive = false
                    resetGame()
                end
            end
        elseif key == "escape" then
            -- Return to main menu
            self.levelSelectionActive = false
        end
    else
        if key == "up" then
            self.selectedOption = math.max(1, self.selectedOption - 1)
        elseif key == "down" then
            self.selectedOption = math.min(#self.options, self.selectedOption + 1)
        elseif key == "return" or key == "kpenter" then
            self:selectOption()
        end
    end
end

function MainMenu:selectOption()
    local option = self.options[self.selectedOption]
    
    if option == "Play Default Level" then
        -- Load the default level or create a new one
        local success, level = LevelManager:loadLevel("level1")
        
        if success then
            LevelEditor.currentLevel = level
        else
            -- If level1 doesn't exist, use the default empty level
            LevelEditor.currentLevel = LevelEditor.currentLevel or TileManager:createTilemap(25, 19)
        end
        
        -- Initialize enemies
        EnemyManager:initFromLevel(LevelEditor.currentLevel)
        
        -- Exit the menu
        self.active = false
        resetGame()
    elseif option == "Select Level" then
        -- Refresh the level list and show level selection
        self:refreshLevelList()
        self.levelSelectionActive = true
    elseif option == "Level Editor" then
        -- Enter editor mode
        self.active = false
        LevelEditor.active = true
    elseif option == "Quit" then
        love.event.quit()
    end
end

function MainMenu:show()
    self.active = true
    self.selectedOption = 1
    self.levelSelectionActive = false
end

return MainMenu 