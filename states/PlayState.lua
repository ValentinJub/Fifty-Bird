--[[
    PlayState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The PlayState class is the bulk of the game, where the player actually controls the bird and
    avoids pipes. When the player collides with a pipe, we should go to the GameOver state, where
    we then go back to the main menu.
]]

PlayState = Class{__includes = BaseState}

PIPE_SPEED = 60
PIPE_WIDTH = 70
PIPE_HEIGHT = 288
-- size of the base gap between pipes
PIPE_GAP_HEIGHT = 150

BIRD_WIDTH = 38
BIRD_HEIGHT = 24


-- randomize the gap between pipes
local function randomizeGap(min, max)
    local randomNumber = math.random(min,max)
    return PIPE_GAP_HEIGHT + randomNumber
end

-- increase the speed scroll of the game
local function increaseGameSpeed()
    PIPE_SPEED = PIPE_SPEED * 1.1
    GROUND_SCROLL_SPEED = GROUND_SCROLL_SPEED * 1.1
    BACKGROUND_SCROLL_SPEED = BACKGROUND_SCROLL_SPEED * 1.1
end

-- reset the speed scroll of the game
local function resetGameSpeed()
    PIPE_SPEED = 60
    GROUND_SCROLL_SPEED = 60
    BACKGROUND_SCROLL_SPEED = 30
end

function PlayState:init()
    self.bird = Bird()
    self.pipePairs = {}
    self.timer = 0
    self.score = 0

    -- keep a min, max value used in random pipe gap generation
    self.min = -10
    self.max = 20
    -- keep track of time for pipe gap height
    self.timePassed = 0

    -- interval at which pipes are spawned
    self.pipeSpawnSpeed = 3

    -- initialize our last recorded Y value for a gap placement to base other gaps off of
    self.lastY = -PIPE_HEIGHT + math.random(80) + 20

    -- initialize pause to false
    self.pause = false

    -- set the game speed to default values
    resetGameSpeed()
end

function PlayState:isPaused()
    return self.pause
end

function PlayState:setPause()
    if self.pause then
        self.pause = false
    else 
        self.pause = true
    end
end

function PlayState:update(dt)

    if love.keyboard.wasPressed("p") then
        self:setPause()
        if self:isPaused() then
            love.audio.pause(sounds["music"])
        else
            love.audio.play(sounds["music"])
        end
    end

    if not self:isPaused() then
    
        -- controls the background and ground scroll, every frame 
        -- scroll our background and ground, looping back to 0 after a certain amount
        BACKGROUND_SCROLL = (BACKGROUND_SCROLL + BACKGROUND_SCROLL_SPEED * dt) % BACKGROUND_LOOPING_POINT
        GROUND_SCROLL = (GROUND_SCROLL + GROUND_SCROLL_SPEED * dt) % VIRTUAL_WIDTH 

        -- update timer for pipe spawning
        self.timer = self.timer + dt

        -- increase time passed each frame
        self.timePassed = self.timePassed + dt

        -- every 10 seconds, decrease:
        -- the pipe height gap random size
        -- the pipes horizontal gap size
        if self.timePassed > 10 then
            self.min = self.min + -10
            self.max = self.max + -10
            -- reset timePassed counter
            self.timePassed = 0

            increaseGameSpeed()

            -- reduces the horizontal pipe gap
            if self.pipeSpawnSpeed <= 0 then
                self.pipeSpawnSpeed = 0
            else
                self.pipeSpawnSpeed = self.pipeSpawnSpeed * 0.8
            end
        end

        -- spawn a new pipe pair every second and a half
        if self.timer > self.pipeSpawnSpeed then
            -- modify the last Y coordinate we placed so pipe gaps aren't too far apart
            -- no higher than 10 pixels below the top edge of the screen,
            -- and no lower than a gap length (90 pixels) from the bottom
            local y = math.max(-PIPE_HEIGHT + 10, 
                math.min(self.lastY + math.random(-20, 20), VIRTUAL_HEIGHT - 90 - PIPE_HEIGHT))
            self.lastY = y

            -- randomize a pipe gap that gets tinier as time passes
            local gap = randomizeGap(self.min, self.max)

            -- add a new pipe pair at the end of the screen at our new Y
            table.insert(self.pipePairs, PipePair(y, gap))

            -- reset timer
            self.timer = 0
        end

        -- for every pair of pipes..
        for k, pair in pairs(self.pipePairs) do
            -- score a point if the pipe has gone past the bird to the left all the way
            -- be sure to ignore it if it's already been scored
            if not pair.scored then
                if pair.x + PIPE_WIDTH < self.bird.x then
                    self.score = self.score + 1
                    pair.scored = true
                    sounds['score']:play()
                end
            end

            -- update position of pair
            pair:update(dt)
        end

        -- we need this second loop, rather than deleting in the previous loop, because
        -- modifying the table in-place without explicit keys will result in skipping the
        -- next pipe, since all implicit keys (numerical indices) are automatically shifted
        -- down after a table removal
        for k, pair in pairs(self.pipePairs) do
            if pair.remove then
                table.remove(self.pipePairs, k)
            end
        end

        -- simple collision between bird and all pipes in pairs
        for k, pair in pairs(self.pipePairs) do
            for l, pipe in pairs(pair.pipes) do
                if self.bird:collides(pipe) then
                    sounds['explosion']:play()
                    sounds['hurt']:play()

                    gStateMachine:change('score', {
                        score = self.score
                    })
                end
            end
        end

        -- update bird based on gravity and input
        self.bird:update(dt)

        -- reset if we get to the ground
        if self.bird.y > VIRTUAL_HEIGHT - 15 then
            sounds['explosion']:play()
            sounds['hurt']:play()

            gStateMachine:change('score', {
                score = self.score
            })
        end
    end
end

function PlayState:render()
    for k, pair in pairs(self.pipePairs) do
        pair:render()
    end

    love.graphics.setFont(flappyFont)
    love.graphics.print('Score: ' .. tostring(self.score), 8, 8)

    self.bird:render()

    -- render the pause menu
    if self:isPaused() then
        -- render count big in the middle of the screen
        love.graphics.setFont(hugeFont)
        love.graphics.printf("Pause", 0, 120, VIRTUAL_WIDTH, 'center')
    end
end

--[[
    Called when this state is transitioned to from another state.
]]
function PlayState:enter()
    -- if we're coming from death, restart scrolling
    scrolling = true
end

--[[
    Called when this state changes to another state.
]]
function PlayState:exit()
    -- stop scrolling for the death/score screen
    scrolling = false
end