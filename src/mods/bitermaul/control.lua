require("map_generation")

local function oninit(event)
  hook_map_gen()
end

local function onload(event)
  hook_map_gen()  
end

if script.level.level_name == "bitermaul" then
  script.on_init(oninit)
  script.on_load(onload)
end