-- Hangman Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_pi = math.pi
local math_sin = math.sin
local math_cos = math.cos
local string_char = string.char
local math_random = math.random
local table_insert = table.insert
local lg = love.graphics

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

local function initMenuParticles(self)
    self.menuParticles = {}
    for _ = 1, 60 do
        table_insert(self.menuParticles, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(2, 8),
            speed = math_random(15, 80),
            angle = math_random() * math_pi * 2,
            pulseSpeed = math_random(0.5, 2),
            pulsePhase = math_random() * math_pi * 2,
            char = string_char(math_random(65, 90)),
            color = {
                math_random(0.6, 0.9),
                math_random(0.7, 1.0),
                math_random(0.8, 1.0)
            }
        })
    end
end

local function initGameParticles(self)
    self.gameParticles = {}
    for _ = 1, 35 do
        table_insert(self.gameParticles, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(1, 5),
            speed = math_random(10, 50),
            angle = math_random() * math_pi * 2,
            char = string_char(math_random(65, 90)),
            isGhost = math_random() > 0.7,
            color = math_random() > 0.5 and
                { 0.3, 0.5, 0.8 } or
                { 0.5, 0.7, 1.0 }
        })
    end
end

function BackgroundManager.new()
    local instance = setmetatable({}, BackgroundManager)
    instance.menuParticles = {}
    instance.gameParticles = {}
    instance.time = 0
    instance.pulseValue = 0
    initMenuParticles(instance)
    initGameParticles(instance)
    return instance
end

function BackgroundManager:update(dt)
    self.time = self.time + dt
    self.pulseValue = math_sin(self.time * 2) * 0.5 + 0.5

    -- Update menu particles
    for _, particle in ipairs(self.menuParticles) do
        particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
        particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt

        if particle.x < -50 then particle.x = 1050 end
        if particle.x > 1050 then particle.x = -50 end
        if particle.y < -50 then particle.y = 1050 end
        if particle.y > 1050 then particle.y = -50 end
    end

    -- Update game particles
    for _, particle in ipairs(self.gameParticles) do
        particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
        particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt

        if particle.x < -50 then particle.x = 1050 end
        if particle.x > 1050 then particle.x = -50 end
        if particle.y < -50 then particle.y = 1050 end
        if particle.y > 1050 then particle.y = -50 end
    end
end

function BackgroundManager:drawMenuBackground(screenWidth, screenHeight, time)
    -- Gradient background with pulsing effect
    for y = 0, screenHeight, 2 do
        local progress = y / screenHeight
        local pulse = (math_sin(time * 2 + progress * 4) + 1) * 0.1
        local wave = math_sin(progress * 8 + time * 3) * 0.05

        local r = 0.08 + progress * 0.3 + pulse + wave
        local g = 0.15 + progress * 0.2 + pulse
        local b = 0.25 + progress * 0.4 + pulse

        lg.setColor(r, g, b, 0.8)
        lg.rectangle("fill", 0, y, screenWidth, 2)
    end

    -- Floating letters with visuals
    for _, particle in ipairs(self.menuParticles) do
        local pulse = (math_sin(particle.pulsePhase + time * particle.pulseSpeed) + 1) * 0.5
        local currentSize = particle.size * (0.7 + pulse * 0.3)
        local alpha = 0.3 + pulse * 0.4

        lg.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        lg.print(particle.char, particle.x, particle.y, 0, currentSize / 18)
    end

    -- Hangman silhouette in background
    lg.setColor(0.4, 0.6, 0.8, 0.2 + self.pulseValue * 0.1)
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2 - 50

    -- Gallows with better proportions
    lg.setLineWidth(4)
    lg.line(centerX - 120, centerY + 180, centerX + 120, centerY + 180)
    lg.line(centerX, centerY + 180, centerX, centerY - 120)
    lg.line(centerX, centerY - 120, centerX + 100, centerY - 120)
    lg.line(centerX + 100, centerY - 120, centerX + 100, centerY - 90)

    -- Head with pulsing effect
    lg.circle("line", centerX + 100, centerY - 70, 25)
    lg.setLineWidth(1)
end

function BackgroundManager:drawGameBackground(screenWidth, screenHeight, time)
    -- Dark, atmospheric gradient with subtle movement
    for y = 0, screenHeight, 1.5 do
        local progress = y / screenHeight
        local wave = math_sin(progress * 12 + time * 0.8) * 0.03
        local pulse = math_sin(progress * 6 + time) * 0.02

        local r = 0.03 + wave + pulse
        local g = 0.06 + progress * 0.08 + wave
        local b = 0.12 + progress * 0.15 + pulse

        lg.setColor(r, g, b, 0.9)
        lg.rectangle("fill", 0, y, screenWidth, 1.5)
    end

    -- Ghost letters with varied behaviors
    for _, particle in ipairs(self.gameParticles) do
        local alpha = particle.isGhost and 0.15 or 0.4
        local sizeMod = particle.isGhost and 0.8 or 1.2
        local pulse = math_sin(time * 2 + particle.x * 0.01) * 0.2 + 0.8

        lg.setColor(particle.color[1], particle.color[2], particle.color[3], alpha * pulse)
        lg.print(particle.char, particle.x, particle.y, time * 0.5, (particle.size * sizeMod) / 12)
    end

    -- Subtle noose pattern with animation
    lg.setColor(0.15, 0.25, 0.35, 0.08)
    local gridSize = 70
    local offset = math_sin(time * 0.3) * 5

    for x = -offset, screenWidth + offset, gridSize do
        for y = -offset, screenHeight + offset, gridSize do
            lg.circle("line", x, y, 10)
            lg.line(x - 6, y - 6, x + 6, y + 6)
            lg.line(x + 6, y - 6, x - 6, y + 6)
        end
    end
end

return BackgroundManager
