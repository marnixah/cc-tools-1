--[[
    Invocation script for fredio applications.

    Automatically creates an event loop, imports the
    given program and runs it in a coroutine.
]]

loop = libfredio.EventLoop()
if arg[1] == nil then
    print("Usage: astart.lua <program>")
    os.exit(1)
end

-- Find executable in path
local executable = nil
local path_entries = string.gmatch(shell.path(), "[^:]+")
for path_entry in path_entries do
    local full_path = path_entry .. "/" .. arg[1]
    local full_path_lua = full_path .. ".lua"
    if fs.exists(full_path) and not fs.isDir(full_path) then
        executable = full_path
        break
    end
    if fs.exists(full_path_lua) and not fs.isDir(full_path_lua) then
        executable = full_path_lua
        break
    end
end

if executable == nil then
    print("Could not find executable " .. arg[1])
    os.exit(1)
end

local _f = libfredio.async(function (path)
    dofile(path)
end)

loop.task(_f(executable))
loop.run_forever()