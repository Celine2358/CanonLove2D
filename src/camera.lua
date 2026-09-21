local Camera = {}
Camera.__index = Camera

function Camera.new(width, height)
    local self = setmetatable({}, Camera)

    self.x = 0
    self.y = 0

    self.width = width
    self.height = height
    self.followSpeed = 8

    return self
end

function Camera:update(dt, target, worldWidth, worldHeight)

    -- 카논이 화면 중앙 근처에 있도록 목표 위치 계산
    local targetX = target.x - self.width / 2
    local targetY = target.y - self.height / 2

    -- 월드 밖을 보여주지 않도록 Clamp(최솟값과 최댓값을 벗어나지 않도록 범위를 제한)한다
    targetX = math.max(0, math.min(worldWidth - self.width, targetX))
    targetY = math.max(0, math.min(worldHeight - self.height, targetY))

    -- 부드러운 추적
    self.x = self.x + (targetX - self.x) * math.min(1, self.followSpeed * dt)
    self.y = self.y + (targetY - self.y) * math.min(1, self.followSpeed * dt)
end

function Camera:beginDraw()

    love.graphics.push()
    love.graphics.translate(-math.floor(self.x), -math.floor(self.y))
end

function Camera:endDraw()
    
    love.graphics.pop()
end

return Camera