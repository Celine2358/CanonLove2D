local Animation = {}
Animation.__index = Animation

function Animation.new(config)
    local self = setmetatable({}, Animation)

    self.frames = {}

    -- canon_stand_1.png ~ canon_stand_12.png 형태로 로드
    for c = 1, config.frameCount do
        local path = string.format("%s/%s_%d.png", config.folder, config.prefix, c)

        self.frames[c] = love.graphics.newImage(path)
    end

    self.frameTime = config.frameTime or 0.1

    -- ~=는 !=와 같다
    self.loop = config.loop ~= false

    self.currentFrame = 1
    self.timer = 0
    self.finished = false
    return self
end

-- Love2D 게임에서 시간의 흐름 (dt)에 따라 애니메이션의 다음 장면(프레임)을 계산하는 함수
function Animation:update(dt)
    -- 예외 처리 (애니메이션 재생이 끝난 경우)
    if self.finished then
        return
    end

    -- 1프레임 애니메이션은 갱신 불필요
    -- #self.frames는 애니메이션에 포함된 총 프레임 개수
    if #self.frames <= 1 then
        return
    end

    -- 타이머 누적
    self.timer = self.timer + dt

    -- 프레임 전환 판단
    -- if 대신 while을 사용한 이유: 컴퓨터가 순간적으로 버벅여서 dt가 매우 크게 들어왔을 때
    -- 지나간 여러 프레임을 한 번에 건너뛰기 위해
        while self.timer >= self.frameTime do
        self.timer = self.timer - self.frameTime
        self.currentFrame = self.currentFrame + 1

        if self.currentFrame > #self.frames then
            if self.loop then
                self.currentFrame = 1
            else
                self.currentFrame = #self.frames
                self.finished = true
                break
            end
        end
    end
end

-- 현재 프레임의 이미지 반환
function Animation:getImage()
    return self.frames[self.currentFrame]
end

-- 애니메이션 초기화
function Animation:reset()
    self.currentFrame = 1
    self.timer = 0
    self.finished = false
end

return Animation