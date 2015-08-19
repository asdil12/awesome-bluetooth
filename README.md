This is a bluetooth manager (with tray icon) for the awesome window manager.

It allows you to
- connect and disconnect bluetooth devices
- view the current connection state of all paired devices
- get a notification box when a device connects or disconnects


It can not pair new devices - that needs to be done using bluetoothctl.

You will need https://aur.archlinux.org/packages/lua-ldbus/ to be installed.


![](http://i.imgur.com/NrZi6hu.png)

The menu shows all paired devices.
Connected devices will have a blue icon.
Disconnected devices will have a gray icon.
Clicking on a device in the menu will toggle the connection status.

Also connect/disconnect events are reported using the usual awesome notify boxes.
