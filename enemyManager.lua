local EnemyManager = {
    enemies = {},
    enemySpeed = 60,
    enemySize = {width = 20, height = 30},
    detectionRange = 250,  -- How far the enemy can detect the player
    gravity = 900,         -- Same gravity as the player
    jumpVelocity = -350,   -- Jump strength (negative because up is negative in y-axis)
    jumpCooldown = 1.5,    -- Time between jumps
    obstacleDetectionRange = 32  -- How far ahead to check for obstacles
}

local TileManager = require('tileManager')

-- Initialize enemies from level data
function EnemyManager:initFromLevel(level)
    self.enemies = {}
    
    if not level then return end
    
    for y = 1, level.height do
        for x = 1, level.width do
            if level.data[y][x] == TileManager.tileTypes.ENEMY then
                local enemyX = (x - 1) * TileManager.tileSize + (TileManager.tileSize - self.enemySize.width) / 2
                local enemyY = (y - 1) * TileManager.tileSize + (TileManager.tileSize - self.enemySize.height) / 2
                
                table.insert(self.enemies, {
                    x = enemyX,
                    y = enemyY,
                    width = self.enemySize.width,
                    height = self.enemySize.height,
                    velocity = {x = 0, y = 0},
                    direction = 1,  -- 1 for right, -1 for left
                    patrolDistance = 100,  -- How far to patrol
                    startX = enemyX,  -- Initial position for patrol
                    state = "patrol",  -- "patrol" or "chase"
                    grounded = false,  -- Whether the enemy is on ground
                    jumpTimer = 0,     -- Timer for jump cooldown
                    isJumping = false  -- Currently in a jump
                })
                
                -- Remove enemy from tilemap after creating the entity
                level.data[y][x] = TileManager.tileTypes.EMPTY
            end
        end
    end
end

-- Update all enemies
function EnemyManager:update(dt, player, level)
    for _, enemy in ipairs(self.enemies) do
        -- Update jump cooldown timer
        if enemy.jumpTimer > 0 then
            enemy.jumpTimer = enemy.jumpTimer - dt
        end
        
        -- Apply gravity if not grounded
        if not enemy.grounded then
            enemy.velocity.y = enemy.velocity.y + self.gravity * dt
            enemy.isJumping = (enemy.velocity.y < 0)  -- Still jumping if moving upward
        else
            enemy.velocity.y = 0
            enemy.isJumping = false
        end
        
        -- Calculate distance to player
        local dx = player.x - enemy.x
        local dy = player.y - enemy.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        -- Check if player is in line of sight
        local canSeePlayer = self:checkLineOfSight(enemy, player, level)
        
        -- Decide state based on player distance and visibility
        if distance < self.detectionRange and canSeePlayer then
            enemy.state = "chase"
        else
            enemy.state = "patrol"
        end

        -- Set horizontal velocity based on state
        self:handleMovement(enemy, level)
        
        -- Check if we need to jump
        self:checkJump(enemy, level)
        
        -- Apply velocity
        enemy.x = enemy.x + enemy.velocity.x * dt
        enemy.y = enemy.y + enemy.velocity.y * dt
        
        -- Reset grounded state before checking collisions
        local wasGrounded = enemy.grounded
        enemy.grounded = false
        
        -- Check for collisions with level
        self:checkCollisions(enemy, level)
        
        -- Edge detection - prevent walking off platforms (only if not jumping)
        if enemy.grounded and not enemy.isJumping then
            self:checkEdges(enemy, level)
        end
    end
end

-- Handle enemy movement based on current state
function EnemyManager:handleMovement(enemy, level)
    if enemy.state == "patrol" then
        -- Simple patrol back and forth
        if enemy.x > enemy.startX + enemy.patrolDistance then
            enemy.direction = -1
        elseif enemy.x < enemy.startX then
            enemy.direction = 1
        end
        
        enemy.velocity.x = self.enemySpeed * enemy.direction
    else
        -- Chase the player
        if player.x < enemy.x then
            enemy.direction = -1
        else
            enemy.direction = 1
        end
        
        enemy.velocity.x = self.enemySpeed * 1.5 * enemy.direction  -- Move faster when chasing
    end
