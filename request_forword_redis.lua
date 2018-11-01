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

local req_method = ngx.req.get_method()
ngx.log(ngx.ERR,"req_method:"..req_method)
local params = {}
ngx.req.read_body()
local headers = ngx.req.get_headers()
local req_body_data = ngx.req.get_body_data()
--获取参数的值
if "GET" == req_method or "DELETE" == req_method then
    params = ngx.req.get_uri_args()
elseif "POST" == req_method or "PUT" == req_method then
    params = ngx.req.get_post_args()
--ngx.log(ngx.ERR,"req_body_data:"..req_body_data)
end
-- 针对H5 PUT请求特殊处理（参数在url后面）
if next(params) == nil and "PUT" == req_method then 
  params = ngx.req.get_uri_args()
end

local phoneString = params["phoneString"]
--针对post请求格式为multipart/form特殊处理
local multipart = require "multipart"
if phoneString == nil and "POST" == req_method then
  local header_args, err = ngx.req.get_headers()
  local req_content_type = header_args["Content-Type"]
  if req_content_type ~= nil and string.find(req_content_type, "multipart/form") then
    local part_data = multipart(req_body_data,req_content_type)
    phoneString = part_data:get("phoneString").value
  end
end
local uri = ngx.var.uri
local request_uri = ngx.var.request_uri
ngx.log(ngx.ERR,"request_uri:"..request_uri)
local http = require "http"
httpc = http:new()

if phoneString ~= nil then
  local redis_host               = "xxx.xxx.xxx"
  local redis_port               = 7000
  local redis_connection_timeout = 1000  --1s
  local redis_key                = "phoneString"
  local redis = require "resty.redis"
  local red = redis:new()
  red:set_timeout(redis_connect_timeout)
  local ok, err = red:connect(redis_host, redis_port)
  if not ok then
    ngx.log(ngx.ERR, "redis connection error while retrieving phoneString: " .. err);
  else
    local hasPhoneString = red:sismember(redis_key,phoneString)
    if hasPhoneString==1 then
      ngx.log(ngx.ERR, "phoneString:"..phoneString.." exist in redis，redirect to iflyread ");
      close_redis(red)
      local iflyread_domain = "http://xxx.xxxx.xxx"
      local resp, err = httpc:request_uri(iflyread_domain..request_uri, {
        method = req_method,
        body = req_body_data,
        headers = headers
       })

      if not resp then
        ngx.status=ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say("can not connect iflyread server")
        ngx.log(ngx.ERR,"can not connect iflyread server",err)
        return
      end

      if resp.status ~= ngx.HTTP_OK then
        ngx.log(ngx.ERR, "iflyread server api http status:",resp.status)
        ngx.status=resp.status
        ngx.say(resp.body)
        return
      end

      ngx.say(resp.body)
      return
    end
  end
end

if "GET" == req_method then
    ngx.log(ngx.ERR,"aliyun："..req_method)
    res = ngx.location.capture(uri,{method = ngx.HTTP_GET,args = params})
elseif "DELETE" == req_method then
    ngx.log(ngx.ERR,"aliyun："..req_method)
    res = ngx.location.capture(uri,{method = ngx.HTTP_DELETE,args = params})
elseif "POST" == req_method then
    ngx.log(ngx.ERR,"aliyun："..req_method)
    res = ngx.location.capture(uri,{method = ngx.HTTP_POST,body = req_body_data})
elseif "PUT" == req_method then
    ngx.log(ngx.ERR,"aliyun:"..req_method)
    if req_body_data == nil then
      res = ngx.location.capture(uri,{method = ngx.HTTP_PUT,args = params})
    else
      res = ngx.location.capture(uri,{method = ngx.HTTP_PUT,body = req_body_data})
    end
end

ngx.say(res.body)
return
