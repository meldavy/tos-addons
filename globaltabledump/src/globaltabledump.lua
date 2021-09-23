local author = 'meldavy'

-- this script dumps _G to a text file for educational purposes. run with DeveloperConsole

-- create dump file and dump a table to it
function tabledump_start(tbl)
    local file = io.open("dump.txt", "a")
    tabledump_printtable(tbl, file)
    file:close()
end

-- gets args of a function as table
function getArgs(fun)
    local args = {}
    local hook = debug.gethook()

    local argHook = function( ... )
        local info = debug.getinfo(3)
        if 'pcall' ~= info.name then return end

        for i = 1, math.huge do
            local name, value = debug.getlocal(2, i)
            if '(*temporary)' == name then
                debug.sethook(hook)
                error('')
                return
            end
            table.insert(args,name)
        end
    end

    debug.sethook(argHook, "c")
    pcall(fun)

    return args
end

-- check if value is in array
function in_array(value, array)
    for index = 1, #array do
        if array[index] == value then
            return index
        end
    end
    return -1
end

-- print table
function tabledump_printtable (tbl, file, indent)
    if not indent then indent = 0 end
    if (indent > 6) then
        -- lets not go too deep into the tree for the sake of file size
        return
    end
    for k, v in pairs(tbl) do
        local indentPrefix = string.rep("    ", indent)
        local prefix = "[" .. tostring(k) .. "]: "
        if type(v) == "table" then
            file:write(indentPrefix .. prefix .. " " .. type(v) .. " {", "\n")
            if (tostring(k) ~= "tolua_ubox" and tostring(k) ~= "_G") then
                -- this takes up too much space, we ignore it
                tabledump_printtable(v, file, indent+1)
            end
            local closingIndentPrefix = string.rep("    ", indent)
            file:write(closingIndentPrefix .. "} // [" .. tostring(k) .. "]", "\n")
        elseif type(v) == 'boolean' then
            file:write(indentPrefix .. prefix .. type(v) .. " = " .. tostring(v), "\n")
        elseif type(v) == 'function' then
            if (string.find(tostring(k), "__", 1, true) == nil) then
                -- ignore default lua methods
                file:write(indentPrefix .. prefix .. type(v) .. "(" .. table.concat(getArgs(v),", ") .. ")", "\n")
            end
        else
            file:write(indentPrefix .. prefix .. type(v) .. " = " .. tostring(v), "\n")
        end
    end
end

tabledump_start(_G)