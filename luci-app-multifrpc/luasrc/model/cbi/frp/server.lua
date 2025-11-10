local n = "frp"
local i = require "luci.dispatcher"
local o = require "luci.model.network".init()
local m = require "nixio.fs"
local a, t, e

arg[1] = arg[1]or""

a = Map("frp")
a.title = translate("Frp服务器设置")
a.redirect = i.build_url("admin", "services", "frp")

t = a:section(NamedSection, arg[1], "frp")
t.title = translate("设置服务器")
t.addremove = false
t.dynamic = false

t:tab("base", translate("基本设置"))

e = t:taboption("base", ListValue, "enabled", translate("开启状态"))
e.default = "1"
e.rmempty = false
e:value("1", translate("启用"))
e:value("0", translate("关闭"))


e = t:taboption("base", Value, "name", translate("服务器名称"))
e.optional = false
e.rmempty = false

e = t:taboption("base", Value, "server_addr", translate("服务器"))
e.optional = false
e.rmempty = false

e = t:taboption("base", Value, "server_port", translate("端口"))
e.datatype = "port"
e.optional = false
e.rmempty = false

e = t:taboption("base", Value, "token", translate("令牌"))
e.description = translate("frpc服务器与frps之间的时间间隔不得超过15分钟")
e.optional = false
e.password = true
e.rmempty = false

e = t:taboption("base", Value, "user", translate("用户名"))
e.description = translate("通常用于区分你与其他客户端")
e.optional = true
e.default = ""
e.rmempty = false

return a
