--[[
    ScoreState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    A simple state used to display the player's score before they
    transition back into the play state. Transitioned to from the
    PlayState when they collide with a Pipe.
]]

ScoreState = Class{__includes = BaseState}

--[[
    When we enter the score state, we expect to receive the score
    from the play state so we know what to render to the State.
]]
function ScoreState:enter(params)
    self.score = params.score

    -- load the trophy_img depending on the score
    if self.score <= 5 then
        self.trophy_img = love.graphics.newImage("trophy-bronze.png")
    elseif self.score <= 14 then
        self.trophy_img = love.graphics.newImage("trophy-silver.png")
    else
        self.trophy_img = love.graphics.newImage("trophy-gold.png")
    end

end

function ScoreState:update(dt)
    -- go back to play if enter is pressed
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('countdown')
    end

    -- controls the background and ground scroll, every frame 
    -- scroll our background and ground, looping back to 0 after a certain amount
    BACKGROUND_SCROLL = (BACKGROUND_SCROLL + BACKGROUND_SCROLL_SPEED * dt) % BACKGROUND_LOOPING_POINT
    GROUND_SCROLL = (GROUND_SCROLL + GROUND_SCROLL_SPEED * dt) % VIRTUAL_WIDTH
end

function ScoreState:render()

    -- render the trophy first
    love.graphics.draw(self.trophy_img
        ,(VIRTUAL_WIDTH / 2 - 55)
        ,(VIRTUAL_HEIGHT / 2 -55))

    -- simply render the score to the middle of the screen
    love.graphics.setFont(flappyFont)
    love.graphics.printf('Oof! You lost!', 0, 64, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(mediumFont)
    love.graphics.printf('Score: ' .. tostring(self.score), 0, 100, VIRTUAL_WIDTH, 'center')

    love.graphics.printf('Press Enter to Play Again!', 0, 160, VIRTUAL_WIDTH, 'center')
end