require("map_generation")

local function oninit(event)
  -- The crash site fucks with map gen, we remove it
  remote.call("freeplay", "set_disable_crashsite", true)
  hook_map_gen()
end

local function onload(event)
  hook_map_gen()  
end

if script.level.level_name == "freeplay" then
  script.on_init(oninit)
  script.on_load(onload)
end