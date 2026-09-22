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
    self.dead = false

    -- 히트박스
    self.colliderWidth = 94
    self.colliderHeight = 230

    -- 원본의 1.2배
    self.spriteScale = 1.20

    -- 애니메이션 목록 KuroStand_1~4
    self.animations = {
        stand = Animation.new({
            folder = "assets/boss",
            prefix = "KuroStand",
            frameCount = 4,
            frameTime = 0.20,
            loop = true
        })
    }

    -- 기본 stand 애니메이션
    self.currentAnimation = self.animations.stand
    
    return self
end

-- 매 프레임마다 갱신
function BossKuro:update(dt)
    self.currentAnimation:update(dt)
end

-- 쿠로가 데미지를 입고, 체력이 0 이하가 되면 사망 상태
function BossKuro:takeDamage(amount)
    if self.dead then
        return
    end

    -- 체력 감소
    self.hp = math.max(0, self.hp - amount)

    -- 사망 처리
    if self.hp <= 0 then
        self.dead = true
    end
end

-- 외부 영역 충돌 검사용 히트박스
function BossKuro:getHitbox()
    return {
        x = self.x - self.colliderWidth / 2, -- 중심점 기준 좌상단 X 좌표
        y = self.y - self.colliderHeight, -- 발밑 기준 좌상단 Y 좌표
        w = self.colliderWidth, -- 가로폭
        h = self.colliderHeight -- 세로폭
    }
end

-- 렌더링
function BossKuro:draw()
    if self.dead then
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