local lcqhttp = {
    ws = require 'lcqhttp.ws',
    log = require 'lcqhttp.log'
}

-- 创建机器人
local arora = lcqhttp.ws.LcqhttpWsClient.new({
    ws_uri = 'ws://127.0.0.1:6700',
    access_token = 'accesstoken or nil', -- 可选项
    recnn_interval = 1, -- 断线重连间隔时间。可选项，不填则不重连
    conn_timeout = 5 -- ws 建立连接超时时间
})

-- 和 http 模式相同
arora:subscribe('*', function(bot, event)
    if event.post_type == 'meta_event' and event.meta_event_type == 'heartbeat' then
        return
    end
    -- 如果使用 ws，那么在启动程序时会看到由 cqhttp 插件发送的 connect event，如果
    -- 没有看到并且程序也没有报错，那么你可能遇到了 wsl 的 bug
    -- https://github.com/daurnimator/lua-http/issues/168
    local sb = {}
    for k,v in pairs(event) do
        table.insert(sb, ('%s: %s'):format(k, v))
    end
    lcqhttp.log.debug('incoming event %s', table.concat(sb, ','))
end)

arora:subscribe('message', function(bot, event)
    if event.message_type == 'private' then
        -- 调用 cqhttp api 来发送消息
        bot:api('send_private_msg', {
            user_id = event.sender.user_id,
            message = ('你好！%s 你刚才说了：%s')
                :format(event.sender.nickname, event.raw_message)
        })
    end
end)

arora:start(function()
    print('server started!')
end)
