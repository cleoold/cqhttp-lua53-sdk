# cqhttp-lua53-sdk

[![License](https://img.shields.io/npm/l/cqhttp.svg)](LICENSE)
![LuaRocks](https://img.shields.io/luarocks/v/cleoold/lcqhttp?color=blue)

This project provides Lua5.3 bindings for [CQHTTP](https://cqhttp.cc/), an extension for [Coolq](cqp.cc). It encapsulates the methods coming from [lua-http](https://github.com/daurnimator/lua-http/) library to be able to directly respond to QQ bot events and call APIs to send messages. This project does not depend on nginx, java or other web servers so it can be served as a script. As the project relies on [cqueues](https://luarocks.org/modules/daurnimator/cqueues) (a dependency of lua-http), which is only runnable on UNIX, it cannot run on Windows. Theoretically the project runs on lua < 5.3 or jit environment.  
__WSL is Recommended__


此项目为 [酷Q](cqp.cc) 的 [CQHTTP](https://cqhttp.cc/) 插件的 Lua5.3 绑定。她封装了 [lua-http](https://github.com/daurnimator/lua-http/) 库的方法使其可以直接响应 QQ 机器人的事件与调用 API 来发送信息。本项目不依靠 nginx/java 等 web 服务器，可以直接作为脚本运行。因为项目依赖 [cqueues](https://luarocks.org/modules/daurnimator/cqueues) 来运行 （lua-http 的依赖），其只在 UNIX 上可用，所以不能在 Windows 上运行。理论上此项目也可以在 < 5.3 和 jit 环境下运行  
__推荐使用 wsl 来运行__


## 安装
```sh
luarocks install --server=https://luarocks.org/dev lcqhttp
```
如果安装 lua-http 时提示找不到 openssl 可以尝试安装包 `libssl-dev`.

或者可以克隆这个仓库到本地，在自己的项目中复制 `lcqhttp` 文件夹。

## 依赖项目
*   [lua-http](https://luarocks.org/modules/daurnimator/http)
*   [lunajson](https://luarocks.org/modules/grafi/lunajson)
*   [sha1](https://luarocks.org/modules/mpeterv/sha1)

## 基本使用（HTTP）
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
local arora = require 'lcqhttp.http'.LcqhttpHttpServer.new({
    api_root = 'http://127.0.0.1:8764',
    host = '127.0.0.1',
    port = '8765',
    access_token = 'accesstoken or nil', -- 可选项
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
每一个回调会在接受事件后独立在 cqueue 的容器中运行，所以不会阻塞其他事件。  
完整实例可以在 [这里](https://github.com/cleoold/cqhttp-lua53-sdk/blob/master/example/demo.lua) 看到，包含 `subscribe` 和 `api` 的使用方法。

## Websocket 客户端
*   lua-http 的 ws 客户端不稳定（断线问题和 服务端离线时的 busy wait），所以不建议在生产环境使用（至少在 wsl 上不建议）
*   https://github.com/daurnimator/lua-http/issues/140
*   https://github.com/daurnimator/lua-http/issues/168

假设配置文件如下（仅保留有关联的部分）：
```json
{
    "ws_host": "0.0.0.0",
    "ws_port": 6700,
    "use_ws": true,
    "access_token": "accesstoken or nil",
}
```
`lcqhttp.ws` 模块 可以创建 ws 客户端
```lua
local beta = require 'lcqhttp.ws'.LcqhttpWsClient.new({
    ws_uri = 'ws://127.0.0.1:6700',
    access_token = 'access_token or nil', -- 可选项
    recnn_interval = 1, -- 断线重连间隔时间。可选项，不填则不重连，掉线时退出程序
})
-- 其余方法相同
```

## 其余
项目目前代码比较简单（如果你能接受奇怪的类写法），有不满足需求的地方可以 monkey patch。文档 is coming

## License
MIT
