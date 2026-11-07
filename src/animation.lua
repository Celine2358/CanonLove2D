local Animation = {}
Animation.__index = Animation

function Animation.new(config)
    local self = setmetatable({}, Animation)

    -- 기존 이미지 프레임 재사용 또는 새로 로드
    if config.frames then
        self.frames = config.frames
    else
        self.frames = {}

        for i = 1, config.frameCount do
            local path = string.format(
                "%s/%s_%d.png",
                config.folder,
                config.prefix,
                i
            )

            self.frames[i] = love.graphics.newImage(path)
        end
    end

    self.frameTime = config.frameTime or 0.1
    self.loop = config.loop ~= false

    -- 정방향 +1, 역방향 -1
    -- reverse false는 1 -> 2 -> ...
    -- reverse true는 13 -> 12 -> ...
    self.direction = config.reverse and -1 or 1

    self.timer = 0
    self.finished = false

    -- 역재생이면 마지막 프레임에서 시작
    self.currentFrame = self.direction == 1 and 1 or #self.frames

    return self
end

-- 프레임 재생
function Animation:update(dt)
    if self.finished or #self.frames <= 1 then
        return
    end

    self.timer = self.timer + dt

    while self.timer >= self.frameTime do
        self.timer = self.timer - self.frameTime

        -- direction에 따라 증가 또는 감소
        self.currentFrame = self.currentFrame + self.direction

        local outOfRange =
            self.currentFrame < 1
            or self.currentFrame > #self.frames

        if outOfRange then
            if self.loop then
                self.currentFrame =
                    self.direction == 1
                    and 1 or #self.frames
            else
                self.currentFrame = math.max(1, math.min(#self.frames, self.currentFrame))
                self.finished = true
                break
            end
        end
    end
end

-- 현재 이미지 반환
function Animation:getImage()
    return self.frames[self.currentFrame]
end

-- 처음부터 재생
function Animation:reset()
    self.currentFrame =
        self.direction == 1 and 1 or #self.frames

    self.timer = 0
    self.finished = false
end

return Animation