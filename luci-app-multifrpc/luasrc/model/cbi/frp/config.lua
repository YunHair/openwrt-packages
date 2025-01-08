local n = "frp"
local i = require "luci.dispatcher"
local o = require "luci.model.network".init()
local m = require "nixio.fs"
local a, t, e

arg[1] = arg[1]or""

a = Map("frp")
a.title = translate("Frp 域名配置")
a.redirect = i.build_url("admin", "services", "frp")

t = a:section(NamedSection, arg[1], "frp")
t.title = translate("配置 Frp 协议参数")
t.addremove = false
t.dynamic = false

t:tab("base", translate("基本设置"))
t:tab("other", translate("其他设置"))

e = t:taboption("base", ListValue, "enable", translate("开启状态"))
e.default = "1"
e.rmempty = false
e:value("1", translate("启用"))
e:value("0", translate("关闭"))

e = t:taboption("base", ListValue, "type", translate("Frp 协议类型"))
e:value("http", translate("HTTP"))
e:value("https", translate("HTTPS"))
e:value("tcp", translate("TCP"))
e:value("udp", translate("UDP"))
e:value("stcp", translate("STCP"))
e:value("xtcp", translate("XTCP"))

e = t:taboption("base", ListValue, "domain_type", translate("域名类型"))
e.default = "custom_domains"
e:value("custom_domains", translate("自定义域名"))
e:value("subdomain", translate("子域名"))
e:value("both_dtype", translate("同时使用2种域名"))
e:depends("type", "http")
e:depends("type", "https")

e = t:taboption("base", Value, "custom_domains", translate("自定义域名"))
e.description = translate("如果服务端配置了主域名(subdomain_host)，则自定义域名不能是属于主域名(subdomain_host) 的子域名或者泛域名。")
e:depends("domain_type", "custom_domains")
e:depends("domain_type", "both_dtype")

e = t:taboption("base", Value, "subdomain", translate("子域名"))
e.description = translate("使用子域名时，必须预先在服务端配置主域名(subdomain_host)参数。")
e:depends("domain_type", "subdomain")
e:depends("domain_type", "both_dtype")

e = t:taboption("base", ListValue, "stcp_role", translate("STCP 服务类型"))
e.default = "server"
e:value("server", translate("STCP Server"))
e:value("visitor", translate("STCP Vistor"))
e:depends("type", "stcp")

e = t:taboption("base", ListValue, "xtcp_role", translate("XTCP 服务类型"))
e.default = "server"
e:value("server", translate("XTCP Server"))
e:value("visitor", translate("XTCP Vistor"))
e:depends("type", "xtcp")

e = t:taboption("base", Value, "remote_port", translate("远程主机端口"))
e.datatype = "port"
e:depends("type", "tcp")
e:depends("type", "udp")

e = t:taboption("other", Flag, "enable_plugin", translate("使用插件"))
e.description = translate("使用插件使用插件模式时，本地 IP 地址和端口无需配置，插件将会处理来自服务端的链接请求。")
e.default = "0"
e:depends("type", "tcp")

e = t:taboption("base", Value, "local_ip", translate("内网主机地址"))
luci.sys.net.ipv4_hints(function(x,d)
e:value(x,"%s (%s)"%{x,d})
end)
luci.sys.net.ipv6_hints(function(x,d)
e:value(x,"%s (%s)"%{x,d})
end)
e:depends("type", "udp")
e:depends("type", "http")
e:depends("type", "https")
e:depends("enable_plugin", 0)

e = t:taboption("base", Value, "local_port", translate("内网主机端口"))
e.datatype = "port"
e:depends("type", "udp")
e:depends("type", "http")
e:depends("type", "https")
e:depends("enable_plugin", 0)

e = t:taboption("base", Value, "stcp_secretkey", translate("STCP 密钥"))
e.default = "abcdefg"
e:depends("type", "stcp")

e = t:taboption("base", Value, "stcp_servername", translate("STCP 服务名称"))
e.description = translate("STCP服务器别名")
e.default = "secret_tcp"
e:depends("stcp_role", "visitor")

e = t:taboption("base", Value, "xtcp_secretkey", translate("XTCP 密钥"))
e.default = "abcdefg"
e:depends("type", "xtcp")

e = t:taboption("base", Value, "xtcp_servername", translate("XTCP 服务名称"))
e.description = translate("XTCP服务器别名")
e.default = "p2p_tcp"
e:depends("xtcp_role", "visitor")

e = t:taboption("other", Flag, "enable_locations", translate("启用 URL 路由"))
e.description = translate("Frp 支持通过url路由将http请求转发到不同的反向web服务。")
e:depends("type", "http")

e = t:taboption("other", Value, "locations", translate("URL 路由"))
e.description = translate("Http requests with url prefix /news will be forwarded to this service.")
e.default = "locations=/"
e:depends("enable_locations", 1)

