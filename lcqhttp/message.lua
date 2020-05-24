-- 对消息进行CQ码转义操作
local cq_escape = function(s)
    local r = s:gsub(',', '&#44;')
        :gsub('[', '&#91;')
        :gsub(']', '&#93;')
        :gsub('&', '&amp;')
    return r
end

-- 对消息进行CQ码去转义操作
local cq_unescape = function(s)
    local r = s:gsub('&#44;', ',')
        :gsub('&#91;', '[')
        :gsub('&#93;', ']')
        :gsub('&amp;', '&')
    return r
end

return {
    cq_escape = cq_escape,
    cq_unescape = cq_unescape
}
