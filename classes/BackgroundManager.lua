-- Hangman Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_pi = math.pi
local math_sin = math.sin
local string_char = string.char
local math_random = math.random
local table_insert = table.insert
local lg = love.graphics

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

local function initFloatingLetters(self)
    self.floatingLetters = {}
    local letterCount = 40

    for _ = 1, letterCount do
        table_insert(self.floatingLetters, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(16, 24),
            speedX = math_random(-20, 20),
            speedY = math_random(-20, 20),
            rotation = math_random() * math_pi * 2,
            rotationSpeed = (math_random() - 0.5) * 2,
            bobSpeed = math_random(1, 3),
            bobAmount = math_random(2, 8),
            char = string_char(math_random(65, 90)),
            alpha = math_random(0.3, 0.7),
            isRevealed = math_random() > 0.7, -- Some letters start revealed
            isGhost = math_random() > 0.8,    -- Some are ghost letters
            color = {
                math_random(0.7, 0.9),
                math_random(0.7, 0.9),
                math_random(0.8, 1.0)
            }
        })
    end
end

local function initFloatingGallows(self)
    self.floatingGallows = {}
    local gallowsCount = 8

    for _ = 1, gallowsCount do
        table_insert(self.floatingGallows, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(0.3, 0.8),
            speedX = math_random(-15, 15),
            speedY = math_random(-15, 15),
            rotation = math_random() * math_pi * 2,
            rotationSpeed = (math_random() - 0.5) * 1,
            bobSpeed = math_random(0.5, 2),
            bobAmount = math_random(1, 4),
            alpha = math_random(0.1, 0.3),
            pulseSpeed = math_random(0.5, 1.5),
            pulsePhase = math_random() * math_pi * 2
        })
    end
end

function BackgroundManager.new()
    local instance = setmetatable({}, BackgroundManager)
    instance.floatingLetters = {}
    instance.floatingGallows = {}
    instance.time = 0
    instance.pulseValue = 0

    initFloatingLetters(instance)
    initFloatingGallows(instance)

    return instance
end

