local Animation = require("src.animation")

-- 카논 객체 생성
local Canon = {}
Canon.__index = Canon

function Canon.new(startX, startY)
    local self = setmetatable({}, Canon)

    -- Transform
    -- x = 중심 위치, y = 발바닥 위치
    self.x = startX
    self.y = startY

    self.velocityY = 0

    -- 1 = 오른쪽, -1 = 왼쪽
    self.facing = 1

    -- Movement
    self.moveSpeed = 320

    -- Unity의 Gravity 느낌
    self.gravity = 1500

    -- 위 방향이 음수이므로 점프는 -값
    self.jumpForce = 650
    self.grounded = true

    -- Collider
    self.colliderWidth = 60
    self.colliderHeight = 125

    -- Stats
    self.maxHp = 100
    self.hp = 100
    self.maxMp = 100
    self.mp = 100
    self.mpRegen = 5

    -- 땅의 마법: Pebble Shot 세팅
    self.pebble = {
        manaCost = 5,

        cooldown = 1.0,
        cooldownTimer = 0,

        -- 발사속도 변경값
        speed = 600,
        -- 사거리 변경값
        range = 700,

        -- 피해량 변경값
        damage = 10,

        -- canon_magic1_4.png에서 발사
        spawnFrame = 4
    }

    -- Animation(카논 애니메이션)
    self.animations = {

        -- 카논 정지
        stand = Animation.new({
            folder = "assets/canon",
            prefix = "canon_stand",
            frameCount = 12,
            frameTime = 0.12,
            loop = true
        }),

        -- 카논 걷기
        walk = Animation.new({
            folder = "assets/canon",
            prefix = "canon_walk",
            frameCount = 7,
            frameTime = 0.09,
            loop = true
        }),

        -- 카논 점프
        jump = Animation.new({
            folder = "assets/canon",
            prefix = "canon_jump",
            frameCount = 1,
            frameTime = 0.1,
            loop = false
        }),

        -- 카논 마법 시전
        magic = Animation.new({
            folder = "assets/canon",
            prefix = "canon_magic1",
            frameCount = 5,
            frameTime = 0.09,
            loop = false
        })
    }

    self.currentAnimationName = "stand"
    self.currentAnimation = self.animations.stand

    -- Attack State
    self.casting = false

    -- 같은 공격에서 Pebble이 여러 번 생성되는 것 방지
    self.pebbleSpawned = false

    -- Rendering, 원본은 268x268 사이즈
    self.spriteScale = 0.7

    return self
end

-- Animation 변경 함수
function Canon:setAnimation(name)
    -- 현재 재생 중인 애니메이션 이름이 새로 바꾸려는 애니메이션 이름과 같다면 즉시 종료
    if self.currentAnimationName == name then
        return
    end

    self.currentAnimationName = name
    self.currentAnimation = self.animations[name]

    self.currentAnimation:reset()
end

-- 카논 점프 함수
function Canon:jump()
    -- 땅에 착지하지 않은 상태 혹은 마법 시전 중이라면 종료
    if not self.grounded then
        return
    end

    if self.casting then
        return
    end

    -- Love2D에선 화면 아래쪽이 +Y, 위쪽이 -Y
    -- jumpForce만큼 위로 점프하도록 velocityY를 음수 값으로 변경
    self.velocityY = -self.jumpForce
    self.grounded = false
end

-- Pebble Shot 시작
function Canon:startPebbleCast()

    -- 다른 마법을 시전 중이면 종료
    if self.casting then
        return false
    end

    -- 쿨타임 중이라면 종료
    if self.pebble.cooldownTimer > 0 then
        return false
    end

    -- 마나가 충분하지 않다면 종료
    if self.mp < self.pebble.manaCost then
        return false
    end

    -- 마나 모소 및 쿨타임 적용
    self.mp = self.mp - self.pebble.manaCost
    self.pebble.cooldownTimer = self.pebble.cooldown

    self.casting = true
    self.pebbleSpawned = false

    self:setAnimation("magic")

    return true
