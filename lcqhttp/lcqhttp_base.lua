local cqueues = require 'cqueues'
local lcqhttp = {
    event = require 'lcqhttp.event',
    util = require 'lcqhttp.util'
}

local LCQHTTP_BASE = lcqhttp.util.createClass {
    constructor = function(self, opt)
        self.eventloop = opt.eventloop or cqueues.new()
        self.bot = self
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

    -- 立即生成一个异步调用并且执行，该函数会立即返回。剩余的代码继续执行并且把 http response 返回给插件（仅 http）
    detach = function(self, f, errfun)
        self.eventloop:wrap(function() xpcall(f, errfun) end)
    end,

    -- yield 当前线程直到 secs 秒后返回
    sleep = function(self, secs)
        cqueues.sleep(secs)
    end
}

return {
    LCQHTTP_BASE = LCQHTTP_BASE
}
