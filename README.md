# Name

lua-resty-redis-client - Wrapper for [lua-resty-redis](https://github.com/openresty/lua-resty-redis), easy to use

# Table of Contents

- [Name](https://github.com/RunnningPig/lua-resty-redis-client#name)
- [Description](https://github.com/RunnningPig/lua-resty-redis-client#description)
- [Synopsis](https://github.com/RunnningPig/lua-resty-redis-client#synopsis)
- [Methods](https://github.com/RunnningPig/lua-resty-redis-client#methods)
  - [new](https://github.com/RunnningPig/lua-resty-redis-client#new)
  - [init_pipeline](https://github.com/RunnningPig/lua-resty-redis-client#init_pipeline)
  - [commit_pipeline](https://github.com/RunnningPig/lua-resty-redis-client#commit_pipeline)
  - [cancel_pipeline](https://github.com/RunnningPig/lua-resty-redis-client#cancel_pipeline)
- [Installation](https://github.com/RunnningPig/lua-resty-redis-client#installation)

# Description

This is a wrapper library for [lua-resty-redis](https://github.com/openresty/lua-resty-redis), simplifying the steps and hiding operations such as connect, keepalive, etc.

# Synopsis

```nginx
# you do not need the following line if you are using
# the OpenResty bundle:
lua_package_path "/path/to/lua-resty-redis-client/lib/?.lua;;";

server {
    location /test {
        content_by_lua_block {
            local redis = require("resty.redis.client")
            local red = redis.new {
                host = "127.0.0.1",
                port = 6379,
                timeout = 1000,  -- 1 sec
            }

            local ok, err = red:set("dog", "an animal")
            if not ok then
                ngx.say("failed to set dog: ", err)
                return
            end

            ngx.say("set result: ", ok)

            local res, err = red:get("dog")
            if not res then
                ngx.say("failed to get dog: ", err)
                return
            end

            if res == ngx.null then
                ngx.say("dog not found.")
                return
            end

            ngx.say("dog: ", res)

            red:init_pipeline()
            red:set("cat", "Marry")
            red:set("horse", "Bob")
            red:get("cat")
            red:get("horse")
            local results, err = red:commit_pipeline()
            if not results then
                ngx.say("failed to commit the pipelined requests: ", err)
                return
            end

            for i, res in ipairs(results) do
                if type(res) == "table" then
                    if res[1] == false then
                        ngx.say("failed to run command ", i, ": ", res[2])
                    else
                        -- process the table value
                    end
                else
                    -- process the scalar value
                end
            end
        }
    }
}
```

# Methods

All of the Redis commands have their own methods with the same name except all in lower case.

You can find the complete list of Redis commands here:

http://redis.io/commands

You need to check out this Redis command reference to see what Redis command accepts what arguments.

The Redis command arguments can be directly fed into the corresponding method call. For example, the "GET" redis command accepts a single key argument, then you can just call the "get" method like this:

```lua
    local res, err = red:get("key")
```

See [lua-resty-redis#methods](https://github.com/openresty/lua-resty-redis#methods) for details.

## new

`syntax: red, err = redis.new(options_table?)`

Creates a redis object. In case of failures, returns `nil` and a string describing the error.

The optional `options_table` argument is a Lua table holding the following keys:

- `host`
  
  The host to connect to (default: `"127.0.0.1"`).
* `port`
  
  The port to connect to (default: `"6379"`)

* `password`
  
  Password for authentication, may be required depending on server configuration.

* `timeout`
  
  Sets the connect, send, and read timeout thresholds (in ms), for subsequent socket operations.
  
  See [lua-resty-redis#set_timeout](https://github.com/openresty/lua-resty-redis#set_timeout) for details.

* `pool_size`
  
  Specifies the size of the connection pool (defaults to 1).
  
  See [lua-resty-redis#connect](https://github.com/openresty/lua-resty-redis#connect) for details.

* `backlog`
  
  If specified, this module will limit the total number of opened connections for this pool. 
  
  See [lua-resty-redis#connect](https://github.com/openresty/lua-resty-redis#connect) for details.

* `max_idle_timeout`
  
  Specifies the max idle timeout (in ms) when the connection is in 
  the pool.
  
  See [lua-resty-redis#set_keepalive](https://github.com/openresty/lua-resty-redis#set_keepalive) for details.

[Back to TOC](https://github.com/RunnningPig/lua-resty-redis-client#table-of-contents)

## init_pipeline

`syntax: red:init_pipeline(n?)`

Enable the redis pipelining mode. All subsequent calls to Redis command methods will automatically get cached and will send to the server in one run when the `commit_pipeline` method is called or get cancelled by calling the `cancel_pipeline` method.

This method always succeeds.

If the redis object is already in the Redis pipelining mode, then calling this method will discard existing cached Redis queries.

The optional `n` argument specifies the (approximate) number of commands that are going to add to this pipeline, which can make things a little faster.

[Back to TOC](https://github.com/RunnningPig/lua-resty-redis-client#table-of-contents)

## commit_pipeline

`syntax: results, err = red:commit_pipeline()`

Quits the pipelining mode by committing all the cached Redis queries to the remote server in a single run. All the replies for these queries will be collected automatically and are returned as if a big multi-bulk reply at the highest level.

This method returns `nil` and a Lua string describing the error upon failures.

[Back to TOC](https://github.com/RunnningPig/lua-resty-redis-client#table-of-contents)

## cancel_pipeline

`syntax: red:cancel_pipeline()`

Quits the pipelining mode by discarding all existing cached Redis commands since the last call to the `init_pipeline` method.

This method always succeeds.

If the redis object is not in the Redis pipelining mode, then this method is a no-op.

[Back to TOC](https://github.com/RunnningPig/lua-resty-redis-client#table-of-contents)

# Installation

```shell
$ luarocks install lua-resty-redis-client
```

[Back to TOC](https://github.com/RunnningPig/lua-resty-redis-client#table-of-contents)
