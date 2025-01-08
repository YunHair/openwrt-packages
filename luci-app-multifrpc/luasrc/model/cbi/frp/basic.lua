local o = require "luci.dispatcher"
local e = require ("luci.model.ipkg")
local s = require "nixio.fs"
local e = luci.model.uci.cursor()
local i = "frp"
local a, t, e
local n = {}

a = Map("frp")
a.title = translate("MultiFrpc 内网穿透")
a.description = translate("Frp 是一个可用于内网穿透的高性能的反向代理应用，MultiFrpc 是一款支持多服务端的 Frp 客户端插件。")

a:section(SimpleSection).template  = "frp/frp_status"

t = a:section(NamedSection, "common", "frp")
t.anonymous = true
t.addremove = false

t:tab("base", translate("基本设置"))
t:tab("other", translate("其他设置"))

e = t:taboption("base", Flag, "enabled", translate("启用"))
e.rmempty = false

e = t:taboption("base", Value, "vhost_http_port", translate("HTTP 穿透服务端口"))
e.datatype = "port"
e.rmempty = false

e = t:taboption("base", Value, "vhost_https_port", translate("HTTPS 穿透服务端口"))
e.datatype = "port"
e.rmempty = false

e = t:taboption("base", Value, "time", translate("服务注册间隔"))
e.description = translate("0表示禁用定时注册功能,单位：分钟")
e.datatype = "range(0,59)"
e.default = 30
e.rmempty = false

-- Other

e = t:taboption("other", Flag, "login_fail_exit", translate("初始登录失败即退出程序"))
e.description = translate("第一次登录失败就退出程序,否则将持续尝试登陆 Frp 服务器。")
e.default = "1"
e.rmempty = false

e = t:taboption("other", Flag, "tcp_mux", translate("TCP 端口复用"))
e.description = translate("该功能默认启用,该配置项在服务端和客户端必须保持一致。")
e.default = "1"
e.rmempty = false

e = t:taboption("other", Flag, "tls_enable", translate("TLS 连接"))
e.description = translate("使用 TLS 协议与服务器连接(若连接服务器异常可以尝试开启)")
e.default = "0"
e.rmempty = false

e = t:taboption("other", Flag, "enable_custom_certificate", translate("自定义TLS协议加密"))
e.description = translate("frp 支持 frpc 和 frps 之间的流量通过 TLS 协议加密,并且支持客户端或服务端单向验证,双向验证等功能。")
e.default = "0"
e.rmempty = false
e:depends("tls_enable", 1)

e = t:taboption("other", Value, "tls_cert_file", translate("TLS 客户端证书文件路径"))
e.description = translate("frps 单向验证 frpc 身份。")
e.placeholder = "/var/etc/frp/client.crt"
e.optional = false
e:depends("enable_custom_certificate", 1)

e = t:taboption("other", Value, "tls_key_file", translate("TLS 客户端密钥文件路径"))
e.description = translate("frps 单向验证 frpc 身份。")
e.placeholder = "/var/etc/frp/client.key"
e.optional = false
e:depends("enable_custom_certificate", 1)

e = t:taboption("other", Value, "tls_trusted_ca_file", translate("TLS CA 证书路径"))
e.description = translate("frpc 单向验证 frps 身份。")
e.placeholder = "/var/etc/frp/ca.crt"
e.optional = false
e:depends("enable_custom_certificate", 1)

e = t:taboption("other", ListValue, "protocol", translate("协议类型"))
e.description = translate("从 v0.12.0 版本开始,底层通信协议支持选择 kcp 协议加速。")
e.default = "tcp"
e:value("tcp", translate("TCP 协议"))
e:value("kcp", translate("KCP 协议"))

e = t:taboption("other", Flag, "enable_http_proxy", translate("通过代理连接 frps"))
e.description = translate("frpc 支持通过 HTTP PROXY 和 frps 进行通信")
e.default = "0"
e.rmempty = false
e:depends("protocol", "tcp")

e = t:taboption("other", Value, "http_proxy", translate("HTTP 代理"))
e.placeholder = "http://user:pwd@192.168.1.128:8080"
e:depends("enable_http_proxy", 1)
e.optional = false

e = t:taboption("other", Flag, "enable_cpool", translate("启用连接池功能"))
e.description = translate("适合有大量短连接请求时开启")
e.rmempty = false

e = t:taboption("other", Value, "pool_count", translate("指定预创建连接的数量"))
e.description = translate("frpc 会预先和服务端建立起指定数量的连接。")
e.datatype = "uinteger"
e.default = "1"
e:depends("enable_cpool", 1)
e.optional = false

