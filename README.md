# cqhttp-lua-sdk

[![License](https://img.shields.io/npm/l/cqhttp.svg)](LICENSE)

此项目为 [酷Q](cqp.cc) 的 [CQHTTP](https://cqhttp.cc/) 插件的 Lua5.3 绑定。她封装了 [lua-http](https://github.com/daurnimator/lua-http/) 库的方法使其可以直接响应 QQ 机器人的事件与调用 API 来发送信息。本项目不依靠 nginx/java 等 web 服务器，可以直接作为脚本运行。因为项目依赖 [cqueues](https://luarocks.org/modules/daurnimator/cqueues) 来运行 （lua-http 的依赖），其只在 UNIX 上可用，所以不能在 Windows 上运行。理论上此项目也可以在 < 5.3 和 jit 环境下运行  
__推荐使用 wsl 来运行__

__测试阶段__

# 安装
```
luarocks install https://raw.githubusercontent.com/cleoold/cqhttp-lua53-sdk/master/lcqhttp-scm-1.rockspec
```
如果安装 lua-http 时提示找不到 openssl 可以尝试安装包 `libssl-dev`.

# 依赖项目
*   [lua-http](https://luarocks.org/modules/daurnimator/http)
*   [lunajson](https://luarocks.org/modules/grafi/lunajson)
*   [sha1](https://luarocks.org/modules/mpeterv/sha1)

# 基本使用（HTTP）
假设用户已经安装且配置了 [CQHTTP](https://cqhttp.cc/)，而且设置文件如下（仅保留有关联的部分）：
```json
{
    "host": "0.0.0.0",
    "port": 8764,      // cqhttp 插件端口
    "use_http": true,
    "use_ws": false,
    "post_url": "http://localhost:8765",  // lua 服务端地址
    "access_token": "accesstoken or nil", // 或者为空字符串
    "secret": "secret or nil",            // 或者为空字符串
}
```
与它相应的 lua 程序如下：
```lua
local lcqhttp = {
    http = require 'lcqhttp.http',
    log = require 'lcqhttp.log'
}

-- 创建机器人
local arora = lcqhttp.http.LCQHTTP_HTTP({
    apiRoot = 'http://localhost:8764',
    host = 'localhost',
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
end)

-- 添加 request 类型的监听器
-- 这个例子里显示 subscribe 的回调函数还接受 response (table) 参数，这个 table 会在
-- 最后作为响应返回给 cqhttp 插件 https://cqhttp.cc/docs/4.15/#/Post?id=%E5%A5%BD%E5%8F%8B%E6%B7%BB%E5%8A%A0
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
```

# 基本使用（WS）
waiting...

# License
MIT
