local data = {
    money_increases = {
        10
    },
    
    waves = {
        {
            batches = 10,
            amount_pr_batch = 2,
            delay_between_batches = 60,
            coins = 100,
            enemy_name = "small-biter"
        },
        {
            batches = 20,
            amount_pr_batch = 2,
            delay_between_batches = 40,
            coins = 200,
            enemy_name = "small-spitter"
        },
        {
            batches = 30,
            amount_pr_batch = 2,
            delay_between_batches = 30,
            coins = 300,
            enemy_name = "medium-biter"
        },
        {
            batches = 40,
            amount_pr_batch = 2,
            delay_between_batches = 20,
            coins = 400,
            enemy_name = "medium-spitter"
        }
    }
}

-- Do some quick data validation
for index, value in ipairs(data.waves) do
    if type(value.amount_pr_batch) ~= "number" or value.amount_pr_batch < 1 then
        error("Expected a positive integer on wave: " .. tostring(index) .. " amount_pr_batch")
    end
    if type(value.batches) ~= "number" or value.batches < 1 then
        error("Expected a positive integer on wave: " .. tostring(index) .. " batches")
    end
    if type(value.delay_between_batches) ~= "number" or value.delay_between_batches < 1 then
        error("Expected a positive integer on wave: " .. tostring(index) .. " delay_between_batches")
    end
end


return data