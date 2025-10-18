-- Hangman Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_sin = math.sin

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local instance = setmetatable({}, Menu)

    instance.screenWidth = 800
    instance.screenHeight = 600
    instance.difficulty = "medium"
    instance.category = "general"
    instance.title = {
        text = "HANGMAN",
        scale = 1,
        scaleDirection = 1,
        scaleSpeed = 0.3,
        minScale = 0.95,
        maxScale = 1.05,
        rotation = 0,
        rotationSpeed = 0.2
    }

    instance.smallFont = love.graphics.newFont(16)
    instance.mediumFont = love.graphics.newFont(22)
    instance.largeFont = love.graphics.newFont(42)
    instance.sectionFont = love.graphics.newFont(18)

    instance:createMenuButtons()
    instance:createOptionsButtons()

    return instance
end

function Menu:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:updateButtonPositions()
    self:updateOptionsButtonPositions()
end

function Menu:createMenuButtons()
    self.menuButtons = {
        {
            text = "Start Game",
            action = "start",
            width = 200,
            height = 45,
            x = 0,
            y = 0
        },
        {
            text = "Options",
            action = "options",
            width = 200,
            height = 45,
            x = 0,
            y = 0
        },
        {
            text = "Quit",
            action = "quit",
            width = 200,
            height = 45,
            x = 0,
            y = 0
        }
    }
    self:updateButtonPositions()
end

function Menu:createOptionsButtons()
    self.optionsButtons = {
        -- Difficulty Section
        {
            text = "Easy",
            action = "diff easy",
            width = 100,
            height = 35,
            x = 0,
            y = 0,
            section = "difficulty"
        },
        {
            text = "Medium",
            action = "diff medium",
            width = 100,
            height = 35,
            x = 0,
            y = 0,
            section = "difficulty"
        },
        {
            text = "Hard",
            action = "diff hard",
            width = 100,
            height = 35,
            x = 0,
            y = 0,
            section = "difficulty"
        },

        -- Category Section
        {
            text = "General",
            action = "cate general",
            width = 120,
            height = 35,
            x = 0,
            y = 0,
            section = "category"
        },
        {
            text = "Animals",
            action = "cate animals",
            width = 120,
            height = 35,
            x = 0,
            y = 0,
            section = "category"
        },
        {
            text = "Science",
            action = "cate science",
            width = 120,
            height = 35,
            x = 0,
            y = 0,
            section = "category"
        },
        {
            text = "Geography",
            action = "cate geography",
            width = 120,
            height = 35,
            x = 0,
            y = 0,
            section = "category"
        },

        -- Navigation
        {
            text = "Back to Menu",
            action = "back",
            width = 160,
            height = 40,
            x = 0,
            y = 0,
            section = "navigation"
        }
    }
    self:updateOptionsButtonPositions()
end

function Menu:updateButtonPositions()
    local startY = self.screenHeight / 2
    for i, button in ipairs(self.menuButtons) do
        button.x = (self.screenWidth - button.width) / 2
        button.y = startY + (i - 1) * 60
    end
end

function Menu:updateOptionsButtonPositions()
    local centerX = self.screenWidth / 2
    local totalSectionsHeight = 250
    local startY = (self.screenHeight - totalSectionsHeight) / 2

    -- Difficulty buttons
    local diffButtonW, diffButtonH, diffSpacing = 100, 35, 15
    local diffTotalW = 3 * diffButtonW + 2 * diffSpacing
    local diffStartX = centerX - diffTotalW / 2
    local diffY = startY + 30

    -- Category buttons (2x2 grid)
    local cateButtonW, cateButtonH, cateSpacing = 120, 35, 15
    local cateTotalW = 2 * cateButtonW + cateSpacing
    local cateStartX = centerX - cateTotalW / 2
    local cateY = startY + 100

    -- Navigation
    local navY = startY + 200

    local diffIndex, cateIndex = 0, 0
    for _, button in ipairs(self.optionsButtons) do
        if button.section == "difficulty" then
            button.x = diffStartX + diffIndex * (diffButtonW + diffSpacing)
            button.y = diffY
            diffIndex = diffIndex + 1
        elseif button.section == "category" then
            button.x = cateStartX + (cateIndex % 2) * (cateButtonW + cateSpacing)
            button.y = cateY + math.floor(cateIndex / 2) * (cateButtonH + 10)
            cateIndex = cateIndex + 1
        elseif button.section == "navigation" then
            button.x = centerX - button.width / 2
            button.y = navY
        end
    end
