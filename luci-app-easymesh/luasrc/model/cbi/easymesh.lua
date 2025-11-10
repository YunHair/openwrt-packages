local m, s, o
local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local iwinfo = require "iwinfo"

m = Map("easymesh",
    translate("Easy Mesh 无线组网配置"),
    translate("基于 Batman-adv 协议（移动自组网高级方案）。请先配置 Mesh 主服务器，再配置节点设备。配置节点时需先启用无线 Mesh 并建立连接，再启用 DHCP 节点模式。默认设置适用于大多数 Mesh 无线组网场景。")
    .. "<br/>" .. translate("官方网站：") .. ' <a href="https://www.open-mesh.org/projects/batman-adv/wiki" target="_blank">https://www.open-mesh.org/projects/batman-adv/wiki</a>'
)

-- 确保 get_verbose_hw_info() 函数优先声明
local function get_verbose_hw_info(iface)
    local type = iwinfo.type(iface)
    if not type then return "通用设备" end

    local driver = iwinfo[type]
    if not driver then return "不支持的驱动" end

    local hw_name = driver.hardware_name and driver.hardware_name(iface) or "未知硬件"
    local hw_modes = driver.hwmodelist and driver.hwmodelist(iface) or {}

    local supported_modes = {}
    for mode, supported in pairs(hw_modes) do
        if supported then
            table.insert(supported_modes, mode)
        end
    end

    return hw_name .. " (" .. (#supported_modes > 0 and table.concat(supported_modes, "/") or "无模式信息") .. ")"
end

-- 修正后的邻居节点检测函数
function detect_Node()
    local data = {}

    -- 执行 batctl 获取邻居节点列表
    local lps = luci.util.execi("batctl n 2>/dev/null | tail -n +3")  -- 跳过表头

    for line in lps do
        -- 调试输出原始行
        print("调试：原始数据 -> [" .. line .. "]")

        -- 跳过无效行（表头）
        if string.match(line, "Neighbor%s+last%-seen%s+speed%s+IF") then
            print("调试：跳过表头行 -> [" .. line .. "]")
        else
            -- 标准化空格
            line = string.gsub(line, "%s+", " ")

            -- 提取字段
            local neighbor, lastseen, interface = line:match("(%S+)%s+(%S+)%s+%(.+%)%s+%[(%S+)%]")

            -- 调试输出解析值
            if neighbor and lastseen and interface then
                print(string.format("调试：解析结果 -> 接口: %s, 邻居节点: %s, 最后活跃: %s", interface, neighbor, lastseen))
                
                table.insert(data, {
                    ["IF"] = interface,
                    ["Neighbor"] = neighbor,
                    ["lastseen"] = lastseen
                })
            else
                print("调试：因格式错误跳过 -> [" .. line .. "]")
            end
        end
    end
    return data
end

-- 准确获取活跃节点数
local Nodes = luci.sys.exec("batctl n 2>/dev/null | grep -E '^[0-9a-fA-F]{2}:' | wc -l")

-- 显示 Mesh 状态表格
local Node = detect_Node()
v = m:section(Table, Node, translate("Mesh 网络状态"), "<b>" .. translate("活跃节点数量：") .. Nodes .. "</b>")
v:option(DummyValue, "IF", translate("网络接口"))
v:option(DummyValue, "Neighbor", translate("邻居节点"))
v:option(DummyValue, "lastseen", translate("最后活跃时间"))

s = m:section(TypedSection, "easymesh", translate("Mesh 参数设置"))
s.anonymous = true

s:tab("setup", translate("基础设置"))
s:tab("apmode", translate("AP 模式"))
s:tab("advanced", translate("高级设置"))

-- 启用 EasyMesh
o = s:taboption("setup", Flag, "enabled", translate("启用 Mesh 网络"),
    translate("根据本配置的设定，切换此开关可激活或停用本设备的 Mesh 网络功能。"))
o.default = 0

-- Mesh 模式选择
o = s:taboption("setup", ListValue, "role", translate("Mesh 模式"),
    translate("选择本设备在 Mesh 网络中的角色：<b>主服务器</b>、<b>客户端</b> 或 <b>节点</b>。"))
o:value("server", translate("主服务器"))
o:value("off", translate("节点"))
o:value("client", translate("客户端"))
o.default = "server"

-- 常规 WiFi 网络 SSID
o = s:taboption("setup", Value, "wifi_id", translate("WiFi 网络名称 (SSID)"),
    translate("常规 WiFi 网络的 SSID 标识。"))
o.default = "easymesh_AC"

-- 选择常规 AP 的无线射频
wifiRadio = s:taboption("setup", ListValue, "wifi_radio", translate("常规 AP 射频"),
    translate("选择用于常规 WiFi 接入点的无线射频设备。"))

uci:foreach("wireless", "wifi-device",
    function(s)
        local iface = s['.name']
        local hw_modes = get_verbose_hw_info(iface)
        local desc = string.format("%s (%s)", iface, hw_modes)
        wifiRadio:value(iface, desc)
    end)
wifiRadio.default = "radio1"
wifiRadio.widget = "select"

-- 选择 Mesh 回程的无线射频
apRadio = s:taboption("setup", MultiValue, "apRadio", translate("Mesh 回程射频"),
    translate("选择用于 Mesh 回程通信的无线射频接口。"))

uci:foreach("wireless", "wifi-device",
    function(s)
        local iface = s['.name']
        local hw_modes = get_verbose_hw_info(iface)
        local desc = string.format("%s (%s)", iface, hw_modes)
        apRadio:value(iface, desc)
    end)
apRadio.default = "radio0"
apRadio.widget = "select"

o = s:taboption("setup", Value, "mesh_id", translate("Mesh 网络 SSID"), translate('<p style="text-align: justify; padding: 0;"><strong>请确保所有服务器/节点使用相同的 SSID</strong></p>'))
o.default = "easymesh_AC"

encryption = s:taboption("setup", Flag, "encryption", translate("密码保护"), translate('<p style="text-align: justify; padding: 0;"><strong>启用此选项要求输入密码才能加入 Mesh 网络</strong></p>'))
encryption.default = 0

o = s:taboption("setup", Value, "key", translate("Mesh 网络密码"))
o.default = "easymesh"
o:depends("encryption", 1)
o.password = true
o.datatype = "minlength(8)"

btnReapply = s:taboption("setup", Button, "_btn_reapply", translate("重新应用 EasyMesh 设置"), translate('<p style="text-align: justify; padding: 0;"><strong>在保存并应用配置后，使用此按钮重新应用 EasyMesh 设置</p></strong>'))
function btnReapply.write()
    io.popen("/easymesh/easymesh.sh &")
end

enable_kvr = s:taboption("advanced", Flag, "kvr", translate("K/V/R 漫游协议"), translate('<p style="text-align: justify; padding: 0;"><strong>除非您了解这些参数的作用，否则请保持默认设置</p></strong>'))
enable_kvr.default = 1

mobility_domain = s:taboption("advanced", Value, "mobility_domain", translate("移动域标识"))
mobility_domain.default = "4f57"
mobility_domain.datatype = "and(hexstring,rangelength(4,4))"

rssi_val = s:taboption("advanced", Value, "rssi_val", translate("良好 RSSI 阈值"))
rssi_val.default = "-60"
rssi_val.datatype = "range(-120,-1)"

low_rssi_val = s:taboption("advanced", Value, "low_rssi_val", translate("差 RSSI 阈值"))
low_rssi_val.default = "-88"
low_rssi_val.datatype = "range(-120,-1)"

---- AP 模式配置
o = s:taboption("apmode", Value, "hostname", translate("节点主机名"))
o.default = "node2"
o:value("node2", "node2")
o:value("node3", "node3")
o:value("node4", "node4")
o:value("node5", "node5")
o:value("node6", "node6")
o:value("node7", "node7")
o:value("node8", "node8")
o:value("node9", "node9")
o.datatype = "string"
o:depends({role="off",role="client"})

-- IP 模式 (DHCP 或静态)
ipmode = s:taboption("apmode", ListValue, "ipmode", translate("IP 模式"), translate("选择节点使用 DHCP 还是静态 IP"))
ipmode:value("dhcp", translate("DHCP"))
ipmode:value("static", translate("静态 IP"))
ipmode.default = "dhcp"
ipmode:depends({role="off",role="client"})

-- 静态 IP 地址
o = s:taboption("apmode", Value, "ipaddr", translate("静态 IP 地址"))
o.default = "192.168.8.3"
o.datatype = "ip4addr"
o:depends({ipmode="static",role="off",role="client"})

-- DNS (Mesh 网关 IP)
o = s:taboption("apmode", Value, "gateway", translate("Mesh 网关 IP 地址"))
o.default = "192.168.8.1"
o.datatype = "ip4addr"
o:depends({ipmode="static",role="off",role="client"})

-- IPv4 子网掩码
o = s:taboption("apmode", Value, "netmask", translate("IPv4 子网掩码"))
o.default = "255.255.255.0"
o.datatype = "ip4addr"
o:depends({ipmode="static",role="off",role="client"})

-- DNS 服务器
o = s:taboption("apmode", Value, "dns", translate("DNS 服务器"))
o.default = "192.168.8.1"
o.datatype = "ip4addr"
o:depends({ipmode="static",role="off",role="client"})

btnAPMode = s:taboption("apmode", Button, "_btn_apmode", translate("启用纯 AP 模式"), translate("警告：此操作将修改节点 IP 地址，可能导致无法访问本管理界面"))
function btnAPMode.write()
    io.popen("/easymesh/easymesh.sh dumbap &")
end
btnAPMode:depends({role="off",role="client"})

return m
