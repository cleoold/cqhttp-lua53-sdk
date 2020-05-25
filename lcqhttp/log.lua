local lcqhttp = {
    util = require 'lcqhttp.util'
}

local log = function(pre, fmt, ...)
    fmt = fmt or 'unknown'
    print(lcqhttp.util.timestr()..' '..pre..fmt:format(...))
end

local lerror = function(fmt, ...) log('ERROR: ', fmt, ...) end

local lwarn = function(fmt, ...) log('WARNING: ', fmt, ...) end

local ldebug = function(fmt, ...) log('DEBUG: ', fmt, ...) end

return {
    log = log,
    error = lerror,
    warn = lwarn,
    debug = ldebug
}
