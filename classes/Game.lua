-- Hangman Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_random = math.random
local table_insert = table.insert
local math_sin = math.sin
local math_max = math.max
local math_min = math.min
local string_find = string.find
local string_char = string.char
local string_rep = string.rep
local lg = love.graphics

local WordBank = require("classes.WordBank")
local SoundManager = require("classes.SoundManager")

local Game = {}
Game.__index = Game

function Game.new()
    local instance = setmetatable({}, Game)

    instance.screenWidth = 800
    instance.screenHeight = 600
    instance.gameOver = false
    instance.won = false
    instance.difficulty = "medium"
    instance.category = "general"
    instance.wordBank = WordBank.new()
    instance.currentWord = ""
    instance.displayWord = ""
    instance.guessedLetters = {}
    instance.wrongGuesses = 0
    instance.maxWrongGuesses = 6
    instance.hintAvailable = true
    instance.revealTimer = 0
    instance.revealLetter = nil
    instance.animations = {}
    instance.powerUpParticles = {}
    instance.screenShake = { intensity = 0, duration = 0, timer = 0, active = false }
    instance.buttonHover = nil
    instance.time = 0
    instance.coins = 0


    -- Power-ups System
    instance.powerUps = {
        reveal_vowel = {
            name = "Vowel Revealer",
            description = "Reveals a random vowel",
            cost = 2,
            available = true,
            used = false,
            color = { 0.2, 0.8, 0.4 }
        },
        second_chance = {
            name = "Second Chance",
            description = "Removes one wrong guess",
            cost = 3,
            available = true,
            used = false,
            color = { 0.9, 0.7, 0.1 }
        },
        letter_eliminator = {
            name = "Letter Eliminator",
            description = "Removes 3 wrong letters",
            cost = 4,
            available = true,
            used = false,
            color = { 0.8, 0.3, 0.8 }
        }
    }

    local soundManager = SoundManager.new()
    instance.sounds = soundManager

    return instance
end

local function isLetterGuessed(self, letter)
    for _, guessed in ipairs(self.guessedLetters) do
        if guessed == letter then return true end
    end
    return false
end

local function createLetterParticles(self, letter, x, y, correct)
    local color = correct and { 0.3, 0.9, 0.4 } or { 0.9, 0.3, 0.4 }
    for _ = 1, 15 do
        table_insert(self.powerUpParticles, {
            x = x,
            y = y,
            dx = (math_random() - 0.5) * 300,
            dy = (math_random() - 0.5) * 300 - 150,
            life = math_random(1.2, 2.5),
            color = color,
            size = math_random(5, 12),
            char = letter,
            rotation = math_random() * 6.28,
            spin = (math_random() - 0.5) * 8
        })
    end
end

local function createPowerUpParticles(self, x, y, color, count)
    for _ = 1, count or 20 do
        table_insert(self.powerUpParticles, {
            x = x,
            y = y,
            dx = (math_random() - 0.5) * 400,
            dy = (math_random() - 0.5) * 400,
            life = math_random(0.8, 2.0),
            color = color or { 1, 1, 1 },
            size = math_random(4, 12),
            char = string_char(math_random(65, 90)),
            rotation = 0,
            spin = (math_random() - 0.5) * 10
        })
    end
end