function BackgroundManager:update(dt)
    self.time = self.time + dt
    self.pulseValue = math_sin(self.time * 2) * 0.5 + 0.5

    -- Update floating letters
    for _, letter in ipairs(self.floatingLetters) do
        letter.x = letter.x + letter.speedX * dt
        letter.y = letter.y + letter.speedY * dt

        -- Bobbing motion
        letter.y = letter.y + math_sin(self.time * letter.bobSpeed) * letter.bobAmount * dt
        letter.rotation = letter.rotation + letter.rotationSpeed * dt

        -- Wrap around screen edges
        if letter.x < -50 then letter.x = 1050 end
        if letter.x > 1050 then letter.x = -50 end
        if letter.y < -50 then letter.y = 1050 end
        if letter.y > 1050 then letter.y = -50 end

        -- Occasionally change revealed state
        if math_random() < 0.01 then
            letter.isRevealed = not letter.isRevealed
        end
    end

    -- Update floating gallows
    for _, gallows in ipairs(self.floatingGallows) do
        gallows.x = gallows.x + gallows.speedX * dt
        gallows.y = gallows.y + gallows.speedY * dt

        -- Bobbing motion
        gallows.y = gallows.y + math_sin(self.time * gallows.bobSpeed) * gallows.bobAmount * dt
        gallows.rotation = gallows.rotation + gallows.rotationSpeed * dt

        -- Wrap around screen edges
        if gallows.x < -100 then gallows.x = 1100 end
        if gallows.x > 1100 then gallows.x = -100 end
        if gallows.y < -100 then gallows.y = 1100 end
        if gallows.y > 1100 then gallows.y = -100 end
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

    -- Draw floating gallows
    for _, gallows in ipairs(self.floatingGallows) do
        local pulse = (math_sin(gallows.pulsePhase + time * gallows.pulseSpeed) + 1) * 0.5
        local currentAlpha = gallows.alpha * (0.7 + pulse * 0.3)

        lg.push()
        lg.translate(gallows.x, gallows.y)
        lg.rotate(gallows.rotation)
        lg.scale(gallows.size, gallows.size)

        lg.setColor(0.4, 0.6, 0.8, currentAlpha)
        lg.setLineWidth(3)

        -- Draw simple gallows
        lg.line(-40, 40, 40, 40)  -- Base
        lg.line(0, 40, 0, -40)    -- Vertical pole
        lg.line(0, -40, 30, -40)  -- Horizontal beam
        lg.line(30, -40, 30, -30) -- Rope

        lg.setLineWidth(1)
        lg.pop()
    end

    -- Draw floating letters
    for _, letter in ipairs(self.floatingLetters) do
        local bobOffset = math_sin(time * letter.bobSpeed) * letter.bobAmount
        local currentY = letter.y + bobOffset
        local currentAlpha = letter.alpha

        if letter.isGhost then
            currentAlpha = currentAlpha * (0.3 + math_sin(time * 2) * 0.2)
        end

        lg.push()
        lg.translate(letter.x, currentY)
        lg.rotate(letter.rotation)

        if letter.isRevealed then
            -- Revealed letters (like correct guesses)
            lg.setColor(0.3, 0.9, 0.4, currentAlpha)
        else
            -- Hidden letters (like unguessed letters)
            lg.setColor(letter.color[1], letter.color[2], letter.color[3], currentAlpha)
        end

        lg.print(letter.char, 0, 0, 0, letter.size / 18)
        lg.pop()
    end

    -- Main gallows silhouette in center background
    lg.setColor(0.4, 0.6, 0.8, 0.15 + self.pulseValue * 0.1)
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2 - 5

    -- Larger, more detailed gallows
    lg.setLineWidth(6)

    -- Base
    lg.line(centerX - 150, centerY + 200, centerX + 150, centerY + 200)

    -- Vertical pole
    lg.line(centerX, centerY + 200, centerX, centerY - 100)

    -- Horizontal beam
    lg.line(centerX, centerY - 100, centerX + 120, centerY - 100)

    -- Support beam
    lg.line(centerX, centerY - 50, centerX + 60, centerY - 100)

    -- Rope
    lg.setLineWidth(3)
    lg.line(centerX + 120, centerY - 100, centerX + 120, centerY - 70)

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

    -- Draw floating gallows
    for _, gallows in ipairs(self.floatingGallows) do
        local pulse = (math_sin(gallows.pulsePhase + time * gallows.pulseSpeed) + 1) * 0.5
        local currentAlpha = gallows.alpha * 0.7 * (0.5 + pulse * 0.5)

        lg.push()
        lg.translate(gallows.x, gallows.y)
        lg.rotate(gallows.rotation)
        lg.scale(gallows.size, gallows.size)

        lg.setColor(0.2, 0.3, 0.4, currentAlpha)
        lg.setLineWidth(2)

        -- Draw gallows with noose
        lg.line(-30, 30, 30, 30)      -- Base
        lg.line(0, 30, 0, -30)        -- Vertical pole
        lg.line(0, -30, 25, -30)      -- Horizontal beam
        lg.line(25, -30, 25, -25)     -- Rope
        lg.circle("line", 25, -20, 5) -- Noose

        lg.setLineWidth(1)
        lg.pop()
    end

    -- Draw floating letters
    for _, letter in ipairs(self.floatingLetters) do
        local bobOffset = math_sin(time * letter.bobSpeed) * letter.bobAmount
        local currentY = letter.y + bobOffset
        local pulse = math_sin(time * 2 + letter.x * 0.01) * 0.3 + 0.7
        local currentAlpha = letter.alpha * pulse * 0.8

        if letter.isGhost then
            currentAlpha = currentAlpha * 0.4
        end

        lg.push()
        lg.translate(letter.x, currentY)
        lg.rotate(letter.rotation + time * 0.5)

        if letter.isRevealed then
            -- Bright revealed letters
            lg.setColor(0.2, 0.8, 0.3, currentAlpha)
        else
            -- Darker, more mysterious unguessed letters
            if letter.isGhost then
                lg.setColor(0.6, 0.7, 1.0, currentAlpha)
            else
                lg.setColor(0.3, 0.5, 0.8, currentAlpha)
            end
        end

        lg.print(letter.char, 0, 0, time * 0.3, letter.size / 15)
        lg.pop()
    end

    -- Subtle grid pattern with hanging nooses
    lg.setColor(0.15, 0.25, 0.35, 0.08)
    local gridSize = 80
    local offset = math_sin(time * 0.3) * 5

    for x = -offset, screenWidth + offset, gridSize do
        for y = -offset, screenHeight + offset, gridSize do
            lg.push()
            lg.translate(x, y)

            -- Draw noose
            lg.setLineWidth(1)
            lg.circle("line", 0, 0, 8)
            lg.line(-5, -5, 5, 5)
            lg.line(5, -5, -5, 5)
            lg.line(0, -8, 0, -12)

            lg.pop()
        end
    end
end

return BackgroundManager
