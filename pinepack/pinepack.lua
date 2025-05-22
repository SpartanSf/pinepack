local char = string.char
local type = type
local sub = string.sub
local tconcat = table.concat

local basedictcompress = {}
local basedictdecompress = {}
for i = 0, 255 do
    local ic, iic = char(i), char(i, 0)
    basedictcompress[ic] = iic
    basedictdecompress[iic] = ic
end

local function dictAddA(str, dict, a, b)
    if a >= 256 then
        a, b = 0, b+1
        if b >= 256 then
            dict = {}
            b = 1
        end
    end
    dict[str] = char(a,b)
    a = a+1
    return dict, a, b
end

local function compress(input)
    if type(input) ~= "string" then
        return nil, "string expected, got "..type(input)
    end
    local len = #input
    if len <= 1 then
        return "u"..input
    end

    local dict = {}
    local a, b = 0, 1

    local result = {"c"}
    local resultlen = 1
    local n = 2
    local word = ""
    for i = 1, len do
        local c = sub(input, i, i)
        local wc = word..c
        if not (basedictcompress[wc] or dict[wc]) then
            local write = basedictcompress[word] or dict[word]
            if not write then
                return nil, "algorithm error, could not fetch word"
            end
            result[n] = write
            resultlen = resultlen + #write
            n = n+1
            if  len <= resultlen then
                return "u"..input
            end
            dict, a, b = dictAddA(wc, dict, a, b)
            word = c
        else
            word = wc
        end
    end
    result[n] = basedictcompress[word] or dict[word]
    resultlen = resultlen+#result[n]
    n = n+1
    if  len <= resultlen then
        return "u"..input
    end
    return tconcat(result)
end

local function dictAddB(str, dict, a, b)
    if a >= 256 then
        a, b = 0, b+1
        if b >= 256 then
            dict = {}
            b = 1
        end
    end
    dict[char(a,b)] = str
    a = a+1
    return dict, a, b
end

local function decompress(input)
    if type(input) ~= "string" then
        return nil, "string expected, got "..type(input)
    end

    if #input < 1 then
        return nil, "invalid input - not a compressed string"
    end

    local control = sub(input, 1, 1)
    if control == "u" then
        return sub(input, 2)
    elseif control ~= "c" then
        return nil, "invalid input - not a compressed string"
    end
    input = sub(input, 2)
    local len = #input

    if len < 2 then
        return nil, "invalid input - not a compressed string"
    end

    local dict = {}
    local a, b = 0, 1

    local result = {}
    local n = 1
    local last = sub(input, 1, 2)
    result[n] = basedictdecompress[last] or dict[last]
    n = n+1
    for i = 3, len, 2 do
        local code = sub(input, i, i+1)
        local lastStr = basedictdecompress[last] or dict[last]
        if not lastStr then
            return nil, "could not find last from dict. Invalid input?"
        end
        local toAdd = basedictdecompress[code] or dict[code]
        if toAdd then
            result[n] = toAdd
            n = n+1
            dict, a, b = dictAddB(lastStr..sub(toAdd, 1, 1), dict, a, b)
        else
            local tmp = lastStr..sub(lastStr, 1, 1)
            result[n] = tmp
            n = n+1
            dict, a, b = dictAddB(tmp, dict, a, b)
        end
        last = code
    end
    return tconcat(result)
end

local function pack_model_data(model)
    local assembled_list = {scale = 1, data = {}, flags = {}}

    for _, polygon in ipairs(model) do
        table.insert(assembled_list.data, polygon.x1)
        table.insert(assembled_list.data, polygon.y1)
        table.insert(assembled_list.data, polygon.z1)
        table.insert(assembled_list.data, polygon.x2)
        table.insert(assembled_list.data, polygon.y2)
        table.insert(assembled_list.data, polygon.z2)
        table.insert(assembled_list.data, polygon.x3)
        table.insert(assembled_list.data, polygon.y3)
        table.insert(assembled_list.data, polygon.z3)

        table.insert(assembled_list.flags, {
            forceRender = polygon.forceRender,
            c = polygon.c,
            outlineColor = polygon.outlineColor
        })
    end

    local max_decimal_places = 0

    for _, value in ipairs(assembled_list.data) do
        local _, fractional = math.modf(value)
        if fractional ~= 0 then
            local str = string.format("%.15f", fractional)
            str = string.gsub(str, "0+$", "")
            local decimal_part = string.match(str, "%.(%d+)")
            if decimal_part then
                max_decimal_places = math.max(max_decimal_places, #decimal_part)
            end
        end
    end

    local scaleFactor = 10 ^ max_decimal_places

    assembled_list.scale = scaleFactor

    for i, polygon_data in ipairs(assembled_list.data) do
        assembled_list.data[i] = polygon_data * scaleFactor
    end

    return compress(textutils.serialise(assembled_list, { compact = true }))
end

local function unpack_model_data(serialized_data)
    local raw = textutils.unserialise(decompress(serialized_data))
    local scale = raw.scale or 1
    local data = raw.data
    local flags = raw.flags

    local model = {}

    for i = 1, #data, 9 do
        local polygon_index = math.floor((i - 1) / 9)

        local flag = flags[polygon_index + 1]
        local polygon = {
            x1 = data[i] / scale,
            y1 = data[i + 1] / scale,
            z1 = data[i + 2] / scale,
            x2 = data[i + 3] / scale,
            y2 = data[i + 4] / scale,
            z2 = data[i + 5] / scale,
            x3 = data[i + 6] / scale,
            y3 = data[i + 7] / scale,
            z3 = data[i + 8] / scale,

            forceRender = flag.forceRender,
            c = flag.c,
            outlineColor = flag.outlineColor
        }

        table.insert(model, polygon)
    end

    return model
end


local function pack_file(path)
    local file = fs.open(path, "r")
    local data = file.readAll()
    file.close()
    data = textutils.unserialise(data)

    return pack_model_data(data)
end

local function pack_model(model)
    return pack_model_data(model)
end

local function unpack_file(path)
    local file = fs.open(path, "r")
    local data = file.readAll()
    file.close()

    return unpack_model_data(data)
end

local function unpack_model(model)
    return unpack_model_data(model)
end

return {
    pack_file = pack_file,
    pack_model = pack_model,
    unpack_file = unpack_file,
    unpack_model = unpack_model
}
