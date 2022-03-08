# vim:set ft= ts=4 sw=4 et:

use t::Test;

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

run_tests();

__DATA__

=== TEST 1: set and get
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua '
            local redis = require "resty.redis.client"
            local red = redis.new {
                host = "127.0.0.1",
                port = $TEST_NGINX_REDIS_PORT,
                timeout = 1000,  -- 1 second 
            }

            local res, err = red:set("dog", "an animal")
            if not res then
                ngx.say("failed to set dog: ", err)
                return
            end

            ngx.say("set dog: ", res)

            for i = 1, 2 do
                local res, err = red:get("dog")
                if err then
                    ngx.say("failed to get dog: ", err)
                    return
                end

                if not res then
                    ngx.say("dog not found.")
                    return
                end

                ngx.say("dog: ", res)
            end
        ';
--- response_body
set dog: OK
dog: an animal
dog: an animal
--- no_error_log
[error]



=== TEST 2: flushall
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua '
            local redis = require "resty.redis.client"
            local red = redis.new {
                host = "127.0.0.1",
                port = $TEST_NGINX_REDIS_PORT,
                timeout = 1000,  -- 1 second 
            }

            local res, err = red:flushall()
            if not res then
                ngx.say("failed to flushall: ", err)
                return
            end
            ngx.say("flushall: ", res)
        ';
--- response_body
flushall: OK
--- no_error_log
[error]



=== TEST 3: get nil bulk value
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua '
            local redis = require "resty.redis.client"
            local red = redis.new {
                host = "127.0.0.1",
                port = $TEST_NGINX_REDIS_PORT,
                timeout = 1000,  -- 1 second 
            }

            local res, err = red:flushall()
            if not res then
                ngx.say("failed to flushall: ", err)
                return
            end

            ngx.say("flushall: ", res)

            for i = 1, 2 do
                res, err = red:get("not_found")
                if err then
                    ngx.say("failed to get: ", err)
                    return
                end

                if res == ngx.null then
                    ngx.say("not_found not found.")
                    return
                end

                ngx.say("get not_found: ", res)
            end
        ';
--- response_body
flushall: OK
not_found not found.
--- no_error_log
[error]



