-- Pathfinder - Love2D
-- Tile-based puzzle: rotate mirrors to direct lasers into targets.
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local SoundManager = {}
SoundManager.__index = SoundManager

function SoundManager.new()
    local instance = setmetatable({
        sounds = {
            win = love.audio.newSource("assets/sounds/win.mp3", "static"),
            wrong = love.audio.newSource("assets/sounds/wrong.mp3", "static"),
        }
    }, SoundManager)

    instance:setVolume(instance.sounds.win, 1)
    instance:setVolume(instance.sounds.wrong, 1)

    --instance:play("background", true)

    return instance
end

function SoundManager:play(soundName, loop)
    if loop then self.sounds[soundName]:setLooping(true) end

    if not self.sounds[soundName] then return end

    self.sounds[soundName]:stop()
    self.sounds[soundName]:play()
end

function SoundManager:setVolume(sound, volume)
    sound:setVolume(volume)
end

return SoundManager
