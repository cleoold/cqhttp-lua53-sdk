local lunajson = require 'lunajson'
local http = {
    ws = require 'http.websocket',
    util = require 'http.util'
}
local lcqhttp = {
    event = require 'lcqhttp.event',
    lcqhttp_base = require 'lcqhttp.lcqhttp_base',
    log = require 'lcqhttp.log',
    util = require 'lcqhttp.util'
}

local LCQHTTP_WS_CLIENT = lcqhttp.util.createClass ({

    -- 创建一个 websocket bot 客户端
    constructor = function(self, opt)
        self.__super.constructor(self, opt)
        self.event_uri = opt.ws_uri..'/event'
        self.api_uri = opt.ws_uri..'/api'
        if opt.accessToken then
            local t = http.util.encodeURI(opt.accessToken)
            self.event_uri = self.event_uri..'?access_token='..t
            self.api_uri = self.api_uri..'?access_token='..t
        end
        self.accessToken = opt.accessToken
        self.event_conn = lcqhttp.util.NULL
        self.ws_timeout = 5
    end,

    -- 开始事件循环
    start = function(self, cb)
        -- 连接到 /event
        self:detach(function() self:_inconnect_event() end, lcqhttp.log.error)
        if cb ~= nil then cb() end
        self.eventloop:loop()
    end,

    -- WS 调用 cqhttp api. 链接每次请求单独开设一个链接
    api = function(self, apiname, content)
        self:detach(function()
            local t = lunajson.encode {
                action = apiname, params = content
            }
            local conn = http.ws.new_from_uri(self.api_uri)
            assert(conn:connect(5))
            assert(conn:send(t))
            local recvd = assert(conn:receive())
            local resj = lunajson.decode(recvd)
            assert(conn:close())
            if resj['status'] ~= 'ok' and resj['status'] ~= 'async' then
                lcqhttp.log.error('action failed: %d', resj['retcode'])
                return
            end
        end, lcqhttp.log.error)
    end,

    -- 处理 /event
    _inconnect_event = function(self)
        self.event_conn = http.ws.new_from_uri(self.event_uri)
        -- this blocks program forever on wsl if target is offline:
        -- https://github.com/daurnimator/lua-http/issues/168
        self.event_conn:connect(5)
        while true do
            -- https://github.com/daurnimator/lua-http/issues/140
            local data = self.event_conn:receive()
            self:detach(function()
                self:_handle_event(data)
            end, lcqhttp.log.error)
        end
    end,

    _handle_event = function(self, data)
        local ok, event = pcall(function() return lcqhttp.event.RawEvent(data) end)
        if not ok then
            error(data)
        end
        for _, f in pairs(self.callbacks['*']) do f(self, event) end
        for _, f in pairs(self.callbacks[event['post_type']]) do f(self, event) end
    end

}, lcqhttp.lcqhttp_base.LCQHTTP_BASE)

return {
    LCQHTTP_WS_CLIENT = LCQHTTP_WS_CLIENT
}