end

-- Check if there's a tile under the enemy when it wants to move
function EnemyManager:checkEdges(enemy, level)
    if not level then return end
    
    local tileSize = TileManager.tileSize
    
    -- Check if there's ground in front of the enemy
    local frontTileX = math.floor((enemy.x + enemy.width * 0.5 + enemy.direction * enemy.width) / tileSize) + 1
    local bottomTileY = math.floor((enemy.y + enemy.height + 2) / tileSize) + 1  -- Check 2 pixels below enemy
    
    -- Get the tile that would be under the enemy's next step
    local groundTile = TileManager:getTile(level, frontTileX, bottomTileY)
    
    -- If there's no solid ground in front, check if we can jump across
    if not groundTile or (groundTile ~= TileManager.tileTypes.WALL and groundTile ~= TileManager.tileTypes.PLATFORM) then
        local canJumpAcross = false
        
        -- Only consider jumping if not on cooldown
        if enemy.jumpTimer <= 0 then
            -- Look ahead for a landing spot (up to 4 tiles away)
            for i = 2, 5 do
                local farX = frontTileX + (enemy.direction * i)
                local groundY = bottomTileY
                local farTile = TileManager:getTile(level, farX, groundY)
                
                if farTile and (farTile == TileManager.tileTypes.WALL or farTile == TileManager.tileTypes.PLATFORM) then
                    -- Before deciding to jump, check for obstacles in the path
                    local pathClear = true
                    for j = 1, i-1 do
                        local pathX = frontTileX + (enemy.direction * j)
                        local midY = math.floor((enemy.y + enemy.height/2 - tileSize/2) / tileSize) + 1
                        local pathTile = TileManager:getTile(level, pathX, midY)
                        
                        if pathTile and (pathTile == TileManager.tileTypes.WALL or pathTile == TileManager.tileTypes.PLATFORM) then
                            pathClear = false
                            break
                        end
                    end
                    
                    if pathClear then
                        canJumpAcross = true
                        break
                    end
                end
            end
        end
        
        if canJumpAcross then
            -- Jump!
            enemy.velocity.y = self.jumpVelocity
            enemy.isJumping = true
            enemy.jumpTimer = self.jumpCooldown
            enemy.grounded = false
        else
            -- Turn around
            enemy.direction = -enemy.direction
            enemy.velocity.x = -enemy.velocity.x
        end
    end
end

-- Check collisions between an enemy and the level
function EnemyManager:checkCollisions(enemy, level)
    if not level then return end
    
    local tileSize = TileManager.tileSize
    
    -- Calculate the tiles the enemy might be colliding with
    local startX = math.floor(enemy.x / tileSize) + 1
    local endX = math.floor((enemy.x + enemy.width) / tileSize) + 1
    local startY = math.floor(enemy.y / tileSize) + 1
    local endY = math.floor((enemy.y + enemy.height) / tileSize) + 1
    
    for y = startY, endY do
        for x = startX, endX do
            local tile = TileManager:getTile(level, x, y)
            if tile == TileManager.tileTypes.WALL or tile == TileManager.tileTypes.PLATFORM then
                local tileX = (x - 1) * tileSize
                local tileY = (y - 1) * tileSize
                
                -- Check for collision
                if enemy.x + enemy.width > tileX and
                   enemy.x < tileX + tileSize and
                   enemy.y + enemy.height > tileY and
                   enemy.y < tileY + tileSize then
                    
                    -- Calculate overlap
                    local overlapX = math.min(enemy.x + enemy.width - tileX, tileX + tileSize - enemy.x)
                    local overlapY = math.min(enemy.y + enemy.height - tileY, tileY + tileSize - enemy.y)
                    
                    -- Resolve collision
                    if overlapX < overlapY then
                        -- Horizontal collision - reverse direction
                        if enemy.x < tileX then
                            enemy.x = tileX - enemy.width
                        else
                            enemy.x = tileX + tileSize
                        end
                        enemy.direction = -enemy.direction
                        enemy.velocity.x = 0
                    else
                        -- Vertical collision
                        if enemy.y < tileY then
                            -- Landing on top
                            enemy.y = tileY - enemy.height
                            enemy.velocity.y = 0
                            enemy.grounded = true
                        else
                            -- Hitting bottom
                            enemy.y = tileY + tileSize
                            enemy.velocity.y = 0
                        end
                    end
                end
            end
        end
    end
