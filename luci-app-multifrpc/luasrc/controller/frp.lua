module("luci.controller.frp", package.seeall)
local uci=require"luci.model.uci".cursor()
local fs = require "nixio.fs"

function index()
	if not nixio.fs.access("/etc/config/frp") then
		return
	end

	entry({"admin", "services", "frp"}, alias("admin", "services", "frp", "base"), _("MultiFrpc 内网穿透"), 100).dependent = true
	entry({"admin", "services", "frp", "base"}, cbi("frp/basic"), _("MultiFrpc 内网穿透"), 1).leaf = true
	entry({"admin", "services", "frp", "service_log"}, cbi("frp/log"), _("插件日志"), 2).leaf = true
	entry({"admin", "services", "frp", "client_log"}, cbi("frp/client_log"), _("客户端日志"), 3).leaf = true
	entry({"admin", "services", "frp", "config"}, cbi("frp/config")).leaf = true
	entry({"admin", "services", "frp", "server"}, cbi("frp/server")).leaf = true
	entry({"admin", "services", "frp", "status"}, call("act_status")).leaf = true
	entry({"admin", "services", "frp", "server_list"}, call("get_server")).leaf = true
	entry({"admin", "services", "frp", "get_log"}, call("get_log")).leaf = true
end

function act_status()
	local e = {}
	-- Get PID: ps | grep "/usr/bin/frpc -c /var/etc/frp/frpc.conf" | grep -v grep | awk '{print $1}'
	e.running = luci.sys.call("pidof frpc > /dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function get_server()
	local ret = {}
	uci:load("frp")
	uci:foreach("frp", "server", function (s)
		table.insert(ret, s["name"])
	end)
	luci.http.prepare_content("application/json")
	luci.http.write_json(ret) 
end

function get_log() 
	local name = luci.http.formvalue("name")
	local log = fs.readfile(string.format("/var/etc/frp/frpc-%s.log", name))or"NOT FOUND"
	luci.http.write(log)
end
