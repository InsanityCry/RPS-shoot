-- Load game resources and initialize
function love.load()
    -- Platform data - creating a box around the screen
    wallThickness = 20
    screenWidth = 800
    screenHeight = 600
    
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
  end
  
  -- Update game state
  function love.update(dt)
    updatePlayer(dt)
    checkCollisions()
    
    -- Update coyote timer
    if player.grounded then
      player.coyoteTimer = player.coyoteTime
    else
      player.coyoteTimer = math.max(0, player.coyoteTimer - dt)
    end
  end
  
  -- Draw all game elements
  function love.draw()
    -- Draw player
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
    
    -- Draw platforms
    love.graphics.setColor(0.5, 0.5, 0.5)
    for _, platform in ipairs(platforms) do
      love.graphics.rectangle("fill", platform.x, platform.y, platform.width, platform.height)
    end
    
    -- Debug info
    if debug then
      love.graphics.setColor(1, 1, 0)
      love.graphics.print("Grounded: " .. tostring(player.grounded), 10, 10)
      love.graphics.print("Coyote Timer: " .. string.format("%.2f", player.coyoteTimer), 10, 30)
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
  
  -- Check for collisions between player and platforms
  function checkCollisions()
    local wasGrounded = player.grounded
    player.grounded = false
    
    for _, platform in ipairs(platforms) do
      -- Predict next position
      local nextX = player.x + player.velocity.x * 0.01
      local nextY = player.y + player.velocity.y * 0.01
      
      -- Only check for collision if we're moving toward the platform
      local checkHorizontal = (player.velocity.x > 0 and player.x + player.width <= platform.x and nextX + player.width > platform.x) or
                             (player.velocity.x < 0 and player.x >= platform.x + platform.width and nextX < platform.x + platform.width)
      
      local checkVertical = (player.velocity.y > 0 and player.y + player.height <= platform.y and nextY + player.height > platform.y) or
                            (player.velocity.y < 0 and player.y >= platform.y + platform.height and nextY < platform.y + platform.height)
      
      -- Check for current collision
      if player.x + player.width > platform.x and
         player.x < platform.x + platform.width and
         player.y + player.height > platform.y and
         player.y < platform.y + platform.height then
         
        -- Handle collision based on direction
        local overlapX = math.min(player.x + player.width - platform.x, platform.x + platform.width - player.x)
        local overlapY = math.min(player.y + player.height - platform.y, platform.y + platform.height - player.y)
        
        -- Resolve collision (simpler approach)
        if overlapX < overlapY and (checkHorizontal or math.abs(player.velocity.x) > 0) then
          -- Horizontal collision
          if player.x < platform.x then
            player.x = platform.x - player.width
          else
            player.x = platform.x + platform.width
          end
          player.velocity.x = 0
        elseif overlapY < overlapX and (checkVertical or math.abs(player.velocity.y) > 0) then
          -- Vertical collision
          if player.y < platform.y then
            -- Landing on top of platform
            player.y = platform.y - player.height
            player.velocity.y = 0
            player.grounded = true
          else
            -- Hitting bottom of platform
            player.y = platform.y + platform.height
            player.velocity.y = 0
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
    -- Reset player
    player.x = screenWidth / 2 - 10
    player.y = screenHeight / 2
    player.velocity.x = 0
    player.velocity.y = 0
    player.grounded = false
    
    -- reset other game state here if needed
  end 