-- We need to clean up a lot of existing recipes now.
-- Its a total conversion, not an extension

function startswith(str, start)
    return str:sub(1, #start) == start
end


for _,recipe in pairs(data.raw.recipe) do
    if  startswith(recipe.name,"bitermaul") then
        print("hi")
    else
        recipe.enabled = false
        if recipe.normal then
            recipe.normal.enabled = false
        end
        if recipe.expensive then
            recipe.expensive.enabled = false
        end
    end
  end