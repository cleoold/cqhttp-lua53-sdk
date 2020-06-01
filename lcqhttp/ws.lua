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

local LcqhttpWsClient = lcqhttp.util.createClass ({

    -- 创建一个 websocket bot 客户端
    constructor = function(self, opt)
        self.__super.constructor(self, opt)
        self.event_uri = opt.ws_uri..'/event'
        self.api_uri = opt.ws_uri..'/api'
        if opt.access_token then
            local t = http.util.encodeURI(opt.access_token)
            self.event_uri = self.event_uri..'?access_token='..t
            self.api_uri = self.api_uri..'?access_token='..t
        end
        self.access_token = opt.access_token
        self.recnn_interval = opt.recnn_interval or lcqhttp.util.NULL
        self.conn_timeout = opt.conn_timeout or 5
        self.event_conn = lcqhttp.util.NULL
    end,

    -- 开始事件循环
    start = function(self, cb)
        -- 连接到 /event
        self:detach(function() self:_inconnect_event() end, lcqhttp.log.error)
        if cb ~= nil then cb() end
        self.eventloop:loop()
    end,

    -- WS 调用 cqhttp api. 每次请求单独开设一个链接
    api = function(self, apiname, content)
        self:detach(function()
            local t = lunajson.encode {
                action = apiname, params = content
            }
            local conn = http.ws.new_from_uri(self.api_uri)
            assert(conn:connect(self.conn_timeout))
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
        ::RECONNECT::
        self.event_conn = http.ws.new_from_uri(self.event_uri)
        -- this blocks program forever on wsl if target is offline:
        -- https://github.com/daurnimator/lua-http/issues/168
        if not self.event_conn:connect(self.conn_timeout) then goto ERROR end
        while true do
            -- https://github.com/daurnimator/lua-http/issues/140
            -- begin monky part
            local ok, data = pcall(function() return self.event_conn:receive() end)
            if not ok or (ok and not data) then goto ERROR end
            -- end monky part
            self:detach(function()
                self:_handle_event(data)
            end, lcqhttp.log.error)
        end
        ::ERROR::
        if self.recnn_interval then
            lcqhttp.log.error('cannot establish connection to %s. try reconnecting in %ds',
                self.event_uri, self.recnn_interval)
            self.event_conn:close()
            self:sleep(self.recnn_interval)
            goto RECONNECT
        else
            lcqhttp.log.error('connection dropped')
            os.exit(1)
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
    LcqhttpWsClient = LcqhttpWsClient
}
