-- 카논과 고대의 마법사가 있을 맵
local Stage = require("src.stage")
-- 카논 스크립트
local Canon = require("src.canon")
-- 카논의 페블 샷
local Projectile = require("src.projectile")
-- 카메라 구현
local Camera = require("src.camera")
-- 고대의 마법사 쿠로
local BossKuro = require("src.bossKuro")
-- 데미지 출력
local DamageText = require("src.damageText")

-- 실제 World의 크기
local WORLD_WIDTH = 1900
local WORLD_HEIGHT = 830

-- 카메라가 한 번에 보여주는 시야 크기
local VIEW_WIDTH = 1280
local VIEW_HEIGHT = 720

local canvas

local stage
local canon
local kuro
local camera

-- 객체 배열
local projectiles = {}
local damageTexts = {}

local font
local bgm

-- AABB 사각형 충돌 검사 함수
-- 두 개의 사각형 영역(a와 b)이 서로 겹쳐 있는지 여부
local function overlap(a, b)
    if not a or not b then
        return false
    end

    return
        a.x < b.x + b.w and
        a.x + a.w > b.x and
        a.y < b.y + b.h and
        a.y + a.h > b.y
end

-- BGM 파일 찾기
local function loadBGM()
    local path = "assets/sounds/ancientHall.mp3"

    if love.filesystem.getInfo(path) then
        local source = love.audio.newSource(path, "stream")

        source:setLooping(true)
        source:setVolume(0.4)

        return source
    end

    print("BGM 파일을 찾지 못했습니다: " .. path)
    return nil
end

-- UI
local function drawBar(label, x, y, width, height, value, maxValue, r, g, b)
    local ratio = math.max(0, math.min(1, value / maxValue))

    -- 배경
    love.graphics.setColor(0.08, 0.08, 0.10, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)

    -- 현재 수치
    love.graphics.setColor(r, g, b, 1)
    love.graphics.rectangle("fill", x, y, width * ratio, height)

    -- 테두리
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", x, y, width, height)

    -- 라벨과 수치를 바 내부에 출력
    love.graphics.printf(
        string.format("%s  %d / %d", label, math.floor(value), maxValue),
        x + 4,
        y + 1,
        width - 8,
        "left"
    )
end

-- 고대의 마법사 쿠로 UI
local function drawBossBar()
    if not kuro then
        return
    end

    local width = 520
    local height = 22
    local x = (VIEW_WIDTH - width) / 2
    local y = 18

    local ratio = math.max(0, math.min(1, kuro.hp / kuro.maxHp))

    -- 이름
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("고대의 마법사 쿠로", x, y - 18, width, "center")

    -- 배경
    love.graphics.setColor(0.10, 0.05, 0.07, 0.92)
    love.graphics.rectangle("fill", x, y, width, height)

    -- HP: 짙은 빨간색 #C71A2E
    love.graphics.setColor(0.78, 0.10, 0.18, 1)
    love.graphics.rectangle("fill", x, y, width * ratio, height)

    -- 테두리
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", x, y, width, height)

    -- 수치
    love.graphics.printf(
        string.format("%d / %d (%.0f%%)", math.floor(kuro.hp), kuro.maxHp, ratio * 100),
        x,
        y + 2,
        width,
        "center"
    )
end

-- Love2D 엔진의 시작점
function love.load()
    -- 픽셀아트 필터 (Nearest Neighbor)
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- 랜덤 시드
    love.math.setRandomSeed(os.time())

    -- 카메라 뷰 크기의 Canvas
    canvas = love.graphics.newCanvas(VIEW_WIDTH, VIEW_HEIGHT)

    -- 맵과 카논 객체 생성
    stage = Stage.new()
    canon = Canon.new(300, stage.floor.y)

    -- 맵 우측 보스 배치
    kuro = BossKuro.new(1600, stage.floor.y)

    -- 카메라
    camera = Camera.new(VIEW_WIDTH, VIEW_HEIGHT)

    Projectile.load()

    -- 폰트
    font = love.graphics.newFont("assets/fonts/Galmuri14.ttf", 16)
    love.graphics.setFont(font)

    -- BGM
    bgm = loadBGM()

    if bgm then
        bgm:play()
    end
end