end

-- Check if the enemy needs to jump over obstacles or gaps
function EnemyManager:checkJump(enemy, level)
    -- Don't try to jump if already jumping or on cooldown
    if enemy.isJumping or enemy.jumpTimer > 0 or not enemy.grounded then
        return
    end
    
    local tileSize = TileManager.tileSize
    
    -- Check for obstacles in front of the enemy
    local checkDistance = self.obstacleDetectionRange
    local startX = enemy.x + (enemy.direction > 0 and enemy.width or 0)
    local endX = startX + (enemy.direction * checkDistance)
    
    -- Check for obstacles at enemy's height
    local midY = enemy.y + (enemy.height / 2)
    local tileX = math.floor((endX) / tileSize) + 1
    local tileY = math.floor(midY / tileSize) + 1
    
    local obstacleFound = false
    local tile = TileManager:getTile(level, tileX, tileY)
    
    if tile == TileManager.tileTypes.WALL or tile == TileManager.tileTypes.PLATFORM then
        obstacleFound = true
    end
    
    -- Also check for gaps if not found an obstacle
    if not obstacleFound then
        -- Check if there's a large gap ahead
        local gapCheckX = math.floor((startX + enemy.direction * 40) / tileSize) + 1
        local floorY = math.floor((enemy.y + enemy.height + 2) / tileSize) + 1
        
        local floorTile = TileManager:getTile(level, gapCheckX, floorY)
        if not floorTile or (floorTile == TileManager.tileTypes.EMPTY) then
            -- Also check if there's a platform we can jump to
            local canJumpTo = false
            local landingX = 0
            
            for i = 1, 5 do  -- Check a few tiles ahead
                local farX = math.floor((startX + enemy.direction * (40 + i * tileSize)) / tileSize) + 1
                local platformTile = TileManager:getTile(level, farX, floorY)
                if platformTile and (platformTile == TileManager.tileTypes.WALL or platformTile == TileManager.tileTypes.PLATFORM) then
                    canJumpTo = true
                    landingX = farX
                    break
                end
            end
            
            if canJumpTo then
                -- Before jumping, make sure there's a clear path and no ceiling
                local canClearJump = true
                
                -- Check for ceiling obstacles that would prevent jumping
                for i = 1, 3 do  -- Check 3 tiles up from current position
                    local ceilingX = math.floor((enemy.x + enemy.width/2) / tileSize) + 1
                    local ceilingY = math.floor((enemy.y - i * tileSize/2) / tileSize) + 1
                    local ceilingTile = TileManager:getTile(level, ceilingX, ceilingY)
                    
                    if ceilingTile and (ceilingTile == TileManager.tileTypes.WALL or ceilingTile == TileManager.tileTypes.PLATFORM) then
                        canClearJump = false
                        break
                    end
                end
                
                -- If we can clear jump and there's a landing spot
                if canClearJump then
                    obstacleFound = true  -- Jump over the gap
                end
            end
        end
    end
    
    -- If we found an obstacle or gap to jump over
    if obstacleFound then
        -- Before jumping, check if there's a landing spot
        local safeToJump = true
        
        -- Estimate jump distance based on current velocity and jump strength
        local jumpDistance = math.abs(enemy.velocity.x) * 0.5  -- Rough estimation of horizontal distance
        local jumpEndX = enemy.x + (enemy.direction * jumpDistance)
        local jumpEndTileX = math.floor(jumpEndX / tileSize) + 1
        local jumpEndTileY = math.floor((enemy.y + enemy.height + 2) / tileSize) + 1
        
        -- Check if there's ground at the estimated landing spot
        local landingTile = TileManager:getTile(level, jumpEndTileX, jumpEndTileY)
        if not landingTile or (landingTile == TileManager.tileTypes.EMPTY) then
            -- Check a bit further for a landing spot
            safeToJump = false
            for i = 1, 3 do
                local extendedX = jumpEndTileX + (enemy.direction * i)
                local extendedTile = TileManager:getTile(level, extendedX, jumpEndTileY)
                if extendedTile and (extendedTile == TileManager.tileTypes.WALL or extendedTile == TileManager.tileTypes.PLATFORM) then
                    safeToJump = true
                    break
                end
            end
        end
        
        -- Only jump if it's safe to do so
        if safeToJump then
            -- Jump!
            enemy.velocity.y = self.jumpVelocity
            enemy.isJumping = true
            enemy.jumpTimer = self.jumpCooldown
            enemy.grounded = false
        else
            -- Turn around instead of jumping
            enemy.direction = -enemy.direction
        end
    end
