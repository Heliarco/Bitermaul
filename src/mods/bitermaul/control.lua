require("map_generation")
require("forces")


local function oninit(event)
  hook_map_gen()
  setup_forces()
end

local function onload(event)
  hook_map_gen()
  setup_forces()
end

if script.level.level_name == "bitermaul" then
  script.on_init(oninit)
  script.on_load(onload)
end