end

function Menu:update(dt, screenWidth, screenHeight)
    if screenWidth ~= self.screenWidth or screenHeight ~= self.screenHeight then
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self:updateButtonPositions()
        self:updateOptionsButtonPositions()
    end

    -- Update title animation
    self.title.scale = self.title.scale + self.title.scaleDirection * self.title.scaleSpeed * dt

    if self.title.scale > self.title.maxScale then
        self.title.scale = self.title.maxScale
        self.title.scaleDirection = -1
    elseif self.title.scale < self.title.minScale then
        self.title.scale = self.title.minScale
        self.title.scaleDirection = 1
    end

    self.title.rotation = self.title.rotation + self.title.rotationSpeed * dt
end

function Menu:draw(screenWidth, screenHeight, state)
    -- Draw animated title
    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.setFont(self.largeFont)

    love.graphics.push()
    love.graphics.translate(screenWidth / 2, screenHeight / 6)
    love.graphics.rotate(math_sin(self.title.rotation) * 0.05)
    love.graphics.scale(self.title.scale, self.title.scale)
    love.graphics.printf(self.title.text, -screenWidth / 2, -self.largeFont:getHeight() / 2, screenWidth, "center")
    love.graphics.pop()

    if state == "menu" then
        self:drawMenuButtons()
        -- Draw instructions
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.setFont(self.smallFont)
        love.graphics.printf("Guess the word before the hangman is complete!\nPress letter keys to guess.",
            0, screenHeight / 4 + 50, screenWidth, "center")
    elseif state == "options" then
        self:drawOptionsInterface()
    end

    -- Draw copyright
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("© 2025 Jericho Crosby – Hangman", 10, screenHeight - 25, screenWidth - 20, "right")
end

function Menu:drawOptionsInterface()
    local totalSectionsHeight = 250
    local startY = (self.screenHeight - totalSectionsHeight) / 2

    -- Draw section headers
    love.graphics.setFont(self.sectionFont)
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.printf("Difficulty", 0, startY + 5, self.screenWidth, "center")
    love.graphics.printf("Category", 0, startY + 75, self.screenWidth, "center")

    self:updateOptionsButtonPositions()
    self:drawOptionSection("difficulty")
    self:drawOptionSection("category")
    self:drawOptionSection("navigation")
end

function Menu:drawOptionSection(section)
    for _, button in ipairs(self.optionsButtons) do
        if button.section == section then
            self:drawButton(button)

            -- Draw selection highlight
            if button.action:sub(1, 4) == "diff" then
                local difficulty = button.action:sub(6)
                if difficulty == self.difficulty then
                    love.graphics.setColor(0.2, 0.8, 0.2, 0.4)
                    love.graphics.rectangle("fill", button.x - 3, button.y - 3, button.width + 6, button.height + 6, 5)
                end
            elseif button.action:sub(1, 4) == "cate" then
                local category = button.action:sub(6)
                if category == self.category then
                    love.graphics.setColor(0.2, 0.8, 0.2, 0.4)
                    love.graphics.rectangle("fill", button.x - 3, button.y - 3, button.width + 6, button.height + 6, 5)
                end
            end
        end
    end
end

function Menu:drawMenuButtons()
    for _, button in ipairs(self.menuButtons) do
        self:drawButton(button)
    end
end

function Menu:drawButton(button)
    love.graphics.setColor(0.25, 0.25, 0.4, 0.9)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 8, 8)

    love.graphics.setColor(0.6, 0.6, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.mediumFont)
    local textWidth = self.mediumFont:getWidth(button.text)
    local textHeight = self.mediumFont:getHeight()
    love.graphics.print(button.text, button.x + (button.width - textWidth) / 2,
        button.y + (button.height - textHeight) / 2)

    love.graphics.setLineWidth(1)
end

function Menu:handleClick(x, y, state)
    local buttons = state == "menu" and self.menuButtons or self.optionsButtons

    for _, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.width and
            y >= button.y and y <= button.y + button.height then
            return button.action
        end
    end

    return nil
end

function Menu:setDifficulty(difficulty)
    self.difficulty = difficulty
end

function Menu:getDifficulty()
    return self.difficulty
end

function Menu:setCategory(category)
    self.category = category
end

function Menu:getCategory()
    return self.category
end

return Menu