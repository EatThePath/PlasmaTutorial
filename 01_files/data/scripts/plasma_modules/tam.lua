--All the steps allong the script process
--Comment and uncomment chunks(turn a --[[ into a -- [[ or the reverse) to run the script at a given step
-- [[

local core = require("plasma_core")
local print = core.print

--Called whenever any weapon is created
local function tam_on_create(self)
end

local function hook(self, core)
  --Could use a condition table to only fire on the weapons we want but I don't remeber how to format those off the top of my head.
  core.add_hook(self, "tam_on_create", "On Weapon Created")
end

--returns this module's table of externally accessible members, required for the framework
return {tam_on_create = tam_on_create, hook = hook}
--]]

--[[
local core = require("plasma_core")
local print = core.print

local function tam_on_create(self)
  --API functions and variables do not have what I consider to be a nice consistent style
  --  so I try to always bind them to locals to keep my code clean.
  local weapon = hv.Weapon
  print(weapon)
end

local function hook(self, core)
  core.add_hook(self, "tam_on_create", "On Weapon Created")
end

return {tam_on_create = tam_on_create, hook = hook}
--]]

--[[

local core = require("plasma_core")
local print = core.print

local function tam_on_create(self)
  local weapon = hv.Weapon
  local w_class = weapon.Class
  local w_name = w_class.Name
  print(w_name)
end

local function hook(self, core)
  core.add_hook(self, "tam_on_create", "On Weapon Created")
end

return {tam_on_create = tam_on_create, hook = hook}
--]]

--[[

local core = require("plasma_core")
local print = core.print

--For clarity, we make a new function that will actually Do Things to the weapon.
local function pop(weapon)
  --but right now we just want to see that it's working
  print("pop")
end

local function tam_on_create(self)
  local weapon = hv.Weapon
  --to clean things up a little I'm condensing the name grabbing to a single line.
  local w_name = weapon.Class.Name
  print(w_name)
  --and then a simple if condition...
  if w_name == "Stage2" then
    pop(weapon)
  end
end

local function hook(self, core)
  core.add_hook(self, "tam_on_create", "On Weapon Created")
end

--Pop doesn't need to go on the export table, because nothing outside the module needs to touch it.
--whenever the file is reloaded, tam_on_create will point to the new local pop()
return {tam_on_create = tam_on_create, hook = hook}

--]]

--[[

local core = require("plasma_core")
local print = core.print

local function pop(weapon)
  local orientation = weapon.Orientation
  --but right now we just want to see that it's working
  print(orientation)
end


local function tam_on_create(self)
  local weapon = hv.Weapon
  local w_name = weapon.Class.Name
  --don't need this print anymore
  --print(w_name)...
  if w_name == "Stage2" then
    pop(weapon)
  end
end

local function hook(self, core)
  core.add_hook(self, "tam_on_create", "On Weapon Created")
end

return {tam_on_create = tam_on_create, hook = hook}

--]]
--[[

local core = require("plasma_core")
local print = core.print

local function pop(weapon)
  --so a weapon should have a target, generally
  local target = weapon.Target
  print(target)
  --The weapon may be fired without a target or the target may die, so check that it's good when we get here.
  if target:isValid() then
    --should be a userdata.
    print(target_position)
    --lets see where it is.
    print(" ".. target_position.x .. " ".. target_position.y .. " "..target_position.z)
  end
end

local function tam_on_create(self)
  local weapon = hv.Weapon
  local w_name = weapon.Class.Name
  if w_name == "Stage2" then
    pop(weapon)
  end
end

local function hook(self, core)
  core.add_hook(self, "tam_on_create", "On Weapon Created")
end

return {tam_on_create = tam_on_create, hook = hook}
--]]

--[[
local core = require("plasma_core")
local print = core.print

local function pop(weapon)
  local target = weapon.Target
  print(target)
  if target:isValid() then
    local p = target.Position
    local p2 = p:copy()
    p2.y = p2.y + 100
    print(" ".. p.x .. " ".. p.y .. " "..p.z)
    print(" ".. p2.x .. " ".. p2.y .. " "..p2.z)
    weapon.OverrideHoming = true
    weapon.HomingPosition = p2
  end
end

local function tam_on_create(self)
  local weapon = hv.Weapon
  local w_name = weapon.Class.Name
  if w_name == "Stage2" then
    pop(weapon)
  end
end

local function hook(self, core)
  core.add_hook(self, "tam_on_create", "On Weapon Created")
end

return {tam_on_create = tam_on_create, hook = hook}
]]


--[[semi-final script, using target radius to scale the flight]]
--[[
local core = require("plasma_core")
local print = core.print

--Called only for our chosen weapon.
local function pop(weapon)
  local target = weapon.Target
  if target:isValid() then
    local p = target.Position
    local p2 = p:copy()
    p2.y = p2.y + (target.Radius * 3)
    weapon.OverrideHoming = true
    weapon.HomingPosition = p2
  end
end

--Called whenever any weapon is created
local function tam_on_create(self)
  local weapon = hv.Weapon
  local w_name = weapon.Class.Name
  --If this is our special missile, do stuff
  if w_name == "Stage2" then
    if(weapon.Target and weapon.Target:isValid()) then
      pop(weapon)
    end
  end
end

--Used by the framework to attach event hooks
local function hook(self, core)
  --Could use a condition table to only fire on the weapons we want but I don't remeber how to format those off the top of my head.
  core.add_hook(self, "tam_on_create", "On Weapon Created")
end

--returns this module's table of externally accessible members, required for the framework
return {tam_on_create = tam_on_create, hook = hook}
--]]

--Cleanup of the hook after initial development: 
--[[

local core = require("plasma_core")
local print = core.print

--Called whenever our weapon is created
local function tam_on_create(self)
  local weapon = hv.Weapon

  if(weapon.Target and weapon.Target:isValid()) then
    local target = weapon.Target
  
    if target:isValid() then
      local p = target.Position
      local p2 = p:copy()
      p2.y = p2.y + (target.Radius * 3)
      weapon.OverrideHoming = true
      weapon.HomingPosition = p2
    end
  end
end

--Used by the framework to attach event hooks
local function hook(self, core)
  --A condition table ensures only gameplay runs this function.
  core.add_hook(self, "tam_on_create", "On Weapon Created",
      { State = "GS_STATE_GAME_PLAY", 
        ["Weapon class"] = "Stage2"})
  print("success")
end

--returns this module's table of externally accessible members, required for the framework
return {tam_on_create = tam_on_create, hook = hook}

--]]