-- Hangman Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_random = math.random
local table_insert = table.insert

local WordBank = require("classes/WordBank")

local Game = {}
Game.__index = Game

function Game.new()
    local instance = setmetatable({}, Game)

    instance.screenWidth = 800
    instance.screenHeight = 600
    instance.wordBank = WordBank.new()
    instance.currentWord = ""
    instance.displayWord = ""
    instance.guessedLetters = {}
    instance.wrongGuesses = 0
    instance.maxWrongGuesses = 6
    instance.gameOver = false
    instance.won = false
    instance.difficulty = "medium"
    instance.category = "general"
    instance.animations = {}
    instance.hintAvailable = true
    instance.revealTimer = 0
    instance.revealLetter = nil
    instance.screenShake = { intensity = 0, duration = 0, timer = 0, active = false }

    -- Power-ups System
    instance.powerUps = {
        reveal_vowel = {
            name = "Vowel Revealer",
            description = "Reveals a random vowel",
            cost = 2,
            available = true,
            used = false
        },
        second_chance = {
            name = "Second Chance",
            description = "Removes one wrong guess",
            cost = 3,
            available = true,
            used = false
        },
        letter_eliminator = {
            name = "Letter Eliminator",
            description = "Removes 3 wrong letters",
            cost = 4,
            available = true,
            used = false
        }
    }
    instance.coins = 0
    instance.powerUpParticles = {}

    return instance
end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
end

function Game:startNewGame(difficulty, category)
    self.difficulty = difficulty or "medium"
    self.category = category or "general"
    self.currentWord = self.wordBank:getRandomWord(self.difficulty, self.category)
    self.displayWord = string.rep("_ ", #self.currentWord):sub(1, -2)
    self.guessedLetters = {}
    self.wrongGuesses = 0
    self.gameOver = false
    self.won = false
    self.hintAvailable = true
    self.revealTimer = 0
    self.revealLetter = nil
    self.animations = {}
    self.powerUpParticles = {}

    -- Reset power-ups for new game
    for _, powerUp in pairs(self.powerUps) do
        powerUp.used = false
        powerUp.available = true
    end

    -- Start with some coins based on difficulty
    self.coins = self.difficulty == "easy" and 3 or self.difficulty == "medium" and 2 or 1
end

function Game:update(dt)
    -- Update screen shake
    if self.screenShake.active then
        self.screenShake.timer = self.screenShake.timer + dt
        if self.screenShake.timer >= self.screenShake.duration then
            self.screenShake.active = false
            self.screenShake.intensity = 0
        end
    end

    -- Update reveal animation
    if self.revealTimer > 0 then
        self.revealTimer = self.revealTimer - dt
        if self.revealTimer <= 0 then
            self.revealLetter = nil
        end
    end

    -- Update power-up particles
    for i = #self.powerUpParticles, 1, -1 do
        local particle = self.powerUpParticles[i]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt
        particle.dy = particle.dy + 200 * dt -- gravity

        if particle.life <= 0 then
            table.remove(self.powerUpParticles, i)
        end
    end

    -- Update other animations
    for i = #self.animations, 1, -1 do
        local anim = self.animations[i]
        anim.progress = anim.progress + dt / anim.duration

        if anim.progress >= 1 then
            if anim.type == "hint" then
                self:guessLetter(anim.letter)
            end
            table.remove(self.animations, i)
        end
    end
end

function Game:triggerScreenShake()
    self.screenShake.intensity = 8
    self.screenShake.duration = 0.2
    self.screenShake.timer = 0
    self.screenShake.active = true
end

function Game:createPowerUpParticles(x, y, color, count)
    for i = 1, count or 15 do
        table_insert(self.powerUpParticles, {
            x = x,
            y = y,
            dx = (math_random() - 0.5) * 300,
            dy = (math_random() - 0.5) * 300,
            life = math_random(0.5, 1.5),
            color = color or { 1, 1, 1 },
            size = math_random(3, 8),
            char = string.char(math_random(65, 90))
        })
    end
end

function Game:createLetterParticles(letter, x, y, correct)
    local color = correct and { 0.2, 0.8, 0.2 } or { 0.8, 0.2, 0.2 }
    for i = 1, 12 do
        table_insert(self.powerUpParticles, {
            x = x,
            y = y,
            dx = (math_random() - 0.5) * 200,
            dy = (math_random() - 0.5) * 200 - 100, -- upward bias
            life = math_random(1.0, 2.0),
            color = color,
            size = math_random(4, 10),
            char = letter,
            rotation = math_random() * 6.28
        })
    end
end

function Game:createWordRevealEffect()
    local centerX = self.screenWidth / 2
    local wordY = self.screenHeight / 2 + 150
    local wordWidth = #self.currentWord * 20

    for i = 1, #self.currentWord do
        local letter = self.currentWord:sub(i, i)
        local x = centerX - wordWidth / 2 + (i - 0.5) * 40

        -- Stagger the particle creation
        love.timer.sleep(0.05)
        self:createLetterParticles(letter, x, wordY, true)
    end
end

function Game:draw()
    -- Apply screen shake if active
    local offsetX, offsetY = 0, 0
    if self.screenShake.active then
        local progress = self.screenShake.timer / self.screenShake.duration
        local currentIntensity = self.screenShake.intensity * (1 - progress)
        offsetX = love.math.random(-currentIntensity, currentIntensity)
        offsetY = love.math.random(-currentIntensity, currentIntensity)
    end

    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)

    self:drawGallows()
    self:drawHangman()
    self:drawWord()
    self:drawGuessedLetters()
    self:drawUI()
    self:drawPowerUpParticles()

    if self.gameOver then
        self:drawGameOver()
    end

    love.graphics.pop()
