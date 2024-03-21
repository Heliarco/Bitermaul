

---@param number uint32
---@param buckets uint32
---@return uint32[]
local split_number_to_buckets = function(number, buckets)
    local result = {}
    local distributed = 0
    local q = math.floor(number / buckets)
    for i =1,buckets do
        result[i] = q
        distributed = distributed + q
    end
    local remaining = number - distributed
    if remaining > number then error("Math dont math right") end
    for i = 1, remaining do
        result[i] = result[i] + 1
        distributed = distributed + 1
    end
    if distributed ~= number then error("Math not mathing hard enough") end
    return result
end


return {
    split_number_to_buckets = split_number_to_buckets
}