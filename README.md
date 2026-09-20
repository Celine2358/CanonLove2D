# CanonLove2D

LÖVE2D와 Lua를 공부하기 위한 간단한 2D 액션 게임 프로젝트입니다.
Magic Celine의 알파 시절 Canon을 플레이어 캐릭터로 사용합니다.

## Development Environment

- LÖVE2D
- Lua
- Visual Studio Code
- Git
- GitHub Desktop

## Current Features

- Canon Stand Animation
- Canon Walk Animation
- Horizontal Movement
- Jump
- Gravity
- Ground Collision
- HP / MP
- MP Recovery
- Pebble Shot
- Pebble Shot Cooldown
- BGM
- Pixel Font
- Virtual Resolution

## Controls

| Key | Action |
| --- | --- |
| Left / Right | Move |
| Space / Up | Jump |
| A | Pebble Shot |
| F1 | Collider Debug |
| ESC | Exit |

## Pebble Shot

Pebble Shot is fired during the fourth frame of Canon's magic animation.

Current prototype parameters:

- Cooldown: 1 second
- MP Cost: 5
- Speed: 600
- Range: 700

These values can be modified in `src/canon.lua`.

## Project Structure

```text
assets/
src/
    animation.lua
    canon.lua
    projectile.lua
    stage.lua

main.lua
conf.lua