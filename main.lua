-- 카논과 고대의 마법사가 있을 맵
local Stage = require("src.stage")
-- 카논 스크립트
local Canon = require("src.canon")
-- 카논의 페블 샷
local Projectile = require("src.projectile")

-- World
local WORLD_WIDTH = 1900
local WORLD_HEIGHT = 830

local canvas

local stage
local canon
local projectiles = {}

local font
local bgm

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
    local ratio = value / maxValue

    -- 배경
    love.graphics.setColor(0.08, 0.08, 0.10, 0.9)

    love.graphics.rectangle("fill", x, y, width, height)

    -- 현재 수치
    love.graphics.setColor(r, g, b, 1)
    love.graphics.rectangle("fill", x, y, width * ratio, height)

    -- 테두리
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", x, y, width, height)
    
    love.graphics.print(
        string.format(
            "%s  %d / %d",
            label,
            math.floor(value),
            maxValue
        ),
        x,
        y - 34
    )
end

-- Love2D 엔진의 시작점
function love.load()
    -- 픽셀아트 필터 (Nearest Neighbor)
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- 가상의 해상도 캔버스 생성
    canvas = love.graphics.newCanvas(WORLD_WIDTH, WORLD_HEIGHT)

    -- 맵과 카논 객체 생성
    stage = Stage.new()
    canon = Canon.new(300, stage.floor.y)

    Projectile.load()

    -- 폰트
    font = love.graphics.newFont("assets/fonts/Galmuri14.ttf", 26)
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
        table.insert(projectiles, Projectile.newPebble(pebbleData))
    end

    -- Projectile
    -- 뒤에서부터 삭제하면 table.remove가 안전
    for c = #projectiles, 1 , -1 do
        
        local projectile = projectiles[c]

        projectile:update(dt)

        if projectile.dead then
            table.remove(projectiles, c)
        end
    end
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

    -- Canon
    canon:draw()

    -- 페블 샷
    for _, projectile
        in ipairs(projectiles)
    do
        projectile:draw()
    end

    -- Debug Collider
    if stage.debugCollider then
        stage:drawDebug()
        canon:drawDebug()
    end

    -- UI
    drawBar(
        "카논의 HP",
        50,
        70,
        360,
        24,
        canon.hp,
        canon.maxHp,
        0.85,
        0.18,
        0.18
    )

    drawBar(
        "카논의 MP",
        50,
        140,
        360,
        24,
        canon.mp,
        canon.maxMp,
        0.20,
        0.45,
        1.0
    )

    -- Skill
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("A : 페블 샷   %.1fs", canon.pebble.cooldownTimer), 50, 210)
    love.graphics.print("SPACE : 점프", 50, 250)
    love.graphics.print("← → : 이동", 50, 290)
    love.graphics.print("F1 : Dev: Collider Debug", 50, 330)
end

-- Draw
function love.draw()

    -- Virtual Resolution에 Draw
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)

    drawWorld()

    love.graphics.setCanvas()

    -- 실제 Window 크기
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local scale = math.min(screenWidth / WORLD_WIDTH, screenHeight / WORLD_HEIGHT)

    local drawWidth = WORLD_WIDTH * scale
    local drawHeight = WORLD_HEIGHT * scale

    local offsetX = (screenWidth - drawWidth) / 2
    local offsetY = (screenHeight - drawHeight) / 2

    -- Letterbox Rendering
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, offsetX, offsetY, 0, scale, scale)
end