function love.conf(t)
    t.identity = "CanonLove2D"

    -- Windows에서 print() 로그 확인용
    t.console = true

    t.window.title = "CanonLove2D - LÖVE Prototype"

    t.window.width = 1200
    t.window.height = 720

    t.window.minwidth = 960
    t.window.minheight = 540

    t.window.resizable = true
    t.window.vsync = 1

end