e = t:taboption("other", ListValue, "log_level", translate("日志记录等级"))
e.default = "warn"
e:value("trace", translate("追踪"))
e:value("debug", translate("调试"))
e:value("info", translate("信息"))
e:value("warn", translate("警告"))
e:value("error", translate("错误"))

e = t:taboption("other", Value, "log_max_days", translate("日志记录天数"))
e.datatype = "uinteger"
e.default = "3"
e.rmempty = false
e.optional = false

e = t:taboption("other", Flag, "admin_enable", translate("开启网页管理"))
e.description = translate("可通过http查看客户端状态以及通过API控制")
e.default = "0"
e.rmempty = false

e = t:taboption("other", Value, "admin_port", translate("管理员端口号"))
e.datatype = "port"
e.default = 7400
e:depends("admin_enable", 1)

e = t:taboption("other", Value, "admin_user", translate("管理员用户名"))
e.optional = false
e.default = "admin"
e:depends("admin_enable", 1)

e = t:taboption("other", Value, "admin_pwd", translate("管理员密码"))
e.optional = false
e.default = "admin"
e.password = true
e:depends("admin_enable", 1)


-- Server List

t = a:section(TypedSection, "server", translate("服务器列表"))
t.anonymous = true
t.addremove = true
t.template = "cbi/tblsection"
t.extedit = o.build_url("admin", "services", "frp", "server", "%s")

function t.create(e,t)
    new = TypedSection.create(e,t)
    luci.http.redirect(e.extedit:format(new))
end

function t.remove(e,t)
    e.map.proceed = true
    e.map:del(t)
    luci.http.redirect(o.build_url("admin","services","frp"))
end

e = t:option(DummyValue, "name", translate("服务器备注"))

e = t:option(DummyValue, "server_addr", translate("服务器地址"))
e.width = "30%"

e = t:option(DummyValue, "server_port", translate("端口"))
e.width = "15%"

e = t:option(DummyValue, "user", translate("用户名"))
e.width = "15%"

e = t:option(Flag, "enabled", translate("开启状态"))
e.width = "10%"
e.rmempty = false

-- Service Lists

t = a:section(TypedSection, "proxy", translate("服务列表"))
t.anonymous = true
t.addremove = true
t.template = "cbi/tblsection"
t.extedit = o.build_url("admin", "services", "frp", "config", "%s")

function t.create(e,t)
new = TypedSection.create(e,t)
luci.http.redirect(e.extedit:format(new))
end

function t.remove(e,t)
e.map.proceed = true
e.map:del(t)
luci.http.redirect(o.build_url("admin","services","frp"))
end

local o = ""
e = t:option(DummyValue, "remark", translate("服务备注名"))
e.width = "10%"

e = t:option(DummyValue, "type", translate("Frp 协议类型"))
e.width = "10%"

e = t:option(DummyValue, "custom_domains", translate("域名/子域名"))
e.width = "20%"

e.cfgvalue = function(t,n)
local t = a.uci:get(i,n,"domain_type")or""
local m = a.uci:get(i,n,"type")or""
if t=="custom_domains" then
local b = a.uci:get(i,n,"custom_domains")or"" return b end
if t=="subdomain" then
local b = a.uci:get(i,n,"subdomain")or"" return b end
if t=="both_dtype" then
local b = a.uci:get(i,n,"custom_domains")or""
local c = a.uci:get(i,n,"subdomain")or""
b="%s/%s"%{b,c} return b end
end

e = t:option(DummyValue, "remote_port", translate("远程主机端口"))
e.width = "10%"
e.cfgvalue = function(t,b)
local t = a.uci:get(i,b,"type")or""
if t==""or b==""then return""end
if t=="http" then
local b = a.uci:get(i,"common","vhost_http_port")or"" return b end
if t=="https" then
local b = a.uci:get(i,"common","vhost_https_port")or"" return b end
if t=="tcp" or t=="udp" then
local b = a.uci:get(i,b,"remote_port")or"" return b end
end

e = t:option(DummyValue, "local_ip", translate("内网主机地址"))
e.width = "15%"

e = t:option(DummyValue, "local_port", translate("内网主机端口"))
e.width = "10%"

e = t:option(DummyValue, "use_encryption", translate("开启数据加密"))
e.width = "15%"

e.cfgvalue = function(t,n)
local t = a.uci:get(i,n,"use_encryption")or""
local b
if t==""or b==""then return""end
if t=="1" then b="ON"
else b="OFF" end
return b
end

e = t:option(DummyValue, "use_compression", translate("使用压缩"))
e.width = "15%"
e.cfgvalue = function(t,n)
local t = a.uci:get(i,n,"use_compression")or""
local b
if t==""or b==""then return""end
if t=="1" then b="ON"
else b="OFF" end
return b
end

e = t:option(Flag, "enable", translate("开启状态"))
e.width = "10%"
e.rmempty = false

return a
