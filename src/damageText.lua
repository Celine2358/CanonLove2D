-- 데미지 출력 damageText.lua

local DamageText = {}
DamageText.__index = DamageText

function DamageText.new(x, y, damage, isCritical)
    local self = setmetatable({}, DamageText)

    self.x = x
    self.y = y

    -- 출력될 피해량
    self.damage = damage
    -- 크리티컬인지?
    self.isCritical = isCritical or false

    -- 지속 시간
    self.life = 0.8
    self.maxLife = 0.8

    -- 위로 올라가는 속도
    self.riseSpeed = 55

    self.dead = false

    return self
end

function DamageText:update(dt)
    -- Love2D에서 -Y는 위쪽!
    self.y = self.y - self.riseSpeed * dt

    -- 데미지 출력의 지속 시간을 dt 만큼 감소
    self.life = self.life - dt

    -- 데미지 출력이 끝났다면 삭제
    if self.life <= 0 then
        self.life = 0
        self.dead = true
    end
end

-- 데미지 출력
function DamageText:draw()
    -- 데미지 출력의 생존 시간만큼 투명도 조절
    local alpha = self.life / self.maxLife

    -- #FF6347
    love.graphics.setColor(1.0, 99/255, 71/255, alpha)

    local text

    if self.isCritical then
        text = string.format("크리티컬! %d", self.damage)
    else
        text = tostring(self.damage)
    end

    -- 숫자가 x 좌표 중심에 오도록 출력
    love.graphics.printf(text, self.x - 80, self.y, 160, "center")
    love.graphics.setColor(1, 1, 1, 1)
end

return DamageText