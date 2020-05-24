local lunajson = require 'lunajson'

local types = { 'message', 'notice', 'request', 'meta_event' }

local rtypes = {} do
    for _, v in pairs(types) do rtypes[v] = true end
end

local RawEvent = function(datastr)
    local e = lunajson.decode(datastr)
    if e['post_type'] == nil or rtypes[e['post_type']] == nil then
        error('invalid event')
    end
    return e
end

return {
    RawEvent = RawEvent,
    types = types,
    rtypes = rtypes
}
