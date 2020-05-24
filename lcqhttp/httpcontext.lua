local http = {
    headers = require 'http.headers',
    request = require 'http.request'
}
local lcqhttp = {
    util = require 'lcqhttp.util'
}

-- lua-http's stream is too verbose, let's make an abstraction
local IncomingHttpRequest = lcqhttp.util.createClass {
    constructor = function(self, stream)
        self.stream = stream
        self.req = {
            headers = assert(stream:get_headers()),
            body = assert(stream:get_body_as_string()) or lcqhttp.util.NULL
        }
        self.res = {
            headers = http.headers.new(),
            body = lcqhttp.util.NULL
        }
        self.res.headers:append('User-Agent', lcqhttp.util.user_agent)
    end,
    respond = function(self, status)
        if status ~= nil then
            self.res.headers:append(':status', status)
        end
        -- the second parameter: if true, end the stream immediately
        assert(self.stream:write_headers(self.res.headers, not self.res.body))
        if self.res.body then assert(self.stream:write_chunk(self.res.body, true)) end
    end
}

local OutgoingHttpRequest = lcqhttp.util.createClass {
    constructor = function(self, uri, method, body)
        self.req = {
            headers = http.headers.new(),
            body = body or nil
        }
        self.req = http.request.new_from_uri(uri)
        self.req.headers:upsert(':method', method)
        self.req.headers:upsert('User-Agent', lcqhttp.util.user_agent)
        self.req.body = body
        self.res = {}
        self.responded = false
    end,
    go = function(self, timeout)
        local headers, stream = self.req:go(timeout)
        self.res.headers = headers
        if headers ~= nil then
            self.responded = true
            self.res.body, _ = stream:get_body_as_string()
        end
        return self
    end
}

return {
    IncomingHttpRequest = IncomingHttpRequest,
    OutgoingHttpRequest = OutgoingHttpRequest
}