end

-- Check if enemy has a clear line of sight to the player
function EnemyManager:checkLineOfSight(enemy, player, level)
    if not level then return false end
    
    local tileSize = TileManager.tileSize
    
    -- Get enemy and player eye positions (using center of their bodies)
    local enemyEyeX = enemy.x + enemy.width/2
    local enemyEyeY = enemy.y + enemy.height/3  -- A bit higher than center for "eyes"
    
    local playerCenterX = player.x + player.width/2
    local playerCenterY = player.y + player.height/2
    
    -- Calculate direction vector
    local dirX = playerCenterX - enemyEyeX
    local dirY = playerCenterY - enemyEyeY
    local distance = math.sqrt(dirX * dirX + dirY * dirY)
    
    -- Normalize direction
    dirX = dirX / distance
    dirY = dirY / distance
    
    -- Ray casting from enemy to player
    local stepSize = tileSize / 2  -- Half tile size for better precision
    local numSteps = math.ceil(distance / stepSize)
    
    for i = 1, numSteps do
        local posX = enemyEyeX + dirX * stepSize * i
        local posY = enemyEyeY + dirY * stepSize * i
        
        -- Convert position to tile coordinates
        local tileX = math.floor(posX / tileSize) + 1
        local tileY = math.floor(posY / tileSize) + 1
        
        -- Check if the tile is solid
        local tile = TileManager:getTile(level, tileX, tileY)
        if tile == TileManager.tileTypes.WALL or tile == TileManager.tileTypes.PLATFORM then
            -- Found an obstacle - can't see the player
            return false
        end
        
        -- If we're very close to the player, we can see them
        if math.abs(posX - playerCenterX) < stepSize and math.abs(posY - playerCenterY) < stepSize then
            return true
        end
    end
    
    -- No obstacles found along the line - can see the player
    return true
end

-- Draw all enemies
function EnemyManager:draw()
    for _, enemy in ipairs(self.enemies) do
        -- Draw enemy body
        if enemy.isJumping then
            -- Draw jumping enemy in a different color
            love.graphics.setColor(1, 0.5, 0.2)
        elseif enemy.state == "chase" then
            -- Draw chasing enemy in an alert color
            love.graphics.setColor(1, 0.3, 0.3)
        else
            love.graphics.setColor(0.8, 0.2, 0.2)
        end
        
        love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.width, enemy.height)
        
        -- Draw enemy "face" direction
        local eyeX = enemy.x + (enemy.direction == 1 and (enemy.width * 0.7) or (enemy.width * 0.3))
        local eyeY = enemy.y + (enemy.height * 0.3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", eyeX, eyeY, 3)
        
        -- Optional: Draw line of sight for debugging
        if enemy.state == "chase" then
            love.graphics.setColor(1, 1, 0, 0.3)
            local eyeX = enemy.x + enemy.width/2
            local eyeY = enemy.y + enemy.height/3
            local playerX = player.x + player.width/2
            local playerY = player.y + player.height/2
            love.graphics.line(eyeX, eyeY, playerX, playerY)
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Check if a player collides with any enemy
function EnemyManager:checkPlayerCollision(player)
    for _, enemy in ipairs(self.enemies) do
        if player.x + player.width > enemy.x and
           player.x < enemy.x + enemy.width and
           player.y + player.height > enemy.y and
           player.y < enemy.y + enemy.height then
            return true  -- Collision detected
        end
    end
    
    return false  -- No collision
end

return EnemyManager 