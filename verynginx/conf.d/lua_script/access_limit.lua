-- access_by_lua_file '/opt/ops/lua/access_limit.lua'
local function close_redis(red)
    if not red then
        return
    end
    --释放连接(连接池实现)
    local pool_max_idle_time = 10000 --毫秒
    local pool_size = 100 --连接池大小
    local ok, err = red:set_keepalive(pool_max_idle_time, pool_size)
 
    if not ok then
        ngx_log(ngx_ERR, "set redis keepalive error : ", err)
    end
end
 
local redis = require "resty.redis"
local red = redis:new()
red:set_timeout(1000)
local ip = "172.16.97.221"
local port = 6389
local redis_db = 10
local ok, err = red:connect(ip,port)
if not ok then
    return close_redis(red)
end
red:select(redis_db)
 
local clientIP = ngx.req.get_headers()["X-Real-IP"]
if clientIP == nil then
   clientIP = ngx.req.get_headers()["x_forwarded_for"]
end
if clientIP == nil then
   clientIP = ngx.var.remote_addr
end


local incrKey = "user:"..clientIP..":freq"
local blockKey = "user:"..clientIP..":block"
local whiteKey = "user:"..clientIP..":white"

-- white
local is_white,err = red:get(whiteKey) -- check if ip is white
if tonumber(is_white) == 1 then
   return close_redis(red)
end
 
-- block
local is_block,err = red:get(blockKey) -- check if ip is blocked
if tonumber(is_block) == 1 then
   local ttl = red:ttl(whiteKey)
   if tonumber(ttl) < 0 then
      ttl = 60000
   end
   local time = ngx.time() + ttl
   ngx.header["Access-Control-Allow-Origin"] = "*"
   ngx.header["Access-Control-Allow-Headers"] = "DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range, userid, agent, brandid, language, token"
   ngx.header['Content-Type'] = 'application/json; charset=utf-8'
   ngx.say('{"Code":199,"Data":{"Msg":"请勿刷新过于频繁!","Time":"'..time..'"}}')
   ngx.exit(ngx.HTTP_OK)
   return close_redis(red)
--   ngx.exit(ngx.HTTP_FORBIDDEN)
--   return close_redis(red)
end
 
res, err = red:incr(incrKey)
 
if res == 1 then
   res, err = red:expire(incrKey,10)
end
 
if res > 200 then
    res, err = red:set(blockKey,1)
    res, err = red:expire(blockKey,1800)
end
 
-- url block
local incrKeyUrl = "user:"..clientIP..":freqUrl:"..ngx.var.uri
local blockKeyUrl = "user:"..clientIP..":blockUrl:"..ngx.var.uri
 
local is_block,err = red:get(blockKeyUrl) -- check if ip is blocked
if tonumber(is_block) == 1 then
   ngx.exit(ngx.HTTP_FORBIDDEN)
   return close_redis(red)
end
 
res, err = red:incr(incrKeyUrl)
 
if res == 1 then
   res, err = red:expire(incrKeyUrl,10)
end
 
if res > 70 then
    res, err = red:set(blockKeyUrl,1)
    res, err = red:expire(blockKeyUrl,60)
end
 
close_redis(red)
