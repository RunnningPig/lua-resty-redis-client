local redis = require("resty.redis")

local unpack = unpack
local ipairs = ipairs
local rawget = rawget
local assert = assert
local setmetatable = setmetatable

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end


local _M = {
    VERSION = "0.2.0"
}

local mt = {__index = _M}


local function auth(self, redis)
    assert(self.opts.password)

    local times, err = redis:get_reused_times()
    if not times then
        return nil, err
    end

    if times > 0 then
        return true
    end

    local ok, err = redis:auth(self.opts.password)
    if not ok then
        return nil, err
    end

    return true
end


local function connect(self)
    local red, err = redis:new()
    if not red then
        return nil, err
    end

    if self.opts.timeout then
        red:set_timeout(self.opts.timeout)
    end

    local ok, err = red:connect(self.host, self.port, {
        pool_size = self.pool_size,
        backlog   = self.opts.backlog,
    })
    if not ok then
        return nil, err
    end

    -- password auth
    if self.opts.password then
        local ok, err = auth(self, red)
        if not ok then
            return nil, err
        end
    end

    return red
end


local function keepalive(self, redis)
    redis:set_keepalive(self.opts.max_idle_timeout)
end


function _M:init_pipeline(n)
    self.reqs = new_tab(n or 4, 0)
end


function _M.cancel_pipeline(self)
    self.reqs = nil
end


function _M.commit_pipeline(self)
    local reqs = rawget(self, "reqs")
    if not reqs then
        return nil, "no pipeline"
    end

    self.reqs = nil

    local red, err = connect(self)
    if not red then
        return nil, err
    end

    red:init_pipeline(#reqs)

    for _, req in ipairs(reqs) do
        red[req.cmd](red, unpack(req.args))
    end

    local results, err = red:commit_pipeline()
    if not results then
        return nil, err
    end

    keepalive(self, red)

    return results
end


local function do_cmd(self, cmd, ...)
    local reqs = rawget(self, "reqs")
    if reqs then
        reqs[#reqs + 1] = {
            cmd  = cmd,
            args = {...},
        }
        return
    end

    local red, err = connect(self)
    if not red then
        return nil, err
    end

    local res, err = red[cmd](red, ...)
    if not res then
        return nil, err
    end

    keepalive(self, red)

    return res
end


function _M.new(opts)
    opts = opts or {}
    return setmetatable({
        host      = opts.host or "127.0.0.1",
        port      = opts.port or 6379,
        pool_size = opts.pool_size or 1,
        opts = {
            password    = opts.password,
            timeout     = opts.timeout,
            backlog     = opts.backlog,
            max_idle_timeout = opts.max_idle_timeout,
        },
    }, mt)
end


setmetatable(_M, {__index = function(self, cmd)
    local method =
        function (self, ...)
            return do_cmd(self, cmd, ...)
        end

    -- cache the lazily generated method in our
    -- module table
    _M[cmd] = method
    return method
end})


return _M