end

function Game:drawPowerUpParticles()
    for _, particle in ipairs(self.powerUpParticles) do
        local alpha = math.min(1, particle.life * 2)
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.push()
        love.graphics.translate(particle.x, particle.y)
        love.graphics.rotate(particle.rotation or 0)
        love.graphics.print(particle.char, -particle.size / 2, -particle.size / 2, 0, particle.size / 20)
        love.graphics.pop()
    end
end

function Game:drawGallows()
    local centerX = self.screenWidth / 2
    local baseY = self.screenHeight / 2 + 100

    love.graphics.setColor(0.6, 0.4, 0.2)
    love.graphics.setLineWidth(8)

    -- Base
    love.graphics.line(centerX - 80, baseY, centerX + 80, baseY)
    -- Vertical pole
    love.graphics.line(centerX, baseY, centerX, baseY - 200)
    -- Horizontal beam
    love.graphics.line(centerX, baseY - 200, centerX + 100, baseY - 200)
    -- Rope
    love.graphics.line(centerX + 100, baseY - 200, centerX + 100, baseY - 170)

    love.graphics.setLineWidth(1)
end

function Game:drawHangman()
    local centerX = self.screenWidth / 2
    local baseY = self.screenHeight / 2 + 100
    local headCenterX = centerX + 100
    local headCenterY = baseY - 150

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.setLineWidth(4)

    -- Head (always drawn first)
    if self.wrongGuesses >= 1 then
        love.graphics.circle("line", headCenterX, headCenterY, 20)
    end

    -- Body
    if self.wrongGuesses >= 2 then
        love.graphics.line(headCenterX, headCenterY + 20, headCenterX, headCenterY + 70)
    end

    -- Left arm
    if self.wrongGuesses >= 3 then
        love.graphics.line(headCenterX, headCenterY + 30, headCenterX - 25, headCenterY + 50)
    end

    -- Right arm
    if self.wrongGuesses >= 4 then
        love.graphics.line(headCenterX, headCenterY + 30, headCenterX + 25, headCenterY + 50)
    end

    -- Left leg
    if self.wrongGuesses >= 5 then
        love.graphics.line(headCenterX, headCenterY + 70, headCenterX - 25, headCenterY + 110)
    end

    -- Right leg
    if self.wrongGuesses >= 6 then
        love.graphics.line(headCenterX, headCenterY + 70, headCenterX + 25, headCenterY + 110)
    end

    -- Face (sad when losing)
    if self.wrongGuesses >= 1 then
        love.graphics.setColor(0.9, 0.9, 0.9)
        -- Eyes
        love.graphics.points(headCenterX - 8, headCenterY - 5, headCenterX + 8, headCenterY - 5)

        -- Mouth (changes based on game state)
        if self.gameOver and not self.won then
            -- Sad mouth when lost
            love.graphics.arc("line", headCenterX, headCenterY + 5, 10, 0.3, 2.8)
        else
            -- Neutral mouth otherwise
            love.graphics.line(headCenterX - 8, headCenterY + 8, headCenterX + 8, headCenterY + 8)
        end
    end

    love.graphics.setLineWidth(1)
