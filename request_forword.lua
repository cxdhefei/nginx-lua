--获取参数的值
local req_method = ngx.req.get_method()
ngx.req.read_body()
local request_uri = ngx.var.request_uri
local headers = ngx.req.get_headers()
local req_body_data = ngx.req.get_body_data()
if "GET" == req_method or "DELETE" == req_method then
    params = ngx.req.get_uri_args()
elseif "POST" == req_method or "PUT" == req_method then
    params = ngx.req.get_post_args()
end

--local request_path = "hmreader-gateway"..request_uri
local uri = ngx.var.uri
if "GET" == req_method then
    ngx.log(ngx.ERR,"aliyun liusheng callback："..req_method)
    res,err = ngx.location.capture(uri,{method = ngx.HTTP_GET,args = params})
elseif "DELETE" == req_method then
    ngx.log(ngx.ERR,"aliyun liusheng callback："..req_method)
    res,err = ngx.location.capture(uri,{method = ngx.HTTP_DELETE,args = params})
elseif "POST" == req_method then
    ngx.log(ngx.ERR,"aliyun liusheng callback："..req_method)
    res,err = ngx.location.capture(uri,{method = ngx.HTTP_POST,body = req_body_data})
elseif "PUT" == req_method then
    ngx.log(ngx.ERR,"aliyun liusheng callback:"..req_method)
    res,err = ngx.location.capture(uri,{method = ngx.HTTP_PUT,body = req_body_data})
end

if not res then
  ngx.status=ngx.HTTP_INTERNAL_SERVER_ERROR
  ngx.say(" liusheng callback can not connect iflyread server ")
  ngx.log(ngx.ERR," liusheng callback can not connect iflyread server ",err)
else
  ngx.say(res.body)
end

local http = require "http"
httpc = http:new()

local iflyread_domain = "http://xxx.xxx.xxxx"
local resp, err1 = httpc:request_uri(iflyread_domain..request_uri, {
  method = req_method,
  body = req_body_data,
  headers = headers
 })

if not resp then
  ngx.log(ngx.ERR," liusheng callback can not connect iflyread server ",err1)
  return
end

if resp.status ~= ngx.HTTP_OK then
  ngx.log(ngx.ERR, " iflyread server api http status: ",resp.status)
  return
end

ngx.log(ngx.ERR, "liusheng callback to iflyread server api, http status: ",resp.status)

return
