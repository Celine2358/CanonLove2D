-- 페블 샷 발사체
local Projectile = {}
Projectile.__index = Projectile

local pebbleImage = nil
local pebbleHitFrames = {}
local pebbleCastSound = nil

-- 게임이 처음 켜질 때 딱 한 번만 실행되는 정적 로드 함수
function Projectile.load()
    pebbleImage = love.graphics.newImage("assets/skills/pebble.png")

    -- 페블 샷 적중 애니메이션 프레임
    for c = 1, 3 do
        pebbleHitFrames[c] = love.graphics.newImage("assets/skills/pebble_hit_" .. c .. ".png")
    end

    if love.filesystem.getInfo("assets/sounds/pebbleShot_cast.mp3") then
        pebbleCastSound = love.audio.newSource("assets/sounds/pebbleShot_cast.mp3", "static")

        -- 음량 75%
        pebbleCastSound:setVolume(0.75)
    end
end

-- 페블 샷 시전 사운드
function Projectile.playCastSound()
    if pebbleCastSound then
        local sfx = pebbleCastSound:clone()
        sfx:play()
    end
end

-- 카논이 마법 시전 프레임에서 반환했던 projectileData 테이블을 여기서 넘겨받아
-- 페블 샷 인스턴스를 생성한다
function Projectile.newPebble(data)
    local self = setmetatable({}, Projectile)

    self.state = "fly"

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

    -- 크리티컬 처리
    self.isCritical = data.isCritical or false

    self.scale = 1.0
    self.width = 18
    self.height = 18

    self.hitFrame = 1
    self.hitTimer = 0
    self.hitFrameTime = 0.11

    -- 투사체가 살아있는지?
    self.dead = false

    return self
end

-- 페블 샷 히트박스 반환 함수
function Projectile:getHitbox()

    -- 페블 샷이 날아가는 중이지 않으면 nil 반환
    if self.state ~= "fly" then
        return nil
    end

    return {
        x = self.x - self.width / 2,
        y = self.y - self.height / 2,
        w = self.width,
        h = self.height
    }
end

-- 페블 샷이 어딘가에 충돌됐다면?
function Projectile:impact()

    -- 페블 샷이 날아가는 중이지 않으면 nil 반환
    if self.state ~= "fly" then
        return
    end

    -- 상태를 hit으로 변경하고, 타격 애니메이션 재생을 위한 타이머 및 프레임 초기화
    self.state = "hit"
    self.hitFrame = 1
    self.hitTimer = 0
end

-- 매 프레임마다 페블 샷의 이동, 사거리 체크, 충돌, 타격 이펙트 처리
function Projectile:update(dt, stage)

    -- 페블 샷이 날아가는 중이라면?
    if self.state == "fly" then
        -- 방향(-1 또는 1)과 속도, dt를 계산
        self.x = self.x + self.direction * self.speed * dt

        -- 처음 발사 지점에서 이동한 거리
        local distance = math.abs(self.x - self.startX)

        -- 사거리 초과
        if distance >= self.range then
            self:impact()
            return
        end

        -- 맵의 좌우 벽 / 바닥 충돌
        if self.x <= 0 or self.x >= stage.width or self.y >= stage.floor.y then
            self:impact()
            return
        end

    -- 페블 샷이 무언가에 부딫혀 충돌 이펙트가 재생 중인 경우
    else
        -- 경과 시간 충돌 타이머에 누적
        self.hitTimer = self.hitTimer + dt

        -- 프레임 스킵 방지
        while self.hitTimer >= self.hitFrameTime do
            self.hitTimer = self.hitTimer - self.hitFrameTime
            self.hitFrame = self.hitFrame + 1

            -- 애니메이션 종료 체크
            if self.hitFrame > #pebbleHitFrames then
                -- 객체 삭제 상태로 변경
                self.dead = true
                break
            end
        end
    end
end

-- 화면 출력
function Projectile:draw()

    love.graphics.setColor(1, 1, 1, 1)

    if self.state == "fly" then
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
    else
        local image = pebbleHitFrames[self.hitFrame]

        if not image then
            return
        end

        love.graphics.draw(
            image,
            self.x,
            self.y,
            0,
            1,
            1,
            image:getWidth() / 2,
            image:getHeight() / 2
        )
    end
end

return Projectile