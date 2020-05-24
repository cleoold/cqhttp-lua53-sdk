local cqueues = require 'cqueues'
local lunajson = require 'lunajson'
local sha1 = require 'sha1'
local http = {
    server = require 'http.server',
}
local lcqhttp = {
    event = require 'lcqhttp.event',
    log = require 'lcqhttp.log',
    httpcontext = require 'lcqhttp.httpcontext',
    util = require 'lcqhttp.util'
}

local LCQHTTP_HTTP = lcqhttp.util.createClass {

    -- 创建一个 http bot 对象
    constructor = function(self, opt)
        self.apiRoot = opt.apiRoot
        self.accessToken = lcqhttp.util.NULL
        if opt.accessToken then
            self.accessToken = 'Token '..opt.accessToken
        end
        self.secret = opt.secret or lcqhttp.util.NULL
        self.host = opt.host
        self.port = opt.port

        self.bot = self
        self.eventloop = cqueues.new()
        self.server = lcqhttp.util.NULL
        -- https://cqhttp.cc/docs/4.15/#/Post
        self.callbacks = { ['*'] = {} }
        for _, type in pairs(lcqhttp.event.types) do self.callbacks[type] = {} end
    end,

    -- 添加事件监听器
    subscribe = function(self, post_type, cb)
        if self.callbacks[post_type] == nil then
            error('subscribe only accepts one of these types: *, '..table.concat(lcqhttp.event.types, ','))
        end
        table.insert(self.callbacks[post_type], cb)
        return self
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

    -- 调用 cqhttp 插件 api
    api = function(self, apiname, content)
        local path = self.apiRoot..'/'..apiname
        local str = lunajson.encode(content)
        local task = lcqhttp.httpcontext.OutgoingHttpRequest(path, 'POST', str)
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
    end,

    -- 立即生成一个异步调用并且执行，该函数会立即返回
    detach = function(self, f)
        self.eventloop:wrap(f)
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

    _handle = function(self, server, stream)
        local httpctx = lcqhttp.httpcontext.IncomingHttpRequest(stream)
        httpctx.res.headers:append("Access-Control-Allow-Origin", "*")
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
}

return {
    LCQHTTP_HTTP = LCQHTTP_HTTP
}