end

-- Update
function Canon:update(dt, stage)

    -- Cooldown / MP
    self.pebble.cooldownTimer = math.max(0, self.pebble.cooldownTimer - dt)
    self.mp = math.min(self.maxMp, self.mp + self.mpRegen * dt)


    -- 수평 이동 Movement
    -- 왼쪽으로는 -1, 오른쪽으로는 +1
    local moveDirection = 0

    -- 마법 시전 중에는 이동 잠금
    if not self.casting then

        -- 왼쪽 화살표 키: 왼쪽 이동
        if love.keyboard.isDown("left") then
            moveDirection = moveDirection - 1
        end

        -- 오른쪽 화살표 키: 오른쪽 이동
        if love.keyboard.isDown("right") then
            moveDirection = moveDirection + 1
        end

        -- 이동 및 바라보는 방향 갱신
        if moveDirection ~= 0 then
            self.facing = moveDirection

            -- 카논의 X 좌표에 방향 x 이동 속도 x dt를 곱한다
            self.x = self.x + moveDirection * self.moveSpeed * dt
        end
    end


    -- Gravity
    if not self.grounded then
        -- 카논이 땅에 딛고 있지 않을 때 중력 적용(추락 속도가 점점 가속)
        self.velocityY = self.velocityY + self.gravity * dt
    end

    -- 현재 위치 + (속도 x 시간)의 원리
    self.y = self.y + self.velocityY * dt

    -- 땅(발판) 충돌
    stage:resolvePlayer(self)

    -- 애니메이션 상태
    if self.casting then
        self:setAnimation("magic")

    elseif not self.grounded then
        self:setAnimation("jump")

    elseif moveDirection ~= 0 then
        self:setAnimation("walk")

    else
        self:setAnimation("stand")
    end

    -- 애니메이션 최신화
    self.currentAnimation:update(dt)

    -- Magic1 Frame 4에서 Pebble 생성
    local projectileData = nil

    if self.casting then

        if
            not self.pebbleSpawned
            and self.currentAnimation.currentFrame >= self.pebble.spawnFrame
        then
            self.pebbleSpawned = true

            projectileData = {
                x = self.x + self.facing * 70,
                y = self.y - 105,
                direction = self.facing,
                speed = self.pebble.speed,
                range = self.pebble.range,
                damage = self.pebble.damage
            }
        end

        -- Magic 애니메이션 종료
        if self.currentAnimation.finished then
            self.casting = false
        end
    end

    return projectileData
end

-- Canon Draw
function Canon:draw()
    -- 현재 출력할 이미지 가져오기
    local image = self.currentAnimation:getImage()

    -- 가로 크기 및 좌우 반전 계산
    -- 기본 크기 배율에 바라보는 방향을 곱한다. (오른쪽은 1, 왼쪽은 -1)
    local scaleX = self.spriteScale * -self.facing

    love.graphics.setColor(1, 1, 1, 1)

    -- x = 캐릭터 중심
    -- y = 발 위치
    -- 캐릭터가 제자리에서 좌우 반전되도록 원점(바닥 중앙) 변경 후 그리기
    love.graphics.draw(image, self.x, self.y, 0, scaleX, self.spriteScale, image:getWidth() / 2, image:getHeight())
end

-- Collider 디버그
function Canon:drawDebug()

    -- 빨간색에 투명도 40%
    love.graphics.setColor(1, 0, 0, 0.4)

    -- 꽉 찬 사각형으로 히트박스 만들기
    love.graphics.rectangle(
        "fill", 
        self.x - self.colliderWidth / 2, 
        self.y - self.colliderHeight, 
        self.colliderWidth, 
        self.colliderHeight
    )
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- 어디서든 카논 객체를 불러오게 반환
return Canon