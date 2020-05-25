local lcqhttp = {
    http = require 'lcqhttp.http',
    log = require 'lcqhttp.log'
}

-- 创建机器人
local arora = lcqhttp.http.LCQHTTP_HTTP:new({
    apiRoot = 'http://127.0.0.1:8764',
    host = '127.0.0.1',
    port = '8765',
    accessToken = 'accesstoken or nil', -- 可选项
    secret = 'secret or nil' -- 可选项
})

-- 添加全局监听器，此函数会响应所有事件。
-- subscribe 接受回调，第一个参数为 bot，即机器人，第二个 event 是 table
-- 本例中打印 event 的内容
arora:subscribe('*', function(bot, event)
    local sb = {}
    for k,v in pairs(event) do
        table.insert(sb, ('%s: %s'):format(k, v))
    end
    lcqhttp.log.debug('incoming event %s', table.concat(sb, ','))
end)

-- 添加 message 类型的监听器 https://cqhttp.cc/docs/4.15/#/Message
arora:subscribe('message', function(bot, event)
    if event.message_type == 'private' then
        -- 调用 cqhttp api 来发送消息
        bot:api('send_private_msg', {
            user_id = event.sender.user_id,
            message = ('你好！%s 你刚才说了：%s')
                :format(event.sender.nickname, event.raw_message)
        })
    end
    --[[
    当心异常处理！如果你调用了 cqueue 的事件队列来直接返回，函数触发了 error 会造成
    类似于 nodejs 的 "unhandled promise rejection error" 从而直接中止程序
    必要时可以使用 bot:detach 来进行异常捕获。不过一般情况下不需要直接返回
    错误：
    bot.eventloop:wrap(function()
        error('hahaha I crashed')
    end)
    acceptable:
    bot:detach(function()
        error('hahaha I crashed')
    end, lcqhttp.log.error)
    ]]--
end)

-- 添加 request 类型的监听器
-- 这个例子里显示 subscribe 的回调函数还接受 response (table) 参数，这个 table 会在
-- 最后作为响应返回给 cqhttp 插件 https://cqhttp.cc/docs/4.15/#/Post?id=%E5%A5%BD%E5%8F%8B%E6%B7%BB%E5%8A%A0
-- 在 bot:detach 的回调中修改的 response 无效
arora:subscribe('request', function(bot, event, response)
    -- 拒绝好友请求
    if event.request_type == 'friend' then
        response.approve = false
    end
end)

-- 开始服务，这回开始事件循环，事件循环可以在 bot.eventloop 获取以使用 cqueues 来进行其他
-- 异步操作
arora:start(function()
    print('server started!')
end)
