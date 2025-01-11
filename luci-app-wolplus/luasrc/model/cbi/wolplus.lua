local i = require "luci.sys"
local t, e
t = Map("wolplus", translate("网络唤醒++"), translate("唤醒你的局域网设备") .. [[<br/><br/><a href="https://github.com/sundaqiang/openwrt-packages" target="_blank">Powered by sundaqiang</a>]])
t.template = "wolplus/index"
e = t:section(TypedSection, "macclient", translate("设备列表"))
e.template = "cbi/tblsection"
e.anonymous = true
e.addremove = true
---- add device section
a = e:option(Value, "name", translate("主机名称"))
a.optional = false
---- mac address
nolimit_mac = e:option(Value, "macaddr", translate("MAC地址"))
nolimit_mac.rmempty = false
i.net.mac_hints(function(e, t) nolimit_mac:value(e, "%s (%s)" % {e, t}) end)
----- network interface
nolimit_eth = e:option(Value, "maceth", translate("网络接口"))
nolimit_eth.rmempty = false
for t, e in ipairs(i.net.devices()) do if e ~= "lo" then nolimit_eth:value(e) end end
----- wake device
btn = e:option(Button, "_awake", translate("唤醒主机"))
btn.inputtitle	= translate("唤醒")
btn.inputstyle	= "apply"
btn.disabled	= false
btn.template = "wolplus/awake"
function gen_uuid(format)
    local uuid = i.exec("echo -n $(cat /proc/sys/kernel/random/uuid)")
    if format == nil then
        uuid = string.gsub(uuid, "-", "")
    end
    return uuid
end
function e.create(e, t)
    local uuid = gen_uuid()
    t = uuid
    TypedSection.create(e, t)
end

return t