local function useRevealVowel(self)
    local vowels = { "A", "E", "I", "O", "U" }
    local availableVowels = {}

    for _, vowel in ipairs(vowels) do
        if not isLetterGuessed(self, vowel) and string_find(self.currentWord, vowel) then
            table_insert(availableVowels, vowel)
        end
    end

    if #availableVowels > 0 then
        local vowel = availableVowels[math_random(#availableVowels)]
        self:guessLetter(vowel)

        -- Create special particle effect
        local centerX = self.screenWidth / 2
        local wordY = self.screenHeight / 2 + 150
        createLetterParticles(self, vowel, centerX, wordY - 50, true)
    end
end

local function useHint(self)
    if not self.hintAvailable or self.gameOver then return end

    -- Find an unguessed letter in the word
    local availableHints = {}
    for i = 1, #self.currentWord do
        local letter = self.currentWord:sub(i, i)
        if not isLetterGuessed(self, letter) and not string_find(self.displayWord:sub((i - 1) * 2 + 1, (i - 1) * 2 + 1), "[A-Z]") then
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

local function useSecondChance(self)
    if self.wrongGuesses > 0 then
        self.wrongGuesses = self.wrongGuesses - 1

        -- Create healing particle effect around hangman
        local headCenterX = self.screenWidth / 2 + 100
        local headCenterY = self.screenHeight / 2 + 100 - 150
        createPowerUpParticles(self, headCenterX, headCenterY, { 0.2, 0.8, 0.2 }, 30)
    end
end

local function useLetterEliminator(self)
    local wrongLetters = {}

    -- Find letters that are wrong and not guessed
    for i = 65, 90 do
        local letter = string_char(i)
        if not isLetterGuessed(self, letter) and not string_find(self.currentWord, letter) then
            table_insert(wrongLetters, letter)
        end
    end

    -- Remove up to 3 wrong letters
    for i = 1, math_min(3, #wrongLetters) do
        if #wrongLetters > 0 then
            local randomIndex = math_random(#wrongLetters)
            local letter = table.remove(wrongLetters, randomIndex)
            table_insert(self.guessedLetters, letter)

            -- Create elimination particle effect
            local startX = 50
            local startY = self.screenHeight - 100
            createLetterParticles(self, letter, startX + (i - 1) * 40, startY, false)
        end
    end
end

local function usePowerUp(self, powerUp)
    if powerUp.used or self.coins < powerUp.cost then return end

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
            createPowerUpParticles(self, buttonX + buttonWidth / 2, currentY + buttonHeight / 2, { 0.8, 0.4, 1 }, 25)
            break
        end
    end

    -- Apply power-up effect
    if powerUp == self.powerUps.reveal_vowel then
        useRevealVowel(self)
    elseif powerUp == self.powerUps.second_chance then
        useSecondChance(self)
    elseif powerUp == self.powerUps.letter_eliminator then
        useLetterEliminator(self)
    end
end

local function checkPowerUpClicks(self, x, y)
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
            usePowerUp(self, powerUp)
            return
        end
    end
end

local function resetGame(self)
    self:startNewGame(self.difficulty, self.category)
end

local function triggerScreenShake(self)
    self.screenShake.intensity = 10
    self.screenShake.duration = 0.25
    self.screenShake.timer = 0
    self.screenShake.active = true
end

local function drawGallows(self)
    local centerX = self.screenWidth / 2
    local baseY = self.screenHeight / 2 + 100

    -- Gallows with wood texture effect
    lg.setColor(0.5, 0.3, 0.1)
    lg.setLineWidth(10)

    -- Base with shadow
    lg.setColor(0.3, 0.2, 0.05)
    lg.line(centerX - 85, baseY + 5, centerX + 85, baseY + 5)

    lg.setColor(0.6, 0.4, 0.2)
    lg.line(centerX - 80, baseY, centerX + 80, baseY)

    -- Vertical pole
    lg.setColor(0.3, 0.2, 0.05)
    lg.line(centerX + 3, baseY, centerX + 3, baseY - 200)

    lg.setColor(0.6, 0.4, 0.2)
    lg.line(centerX, baseY, centerX, baseY - 200)

    -- Horizontal beam
    lg.setColor(0.3, 0.2, 0.05)
    lg.line(centerX, baseY - 203, centerX + 103, baseY - 203)

    lg.setColor(0.6, 0.4, 0.2)
    lg.line(centerX, baseY - 200, centerX + 100, baseY - 200)

    -- Rope with swing effect
    local ropeSwing = math_sin(self.time * 2) * 2
    lg.setColor(0.8, 0.8, 0.8)
    lg.setLineWidth(3)
    lg.line(centerX + 100 + ropeSwing, baseY - 200, centerX + 100 + ropeSwing, baseY - 170)

    lg.setLineWidth(1)
end

local function drawHangman(self)
    local centerX = self.screenWidth / 2
    local baseY = self.screenHeight / 2 + 100
    local headCenterX = centerX + 100
    local headCenterY = baseY - 150
    local pulse = math_sin(self.time * 4) * 0.05 + 0.95

    lg.setColor(0.95, 0.95, 0.95)
    lg.setLineWidth(5)

    -- Head (always drawn first)
    if self.wrongGuesses >= 1 then
        lg.circle("line", headCenterX, headCenterY, 22 * pulse)

        -- Face details
        lg.setColor(0.3, 0.3, 0.3)
        lg.setLineWidth(2)

        -- Eyes (change based on game state)
        if self.gameOver and not self.won then
            -- X eyes when dead
            lg.line(headCenterX - 8, headCenterY - 5, headCenterX - 4, headCenterY - 1)
            lg.line(headCenterX - 4, headCenterY - 5, headCenterX - 8, headCenterY - 1)
            lg.line(headCenterX + 8, headCenterY - 5, headCenterX + 4, headCenterY - 1)
            lg.line(headCenterX + 4, headCenterY - 5, headCenterX + 8, headCenterY - 1)
        else
            -- Normal eyes
            lg.circle("fill", headCenterX - 8, headCenterY - 5, 2)
            lg.circle("fill", headCenterX + 8, headCenterY - 5, 2)
        end
    end

    lg.setColor(0.95, 0.95, 0.95)
    lg.setLineWidth(4)

    -- Body
    if self.wrongGuesses >= 2 then
        lg.line(headCenterX, headCenterY + 22, headCenterX, headCenterY + 75)
    end

    -- Left arm
    if self.wrongGuesses >= 3 then
        lg.line(headCenterX, headCenterY + 30, headCenterX - 28, headCenterY + 55)
    end

    -- Right arm
    if self.wrongGuesses >= 4 then
        lg.line(headCenterX, headCenterY + 30, headCenterX + 28, headCenterY + 55)
    end

    -- Left leg
    if self.wrongGuesses >= 5 then
        lg.line(headCenterX, headCenterY + 75, headCenterX - 28, headCenterY + 115)
    end

    -- Right leg
    if self.wrongGuesses >= 6 then
        lg.line(headCenterX, headCenterY + 75, headCenterX + 28, headCenterY + 115)
    end

    -- Mouth (changes based on game state)
    if self.wrongGuesses >= 1 then
        lg.setColor(0.3, 0.3, 0.3)
        lg.setLineWidth(2)

        if self.gameOver and not self.won then
            -- Sad mouth when lost
            lg.arc("line", headCenterX, headCenterY + 8, 12, 0.3, 2.8)
        elseif self.gameOver and self.won then
            -- Happy mouth when won
            lg.arc("line", headCenterX, headCenterY + 3, 10, 3.5, 5.9)
        else
            -- Neutral mouth otherwise
            lg.line(headCenterX - 9, headCenterY + 8, headCenterX + 9, headCenterY + 8)
        end
    end

    lg.setLineWidth(1)
end

local function drawWord(self)
    local centerX = self.screenWidth / 2
    local wordY = self.screenHeight / 2 + 150

    -- Word background
    lg.setColor(0, 0, 0, 0.3)
    lg.rectangle("fill", centerX - 200, wordY - 25, 400, 60, 10)

    lg.setColor(1, 1, 1)
    local font = lg.newFont(36)
    lg.setFont(font)

    -- Calculate exact letter positions for particle effects
    local letterSpacing = 36 -- This matches the font size
    local wordWidth = #self.currentWord * letterSpacing
    local startX = centerX - wordWidth / 2 + letterSpacing / 2

    -- Draw the word and store letter positions for particles
    self.letterPositions = {}
    for i = 1, #self.currentWord do
        local letter = self.displayWord:sub((i - 1) * 2 + 1, (i - 1) * 2 + 1)
        local x = startX + (i - 1) * letterSpacing
        self.letterPositions[i] = x -- Store position for particles
        lg.print(letter, x - font:getWidth(letter) / 2, wordY - 18)
    end

    -- Draw reveal animation if active
    if self.revealLetter then
        local alpha = (math_sin(self.time * 8) + 1) * 0.5
        lg.setColor(1, 1, 0, alpha)
        lg.setFont(lg.newFont(20))
        lg.printf("Hint: Letter '" .. self.revealLetter .. "' is in the word!",
            0, wordY - 45, self.screenWidth, "center")
    end
end

local function drawGuessedLetters(self)
    local startX = 15
    local startY = self.screenHeight - 45

    -- Background for guessed letters
    lg.setColor(0, 0, 0, 0.3)
    lg.rectangle("fill", startX - 10, startY - 40, 300, 80, 8)

    lg.setColor(1, 1, 1)
    lg.setFont(lg.newFont(20))
    lg.print("Guessed Letters:", startX, startY - 30)

    local letters = ""
    for _, letter in ipairs(self.guessedLetters) do
        local inWord = string_find(self.currentWord, letter) ~= nil
        lg.setColor(inWord and 0.3 or 0.9, inWord and 0.9 or 0.3, inWord and 0.4 or 0.3)
        letters = letters .. letter .. " "
    end

    lg.print(letters, startX, startY)
end

local function drawActionButtons(self)
    local buttonWidth = 120
    local buttonHeight = 40

    -- Reset button
    local resetHover = self.buttonHover == "reset"
    lg.setColor(0.8, 0.6, 0.2, resetHover and 0.8 or 0.5)
    lg.rectangle("fill", self.screenWidth - 140, 160, buttonWidth, buttonHeight, 6)
    lg.setColor(1, 0.8, 0.3, resetHover and 1 or 0.7)
    lg.rectangle("line", self.screenWidth - 140, 160, buttonWidth, buttonHeight, 6)
    lg.setColor(1, 1, 1)
    lg.setFont(lg.newFont(18))
    lg.print("Reset", self.screenWidth - 130, 172)

    -- Hint button if available
    if self.hintAvailable then
        local hintHover = self.buttonHover == "hint"
        lg.setColor(0.3, 0.7, 1, hintHover and 0.8 or 0.5)
        lg.rectangle("fill", self.screenWidth - 140, 210, buttonWidth, buttonHeight, 6)
        lg.setColor(0.5, 0.8, 1, hintHover and 1 or 0.7)
        lg.rectangle("line", self.screenWidth - 140, 210, buttonWidth, buttonHeight, 6)
        lg.setColor(1, 1, 1)
        lg.print("Get Hint", self.screenWidth - 130, 222)
    end
end

local function drawPowerUpButtons(self)
    local buttonY = 260
    local buttonWidth = 120
    local buttonHeight = 35
    local spacing = 10

    local powerUpsList = {
        self.powerUps.reveal_vowel,
        self.powerUps.second_chance,
        self.powerUps.letter_eliminator
    }

    for i, powerUp in ipairs(powerUpsList) do
        local buttonX = self.screenWidth - 140
        local currentY = buttonY + (i - 1) * (buttonHeight + spacing)
        local isHovered = self.buttonHover == "powerup_" .. i

        if powerUp.used then
            -- Used power-up (grayed out)
            lg.setColor(0.3, 0.3, 0.3, 0.5)
            lg.rectangle("fill", buttonX, currentY, buttonWidth, buttonHeight, 5)
            lg.setColor(0.5, 0.5, 0.5)
            lg.rectangle("line", buttonX, currentY, buttonWidth, buttonHeight, 5)
        elseif self.coins >= powerUp.cost then
            -- Affordable power-up
            lg.setColor(powerUp.color[1], powerUp.color[2], powerUp.color[3], isHovered and 0.9 or 0.7)
            lg.rectangle("fill", buttonX, currentY, buttonWidth, buttonHeight, 5)
            lg.setColor(1, 1, 1, isHovered and 1 or 0.8)
            lg.rectangle("line", buttonX, currentY, buttonWidth, buttonHeight, 5)
        else
            -- Can't afford
            lg.setColor(0.5, 0.5, 0.5, 0.4)
            lg.rectangle("fill", buttonX, currentY, buttonWidth, buttonHeight, 5)
            lg.setColor(0.7, 0.7, 0.7)
            lg.rectangle("line", buttonX, currentY, buttonWidth, buttonHeight, 5)
        end

        -- Button text
        lg.setColor(1, 1, 1)
        lg.setFont(lg.newFont(12))

        if powerUp.used then
            lg.print("USED", buttonX + 40, currentY + 12)
        else
            lg.print(powerUp.name, buttonX + 10, currentY + 5)
            lg.print("Cost: " .. powerUp.cost, buttonX + 10, currentY + 20)
        end
    end
end

local function drawUI(self)
    -- Draw wrong guesses counter with styling
    lg.setColor(0.9, 0.3, 0.3)
    lg.setFont(lg.newFont(24))
    lg.print("Wrong: " .. self.wrongGuesses .. "/" .. self.maxWrongGuesses,
        self.screenWidth - 180, 50)

    -- Draw coins with coin icon effect
    lg.setColor(1, 0.8, 0.2)
    local coinPulse = math_sin(self.time * 5) * 0.2 + 0.8
    lg.setColor(1, 0.8 * coinPulse, 0.2 * coinPulse)
    lg.print("Coins: " .. self.coins, self.screenWidth - 180, 80)

    -- Draw buttons
    drawActionButtons(self)
    drawPowerUpButtons(self)

    -- Draw category and difficulty with styling
    lg.setColor(1, 1, 1, 0.8)
    lg.setFont(lg.newFont(18))
    lg.print("Category: " .. self.category:upper(), 50, 50)
    lg.print("Difficulty: " .. self.difficulty:upper(), 50, 80)

    -- Instructions
    lg.setColor(1, 1, 1, 0.6)
    lg.setFont(lg.newFont(14))
    lg.print("Press ESC for menu", self.screenWidth - 180, self.screenHeight - 40)
end

local function drawGameOver(self)
    -- Semi-transparent overlay
    lg.setColor(0, 0, 0, 0.7)
    lg.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    local font = lg.newFont(48)
    lg.setFont(font)

    if self.won then
        lg.setColor(0.2, 0.8, 0.2)
        lg.printf("YOU WIN!", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")

        -- Award coins for winning
        local coinsWon = 5 - self.wrongGuesses
        if coinsWon > 0 then
            lg.setColor(1, 0.8, 0.2)
            lg.setFont(lg.newFont(24))
            lg.printf("+ " .. coinsWon .. " coins!", 0, self.screenHeight / 2 - 20, self.screenWidth, "center")
        end
    else
        lg.setColor(0.8, 0.2, 0.2)
        lg.printf("GAME OVER", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")
    end

    -- Draw the actual word
    lg.setColor(1, 1, 1)
    lg.setFont(lg.newFont(28))
    lg.printf("The word was: " .. self.currentWord,
        0, self.screenHeight / 2, self.screenWidth, "center")

    lg.setFont(lg.newFont(20))
    lg.printf("Click anywhere to continue",
        0, self.screenHeight / 2 + 60, self.screenWidth, "center")
end

local function drawPowerUpParticles(self)
    for _, particle in ipairs(self.powerUpParticles) do
        local alpha = math_min(1, particle.life * 1.5)
        lg.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        lg.push()
        lg.translate(particle.x, particle.y)
        lg.rotate(particle.rotation or 0)
        lg.print(particle.char, -particle.size / 2, -particle.size / 2, 0, particle.size / 18)
        lg.pop()
    end
end

local function createWordRevealEffect(self)
    local wordY = self.screenHeight / 2 + 150

    for i = 1, #self.currentWord do
        local letter = self.currentWord:sub(i, i)
        local x = self.letterPositions[i]
        if x then
            createLetterParticles(self, letter, x, wordY - 5, true)
        end
    end
end

function Game:guessLetter(letter)
    if self.gameOver or isLetterGuessed(self, letter) then return end

    table_insert(self.guessedLetters, letter)

    if string_find(self.currentWord, letter) then
        -- Correct guess - update display word
        local newDisplay = ""
        for i = 1, #self.currentWord do
            local currentChar = self.currentWord:sub(i, i)
            if currentChar == letter or string_find(self.displayWord:sub((i - 1) * 2 + 1, (i - 1) * 2 + 1), "[A-Z]") then
                newDisplay = newDisplay .. currentChar .. " "
            else
                newDisplay = newDisplay .. "_ "
            end
        end
        self.displayWord = newDisplay:sub(1, -2)

        -- Award coin for correct guess
        self.coins = self.coins + 1

        -- Create particle effects for ALL occurrences of the letter
        local wordY = self.screenHeight / 2 + 150
        for i = 1, #self.currentWord do
            if self.currentWord:sub(i, i) == letter then
                local x = self.letterPositions[i]
                if x then -- Ensure position exists
                    createLetterParticles(self, letter, x, wordY - 5, true)
                end
            end
        end

        -- Check if won
        if not string_find(self.displayWord, "_") then
            self.gameOver = true
            self.won = true
            createWordRevealEffect(self)

            -- Award bonus coins for winning
            local bonusCoins = math_max(1, 5 - self.wrongGuesses)
            self.coins = self.coins + bonusCoins
            self.sounds:play("win")
            return
        end
        self.sounds:play("correct_guess")
    else
        -- Wrong guess
        self.wrongGuesses = self.wrongGuesses + 1
        triggerScreenShake(self)
        self.sounds:play("wrong")

        -- Create particle effect for wrong guess at hangman position
        local headCenterX = self.screenWidth / 2 + 100
        local headCenterY = self.screenHeight / 2 + 100 - 150
        createLetterParticles(self, letter, headCenterX, headCenterY, false)

        -- Check if lost
        if self.wrongGuesses >= self.maxWrongGuesses then
            self.gameOver = true
            self.won = false
            self.displayWord = self.currentWord:gsub(".", "%0 "):sub(1, -2)
        end
    end
end

function Game:isGameOver() return self.gameOver end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
end

function Game:startNewGame(difficulty, category)
    self.difficulty = difficulty or "medium"
    self.category = category or "general"
    self.currentWord = self.wordBank:getRandomWord(self.difficulty, self.category)
    self.displayWord = string_rep("_ ", #self.currentWord):sub(1, -2)
    self.guessedLetters = {}
    self.wrongGuesses = 0
    self.gameOver = false
    self.won = false
    self.hintAvailable = true
    self.revealTimer = 0
    self.revealLetter = nil
    self.animations = {}
    self.powerUpParticles = {}
    self.time = 0

    -- Reset power-ups for new game
    for _, powerUp in pairs(self.powerUps) do
        powerUp.used = false
        powerUp.available = true
    end

    -- Start with some coins based on difficulty
    self.coins = self.difficulty == "easy" and 4 or self.difficulty == "medium" and 3 or 2
end

function Game:handleClick(x, y)
    if self.gameOver then return end

    -- Check reset button
    if x >= self.screenWidth - 140 and x <= self.screenWidth - 20 and
        y >= 160 and y <= 200 then
        resetGame()
        return
    end

    -- Check hint button
    if self.hintAvailable and x >= self.screenWidth - 140 and x <= self.screenWidth - 20 and
        y >= 210 and y <= 250 then
        useHint(self)
        return
    end

    -- Check power-up buttons
    checkPowerUpClicks(self, x, y)
end

function Game:update(dt)
    self.time = self.time + dt

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
        particle.rotation = particle.rotation + particle.spin * dt

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

    -- Update button hover state
    self:updateButtonHover(love.mouse.getX(), love.mouse.getY())
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

    lg.push()
    lg.translate(offsetX, offsetY)

    drawGallows(self)
    drawHangman(self)
    drawWord(self)
    drawGuessedLetters(self)
    drawUI(self)
    drawPowerUpParticles(self)

    if self.gameOver then drawGameOver(self) end

    lg.pop()
end

function Game:updateButtonHover(x, y)
    self.buttonHover = nil

    if self.gameOver then return end

    -- Check reset button
    if x >= self.screenWidth - 140 and x <= self.screenWidth - 20 and
        y >= 160 and y <= 200 then
        self.buttonHover = "reset"
        return
    end

    -- Check hint button
    if self.hintAvailable and x >= self.screenWidth - 140 and x <= self.screenWidth - 20 and
        y >= 210 and y <= 250 then
        self.buttonHover = "hint"
        return
    end

    -- Check power-up buttons
    local buttonY = 260
    local buttonWidth = 120
    local buttonHeight = 35
    local spacing = 10

    local powerUpsList = {
        self.powerUps.reveal_vowel,
        self.powerUps.second_chance,
        self.powerUps.letter_eliminator
    }

    for i, _ in ipairs(powerUpsList) do
        local buttonX = self.screenWidth - 140
        local currentY = buttonY + (i - 1) * (buttonHeight + spacing)

        if x >= buttonX and x <= buttonX + buttonWidth and
            y >= currentY and y <= currentY + buttonHeight then
            self.buttonHover = "powerup_" .. i
            return
        end
    end
end

return Game
