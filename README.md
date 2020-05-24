# cqhttp-lua-sdk

[![License](https://img.shields.io/npm/l/cqhttp.svg)](LICENSE)
![LuaRocks](https://img.shields.io/luarocks/v/cleoold/lcqhttp?color=blue)

此项目为 [酷Q](cqp.cc) 的 [CQHTTP](https://cqhttp.cc/) 插件的 Lua5.3 绑定。她封装了 [lua-http](https://github.com/daurnimator/lua-http/) 库的方法使其可以直接响应 QQ 机器人的事件与调用 API 来发送信息。本项目不依靠 nginx/java 等 web 服务器，可以直接作为脚本运行。因为项目依赖 [cqueues](https://luarocks.org/modules/daurnimator/cqueues) 来运行 （lua-http 的依赖），其只在 UNIX 上可用，所以不能在 Windows 上运行。理论上此项目也可以在 < 5.3 和 jit 环境下运行  
__推荐使用 wsl 来运行__

__测试阶段__

# 安装
```
luarocks install --server=https://luarocks.org/dev lcqhttp
```
如果安装 lua-http 时提示找不到 openssl 可以尝试安装包 `libssl-dev`.

# 依赖项目
*   [lua-http](https://luarocks.org/modules/daurnimator/http)
*   [lunajson](https://luarocks.org/modules/grafi/lunajson)
*   [sha1](https://luarocks.org/modules/mpeterv/sha1)

# 基本使用（HTTP）
假设用户已经安装且配置了 [CQHTTP](https://cqhttp.cc/)，而且设置文件如下（仅保留有关联的部分）：
```js
{
    "host": "0.0.0.0",
    "port": 8764,      // cqhttp 插件端口
    "use_http": true,
    "post_url": "http://127.0.0.1:8765",  // lua 服务端地址
    "access_token": "accesstoken or nil", // 或者为空字符串
    "secret": "secret or nil",            // 或者为空字符串
}
```
使用 `lcqhttp.http` 模块，与它相应的 lua 配置如下：
```lua
local arora = require 'lcqhttp.http'.LCQHTTP_HTTP:new({
    apiRoot = 'http://127.0.0.1:8764',
    host = '127.0.0.1',
    port = '8765',
    accessToken = 'accesstoken or nil', -- 可选项
    secret = 'secret or nil' -- 可选项
})

arora:subscribe('message', function(bot, event)
    if event.message_type == 'private' then
        bot:api('send_private_msg', {
            user_id = event.sender.user_id,
            message = ('你好！%s 你刚才说了：%s')
                :format(event.sender.nickname, event.raw_message)
        })
    end
end):start(function()
    print('server started!')
end)
```
完整实例可以在 [这里](example/demo.lua) 看到，包含 `subscribe` 和 `api` 的使用方法。

# License
MIT