end

function Game:drawWord()
    local centerX = self.screenWidth / 2
    local wordY = self.screenHeight / 2 + 150

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(32))

    -- Draw the word with spaces
    love.graphics.printf(self.displayWord, 0, wordY, self.screenWidth, "center")

    -- Draw reveal animation if active
    if self.revealLetter then
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("Hint: Letter '" .. self.revealLetter .. "' is in the word!",
            0, wordY - 40, self.screenWidth, "center")
    end
end

function Game:drawGuessedLetters()
    local startX = 50
    local startY = self.screenHeight - 100

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.print("Guessed Letters:", startX, startY - 30)

    local letters = ""
    for _, letter in ipairs(self.guessedLetters) do
        letters = letters .. letter .. " "
    end

    love.graphics.print(letters, startX, startY)
end

function Game:drawUI()
    -- Draw wrong guesses counter
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print("Wrong: " .. self.wrongGuesses .. "/" .. self.maxWrongGuesses,
        self.screenWidth - 150, 50)

    -- Draw coins
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.print("Coins: " .. self.coins, self.screenWidth - 150, 80)

    -- Draw reset button (always visible during gameplay)
    if not self.gameOver then
        love.graphics.setColor(0.8, 0.6, 0.2)
        love.graphics.rectangle("line", self.screenWidth - 140, 160, 120, 40, 5) -- Adjusted x and width
        love.graphics.setColor(0.8, 0.6, 0.2, 0.3)
        love.graphics.rectangle("fill", self.screenWidth - 140, 160, 120, 40, 5) -- Adjusted x and width
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.print("Reset", self.screenWidth - 130, 172) -- Adjusted x position
    end

    -- Draw hint button if available
    if self.hintAvailable and not self.gameOver then
        love.graphics.setColor(0.3, 0.7, 1)
        love.graphics.rectangle("line", self.screenWidth - 140, 210, 120, 40, 5) -- Adjusted x and width
        love.graphics.setColor(0.3, 0.7, 1, 0.3)
        love.graphics.rectangle("fill", self.screenWidth - 140, 210, 120, 40, 5) -- Adjusted x and width
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.print("Get Hint", self.screenWidth - 130, 222) -- Adjusted x position
    end

    -- Draw power-up buttons
    self:drawPowerUpButtons()

    -- Draw category and difficulty
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print("Category: " .. self.category:upper(), 50, 50)
    love.graphics.print("Difficulty: " .. self.difficulty:upper(), 50, 80)

    love.graphics.print("Press ESC to menu", 50, self.screenHeight - 40)
end

function Game:drawPowerUpButtons()
    local buttonY = 260
    local buttonWidth = 120 -- Increased width from 100 to 120
    local buttonHeight = 35
    local spacing = 10

    for i, powerUp in ipairs({
        self.powerUps.reveal_vowel,
        self.powerUps.second_chance,
        self.powerUps.letter_eliminator
    }) do
        local buttonX = self.screenWidth - 140 -- Moved left by 20 pixels (from 120 to 140)
        local currentY = buttonY + (i - 1) * (buttonHeight + spacing)

        -- Determine button color based on availability
        if powerUp.used then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5) -- Used - grayed out
        elseif self.coins >= powerUp.cost then
            love.graphics.setColor(0.8, 0.4, 1, 0.8)   -- Affordable - purple
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5) -- Can't afford - dark
        end

        love.graphics.rectangle("fill", buttonX, currentY, buttonWidth, buttonHeight, 5)

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", buttonX, currentY, buttonWidth, buttonHeight, 5)

        -- Button text
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(12))

        if powerUp.used then
            love.graphics.print("USED", buttonX + 40, currentY + 12) -- Centered text for USED
        else
            love.graphics.print(powerUp.name, buttonX + 10, currentY + 5) -- Adjusted text position
            love.graphics.print("Cost: " .. powerUp.cost, buttonX + 10, currentY + 20) -- Adjusted text position
        end
    end
end

