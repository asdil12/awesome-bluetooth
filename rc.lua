local bluetooth = require("bluetooth")
async = require("async") -- must be global

function string.trim(s)
        if s then
                return (s:gsub("^%s*(.-)%s*$", "%1"))
        else
                return ""
        end
endo

local icondir = os.getenv("HOME") .. "/.config/awesome/icons/"

-- Create widget
btwidget = awful.widget.button({image = icondir .. "bluetooth.png", menu = btmenu})
btmenu = nil
btwidget:buttons(awful.util.table.join(
	awful.button({}, 1, nil, function()
		if btmenu ~= nil and btmenu.wibox.visible then
			btmenu:hide()
			btmenu = nil
			return
		end
		local items = {}
		for i, iv in ipairs(sortpairs(bluetooth.devices(), function(a,b) return a.key < b.key end)) do
			local path = iv.key
			local v = iv.value
			items[#items+1] = {
				v.Alias, function() -- onclick
					local action = v.Connected and "disconnect" or "connect"
					-- Hack to allow non-blocking execution
					async.execute(string.format("cd %s/.config/awesome ; ./bluetooth.lua %s %s", os.getenv("HOME"), action, path),
					function(str)
						str = string.trim(str)
						if str ~= "OK" then
							naughty.notify({
								title = "Bluetooth Verbindung fehlgeschlagen",
								text = string.format("Konnte nicht mit Gerät »%s« verbinden.<br />%s", v.Alias, str)
							})
						end
					end)
				end,
				string.format(icondir .. "btprofiles/%s%s.png", v.Icon, v.Connected and "_connected" or "")
			}
		end
		btmenu = awful.menu({items = items, theme = { width = 250 }})
		btmenu:show()
	end),
	awful.button({}, 3, nil, function()
		if btmenu ~= nil then
			btmenu:hide()
			btmenu = nil
		end
	end)
))

-- Use awesome's dbus lib to listen on dbus for bluetooth events
dbus.add_match("system", "interface='org.freedesktop.DBus.Properties'")
dbus.connect_signal('org.freedesktop.DBus.Properties', function (data, interface, chprop)
	if interface == "org.bluez.Device1" then
		if chprop.Connected ~= nil then
			local path = data.path
			local devices = bluetooth.devices()
			if devices == nil or devices[path] == nil then
				return
			end
			local name = devices[path].Alias
			naughty.notify({
				title = string.format("Bluetooth Verbindung %s", chprop.Connected and "hergestellt" or "getrennt"),
				text = string.format(
					chprop.Connected and "Sie sind nun mit dem Gerät »%s« verbunden."
					or "Verbindung mit dem Gerät »%s« getrennt.", name)
			})
		end
	end
end)



-- now add the btwidget widget to some layout
