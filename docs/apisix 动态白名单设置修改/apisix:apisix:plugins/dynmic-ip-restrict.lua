--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
local core = require("apisix.core")
local pairs       = pairs
local type        = type
local ngx         = ngx
local redis_utils     = require("apisix.utils.redis")

local schema = {
    type = "object",
    properties = {
        redis_host = {
            type = "string", minLength = 2
        },
        redis_port = {
            type = "integer", minimum = 1, default = 6379,
        },
        redis_username = {
            type = "string", minLength = 1,
        },
        redis_password = {
            type = "string", minLength = 0,
        },
        redis_database = {
            type = "integer", minimum = 0, default = 0,
        },
        redis_timeout = {
            type = "integer", minimum = 1, default = 1000,
        },
        redis_ssl = {
            type = "boolean", default = false,
        },
        redis_ssl_verify = {
            type = "boolean", default = false,
        },
        message = {
            type = "string",default = "IP restriction",
        }
    },
    required = {"redis_host"},
    minProperties = 1,
}

local plugin_name = "dynmic-ip-restrict"

local _M = {
    version = 0.1,
    priority = 3001,
    name = plugin_name,
    schema = schema,
}


function _M.check_schema(conf)
    local ok, err = core.schema.check(schema, conf)
    if not ok then
        return false, err
    end

    return true
end


local function optimized_ip_to_ascii(ip)
    -- 格式验证 (保持原有正则)
    if not ip:match("^(%d+).(%d+).(%d+).(%d+)$") then
        return nil, "invalid ip format"
    end

    -- 数值范围验证
    for seg in ip:gmatch("%d+") do
        local n = tonumber(seg)
        if not n or n < 0 or n > 255 then
            return nil, "invalid ip segment"
        end
    end

    -- 优化后的遍历计算
    local sum = 0
    for i = 1, #ip do
        local c = ip:byte(i)
        if c ~= 46 then  -- 46 是 '.' 的 ASCII 码
            sum = sum + c
        end
    end
    return sum
end


function _M.rewrite(conf, ctx)

    core.log.error("---------------------")
    core.log.error(core.json.encode(ctx.var.remote_addr))
    local red,err = redis_utils.new(conf)
    if err then
        core.log.error(err)
        return
    end

    if red == nil then
        core.log.error("connect to redis failed")
        return
    end

    local bs,err = optimized_ip_to_ascii(ctx.var.remote_addr)
    if err then
        core.log.error(err)
        return
    end

    local s,err = red:getbit('block_ip',bs)
    core.log.error(core.json.encode(err))
    core.log.error(core.json.encode(s))
    if s == ngx.null or s == 0 then
        return
    else
        return 403, { message = conf.message }
    end

end

return _M
