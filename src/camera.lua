local Camera = {}
Camera.__index = Camera

-- 카메라 객체를 새로 만드는 생성자 함수
function Camera.new(width, height)

    -- 빈 테이블 {}을 만들고 위에서 정의한 Camera 메타테이블을 연결하여
    -- 새로운 카메라 인스턴스를 생성한다
    local self = setmetatable({}, Camera)

    -- 카메라의 현재 월드 좌표를 0, 0으로 초기화
    self.x = 0
    self.y = 0

    -- 카메라가 보여줄 화면의 크기, 카논을 따라가는 속도의 가중치
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