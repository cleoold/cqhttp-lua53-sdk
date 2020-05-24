package = "lcqhttp"
version = "scm-1"

source = {
    url = "git+https://github.com/cleoold/cqhttp-lua53-sdk.git"
}

description = {
    summary = "Lua binding of CQHTTP",
    detailed = "此项目为 [酷Q](cqp.cc) 的 [CQHTTP](https://cqhttp.cc/) 插件的 Lua 绑定。她封装了 [lua-http](https://github.com/daurnimator/lua-http/) 库的方法使其可以直接响应 QQ 机器人的事件与调用 API 来发送信息。",
    homepage = "https://github.com/cleoold/cqhttp-lua53-sdk",
    license = "MIT"
}

dependencies = {
    "lua >= 5.1",
    "http >= 0.3",
    "lunajson >= 1.2.2",
    "sha1 >= 0.6.0"
}

build = {
    type = "builtin",
    modules = {
        ["lcqhttp.event"] = "lcqhttp/event.lua",
        ["lcqhttp.http"] = "lcqhttp/http.lua",
        ["lcqhttp.httpcontext"] = "lcqhttp/httpcontext.lua",
        ["lcqhttp.log"] = "lcqhttp/log.lua",
        ["lcqhttp.message"] = "lcqhttp/message.lua",
        ["lcqhttp.util"] = "lcqhttp/util.lua"
    }
}
