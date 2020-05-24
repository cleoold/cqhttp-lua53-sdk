local lcqhttp = {
    util = require 'lcqhttp.util'
}

local log = function(fmt, ...)
    print(lcqhttp.util.timestr()..' '..fmt:format(...))
end

local lerror = function(fmt, ...) log('ERROR: '..fmt, ...) end

local lwarn = function(fmt, ...) log('WARNING: '..fmt, ...) end

local ldebug = function(fmt, ...) log('DEBUG: '..fmt, ...) end

return {
    log = log,
    error = lerror,
    warn = lwarn,
    debug = ldebug
}
