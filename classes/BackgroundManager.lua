-- Hangman Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_pi = math.pi
local math_sin = math.sin
local math_cos = math.cos
local math_random = math.random
local table_insert = table.insert

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

function BackgroundManager.new()
    local instance = setmetatable({}, BackgroundManager)
    instance.menuParticles = {}
    instance.gameParticles = {}
    instance.time = 0
    instance:initMenuParticles()
    instance:initGameParticles()
    return instance
end

function BackgroundManager:initMenuParticles()
    self.menuParticles = {}
    for _ = 1, 40 do
        table_insert(self.menuParticles, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(2, 6),
            speed = math_random(20, 60),
            angle = math_random() * math_pi * 2,
            pulseSpeed = math_random(0.3, 1.5),
            pulsePhase = math_random() * math_pi * 2,
            char = string.char(math_random(65, 90)) -- Random letters
        })
    end
end

function BackgroundManager:initGameParticles()
    self.gameParticles = {}
    for _ = 1, 25 do
        table_insert(self.gameParticles, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(1, 4),
            speed = math_random(10, 40),
            angle = math_random() * math_pi * 2,
            char = string.char(math_random(65, 90)),
            isGhost = math_random() > 0.7
        })
    end
end

function BackgroundManager:update(dt)
    self.time = self.time + dt

    -- Update menu particles
    for _, particle in ipairs(self.menuParticles) do
        particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
        particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt

        if particle.x < -50 then particle.x = 1000 + 50 end
        if particle.x > 1000 + 50 then particle.x = -50 end
        if particle.y < -50 then particle.y = 1000 + 50 end
        if particle.y > 1000 + 50 then particle.y = -50 end
    end

    -- Update game particles
    for _, particle in ipairs(self.gameParticles) do
        particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
        particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt

        if particle.x < -50 then particle.x = 1000 + 50 end
        if particle.x > 1000 + 50 then particle.x = -50 end
        if particle.y < -50 then particle.y = 1000 + 50 end
        if particle.y > 1000 + 50 then particle.y = -50 end
    end
end

function BackgroundManager:drawMenuBackground(screenWidth, screenHeight)
    local time = love.timer.getTime()

    -- Gradient background
    for y = 0, screenHeight, 3 do
        local progress = y / screenHeight
        local pulse = (math_sin(time * 1.5 + progress * 3) + 1) * 0.08

        local r = 0.05 + progress * 0.2 + pulse
        local g = 0.1 + progress * 0.1 + pulse
        local b = 0.2 + progress * 0.3 + pulse

        love.graphics.setColor(r, g, b, 0.7)
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Floating letters
    love.graphics.setColor(0.6, 0.8, 1, 0.5)
    for _, particle in ipairs(self.menuParticles) do
        local pulse = (math_sin(particle.pulsePhase + time * particle.pulseSpeed) + 1) * 0.5
        local currentSize = particle.size * (0.8 + pulse * 0.2)
        love.graphics.print(particle.char, particle.x, particle.y, 0, currentSize/20)
    end

    -- Hangman silhouette in background
    love.graphics.setColor(0.3, 0.4, 0.6, 0.15)
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2 - 50
    local scale = 2 + math_sin(time) * 0.3

    -- Gallows
    love.graphics.setLineWidth(3)
    love.graphics.line(centerX - 100, centerY + 150, centerX + 100, centerY + 150)
    love.graphics.line(centerX, centerY + 150, centerX, centerY - 100)
    love.graphics.line(centerX, centerY - 100, centerX + 80, centerY - 100)
    love.graphics.line(centerX + 80, centerY - 100, centerX + 80, centerY - 80)

    -- Head
    love.graphics.circle("line", centerX + 80, centerY - 60, 20)
    love.graphics.setLineWidth(1)
end

function BackgroundManager:drawGameBackground(screenWidth, screenHeight)
    local time = love.timer.getTime()

    -- Dark, moody gradient
    for y = 0, screenHeight, 2 do
        local progress = y / screenHeight
        local wave = math_sin(progress * 10 + time * 0.5) * 0.05
        local r = 0.02 + wave
        local g = 0.05 + progress * 0.05 + wave
        local b = 0.1 + progress * 0.1 + wave

        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Ghost letters floating around
    for _, particle in ipairs(self.gameParticles) do
        if particle.isGhost then
            love.graphics.setColor(0.3, 0.5, 0.8, 0.2)
        else
            love.graphics.setColor(0.5, 0.7, 1, 0.3)
        end
        love.graphics.print(particle.char, particle.x, particle.y, 0, particle.size/15)
    end

    -- Subtle noose pattern in background
    love.graphics.setColor(0.1, 0.2, 0.3, 0.1)
    local gridSize = 60
    for x = 0, screenWidth, gridSize do
        for y = 0, screenHeight, gridSize do
            love.graphics.circle("line", x, y, 8)
            love.graphics.line(x - 5, y - 5, x + 5, y + 5)
            love.graphics.line(x + 5, y - 5, x - 5, y + 5)
        end
    end
end

return BackgroundManager