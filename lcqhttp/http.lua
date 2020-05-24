local lunajson = require 'lunajson'
local sha1 = require 'sha1'
local http = {
    server = require 'http.server',
}
local lcqhttp = {
    event = require 'lcqhttp.event',
    lcqhttp_base = require 'lcqhttp.lcqhttp_base',
    log = require 'lcqhttp.log',
    httpcontext = require 'lcqhttp.httpcontext',
    util = require 'lcqhttp.util'
}

local LcqhttpApiRequester = lcqhttp.util.createClass {
    -- 用于调用 api 的类，可以单独使用
    constructor = function(self, opt)
        self.apiRoot = opt.apiRoot
        self.accessToken = lcqhttp.util.NULL
        if opt.accessToken then
            self.accessToken = 'Token '..opt.accessToken
        end
    end,
    -- 调用 api，返回结果
    api = function(self, apiname, content)
        local path = self.apiRoot..'/'..apiname
        local str = lunajson.encode(content)
        local task = lcqhttp.httpcontext.OutgoingHttpRequest:new(path, 'POST', str)
        task.req.headers:upsert('Content-Type', 'application/json')
        if self.accessToken then
            task.req.headers:upsert('Authorization', self.accessToken)
        end
        task:go()

        if not task.responded then
            lcqhttp.log.error('unable to connect %s: connection timed out', path)
            return
        end
        local status = task.res.headers:get ':status'
        if status ~= '200' or task.res.body == nil then
            lcqhttp.log.error('unable to post %s: status code %d', path, status)
            return
        end
        local resj = lunajson.decode(task.res.body)
        if resj['status'] ~= 'ok' and resj['status'] ~= 'async' then
            lcqhttp.log.error('action failed: %d', resj['retcode'])
            return
        end

        return resj['data']
    end,
}

local LCQHTTP_HTTP = lcqhttp.util.createClass ({

    -- 创建一个 http bot 对象
    constructor = function(self, opt)
        self.__super.constructor(self, opt)
        self.apirequester = LcqhttpApiRequester:new({
            apiRoot = opt.apiRoot,
            accessToken = opt.accessToken
        })
        self.secret = opt.secret or lcqhttp.util.NULL
        self.host = opt.host
        self.port = opt.port
        self.server = lcqhttp.util.NULL
    end,

        -- 开始事件循环
    start = function(self, cb)
        self.server = assert(http.server.listen {
            host = self.host, port = self.port,
            onstream = function(...) self:_handle(...) end,
            onerror = function(...) self:_on_server_error(...) end,
            cq = self.eventloop
        })
        self.server:listen()
        if cb ~= nil then cb() end
        self.server:loop()
        return self
    end,

    -- POST 调用 cqhttp 插件 api，返回响应值或 nil
    api = function(self, apiname, content)
        return self.apirequester:api(apiname, content)
    end,

    _handle_posted_event = function(self, httpctx)
        -- check signature
        if self.secret then
            local computed = sha1.hmac(self.secret, httpctx.req.body)
            if 'sha1='..computed ~= httpctx.req.headers:get 'x-signature' then
                httpctx:respond('401')
                return
            end
        end
        -- request body should be json
        local ok, event = pcall(function() return lcqhttp.event.RawEvent(httpctx.req.body) end)
        if not ok then
            httpctx:respond('400')
            return
        end

        -- response body to be sent back
        local rescontent = {}
        for _, f in pairs(self.callbacks['*']) do f(self, event, rescontent) end
        for _, f in pairs(self.callbacks[event['post_type']]) do f(self, event, rescontent) end

        httpctx.res.headers:append('Content-Type', 'application/json')
        httpctx.res.body = lunajson.encode(rescontent)
        httpctx:respond('200')
    end,

    _handle_others = function(self, httpctx)
        httpctx:respond('404')
    end,

    -- 接受所有 http 请求，封装后分发给各路由
    _handle = function(self, server, stream)
        local httpctx = lcqhttp.httpcontext.IncomingHttpRequest:new(stream)
        httpctx.res.headers:append("Access-Control-Allow-Origin", "*")
        -- 只接受插件发送的 post 请求
        if httpctx.req.headers:get ':method' == 'POST' then
            self:_handle_posted_event(httpctx)
        else
            self:_handle_others(httpctx)
        end
    end,

    _on_server_error = function(self, server, context, op, err, errno)
        -- refer to github.com/daurnimator/lua-http/blob/master/examples/server_hello.lua
        -- for explanation for parameters
        lcqhttp.log.error('%s : %s', tostring(context), err and tostring(err) or '')
    end,

}, lcqhttp.lcqhttp_base.LCQHTTP_BASE)

return {
    LcqhttpApiRequester = LcqhttpApiRequester,
    LCQHTTP_HTTP = LCQHTTP_HTTP
}
