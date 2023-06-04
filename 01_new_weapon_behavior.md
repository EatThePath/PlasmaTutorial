For this first tutorial I'm showing the steps I went through to make a simple script for Lunar Sage/Strygon. The request was to make a top-attack missile for a possible ground level; the missile should fly towards a target more or less level with the ground, then when close to the target it flys sharply upwards before finally diving down to hit the top of the target.

Whenever I'm confronted with a weapon where you can divide it's behavior up into distinct stages, I reach for the spawn mechanics. In this case I made three copies of the retail Interceptor, with a few adjustments. Here is a condensed version of the weapon table showing only how they deviate from the interceptor.

```
$Name: Stage1
$Detonation Radius: 500
$Cargo Size: 0.05
$Flags: ( "spawn stage2,1" "no lifeleft penalty" )
$Trail:
 +Start Width: 10.25
 +Max Life: 10.7
$Spawn Angle: 0.0001

$Name: Stage2
$Detonation Range: 400
$Homing: YES
 +Turn Time: 0.01
 +View Cone: 360
$Flags: ( "spawn stage3,1" "no lifeleft penalty" "inherit parent target" "child" )
$Trail:
 +Start Width: 10.25
 +Max Life: 10.7
$Spawn Angle: 0.0001

$Name: Stage3
$Homing: YES
 +Turn Time: 0.1
 +View Cone: 360
$Flags: ( "no lifeleft penalty" "inherit parent target" "child")
$Trail:
 +Start Width: 10.25
 +Max Life: 10.7
```

For the first stage I make it very small so we can carry a bunch for testing, and I add the spawn data. The spawn angle ensures the next stage keeps going in the same direction, the no lifeleft flag keeps it from dying early if I do something funky, and detonation range makes it deploy the next stage after flying a given distance. For a game-ready weapon you'd probably use radius instead, for distance to target. I also slap a big trail on it to see what it's doing more easily.

For the second stage, I'm hoping I'll be able to lead it around with scripting so I give it a huge view cone and quick turning to keep it from losing it's target. It also uses detonation range. It of course also has spawn data for the third stage.

The third stage is very much the same as the second besides not spawning anything.

Mod files for this test also include a ship table to allow use of this weapon, and a simple mission where we have our fighter and something to shoot.

## Our module

All our background out of the way it's time to create our script module file. This takes the form of `mod:data/scripts/plasma_modules/tam.lua`, TAM for Top Attack Missile. For starters this file can consist entirely of:

```lua
return {}
```

Traditionally you'd also need at least one other file, a `-sct.tbm` file, to tell the engine what to do with your script. For us Plasma Core has that covered. On game start Plasma Core finds and attempts to load any scripts in the scripts/plasma_modules folder, and our basic file is enough for it to work with. From then on we can reload.

# Finally, we code
Alright, it's time to get started on the actual module development process.But there is one quirk of my example code I must mention before getting fully into it...


This code:
```lua
local module  = {}

function module:echo()
  ba.print("echo ".. self.v)
end

function module:echo2(value)
  self.v = value
  self:echo()
  self.v = ' '
end

return module
```
and this code:

```lua
local function echo(self)
  ba.print("echo ".. self.v)
end

local function echo2(self, value)
  self.v = value
  echo(self)
  self.v = ' '
end

return {echo = echo, echo2 = echo2}
```

Create practically identical plasma core modules. The first version is typical of what you'd see in any random FSO script you might grab. The second version is the form I currently favor, despite the arguably ugly return statement. I've many small reasons, consider it personal taste.

## The initial module

The basic tam.lua described above is honestly a bit too basic. Before we start the game for the first time, I'll flesh it out a little more.

```lua
--Called whenever any weapon is created
local function tam_on_create(self)
end

local function hook(self, core)
  --Could use a condition table to only fire on the weapons we want but I didn't remember how to format those off the top of my head. so lets keep it simple
  core.add_hook(self, "tam_on_create", "On Weapon Created")
end


--returns this module's table of externally accessible members, required for the framework
return {tam_on_create = tam_on_create, hook = hook}
```

Right away, there's something to explain for both new and old scripters. FSO scripting often hinges on attaching functions to code "hooks". This says to the engine "Whenever you do this thing, run this code". Traditionally you'd do that in a script table file, but interactive development needs it to be handled a little specially.

When Plasma Core runs at game start it checks all the modules it loads for a function named `hook`, and runs it. Because the engine doesn't have a way for you to remove or replace existing hooks this function is intended to only ever be run once, even if you reload the module. It's possible to add new hooks at runtime via Codekeys, but for this project I'm confident this is the only this hook that will be involved so I put it in the initial script.

When a module's `hook()` is called it is passed the module table itself and the Plasma Core main library. You can name these arguments whatever you want, I always name them `self` and `core` for simplicity.