-- Update
function love.update(dt)
    -- Canon
    local pebbleData = canon:update(dt, stage)

    -- magic1 4프레임에서 반환된 데이터
    if pebbleData then
        Projectile.playCastSound()
        table.insert(projectiles, Projectile.newPebble(pebbleData))
    end

    -- 쿠로 행동
    kuro:update(dt)

    -- Projectile
    -- 뒤에서부터 삭제하면 table.remove가 안전
    for c = #projectiles, 1 , -1 do
        
        local projectile = projectiles[c]

        projectile:update(dt, stage)

        -- 쿠로와 충돌
        if projectile.state == "fly" and not kuro.dead then
            if overlap(projectile:getHitbox(), kuro:getHitbox()) then
                kuro:takeDamage(projectile.damage)

                -- 머리 위에 데미지 출력
                table.insert(damageTexts, DamageText.new(
                    kuro.x, kuro.y - kuro.colliderHeight - 25, projectile.damage, projectile.isCritical
                ))
                projectile:impact()
            end
        end

        -- 페블 샷이 충돌되어 삭제
        if projectile.dead then
            table.remove(projectiles, c)
        end
    end

    -- 데미지 출력
    for c = #damageTexts, 1, -1 do
        local damageText = damageTexts[c]
        damageText:update(dt)

        if damageText.dead then
            table.remove(damageTexts, c)
        end
    end

    -- 카논 카메라 처리
    camera:update(dt, canon, WORLD_WIDTH, WORLD_HEIGHT)
end

-- 키 입력
function love.keypressed(key)
    -- 점프
    if key == "space" or key == "up"
    then
        canon:jump()
    end

    -- 페블 샷
    if key == "a" then
        canon:startPebbleCast()
    end

    -- Collider Debug
    if key == "f1" then
        stage.debugCollider = not stage.debugCollider
    end

    -- 종료
    if key == "escape" then
        love.event.quit()
    end
end

-- World Rendering
local function drawWorld()
    -- Map
    stage:draw()
    -- Kuro
    kuro:draw()
    -- Canon
    canon:draw()

    -- 페블 샷
    for _, projectile in ipairs(projectiles) do
        projectile:draw()
    end

    -- 데미지 출력
    for _, damageText in ipairs(damageTexts) do
        damageText:draw()
    end

    -- Debug Collider
    if stage.debugCollider then
        stage:drawDebug()
        canon:drawDebug()
        kuro:drawDebug()
    end
end

-- UI
local function drawUI()
    drawBossBar()

    love.graphics.setColor(1, 1, 1, 1)

    local infoX = 20
    local infoY = VIEW_HEIGHT - 150

    love.graphics.print(string.format("기본 마력: %d", canon.magicPower), infoX, infoY)
    love.graphics.print(string.format("치명타 확률: %.0f%%", canon.critChance * 100), infoX, infoY + 18)
    love.graphics.print(string.format("치명타 피해: +%.0f%%", canon.critDamageBonus * 100), infoX, infoY + 36)

    drawBar(
        "카논 HP",
        20,
        VIEW_HEIGHT - 72,
        230,
        18,
        canon.hp,
        canon.maxHp,
        0.85, 0.18, 0.18
    )

    drawBar(
        "카논 MP",
        20,
        VIEW_HEIGHT - 42,
        230,
        18,
        canon.mp,
        canon.maxMp,
        0.20, 0.45, 1.0
    )

    love.graphics.print(
        string.format("A: 페블 샷  %.1fs", canon.pebble.cooldownTimer),
        VIEW_WIDTH - 220,
        VIEW_HEIGHT - 72
    )
    love.graphics.print("SPACE: 점프", VIEW_WIDTH - 220, VIEW_HEIGHT - 54)
    love.graphics.print("← →: 이동", VIEW_WIDTH - 220, VIEW_HEIGHT - 36)

    if stage.debugCollider then
        love.graphics.print("F1: Collider Debug ON", 20, VIEW_HEIGHT - 170)
    end
end

-- Draw
function love.draw()

    -- Virtual Resolution에 Draw
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)

    camera:beginDraw()
    drawWorld()
    camera:endDraw()

    -- UI는 카메라 영향 없이 따로 그림
    drawUI()

    love.graphics.setCanvas()

    -- 실제 Window 크기
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local scale = math.min(screenWidth / VIEW_WIDTH, screenHeight / VIEW_HEIGHT)

    local drawWidth = VIEW_WIDTH * scale
    local drawHeight = VIEW_HEIGHT * scale

    local offsetX = (screenWidth - drawWidth) / 2
    local offsetY = (screenHeight - drawHeight) / 2

    -- Letterbox Rendering
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, offsetX, offsetY, 0, scale, scale)
end