local TileManager = {
    tileSize = 32,  -- Default tile size
    tiles = {},     -- Tile definitions
    tilesets = {}   -- Loaded tilesets
}

-- Initialize tile types
TileManager.tileTypes = {
    EMPTY = 0,
    WALL = 1,
    PLATFORM = 2,
    SPIKE = 3,
    -- Add more tile types as needed
}

-- Initialize a new tilemap
function TileManager:createTilemap(width, height)
    local tilemap = {
        width = width,
        height = height,
        data = {}
    }
    
    -- Initialize with empty tiles
    for y = 1, height do
        tilemap.data[y] = {}
        for x = 1, width do
            tilemap.data[y][x] = self.tileTypes.EMPTY
        end
    end
    
    return tilemap
end

-- Set a tile in the tilemap
function TileManager:setTile(tilemap, x, y, tileType)
    if x >= 1 and x <= tilemap.width and y >= 1 and y <= tilemap.height then
        tilemap.data[y][x] = tileType
    end
end

-- Get a tile from the tilemap
function TileManager:getTile(tilemap, x, y)
    if x >= 1 and x <= tilemap.width and y >= 1 and y <= tilemap.height then
        return tilemap.data[y][x]
    end
    return nil
end

-- Draw the tilemap
function TileManager:drawTilemap(tilemap)
    for y = 1, tilemap.height do
        for x = 1, tilemap.width do
            local tile = tilemap.data[y][x]
            local screenX = (x - 1) * self.tileSize
            local screenY = (y - 1) * self.tileSize
            
            -- Draw different tiles based on type
            if tile == self.tileTypes.WALL then
                love.graphics.setColor(0.5, 0.5, 0.5)
                love.graphics.rectangle("fill", screenX, screenY, self.tileSize, self.tileSize)
            elseif tile == self.tileTypes.PLATFORM then
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.rectangle("fill", screenX, screenY, self.tileSize, self.tileSize)
            elseif tile == self.tileTypes.SPIKE then
                love.graphics.setColor(1, 0, 0)
                love.graphics.rectangle("fill", screenX, screenY, self.tileSize, self.tileSize)
            end
        end
    end
    love.graphics.setColor(1, 1, 1)  -- Reset color
end

return TileManager 