#!/usr/bin/lua

local ldbus = require "ldbus"
local inspect = require "inspect"

local conn = assert( ldbus.bus.get("system") )

local M = {} -- public interface

function string.starts(String, Start)
	return string.sub(String, 1, string.len(Start))==Start
end

function string.trim(s)
	if s then
		return (s:gsub("^%s*(.-)%s*$", "%1"))
	else
		return ""
	end
end

local function read(riter)
	local first = true
	local results = {}
	while first or riter:next() do
		first = false
		if riter:get_arg_type() == "a" then     -- array
			local ret = read(riter:recurse())
			table.insert(results, ret)
		elseif riter:get_arg_type() == "e" then -- dict_entry
			local ret = read(riter:recurse())
			results[ret[1]] = ret[2]
		elseif riter:get_arg_type() == "r" then -- struct
			local ret = read(riter:recurse())
			table.insert(results, ret)
		elseif riter:get_arg_type() == "v" then -- variant
			local ret = read(riter:recurse())
			table.insert(results, ret[1])
		else                                    -- basic type
			local ret = riter:get_basic()
			table.insert(results, ret)
		end
	end
	return results
end

local function dbus_method_call(destination, path, interface, method)
	local msg = assert(ldbus.message.new_method_call(destination, path, interface, method), "Message Null")
	local iter = ldbus.message.iter.new()
	msg:iter_init_append(iter)

	local reply = assert(conn:send_with_reply_and_block(msg))

	if not reply:iter_init(iter) then
		return nil
	end
	return read(iter)
end

local function dbus_method_call_noreply(destination, path, interface, method)
	local msg = assert(ldbus.message.new_method_call(destination, path, interface, method), "Message Null")
	local iter = ldbus.message.iter.new()
	msg:iter_init_append(iter)
	return conn:send(msg)
end

function M.devices()
	local r = dbus_method_call("org.bluez", "/", "org.freedesktop.DBus.ObjectManager", "GetManagedObjects")
	local devs = {}
	for k, v in pairs(r[1]) do
		if string.starts(k, "/org/bluez/hci0/") and v["org.bluez.Device1"] ~= nil then
			devs[k] = v["org.bluez.Device1"]
			devs[k].Name = string.trim(devs[k].Name)
			devs[k].Alias = string.trim(devs[k].Alias)
			if devs[k].Icon == nil then
				devs[k].Icon = "unknown"
			end
		end
	end
	return devs
end

function M.device_connect(path)    dbus_method_call("org.bluez", path, "org.bluez.Device1", "Connect") end
function M.device_disconnect(path) dbus_method_call("org.bluez", path, "org.bluez.Device1", "Disconnect") end

M.dbus_method_call = dbus_method_call

if arg ~= nil and arg[1] ~= nil then
	local ok = true
	local err
	if arg[1] == "connect" then
		ok, err = pcall(M.device_connect, arg[2])
	elseif arg[1] == "disconnect" then
		ok, err = pcall(M.device_disconnect, arg[2])
	elseif arg[1] == "list" then
		print(inspect(M.devices()))
	end
	if not ok then
		print(err:match(": (.+)"))
	else
		print("OK")
	end
else
	return M
end

--[[
Usage as module:
local bluetooth = require "bluetooth"
local inspect = require('inspect')
print(inspect(bluetooth.devices()))

Usage via cli:
bluetooth.lua list
bluetooth.lua connect/disconnect PATH
eg:
./bluetooth.lua connect    /org/bluez/hci0/dev_C8_84_47_03_CF_ED
./bluetooth.lua disconnect /org/bluez/hci0/dev_C8_84_47_03_CF_ED
--]]
