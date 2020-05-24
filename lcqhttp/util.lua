-- this variable is to signify a field of a table does not exist
local NULL = false

-- the user agent that this bot uses to send requests/responses etc
local user_agent = 'lcqhttp-bot'

local createClass = function(fields, parent)
    fields = fields or {}
    local cls = {}
    for k, v in pairs(fields) do cls[k] = v end

    if parent ~= nil then -- add parent lookup if has parent class
        setmetatable(cls, {
            __index = function(o, k)
                if parent[k] ~= nil then return parent[k] end
            end
        })
    end

    cls.__super = parent
    cls.__index = cls
    function cls:new(...)
        local o = {}
        setmetatable(o, cls)
        o:constructor(...)
        return o
    end

    return cls
end

local timestr = function()
    return os.date("[%Y-%m-%d %H:%M:%S %z]")
end

return {
    NULL = NULL,
    user_agent = user_agent,
    createClass = createClass,
    timestr = timestr
}
