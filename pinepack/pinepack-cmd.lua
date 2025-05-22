local pinepack = require "pinepack"

local path = "/"..shell.dir()
local args = table.pack(...)

if not args[1] then
    print("Must provide model path to pack or unpack")
    return
end

local model_path = fs.combine(path, args[1])
if not fs.exists(model_path) then
    print("Must provide existing model path to pack or unpack")
    return
end

if (not (args[2] == "pack")) and (not (args[2] == "unpack")) then
    print("Must provide argument \"pack\" or \"unpack\"")
    return
end

if args[2] == "pack" then
    local file = fs.open(model_path..".scm", "w")
    file.write(pinepack.pack_file(model_path))
    file.close()
    print("Sucessfully packed "..model_path)
else
    local file = fs.open(model_path..".model", "w")
    file.write(textutils.serialise(pinepack.unpack_file(model_path)))
    file.close()
    print("Sucessfully unpacked "..model_path)
end