function Game:drawGameOver()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    local font = love.graphics.newFont(48)
    love.graphics.setFont(font)

    if self.won then
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.printf("YOU WIN!", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")

        -- Award coins for winning
        local coinsWon = 5 - self.wrongGuesses
        if coinsWon > 0 then
            love.graphics.setColor(1, 0.8, 0.2)
            love.graphics.setFont(love.graphics.newFont(24))
            love.graphics.printf("+ " .. coinsWon .. " coins!", 0, self.screenHeight / 2 - 20, self.screenWidth, "center")
        end
    else
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.printf("GAME OVER", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")
    end

    -- Draw the actual word
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.printf("The word was: " .. self.currentWord,
        0, self.screenHeight / 2, self.screenWidth, "center")

    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf("Click anywhere to continue",
        0, self.screenHeight / 2 + 60, self.screenWidth, "center")
end

function Game:handleClick(x, y)
    if self.gameOver then
        return
    end

    -- Check reset button (adjusted coordinates)
    if x >= self.screenWidth - 140 and x <= self.screenWidth - 20 and
        y >= 160 and y <= 200 then
        self:resetGame()
        return
    end

    -- Check hint button (adjusted coordinates)
    if self.hintAvailable and x >= self.screenWidth - 140 and x <= self.screenWidth - 20 and
        y >= 210 and y <= 250 then
        self:useHint()
        return
    end

    -- Check power-up buttons (adjusted coordinates)
    self:checkPowerUpClicks(x, y)
end

function Game:checkPowerUpClicks(x, y)
    local buttonY = 260
    local buttonWidth = 120 -- Increased width from 100 to 120
    local buttonHeight = 35
    local spacing = 10

    local powerUpsList = {
        self.powerUps.reveal_vowel,
        self.powerUps.second_chance,
        self.powerUps.letter_eliminator
    }

    for i, powerUp in ipairs(powerUpsList) do
        local buttonX = self.screenWidth - 140 -- Moved left by 20 pixels (from 120 to 140)
        local currentY = buttonY + (i - 1) * (buttonHeight + spacing)

        if x >= buttonX and x <= buttonX + buttonWidth and
            y >= currentY and y <= currentY + buttonHeight then
            self:usePowerUp(powerUp)
            return
        end
    end
end

function Game:usePowerUp(powerUp)
    if powerUp.used or self.coins < powerUp.cost then
        return
    end

    self.coins = self.coins - powerUp.cost
    powerUp.used = true

    -- Create particle effect at the button position
    local buttonY = 260
    local buttonWidth = 120 -- Increased width from 100 to 120
    local buttonHeight = 35
    local spacing = 10

    local powerUpsList = {
        self.powerUps.reveal_vowel,
        self.powerUps.second_chance,
        self.powerUps.letter_eliminator
    }

    for i, p in ipairs(powerUpsList) do
        if p == powerUp then
            local buttonX = self.screenWidth - 140 -- Moved left by 20 pixels (from 120 to 140)
            local currentY = buttonY + (i - 1) * (buttonHeight + spacing)
            self:createPowerUpParticles(buttonX + buttonWidth / 2, currentY + buttonHeight / 2, { 0.8, 0.4, 1 }, 25)
            break
        end
    end

    -- Apply power-up effect
    if powerUp == self.powerUps.reveal_vowel then
        self:useRevealVowel()
    elseif powerUp == self.powerUps.second_chance then
        self:useSecondChance()
    elseif powerUp == self.powerUps.letter_eliminator then
        self:useLetterEliminator()
    end
end

function Game:useRevealVowel()
    local vowels = { "A", "E", "I", "O", "U" }
    local availableVowels = {}

    for _, vowel in ipairs(vowels) do
        if not self:isLetterGuessed(vowel) and string.find(self.currentWord, vowel) then
            table_insert(availableVowels, vowel)
        end
    end

    if #availableVowels > 0 then
        local vowel = availableVowels[math_random(#availableVowels)]
        self:guessLetter(vowel)

        -- Create special particle effect
        local centerX = self.screenWidth / 2
        local wordY = self.screenHeight / 2 + 150
        self:createLetterParticles(vowel, centerX, wordY - 50, true)
    end
end

function Game:useSecondChance()
    if self.wrongGuesses > 0 then
        self.wrongGuesses = self.wrongGuesses - 1

        -- Create healing particle effect around hangman
        local headCenterX = self.screenWidth / 2 + 100
        local headCenterY = self.screenHeight / 2 + 100 - 150
        self:createPowerUpParticles(headCenterX, headCenterY, { 0.2, 0.8, 0.2 }, 30)
    end
end

function Game:useLetterEliminator()
    local wrongLetters = {}

    -- Find letters that are wrong and not guessed
    for i = 65, 90 do
        local letter = string.char(i)
        if not self:isLetterGuessed(letter) and not string.find(self.currentWord, letter) then
            table_insert(wrongLetters, letter)
        end
    end

    -- Remove up to 3 wrong letters
    for i = 1, math.min(3, #wrongLetters) do
        if #wrongLetters > 0 then
            local randomIndex = math_random(#wrongLetters)
            local letter = table.remove(wrongLetters, randomIndex)
            table_insert(self.guessedLetters, letter)

            -- Create elimination particle effect
            local startX = 50
            local startY = self.screenHeight - 100
            self:createLetterParticles(letter, startX + (i - 1) * 40, startY, false)
        end
    end
end

function Game:resetGame()
    self:startNewGame(self.difficulty, self.category)
end

function Game:guessLetter(letter)
    if self.gameOver or self:isLetterGuessed(letter) then
        return
    end

    table_insert(self.guessedLetters, letter)

    if string.find(self.currentWord, letter) then
        -- Correct guess - update display word
        local newDisplay = ""
        for i = 1, #self.currentWord do
            local currentChar = self.currentWord:sub(i, i)
            if currentChar == letter or string.find(self.displayWord:sub((i - 1) * 2 + 1, (i - 1) * 2 + 1), "[A-Z]") then
                newDisplay = newDisplay .. currentChar .. " "
            else
                newDisplay = newDisplay .. "_ "
            end
        end
        self.displayWord = newDisplay:sub(1, -2)

        -- Award coin for correct guess
        self.coins = self.coins + 1

        -- Create particle effect for correct guess
        local centerX = self.screenWidth / 2
        local wordY = self.screenHeight / 2 + 150
        local letterIndex = string.find(self.currentWord, letter)
        if letterIndex then
            local wordWidth = #self.currentWord * 20
            local x = centerX - wordWidth / 2 + (letterIndex - 0.5) * 40
            self:createLetterParticles(letter, x, wordY, true)
        end

        -- Check if won
        if not string.find(self.displayWord, "_") then
            self.gameOver = true
            self.won = true
            self:createWordRevealEffect()

            -- Award bonus coins for winning
            local bonusCoins = math.max(1, 5 - self.wrongGuesses)
            self.coins = self.coins + bonusCoins
        end
    else
        -- Wrong guess
        self.wrongGuesses = self.wrongGuesses + 1
        self:triggerScreenShake()

        -- Create particle effect for wrong guess
        local headCenterX = self.screenWidth / 2 + 100
        local headCenterY = self.screenHeight / 2 + 100 - 150
        self:createLetterParticles(letter, headCenterX, headCenterY, false)

        -- Check if lost
        if self.wrongGuesses >= self.maxWrongGuesses then
            self.gameOver = true
            self.won = false
            self.displayWord = self.currentWord:gsub(".", "%0 "):sub(1, -2)
        end
    end
end

function Game:useHint()
    if not self.hintAvailable or self.gameOver then return end

    -- Find an unguessed letter in the word
    local availableHints = {}
    for i = 1, #self.currentWord do
        local letter = self.currentWord:sub(i, i)
        if not self:isLetterGuessed(letter) and not string.find(self.displayWord:sub((i - 1) * 2 + 1, (i - 1) * 2 + 1), "[A-Z]") then
            table_insert(availableHints, letter)
        end
    end

    if #availableHints > 0 then
        local hintLetter = availableHints[math_random(#availableHints)]
        self.revealLetter = hintLetter
        self.revealTimer = 3 -- Show for 3 seconds
        self.hintAvailable = false

        -- Auto-guess the hinted letter after a delay
        table_insert(self.animations, {
            type = "hint",
            progress = 0,
            duration = 1,
            letter = hintLetter
        })
    end
end

function Game:isLetterGuessed(letter)
    for _, guessed in ipairs(self.guessedLetters) do
        if guessed == letter then
            return true
        end
    end
    return false
end

function Game:isGameOver()
    return self.gameOver
end

return Game