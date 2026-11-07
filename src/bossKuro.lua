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

    -- 현재 행동 상태
    self.action = "stand"

    -- 텔레포트 설정
    self.teleportInterval = 20.0 -- 재사용 대기시간
    self.teleportTimer = 5.0 -- 최초 시전은 5초 후

    -- 맵 양끝에서 떨어질 거리
    self.teleportMargin = 180

    -- 현재 위치에서 최소 이동 거리
    self.teleportMinDistance = 280

    -- 카논과 최소한으로 떨어질 거리
    self.teleportPlayerGap = 180

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
        }),

        -- 텔레포트 시전: 1 -> 13
        teleportOut = Animation.new({
            folder = "assets/boss",
            prefix = "KuroTP",
            frameCount = 13,
            frameTime = 0.13,
            loop = false
        })
    }

    -- 텔레포트 등장: 13 -> 1
    -- 같은 이미지 리소스를 역순으로 재생
    self.animations.teleportIn = Animation.new({
        frames = self.animations.teleportOut.frames,
        frameTime = 0.13,
        loop = false,
        reverse = true
    })

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

    -- 텔레포트 효과음
    local tpSoundPath = "assets/sounds/KuroTP.mp3"

    if love.filesystem.getInfo(tpSoundPath) then
        self.teleportSound = love.audio.newSource(tpSoundPath, "static"
    )
    
    self.teleportSound:setVolume(0.5)
else
    self.teleportSound = nil
    print("텔레포트 사운드 없음: " .. tpSoundPath)
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


-- 텔레포트 목적지 X 좌표 계산
function BossKuro:chooseTeleportX(stage, canon)

    -- 맵 끝에서 여백 확보
    local minX = self.teleportMargin
    local maxX = stage.width - self.teleportMargin

    if maxX <= minX then
        return self.x
    end

    -- 최대 30번 새 위치를 뽑아본다
    for i = 1, 30 do
        local candidate = love.math.random(minX, maxX)

        -- 현재 위치에서 충분히 멀어야 한다
        local farFromOld =
            math.abs(candidate - self.x)
            >= self.teleportMinDistance

        -- 카논 바로 위로 등장하지 않게 한다
        local farFromCanon =
            not canon or
            math.abs(candidate - canon.x)
            >= self.teleportPlayerGap

        if farFromOld and farFromCanon then
            return candidate
        end
    end

    -- 조건을 만족하는 좌표를 못 찾으면 이동하지 않음
    return self.x
end


-- 매 프레임마다 갱신
function BossKuro:update(dt, stage, canon)

    -- 완전히 사망했다면 갱신하지 않음
    if self.state == "dead" then
        return
    end

    -- 현재 애니메이션 갱신
    self.currentAnimation:update(dt)

    -- 사망 애니메이션 처리
    if self.state == "dying" then
        if self.currentAnimation.finished then
            self.state = "dead"
            self.dead = true
        end

        return
    end

    -- 텔레포트 시전: 1 -> 13
    if self.action == "teleportOut" then

        -- 소멸 애니메이션 종료 시 이동
        if self.currentAnimation.finished then

            self.x = self:chooseTeleportX(stage, canon)

            -- 역재생 등장 애니메이션
            self.action = "teleportIn"
            self:setAnimation("teleportIn")
        end

        return
    end

    -- 텔레포트 등장: 13 -> 1
    if self.action == "teleportIn" then

        -- 역재생 종료 시 Stand 복귀
        if self.currentAnimation.finished then

            self.action = "stand"
            self:setAnimation("stand")

            -- 다음 텔레포트 대기
            self.teleportTimer = self.teleportInterval
        end

        return
    end

    -- Stand 상태에서 텔레포트 타이머
    self.teleportTimer = math.max(0, self.teleportTimer - dt)

    -- 쿨타임이 끝났다면 텔레포트 시작
    if self.teleportTimer <= 0 then
        self:startTeleport()
    end
end


-- 쿠로가 데미지를 입고, 체력이 0 이하가 되면 사망 상태
function BossKuro:takeDamage(amount)

    -- 죽는 중이거나 이미 죽었으면 추가 피해 무시
    -- 살아 있고 Stand 상태일 때만 피해 적용
    if self.state ~= "alive" or self.action ~= "stand" then
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
    self.action = "stand"
    
    -- 진행 중인 텔레포트 효과음 중단
    if self.teleportSound then
        self.teleportSound:stop()
    end

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
    -- 텔레포트 중에는 충돌 영역 없음
    if self.state ~= "alive" or self.action ~= "stand"
    then
        return nil
    end

    return {
        x = self.x - self.colliderWidth / 2, -- 중심점 기준 좌상단 X 좌표
        y = self.y - self.colliderHeight, -- 발밑 기준 좌상단 Y 좌표
        w = self.colliderWidth, -- 가로폭
        h = self.colliderHeight -- 세로폭
    }
end

-- 텔레포트 시작
function BossKuro:startTeleport()

    -- 살아 있지 않다면 사용 불가
    if self.state ~= "alive" then
        return false
    end

    -- 다른 행동 중이면 사용 불가
    if self.action ~= "stand" then
        return false
    end

    -- 텔레포트 시전 상태 진입
    self.action = "teleportOut"

    -- KuroTP_1부터 애니메이션 시작
    self:setAnimation("teleportOut")

    -- 텔레포트 사운드 1회 재생
    if self.teleportSound then
        self.teleportSound:stop()
        self.teleportSound:play()
    end

    return true
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
    -- 피격 가능한 상태일 때만 디버그 히트박스 출력
    if not self:getHitbox() then
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