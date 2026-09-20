-- 페블 샷 발사체
local Projectile = {}
Projectile.__index = Projectile

local pebbleImage = nil

-- 게임이 처음 켜질 때 딱 한 번만 실행되는 정적 로드 함수
function Projectile.load()
    pebbleImage = love.graphics.newImage("assets/skills/pebble.png")
end

-- 카논이 마법 시전 프레임에서 반환했던 projectileData 테이블을 여기서 넘겨받아
-- 페블 샷 인스턴스를 생성한다
function Projectile.newPebble(data)
    local self = setmetatable({}, Projectile)

    self.image = pebbleImage

    -- 페블 샷이 날아가기 시작할 현재 위치
    -- 맨 처음 발사된 X 좌표를 따로 기억해둔다
    self.x = data.x
    self.y = data.y
    self.startX = data.x

    -- 날아갈 방향(-1 or 1), 속도, 최대 사거리, 공격력을 불러온다
    self.direction = data.direction
    self.speed = data.speed
    self.range = data.range
    self.damage = data.damage

    -- 투사체가 살아있는지?
    self.dead = false
    self.scale = 1.0

    return self
end

-- 페블 샷 이동 및 사거리 제한 처리
function Projectile:update(dt)

    self.x = self.x + self.direction * self.speed * dt

    -- 처음 발사 지점에서 이동한 거리
    local distance = math.abs(self.x - self.startX)

    -- 지정 사거리 초과
    if distance >= self.range then
        self.dead = true
    end
end

-- 화면 출력
function Projectile:draw()

    love.graphics.setColor(1, 1, 1, 1)

    local scaleX = self.scale * -self.direction
    
    love.graphics.draw(
        self.image,
        self.x,
        self.y,
        0,
        scaleX,
        self.scale,
        self.image:getWidth() / 2,
        self.image:getHeight() / 2
    )
end

return Projectile