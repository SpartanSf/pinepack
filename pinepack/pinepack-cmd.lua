local path = "/"..shell.dir()
local args = table.pack(...)

if not args[1] then
    print("Must provide model file to pack")
    return
end
