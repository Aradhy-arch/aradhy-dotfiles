-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function ()
    hl.exec_cmd("systemctl --user start hyprpolkitagent") 
    hl.exec_cmd(terminal)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("waybar & swaync & hyprpaper & hyprsunset")
    hl.exec_cmd("udiskie -t")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
end)
