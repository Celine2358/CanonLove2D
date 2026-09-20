-- Stage라는 이름의 빈 테이블을 생성한다
local Stage = {}
Stage.__index = Stage

function Stage.new()
    local self = setmetatable({}, Stage)

    self.width = 1900
    self.height = 830

    self.background = love.graphics.newImage("assets/maps/ancient_hall.png")

    -- 카논이 서 있을 바닥 Collider
    -- ancient_hall 이미지에 맞춰 y 값은 직접 조정 가능하게
    self.floor = {x = 0, y = 700, width = 1900, height = 130}

    self.debugCollider = false
    
    return self
end

-- 카논의 충돌 및 이동 제한 처리
function Stage:resolvePlayer(player)
    local floor = self.floor
    
    -- 떨어지는 중이고 발이 바닥보다 아래로 내려갔다면 바닥에 고정
    if player.y >= floor.y and player.velocityY >= 0 then
        player.y = floor.y
        player.velocityY = 0
        player.grounded = true
    else
        player.grounded = false
    end

    -- 맵 밖으로 나가지 않게 제한
    local halfWidth = player.colliderWidth / 2

    player.x = math.max(halfWidth, math.min(self.width - halfWidth, player.x))
end


-- 맵 배경 출력
function Stage:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.background, 0, 0)
end

-- 디버그용 충돌 영역 그리기
function Stage:drawDebug()
    if not self.debugCollider then
        return
    end

    -- 초록색에 투명도 35%
    love.graphics.setColor(0, 1, 0, 0.35)
    love.graphics.rectangle("fill", self.floor.x, self.floor.y, self.floor.width, self.floor.height)
    love.graphics.setColor(1, 1, 1, 1)
end

return Stage