=== TEST 4: get nil list
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua '
            local redis = require "resty.redis.client"
            local red = redis.new {
                host = "127.0.0.1",
                port = $TEST_NGINX_REDIS_PORT,
                timeout = 1000,  -- 1 second 
            }

            local res, err = red:flushall()
            if not res then
                ngx.say("failed to flushall: ", err)
                return
            end

            ngx.say("flushall: ", res)

            for i = 1, 2 do
                res, err = red:lrange("nokey", 0, 1)
                if err then
                    ngx.say("failed to get: ", err)
                    return
                end

                if res == ngx.null then
                    ngx.say("nokey not found.")
                    return
                end

                ngx.say("get nokey: ", #res, " (", type(res), ")")
            end
        ';
--- response_body
flushall: OK
get nokey: 0 (table)
get nokey: 0 (table)
--- no_error_log
[error]



=== TEST 5: incr and decr
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua '
            local redis = require "resty.redis.client"
            local red = redis.new {
                host = "127.0.0.1",
                port = $TEST_NGINX_REDIS_PORT,
                timeout = 1000,  -- 1 second 
            }

            local res, err = red:set("connections", 10)
            if not res then
                ngx.say("failed to set connections: ", err)
                return
            end

            ngx.say("set connections: ", res)

            res, err = red:incr("connections")
            if not res then
                ngx.say("failed to set connections: ", err)
                return
            end

            ngx.say("incr connections: ", res)

            local res, err = red:get("connections")
            if err then
                ngx.say("failed to get connections: ", err)
                return
            end

            res, err = red:incr("connections")
            if not res then
                ngx.say("failed to incr connections: ", err)
                return
            end

            ngx.say("incr connections: ", res)

            res, err = red:decr("connections")
            if not res then
                ngx.say("failed to decr connections: ", err)
                return
            end

            ngx.say("decr connections: ", res)

            res, err = red:get("connections")
            if not res then
                ngx.say("connections not found.")
                return
            end

            ngx.say("connections: ", res)

            res, err = red:del("connections")
            if not res then
                ngx.say("failed to del connections: ", err)
                return
            end

            ngx.say("del connections: ", res)

            res, err = red:incr("connections")
            if not res then
                ngx.say("failed to set connections: ", err)
                return
            end

            ngx.say("incr connections: ", res)

            res, err = red:get("connections")
            if not res then
                ngx.say("connections not found.")
                return
            end

            ngx.say("connections: ", res)
        ';
--- response_body
set connections: OK
incr connections: 11
incr connections: 12
decr connections: 11
connections: 11
del connections: 1
incr connections: 1
connections: 1
--- no_error_log
[error]



=== TEST 6: bad incr command format
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua '
            local redis = require "resty.redis.client"
            local red = redis.new {
                host = "127.0.0.1",
                port = $TEST_NGINX_REDIS_PORT,
                timeout = 1000,  -- 1 second 
            }

            local res, err = red:incr("connections", 12)
            if not res then
                ngx.say("failed to set connections: ", res, ": ", err)
                return
            end

            ngx.say("incr connections: ", res)
        ';
--- response_body
failed to set connections: nil: ERR wrong number of arguments for 'incr' command
--- no_error_log
[error]



=== TEST 7: lpush and lrange
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua '
            local redis = require "resty.redis.client"
            local red = redis.new {
                host = "127.0.0.1",
                port = $TEST_NGINX_REDIS_PORT,
                timeout = 1000,  -- 1 second 
            }

            local res, err = red:flushall()
            if not res then
                ngx.say("failed to flushall: ", err)
                return
            end
            ngx.say("flushall: ", res)

            local res, err = red:lpush("mylist", "world")
            if not res then
                ngx.say("failed to lpush: ", err)
                return
            end
            ngx.say("lpush result: ", res)

            res, err = red:lpush("mylist", "hello")
            if not res then
                ngx.say("failed to lpush: ", err)
                return
            end
            ngx.say("lpush result: ", res)

            res, err = red:lrange("mylist", 0, -1)
            if not res then
                ngx.say("failed to lrange: ", err)
                return
            end
            local cjson = require "cjson"
            ngx.say("lrange result: ", cjson.encode(res))
        ';
--- response_body
flushall: OK
lpush result: 1
lpush result: 2
lrange result: ["hello","world"]
--- no_error_log
[error]



=== TEST 8: blpop expires its own timeout
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua '
            local redis = require "resty.redis.client"
            local red = redis.new {
                host = "127.0.0.1",
                port = $TEST_NGINX_REDIS_PORT,
                timeout = 2500,  -- 2.5 seconds
            }

            local res, err = red:flushall()
            if not res then
                ngx.say("failed to flushall: ", err)
                return
            end
            ngx.say("flushall: ", res)

            local res, err = red:blpop("key", 1)
            if err then
                ngx.say("failed to blpop: ", err)
                return
            end

            if res == ngx.null then
                ngx.say("no element popped.")
                return
            end

            local cjson = require "cjson"
            ngx.say("blpop result: ", cjson.encode(res))
        ';
--- response_body
flushall: OK
no element popped.
--- no_error_log
[error]
--- timeout: 3



=== TEST 9: mget
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua '
            local redis = require "resty.redis.client"
            local red = redis.new {
                host = "127.0.0.1",
                port = $TEST_NGINX_REDIS_PORT,
                timeout = 1000,  -- 1 second 
            }

            ok, err = red:flushall()
            if not ok then
                ngx.say("failed to flush all: ", err)
                return
            end

            local res, err = red:set("dog", "an animal")
            if not res then
                ngx.say("failed to set dog: ", err)
                return
            end

            ngx.say("set dog: ", res)

            for i = 1, 2 do
                local res, err = red:mget("dog", "cat", "dog")
                if err then
                    ngx.say("failed to get dog: ", err)
                    return
                end

                if not res then
                    ngx.say("dog not found.")
                    return
                end

                local cjson = require "cjson"
                ngx.say("res: ", cjson.encode(res))
            end
        ';
--- response_body
set dog: OK
res: ["an animal",null,"an animal"]
res: ["an animal",null,"an animal"]
--- no_error_log
[error]



=== TEST 10: hmget array_to_hash
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua '
            local redis = require "resty.redis.client"
            local red = redis.new {
                host = "127.0.0.1",
                port = $TEST_NGINX_REDIS_PORT,
                timeout = 1000,  -- 1 second 
            }

            ok, err = red:flushall()
            if not ok then
                ngx.say("failed to flush all: ", err)
                return
            end

            local res, err = red:hmset("animals", { dog = "bark", cat = "meow", cow = "moo" })
            if not res then
                ngx.say("failed to set animals: ", err)
                return
            end

            ngx.say("hmset animals: ", res)

            local res, err = red:hmget("animals", "dog", "cat", "cow")
            if not res then
                ngx.say("failed to get animals: ", err)
                return
            end

            ngx.say("hmget animals: ", res)

            local res, err = red:hgetall("animals")
            if err then
                ngx.say("failed to get animals: ", err)
                return
            end

            if not res then
                ngx.say("animals not found.")
                return
            end

            local h = red:array_to_hash(res)

            ngx.say("dog: ", h.dog)
            ngx.say("cat: ", h.cat)
            ngx.say("cow: ", h.cow)
        ';
--- response_body
hmset animals: OK
hmget animals: barkmeowmoo
dog: bark
cat: meow
cow: moo
--- no_error_log
[error]



=== TEST 11: boolean args
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua '
            local redis = require "resty.redis.client"
            local red = redis.new {
                host = "127.0.0.1",
                port = $TEST_NGINX_REDIS_PORT,
                timeout = 1000,  -- 1 second 
            }

            ok, err = red:set("foo", true)
            if not ok then
                ngx.say("failed to set: ", err)
                return
            end

            local res, err = red:get("foo")
            if not res then
                ngx.say("failed to get: ", err)
                return
            end

            ngx.say("foo: ", res, ", type: ", type(res))

            ok, err = red:set("foo", false)
            if not ok then
                ngx.say("failed to set: ", err)
                return
            end

            local res, err = red:get("foo")
            if not res then
                ngx.say("failed to get: ", err)
                return
            end

            ngx.say("foo: ", res, ", type: ", type(res))

            ok, err = red:set("foo", nil)
            if not ok then
                ngx.say("failed to set: ", err)
            end

            local res, err = red:get("foo")
            if not res then
                ngx.say("failed to get: ", err)
                return
            end

            ngx.say("foo: ", res, ", type: ", type(res))
        ';
--- response_body
foo: true, type: string
foo: false, type: string
failed to set: ERR wrong number of arguments for 'set' command
foo: false, type: string
--- no_error_log
[error]



=== TEST 12: set and get (key with underscores)
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua '
            local redis = require "resty.redis.client"
            local red = redis.new {
                host = "127.0.0.1",
                port = $TEST_NGINX_REDIS_PORT,
                timeout = 1000,  -- 1 second 
            }

            local res, err = red:set("a_dog", "an animal")
            if not res then
                ngx.say("failed to set a_dog: ", err)
                return
            end

            ngx.say("set a_dog: ", res)

            for i = 1, 2 do
                local res, err = red:get("a_dog")
                if err then
                    ngx.say("failed to get a_dog: ", err)
                    return
                end

                if not res then
                    ngx.say("a_dog not found.")
                    return
                end

                ngx.say("a_dog: ", res)
            end
        ';
--- response_body
set a_dog: OK
a_dog: an animal
a_dog: an animal
--- no_error_log
[error]
