
--!native
--!strict

local Chaconne = require(game.ReplicatedStorage.Chaconne)
local cell = Chaconne.cell
local formula = Chaconne.formula

-- Initialize a state object that counts kills.
local kills = cell(0)
-- Derive a state called `points` that depends on the amount of kills you have.
local points = formula(function(use)
	return use(kills) * 10
end)
-- Derive a state whose value is a string which says how much you've earned
-- of the previous states (and is therefore depended on those states).
local progressText = formula(function(use)
    return `You have {use(points)} points and {use(kills)} kills.`
end)

-- Subscribe the print function so that every update to the
-- `progressText` is printed out to the console.
progressText:subscribe(print)
kills:set(1) --> You have 10 points and 1 kills.
kills:set(2) --> You have 10 points and 2 kills.
             --> You have 20 points and 2 kills.
-- ^^^ It prints out twice because as `kills` updates, it also 
--     updates `points`, both of which `progressText` is dependent on.
points:dispose()
kills:set(3) --> You have nil points and 3 kills.
-- ^^^ disposed states that used by derived cells will have their values fallback to `nil`.
kills:dispose()
progressText:dispose()