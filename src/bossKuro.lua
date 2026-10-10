local Animation = require("src.animation")

-- 보스: 고대의 마법사 쿠로 객체 생성
local BossKuro = {}
BossKuro.__index = BossKuro

-- 쿠로를 생성하고 초기 상태 설정
function BossKuro.new(x, y)

    local self = setmetatable({}, BossKuro)

    -- 초기 소환 위치 설정
    self.x = x
    self.y = y

    -- 체력 및 생존 상태 관리 변수
    self.maxHp = 10000
    self.hp = 10000

    -- 쿠로의 상태
    -- alive: 살아 있음
    -- dying: 사망 애니메이션 재생 중
    -- dead: 사망
    self.state = "alive"
    self.dead = false

    -- 히트박스
    self.colliderWidth = 94
    self.colliderHeight = 230

    -- 원본의 1.2배
    self.spriteScale = 1.20

    -- 애니메이션 목록
    self.animations = {

        -- 기본 Stand KuroStand_1~4
        stand = Animation.new({
            folder = "assets/boss",
            prefix = "KuroStand",
            frameCount = 4,
            frameTime = 0.20,
            loop = true
        }),

        -- 사망 Die KuroDie_1~14
        die = Animation.new({
            folder = "assets/boss",
            prefix = "KuroDie",
            frameCount = 14,
            frameTime = 0.11,
            loop = false
        })
    }

    self.currentAnimationName = "stand"
    -- 기본 stand 애니메이션
    self.currentAnimation = self.animations.stand

    -- 사망 사운드
    local deathSoundPath = "assets/sounds/KuroDisappear.mp3"

    if love.filesystem.getInfo(deathSoundPath) then
        self.deathSound = love.audio.newSource(deathSoundPath, "static")
        self.deathSound:setVolume(0.8)
    else
        self.deathSound = nil
        print("쿠로 사망 사운드를 찾지 못했습니다: " .. deathSoundPath)
    end
    
    return self
end

-- Animation 변경
function BossKuro:setAnimation(name)

    if self.currentAnimationName == name then
        return
    end

    self.currentAnimationName = name
    self.currentAnimation = self.animations[name]

    self.currentAnimation:reset()
end

-- 매 프레임마다 갱신
function BossKuro:update(dt)
    -- 완전히 죽은 뒤에는 갱신하지 않음
    if self.state == "dead" then
        return
    end

    self.currentAnimation:update(dt)

    -- 사망 애니메이션 종료 체크
    if
        self.state == "dying"
        and self.currentAnimation.finished
    then

        self.state = "dead"
        self.dead = true
    end
end

-- 쿠로가 데미지를 입고, 체력이 0 이하가 되면 사망 상태
function BossKuro:takeDamage(amount)

    -- 죽는 중이거나 이미 죽었으면 추가 피해 무시
    if self.state ~= "alive" then
        return
    end

    -- 체력 감소
    self.hp = math.max(0, self.hp - amount)

    -- 사망 처리
    if self.hp <= 0 then
        self:startDeath()
    end
end

-- 사망 시작
function BossKuro:startDeath()

    -- 중복 실행 방지
    if self.state ~= "alive" then
        return
    end

    self.state = "dying"

    -- 사망 애니메이션 시작
    self:setAnimation("die")


    -- 사망 사운드 1회 재생
    if self.deathSound then
        self.deathSound:stop()
        self.deathSound:play()
    end
end

-- 외부 영역 충돌 검사용 히트박스
function BossKuro:getHitbox()

    -- 사망 중에는 공격 판정을 받지 않음
    if self.state ~= "alive" then
        return nil
    end

    return {
        x = self.x - self.colliderWidth / 2, -- 중심점 기준 좌상단 X 좌표
        y = self.y - self.colliderHeight, -- 발밑 기준 좌상단 Y 좌표
        w = self.colliderWidth, -- 가로폭
        h = self.colliderHeight -- 세로폭
    }
end

-- 렌더링
function BossKuro:draw()
    -- 사망 애니메이션까지 끝났다면 출력 X
    if self.state == "dead" then
        return
    end

    local image = self.currentAnimation:getImage()

    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.draw(
        image,
        self.x,
        self.y,
        0,
        self.spriteScale,
        self.spriteScale,
        image:getWidth() / 2,
        image:getHeight()
    )
end

-- 히트박스 디버그
function BossKuro:drawDebug()

    -- 살아 있을 때만 히트박스 표시
    if self.state ~= "alive" then
        return
    end

    -- 자주색 투명도 35%
    love.graphics.setColor(1, 0, 1, 0.35)

    -- 꽉 찬 히트박스 사각형
    love.graphics.rectangle(
        "fill",
        self.x - self.colliderWidth / 2,
        self.y - self.colliderHeight,
        self.colliderWidth,
        self.colliderHeight
    )

    love.graphics.setColor(1, 1, 1, 1)
end

return BossKuro