`core` provides to functions that are either just handy or make the reloading possible, listed out in the Plasma Core [documentation](https://github.com/FSO-Scripters/fso-scripts/blob/master/plasma_core/Readme.md). The `add_hook` function fills the role a script table's hook definitions. You pass it the _name_ of the module function that the hook will call, and the module function with that name must be in your module table (the return statement at the end). This helps ensure that when you reload your script you can update that function, and so long as the name is the same the hook will always call the newest version of it.

In this case, I want to mess with every stage2 and stage3, so running code from "On Weapon Created" seems like a good way to get access to them reliably. At this stage I don't know exactly what I'm going to do with them, but I can still make my empty function and flesh it out later.

Alright. Finally, we can launch the game! When we do fs2_open.log will have messages roughly like this:

```
fennel searcher compiled plasma_core.fnl

plasma core scan started
plasma core scan attempting to load tam

*: Module tamFirst load
Module tam running hook
done setting up tam
plasma core scan attempting to load codekeys

fennel searcher compiled codekeys.fnl
*: Module codekeysFirst load
Module codekeys running configure
Module codekeys running hook
done setting up codekeys
plasma core scan done
```
There may be more, or less, depending on how much I've compulsively fiddled with the log verbosity since uploading 0.11, but that basic info should be there. The important thing is there's no errors. 

Now in the test mission I can lock on with my test missile and fire. Since I left all the explosion effects on all the stages, I can see it fly straight to the target, blow up three times on the way, and finally hit the target. 

The script doesn't do anything, and that's ok. We know for certain that we didn't make any simple-ass typos in the boilerplate and can get started adding to that foundation!

So if we look in the scripting documentation (see the flags in the setup section if you don't know where that is) we can see hooks have 'hook variables', values that are acessible to code running in that hook. This is how we'll get ahold of our missiles to fiddle with.

Especially when it's so cheap to do so, I like to apply "trust but verify" to programming, so lets do that here. I'll add a bit of code that ensures that hook variable does what I expect it to.

```lua
local core = require("plasma_core")
local print = core.print

local function tam_on_create(self)
  --API functions and variables do not have what I consider to be a nice consistent style
  --  so I try to always bind them to locals to keep my code clean.
  local weapon = hv.Weapon
  --this is plasma_core's print function and results may differ if you use engine base print
  print(weapon)
end

local function hook(self, core)
  core.add_hook(self, "tam_on_create", "On Weapon Created")
end

return {tam_on_create = tam_on_create, hook = hook}
```

This will also serve as a test that codekeys and reload are working right. I save the modified tam.lua, switch to game, hit 0 to clean the log and 9 to reload scrips, then fire a missile and check the log after it finishes flight.

```
fennel searcher compiled plasma_core.fnl
*: Module tam already loaded, merging
done setting up tam
fennel searcher compiled codekeys.fnl
*: Module codekeys already loaded, merging
Module codekeys running configure
done setting up codekeys
*: is userdata
*: is userdata
*: is userdata
```

So we can see that the reload happened and had no errors, and a message was printed for each of our three missiles that were created. In this case the `weapon` variable is a `userdata`, which is to say it's an object defined and managed by the FSO scripting API, not the lua standard. This is normal and fine, it's what we should expect in this case, it just also means that there's generally no way to turn it into a string cleanly, so pcore's print will just state the type and move on.

We're going to want to do specific things to different types of weapons, so if we check the documentation we can see that weapons have a Class value, also a userdata, and that class should have a name which we can print.

```lua
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
```
reload, fire, and...
```
*: Stage1
*: Stage2
*: Stage3
```

For the next step I'm going to want to mess with only the Stage2 when it's created. To do that I'm going to make a new function that contains whatever we're going to do to it, and only call it for the weapon we want to deal with.
```lua
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

return {tam_on_create = tam_on_create, hook = hook}
```
The returned 'export table' at the end doesn't need to have `pop` added to it. Nothing outside this module needs to be able to call it, and all internal references will be updated on reloads. This means the export table becomes an automatic summary of parts of the module that other things can touch directly, which is one reason I favor this style.

Two things worth mentioning about this code...
1. There are better ways to make a weapon-specific hook, which I'll cover at the end of this tutorial, but for now I'm sticking to this for reasons I'll also cover then.
2. If you've got a programming background `w_name == "Stage2"` may be raising your blood pressure. In most languages comparing strings is exceptionally slow and teaching people to do it is sloppy at best. However Lua is specialized to avoid this cost. If you have to create a string, like building one out of pieces, that can be very slow, but for cases like this one it's perfectly fine.

Anyway, if we reload and test this code...

```
*: Stage1
*: Stage2
*: pop
*: Stage3
```

It works, good.

So we've got the stage2 creation isolated, what are we going to do with it?

My first idea is to take fairly direct control of the missile's AI or physics and mess with it. Looking through the scripting documentation to find ways to do this, it helps to keep in mind that there's some class inheritance going on. What that means specifically is that every `weapon` object is also an `object` object(yes, having an object type named `object` can get confusing. We're stuck with it). And that means any of the values or functions in the `object` documentation also apply to our `weapon`, and objects have an `Orientation`.

we can access it like so.

```lua
local function pop(weapon)
  local orientation = weapon.Orientation
  --but right now we just want to see that it's working
  print(orientation)
end
```

I'll spare you the blow by blow trial and error, but this ultimately doesn't work out. I wanted to still mention inheritance and show a bit of how sometimes the idea just doesn't pan out, but I tried several ways to mess with orientation and none of them worked. There probably is a way to do it this way still, but it goes past the level of complexity I am ready to tackle here.

So now what?

I go back to the scripting docs and skim/search through potentially relevant spelling sections, until I see this in `weapon`:
```
object HomingObject = object
    Object that weapon will home in on. Value may also be a deriviative of the 'object' class, such as 'ship'
    Value: Object that weapon is homing in on, or an invalid object handle if weapon is not homing or the weapon handle is invalid

vector HomingPosition = vector
    Position that weapon will home in on (World vector), setting this without a homing object in place will not have any effect!
    Value: Homing point, or null vector if weapon handle is invalid

subsystem HomingSubsystem = subsystem
    Subsystem that weapon will home in on.
    Value: Homing subsystem, or invalid subsystem handle if weapon is not homing or weapon handle is invalid
```

I think I can work with this. If we get the location of the target ship, then set a new homing location based on it for stage2, we should be in business.

Again, for this live development workflow we can test each step along the way, so breaking it down, we first need to get the target's position.

Nothing else is changing, so here's the new `pop`

```lua
local function pop(weapon)
  --should be a userdata.
  local target = weapon.Target
  print(target)
  --The weapon may be fired without a target or the target may die, so check that it's good when we get here.
  if target:isValid() then
    local target_position = target.Position
    --should be a userdata.
    print(target_position)
    --lets see where it is.
    print(" ".. target_position.x .. " ".. target_position.y .. " "..target_position.z)
  end
end
```
New log after testing:
```
*: is userdata
*: is userdata
*:  -49.400001525879 0 1000
```
exact position will vary but, there we go.

From here, we need to move the target position. I'm going to make a copy of the target position to do this, because the FSO API is somewhat unpredictable about if a userdata is a value or a reference to a value. What that could mean here is that if I do:

```lua
local p = target.Position
p.y=p.y+10
```

I could conceivably be modifying the target's actual current position! I'm pretty sure that's not the case here, but it's a class of problem I try to be in the habit of guarding against. So, lets do this:
```lua
local function pop(weapon)
  local target = weapon.Target
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
```
the log after testing,
```
*:  -49.400001525879 0 1000
*:  -49.400001525879 100 1000
```

But more importantly, we can see the missile pop up and then descend! 

One oddity is that the missile flies up to over the ship's center of mass no matter what subsystem it's targeting. Unfortunately, any attempt I've made to fix that hasn't panned out.

A different refinement that does work is to scale the flight path based on the target's size.

```lua
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
```

And it works. 

Here's the final full script:

```lua
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
    pop(weapon)
  end
end

--Used by the framework to attach event hooks
local function hook(self, core)
  --Could use a condition table to only fire on the weapons we want but I don't remeber how to format those off the top of my head.
  core.add_hook(self, "tam_on_create", "On Weapon Created")
end

--returns this module's table of externally accessible members, required for the framework
return {tam_on_create = tam_on_create, hook = hook}
```

And there you have it. I didn't have to restart the game once through the whole thing, and I have my new gameplay mechanic functional. For bigger tasks of course you'll usually need to do more planning than this, but you'll typically be able to prototype individual bits of whatever you're doing this way and then assemble them.

Finally, I think seeing it in action is demonstrative of the fluidity of this, so you can see me walk through the steps in-game at https://youtu.be/bTUhI7lHjo4

# Cleanup

The approach used here is a bit crude, partly by design. Before closing out, lets look at what a cleaner, finalized version looks like. First, I'm going to change hook.

```lua
local function hook(self, core)
  --Now using a condition table to ensures the hook only runs for this specific weapon.
  core.add_hook(self, "tam_on_create", "On Weapon Created",
                    {
                      State = "GS_STATE_GAME_PLAY",
                      ["Weapon class"] = "Stage2"
                    })
  print("success")
end
```

The new thing being passed into ```add_hook``` is the conditions table. It tells the engine when you want to run your hook, so this tells it we only want to run it during the gameplay, not during the menus or anywhere else, and what weapon to run it for. The game state in this case is a bit redundant as weapons aren't being created in other states, but it's good practice to constrain the state and even the application(FSO vs FRED) for safety.

With that we can slim down the rest of the logic further. `pop` vanishes, and `tam_on_create` becomes...

```lua
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
```

of course, since we've modified the hook this change does require a game restart to take effect. If we simply do a script reload with this change, now every stage of the missile will fly to the 'pop-up' position. But if we restart the game it all clears up properly

During development I tend to use few if any conditions for most of the process. This is partly due to personal familiarity, but also because doin the conditions checks myself allows for some flexibility. If in developing this script I'd decided I wanted to do something funky with stage 1 or 3, with the original approach I could have done so easily, but if I'd used conditions I'd need to restart the game.

But once you hit the end of development hook conditions can make your scripts run faster and in some cases be easier to read when someone else needs to make edits, or when you yourself come back after enough time has passed. 