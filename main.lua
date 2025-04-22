-- Load game resources and initialize
local TileManager = require('tileManager')
local LevelEditor = require('levelEditor')

function love.load()
    -- Platform data - creating a box around the screen
    wallThickness = 20
    screenWidth = 800
    screenHeight = 600
    
    -- Initialize default platforms (will be replaced by level data)
    platforms = {
      -- Bottom wall
      {x = 0, y = screenHeight - wallThickness, width = screenWidth, height = wallThickness},
      -- Top wall
      {x = 0, y = 0, width = screenWidth, height = wallThickness},
      -- Left wall
      {x = 0, y = 0, width = wallThickness, height = screenHeight},
      -- Right wall
      {x = screenWidth - wallThickness, y = 0, width = wallThickness, height = screenHeight}
    }
  
    -- Player settings - placed safely inside the box
    player = {
      x = screenWidth / 2 - 10,  -- Centered horizontally
      y = screenHeight / 2,      -- Middle of screen
      width = 20,
      height = 40,
      speed = 200,
      jumpVelocity = -400,
      velocity = {x = 0, y = 0},
      grounded = false,
      coyoteTime = 0.15,         -- Time window where player can still jump after leaving ground
      coyoteTimer = 0            -- Current coyote time counter
    }
    
    -- Physics settings
    gravity = 900
    
    -- Debug flag
    debug = false

    -- Initialize level editor
    LevelEditor:init()
end
  
-- Update game state
function love.update(dt)
    -- Update level editor if active
    LevelEditor:update(dt)

    -- Only update player if not in editor mode
    if not LevelEditor.active then
        updatePlayer(dt)
        checkCollisions()
        
        -- Update coyote timer
        if player.grounded then
            player.coyoteTimer = player.coyoteTime
        else
            player.coyoteTimer = math.max(0, player.coyoteTimer - dt)
        end
    end
end
  
-- Draw all game elements
function love.draw()
    if LevelEditor.active then
        -- Draw level editor
        LevelEditor:draw()
    else
        -- Draw the current level if it exists
        if LevelEditor.currentLevel then
            TileManager:drawTilemap(LevelEditor.currentLevel)
        end

        -- Draw player
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
        
        -- Debug info
        if debug then
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("Grounded: " .. tostring(player.grounded), 10, 10)
            love.graphics.print("Coyote Timer: " .. string.format("%.2f", player.coyoteTimer), 10, 30)
        end
    end
end
  
-- Update player position and handle input
function updatePlayer(dt)
    -- Apply gravity
    if not player.grounded then
        player.velocity.y = player.velocity.y + gravity * dt
    end
    
    -- Reset horizontal velocity
    player.velocity.x = 0
    
    -- Handle keyboard input - support both arrow keys and WASD
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        player.velocity.x = -player.speed
    end
    
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        player.velocity.x = player.speed
    end
    
    -- Update player position
    player.x = player.x + player.velocity.x * dt
    player.y = player.y + player.velocity.y * dt
    
    -- Reset grounded state
    player.grounded = false
end
  
-- Handle jumping on key press
function love.keypressed(key)
    -- Toggle level editor with Tab
    if key == "tab" then
        LevelEditor:toggle()
        return
    end

    -- Pass keypressed events to level editor if active
    if LevelEditor.active then
        LevelEditor:keypressed(key)
        return
    end

    if (key == "w" or key == "up") and (player.grounded or player.coyoteTimer > 0) then
        player.velocity.y = player.jumpVelocity
        player.grounded = false
        player.coyoteTimer = 0
    end
    
    -- Restart the whole application when Ctrl+R is pressed
    if key == "r" and love.keyboard.isDown("lctrl", "rctrl") then
        love.event.quit("restart")
    end
    
    -- Toggle debug mode with F1
    if key == "f1" then
        debug = not debug
    end
end
  
-- Check for collisions between player and level tiles
function checkCollisions()
    local wasGrounded = player.grounded
    player.grounded = false
    
    -- Check collisions with level tiles if a level is loaded
    if LevelEditor.currentLevel then
        local level = LevelEditor.currentLevel
        local tileSize = TileManager.tileSize
        
        -- Calculate the tiles the player might be colliding with
        local startX = math.floor(player.x / tileSize) + 1
        local endX = math.floor((player.x + player.width) / tileSize) + 1
        local startY = math.floor(player.y / tileSize) + 1
        local endY = math.floor((player.y + player.height) / tileSize) + 1
        
        for y = startY, endY do
            for x = startX, endX do
                local tile = TileManager:getTile(level, x, y)
                if tile == TileManager.tileTypes.WALL or tile == TileManager.tileTypes.PLATFORM then
                    local tileX = (x - 1) * tileSize
                    local tileY = (y - 1) * tileSize
                    
                    -- Check for collision
                    if player.x + player.width > tileX and
                       player.x < tileX + tileSize and
                       player.y + player.height > tileY and
                       player.y < tileY + tileSize then
                        
                        -- Calculate overlap
                        local overlapX = math.min(player.x + player.width - tileX, tileX + tileSize - player.x)
                        local overlapY = math.min(player.y + player.height - tileY, tileY + tileSize - player.y)
                        
                        -- Resolve collision
                        if overlapX < overlapY then
                            -- Horizontal collision
                            if player.x < tileX then
                                player.x = tileX - player.width
                            else
                                player.x = tileX + tileSize
                            end
                            player.velocity.x = 0
                        else
                            -- Vertical collision
                            if player.y < tileY then
                                -- Landing on top
                                player.y = tileY - player.height
                                player.velocity.y = 0
                                player.grounded = true
                            else
                                -- Hitting bottom
                                player.y = tileY + tileSize
                                player.velocity.y = 0
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Also check collisions with the default platforms if no level is loaded
    if not LevelEditor.currentLevel then
        for _, platform in ipairs(platforms) do
            if player.x + player.width > platform.x and
               player.x < platform.x + platform.width and
               player.y + player.height > platform.y and
               player.y < platform.y + platform.height then
                
                local overlapX = math.min(player.x + player.width - platform.x, platform.x + platform.width - player.x)
                local overlapY = math.min(player.y + player.height - platform.y, platform.y + platform.height - player.y)
                
                if overlapX < overlapY then
                    -- Horizontal collision
                    if player.x < platform.x then
                        player.x = platform.x - player.width
                    else
                        player.x = platform.x + platform.width
                    end
                    player.velocity.x = 0
                else
                    -- Vertical collision
                    if player.y < platform.y then
                        player.y = platform.y - player.height
                        player.velocity.y = 0
                        player.grounded = true
                    else
                        player.y = platform.y + platform.height
                        player.velocity.y = 0
                    end
                end
            end
        end
    end
    
    -- Play landing sound effect
    if not wasGrounded and player.grounded then
        -- Add sound effect
    end
end
  
-- Reset the game to initial state
function resetGame()
    -- Reset player to spawn position if available, otherwise center
    if LevelEditor.currentLevel and LevelEditor.currentLevel.playerSpawn then
        player.x = LevelEditor.currentLevel.playerSpawn.x
        player.y = LevelEditor.currentLevel.playerSpawn.y
    else
        player.x = screenWidth / 2 - 10
        player.y = screenHeight / 2
    end
    
    player.velocity.x = 0
    player.velocity.y = 0
    player.grounded = false
    player.coyoteTimer = 0
end 