e = t:taboption("other", ListValue, "plugin", translate("选择插件"))
e:value("http_proxy", translate("http_proxy"))
e:value("socks5", translate("socks5"))
e:value("unix_domain_socket", translate("unix_domain_socket"))
e:depends("enable_plugin", 1)

e = t:taboption("other", Flag, "enable_plugin_httpuserpw", translate("代理认证"))
e.description = translate("http proxy 插件，可以使其他机器通过 frpc 的网络访问互联网；开启身份验证之后需要用户名、密码才能连接到 HTTP 代理。")
e.default = "0"
e:depends("plugin", "http_proxy")

e = t:taboption("other", Value, "plugin_http_user", translate("HTTP 代理用户名"))
e.default = "abc"
e:depends("enable_plugin_httpuserpw", 1)

e = t:taboption("other", Value, "plugin_http_passwd", translate("HTTP 代理密码"))
e.default = "abc"
e:depends("enable_plugin_httpuserpw", 1)

e = t:taboption("other", Value, "plugin_unix_path", translate("Unix Sock 插件路径"))
e.default = "/var/run/docker.sock"
e:depends("plugin", "unix_domain_socket")

e = t:taboption("other", Flag, "enable_http_auth", translate("密码保护您的web服务"))
e.description = translate("Http用户名和密码是Http协议的安全认证。")
e.default = "0"
e:depends("type", "http")

e = t:taboption("other", Value, "http_user", translate("Http用户名"))
e.default = "frp"
e:depends("enable_http_auth", 1)

e = t:taboption("other", Value, "http_pwd", translate("Http密码"))
e.default = "frp"
e:depends("enable_http_auth", 1)

e = t:taboption("other", Flag, "enable_host_header_rewrite", translate("修改 Host Header"))
e.description = translate("Frp可以用修改后的主机头重写http请求。")
e.default = "0"
e:depends("type", "http")

e = t:taboption("other", Value, "host_header_rewrite", translate("Host Header"))
e.description = translate("The Host header will be rewritten to match the hostname portion of the forwarding address.")
e.default = "dev.yourdomain.com"
e:depends("enable_host_header_rewrite", 1)

e = t:taboption("other", Flag, "enable_https_plugin", translate("使用插件"))
e.default = "0"
e:depends("type", "https")

e = t:taboption("other", ListValue, "https_plugin", translate("选择插件"))
e.description = translate("使用插件使用插件模式时，本地 IP 地址和端口无需配置，插件将会处理来自服务端的链接请求。")
e:value("https2http", translate("https2http"))
e:depends("enable_https_plugin", 1)

e = t:taboption("other", Value, "plugin_local_addr", translate("插件本地地址（格式 IP:Port）"))
e.default = "127.0.0.1:80"
e:depends("https_plugin", "https2http")

e = t:taboption("other", Value, "plugin_crt_path", translate("插件证书路径"))
e.default = "./server.crt"
e:depends("https_plugin", "https2http")

e = t:taboption("other", Value, "plugin_key_path", translate("插件私钥路径"))
e.default = "./server.key"
e:depends("https_plugin", "https2http")

e = t:taboption("other", Value, "plugin_host_header_rewrite", translate("插件 Host Header 重写"))
e.default = "127.0.0.1"
e:depends("https_plugin", "https2http")

e = t:taboption("other", Value, "plugin_header_X_From_Where", translate("插件X-From-Where请求头"))
e.default = "frp"
e:depends("https_plugin", "https2http")

e = t:taboption("base", ListValue, "proxy_protocol_version", translate("Proxy-Protocol 版本"))
e.description = translate("将用户的真实IP发送到本地服务的代理协议。")
e.default = "disable"
e:value("disable", translate("关闭"))
e:value("v1", translate("V1"))
e:value("v2", translate("V2"))
e:depends("type", "tcp")
e:depends("type", "stcp")
e:depends("type", "xtcp")
e:depends("type", "http")
e:depends("type", "https")

e = t:taboption("base", Flag, "use_encryption", translate("开启数据加密"))
e.description = translate("将 frpc 与 frps 之间的通信内容加密传输，将会有效防止流量被拦截（启用自定义TLS协议加密后除 xtcp 的 protocol 配置为 kcp 外，可不再设置此项重复加密）。")
e.default = "1"
e.rmempty = false

e = t:taboption("base", Flag, "use_compression", translate("使用压缩"))
e.description = translate("对传输内容进行压缩，加快流量转发速度，但是会额外消耗一些 cpu 资源。")
e.default = "1"
e.rmempty = false

e = t:taboption("base", Value, "remark", translate("服务备注名"))
e.description = translate("<font color=\"red\">确保备注名唯一</font>")
e.rmempty = false

return a
