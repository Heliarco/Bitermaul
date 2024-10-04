local factory_coin = {
    type = "item",
    name = "bitermaul-factory-coin",
    icon = "__bitermaul__/gfx/icons/gearcoin.png",
    icon_size  = 64,
    subgroup = "raw-material",
    order = "factory-coin",
    stack_size = 1000
}

data:extend{factory_coin}


local coin_recipe = {
    type = "recipe",
    name = "bitermaul-factory-coin",
    enabled = true,
    ingredients =
    {
      {"bitermaul-factory-coin", 2},
    },
    result = "bitermaul-factory-coin"
}

data:extend{coin_recipe}