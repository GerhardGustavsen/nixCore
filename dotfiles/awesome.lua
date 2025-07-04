pcall(require, "luarocks.loader")

require("awful.autofocus")
require("awful.hotkeys_popup.keys")

local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local spawn = require("awful.spawn")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
local statusbar = require("statusbar")

------------------------------------------------------------------------------------------------------------
------------------------------------------------- ERROR HANDLING -------------------------------------------
------------------------------------------------------------------------------------------------------------

-- Handle startup errors
if awesome.startup_errors then
    spawn.easy_async_with_shell(
        string.format('dunstify -u critical "<span color=\'red\'>Startup Error</span>" %q', awesome.startup_errors),
        function(_)
        end
    )
end

-- Handle runtime errors
do
    local in_error = false
    awesome.connect_signal(
        "debug::error",
        function(err)
            if in_error then
                return
            end
            in_error = true

            spawn.easy_async_with_shell(
                string.format('dunstify -u critical "<span color=\'red\'>Runtime Error</span>" %q', tostring(err)),
                function(_)
                    in_error = false
                end
            )
        end
    )
end

------------------------------------------------------------------------------------------------------------
------------------------------------------------- SETTINGS -------------------------------------------------
------------------------------------------------------------------------------------------------------------

terminal = "xfce4-terminal"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor
modkey = "Mod4"

------------------------------------------------------------------------------------------------------------
------------------------------------------------- THEMING --------------------------------------------------
------------------------------------------------------------------------------------------------------------

beautiful.init("/home/gg/.config/awesome/theme.lua")

local function set_wallpaper(s)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end
screen.connect_signal("property::geometry", set_wallpaper)

------------------------------------------------------------------------------------------------------------
------------------------------------------------- TILING ---------------------------------------------------
------------------------------------------------------------------------------------------------------------

awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.top
}

awful.screen.connect_for_each_screen(
    function(s)
        set_wallpaper(s)
        awful.tag({"1", "2", "3", "4", "5", "6", "7", "8", "9"}, s, awful.layout.layouts[1])

        awful.tag.add(
            "scrap",
            {
                screen = s,
                layout = awful.layout.suit.floating,
                selected = false
            }
        )

        awful.tag.add(
            "preload",
            {
                screen = s,
                layout = awful.layout.suit.floating,
                selected = false
            }
        )

        for _, t in ipairs(s.tags) do
            t.gap = beautiful.useless_gap
            t.gap_single_client = false -- Like i3's smartgaps
        end

        ----------------------------------------------------------------------------------------------------
        ---------------------------------------------- WIDGETS ---------------------------------------------
        ----------------------------------------------------------------------------------------------------

        -- TAG-list widget
        s.mytaglist =
            awful.widget.taglist {
            screen = s,
            buttons = gears.table.join(
                awful.button(
                    {},
                    1,
                    function(t)
                        t:view_only()
                    end
                )
            ),
            filter = function(t)
                return t.name:match("^%d+$") and (#t:clients() > 0 or t.selected)
            end
        }

        -- Tiling-layout widget
        s.mylayoutbox = awful.widget.layoutbox(s)
        s.mylayoutbox:buttons(
            gears.table.join(
                awful.button(
                    {},
                    1,
                    function()
                        awful.layout.inc(1)
                    end
                )
            )
        )

        -- Statusbar
        s.mywibox = awful.wibar({position = "top", screen = s, height = 22})
        s.mywibox:setup {
            layout = wibox.layout.align.horizontal,
            {
                --- Left widgets
                layout = wibox.layout.fixed.horizontal,
                s.mytaglist
            },
            nil, -- middle widgets
            {
                --- Right widgets
                layout = wibox.layout.fixed.horizontal,
                statusbar.widget,
                wibox.widget.systray(),
                s.mylayoutbox
            }
        }
    end
)

------------------------------------------------------------------------------------------------------------
------------------------------------------------ KEY BINDINGS ----------------------------------------------
------------------------------------------------------------------------------------------------------------

globalkeys =
    gears.table.join(
    ---------------------------------------------- TILING --------------------------------------------------

    -- focus windows
    awful.key(
        {modkey},
        "j",
        function()
            awful.client.focus.byidx(1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key(
        {modkey},
        "k",
        function()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    -- move client
    awful.key(
        {modkey, "Shift"},
        "j",
        function()
            awful.client.swap.byidx(1)
        end,
        {description = "swap with next client by index", group = "client"}
    ),
    awful.key(
        {modkey, "Shift"},
        "k",
        function()
            awful.client.swap.byidx(-1)
        end,
        {description = "swap with previous client by index", group = "client"}
    ),
    -- change master size
    awful.key(
        {modkey},
        "l",
        function()
            awful.tag.incmwfact(0.05)
        end,
        {description = "increase master width factor", group = "layout"}
    ),
    awful.key(
        {modkey},
        "h",
        function()
            awful.tag.incmwfact(-0.05)
        end,
        {description = "decrease master width factor", group = "layout"}
    ),
    -- cycle tiling layout
    awful.key(
        {modkey},
        "m",
        function()
            awful.layout.inc(1)
        end,
        {description = "select next", group = "layout"}
    ),
    -- lock computer
    awful.key(
        {modkey},
        "x",
        function()
            awful.spawn("/home/gg/nixCore/scripts/blurlock.sh")
        end,
        {description = "lock computer", group = "layout"}
    ),
    --------------------------------------------- FUNCTION KEYS --------------------------------------------

    -- Volume keys
    awful.key(
        {},
        "XF86AudioRaiseVolume",
        function()
            awful.spawn("/home/gg/nixCore/scripts/volume.sh up")
        end,
        {description = "volume up", group = "media"}
    ),
    awful.key(
        {},
        "XF86AudioLowerVolume",
        function()
            awful.spawn("/home/gg/nixCore/scripts/volume.sh down")
        end,
        {description = "volume down", group = "media"}
    ),
    -- Mute sound
    awful.key(
        {},
        "XF86AudioMute",
        function()
            awful.spawn("/home/gg/nixCore/scripts/volume.sh mute")
        end,
        {description = "toggle mute", group = "media"}
    ),
    -- Mute mic
    awful.key(
        {},
        "XF86AudioMicMute",
        function()
            awful.spawn.with_shell(
                [[wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED && notify-send -i microphone-sensitivity-muted "Mic muted" || notify-send -i microphone-sensitivity-high "Mic unmuted"]]
            )
        end,
        {description = "toggle mic mute", group = "media"}
    ),
    -- Brightness keys
    awful.key(
        {},
        "XF86MonBrightnessUp",
        function()
            awful.spawn("/home/gg/nixCore/scripts/brightstep.sh up")
        end,
        {description = "brightness up", group = "system"}
    ),
    awful.key(
        {},
        "XF86MonBrightnessDown",
        function()
            awful.spawn("/home/gg/nixCore/scripts/brightstep.sh down")
        end,
        {description = "brightness down", group = "system"}
    ),
    -- Screenshots
    awful.key(
        {},
        "Print",
        function()
            awful.spawn("flameshot screen -p /home/gg/media/img/screenshots/")
        end,
        {description = "screenshot: screen", group = "screenshot"}
    ),
    awful.key(
        {"Shift"},
        "Print",
        function()
            awful.spawn("flameshot gui -p /home/gg/media/img/screenshots/")
        end,
        {description = "screenshot: gui", group = "screenshot"}
    ),
    awful.key(
        {modkey},
        "Print",
        function()
            awful.spawn("flameshot full -p /home/gg/media/img/screenshots/")
        end,
        {description = "screenshot: full", group = "screenshot"}
    ),
    --------------------------------------------- PROGRAMS ------------------------------------------------

    awful.key(
        {modkey},
        "Return",
        function()
            awful.spawn(terminal)
        end,
        {description = "open a terminal", group = "launcher"}
    ),
    awful.key(
        {modkey},
        "w",
        function()
            awful.spawn("firefox")
        end,
        {description = "open web browser", group = "launcher"}
    ),
    awful.key(
        {modkey},
        "s",
        function()
            awful.spawn("spotify")
        end,
        {description = "open Spotify", group = "launcher"}
    ),
    awful.key(
        {modkey},
        "c",
        function()
            awful.spawn("galculator")
        end,
        {description = "open calculator", group = "launcher"}
    ),
    awful.key(
        {modkey},
        "e",
        function()
            awful.spawn("thunar")
        end,
        {description = "open file exporer", group = "launcher"}
    ),
    --------------------------------------------- WORKFLOW ------------------------------------------------

    -- Run program
    awful.key(
        {modkey},
        "r",
        function()
            awful.spawn("rofi -show run")
        end,
        {description = "open launcher", group = "launcher"}
    ),
    -- restore program
    awful.key(
        {modkey},
        "z",
        function()
            local s = awful.screen.focused()
            local scrap_tag = awful.tag.find_by_name(s, "scrap")
            if not scrap_tag then
                return
            end

            for _, c in ipairs(scrap_tag:clients()) do
                c:move_to_tag(s.selected_tag)
                client.focus = c
                c:raise()
                return
            end
        end,
        {description = "restore from scrap pad", group = "client"}
    )
)

clientkeys =
    gears.table.join(
    -- fullscreen
    awful.key(
        {modkey},
        "f",
        function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}
    ),
    -- close program
    awful.key(
        {modkey},
        "q",
        function()
            local c = client.focus
            if not c then
                return
            end

            local class = c.class or ""
            local name = c.name or ""

            -- Programs eligible for scrap
            local scrap_classes = {
                -- Editors
                ["code"] = true,
                ["libreoffice"] = true,
                ["gedit"] = true,
                ["mousepad"] = true,
                ["notepadqq"] = true,
                ["kate"] = true,
                -- Browsers
                ["firefox"] = true,
                ["brave-browser"] = true,
                ["chromium"] = true,
                ["google-chrome"] = true,
                -- CAD / Design
                ["org.kde.kicad"] = true,
                ["Fusion360"] = true
            }

            -- Terminal classes (scrap only if generic name)
            local terminal_classes = {
                ["Alacritty"] = true,
                ["kitty"] = true,
                ["Xfce4-terminal"] = true,
                ["org.gnome.Terminal"] = true,
                ["konsole"] = true,
                ["Terminal"] = true
            }

            local function is_generic_terminal()
                return terminal_classes[class] and
                    (name == "" or name:lower():match("terminal") or name:lower():match("^bash$") or
                        name:lower():match("^zsh$") or
                        name:lower():match("^fish$") or
                        name:lower():match("^sh$"))
            end

            local should_scrap = scrap_classes[class] or is_generic_terminal()

            if should_scrap then
                local scrap_tag = awful.tag.find_by_name(c.screen, "scrap")
                if scrap_tag then
                    for _, cl in ipairs(scrap_tag:clients()) do
                        cl:kill()
                    end
                    c:move_to_tag(scrap_tag)
                    return
                end
            end

            -- Fallback: close normally
            c:kill()
        end,
        {description = "send to scrap or close", group = "client"}
    ),
    -- forcefully close program
    awful.key(
        {modkey, "Shift"},
        "q",
        function(c)
            c:kill()
        end,
        {description = "close", group = "client"}
    ),
    -- togglefloating
    awful.key({modkey}, "space", awful.client.floating.toggle, {description = "toggle floating", group = "client"})
)

--------------------------------------------- MOVE TO TAG ------------------------------------------------

for i = 1, 9 do
    globalkeys =
        gears.table.join(
        globalkeys,
        -- View tag only.
        awful.key(
            {modkey},
            "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
            {description = "view tag #" .. i, group = "tag"}
        ),
        -- Move client to tag.
        awful.key(
            {modkey, "Shift"},
            "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                        tag:view_only()
                    end
                end
            end,
            {description = "move focused client to tag #" .. i, group = "tag"}
        )
    )
end

--------------------------------------------- MOVE TO MONITOR ------------------------------------------------

for i = 1, 9 do
    globalkeys =
        gears.table.join(
        globalkeys,
        awful.key(
            {modkey, "Control"},
            "#" .. (i + 9),
            function()
                local c = client.focus
                local target_screen = screen[i]
                if c and target_screen then
                    c:move_to_screen(target_screen)
                end
            end,
            {description = "move client to screen #" .. i, group = "screen"}
        )
    )
end

root.keys(globalkeys)

------------------------------------------------------------------------------------------------------------
------------------------------------------------- MOUSE BINDINGS -------------------------------------------
------------------------------------------------------------------------------------------------------------

clientbuttons =
    gears.table.join(
    awful.button(
        {},
        1,
        function(c)
            c:emit_signal("request::activate", "mouse_click", {raise = true})
        end
    ),
    awful.button(
        {modkey},
        1,
        function(c)
            c:emit_signal("request::activate", "mouse_click", {raise = true})
            awful.mouse.client.move(c)
        end
    ),
    awful.button(
        {modkey},
        3,
        function(c)
            c:emit_signal("request::activate", "mouse_click", {raise = true})
            awful.mouse.client.resize(c)
        end
    )
)

------------------------------------------------------------------------------------------------------------
------------------------------------------------- CLIENT RULES ---------------------------------------------
------------------------------------------------------------------------------------------------------------

awful.rules.rules = {
    -- All clients:
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_offscreen
        }
    },
    -- Floating clients:
    {
        rule_any = {
            instance = {},
            class = {
                "arandr",
                ".blueman-manager-wrapped",
                "tor browser",
                "pavucontrol",
                "baobab"
            },
            name = {"galculator", "blueman-manager"},
            role = {"galculator", "blueman-manager"}
        },
        properties = {
            floating = true,
            placement = awful.placement.centered
        }
    },
    -- ARandR:
    {
        rule_any = {
            instance = {},
            class = {
                "arandr"
            }
        },
        properties = {floating = true, ontop = true, awful.placement.centered, width = 1000, height = 800},
        callback = function(c)
            gears.timer.start_new(
                0.05,
                function()
                    c:geometry(
                        {
                            width = 1000,
                            height = 600
                        }
                    )
                    awful.placement.centered(c, {honor_workarea = true})
                    return false
                end
            )
        end
    },
    -- Terminal popups:
    {
        rule = {name = "popup"},
        properties = {floating = true, placement = awful.placement.centered, width = 1000, height = 800, ontop = true}
    },
    -- Terminals:
    {
        rule_any = {class = {"Xfce4-terminal", "XTerm", "URxvt", "Alacritty", "kitty", "st"}},
        properties = {size_hints_honor = false}
    }
}

------------------------------------------------------------------------------------------------------------
------------------------------------------------- UPDATING CLIENTS -----------------------------------------
------------------------------------------------------------------------------------------------------------

-- Border and shape
local function update_client_decoration(c)
    local clients = c.screen.tiled_clients
    local only_one = (#clients == 1)
    local is_floating = c.floating
    local is_fullscreen = c.fullscreen

    if (only_one and not is_floating) or is_fullscreen then
        c.border_width = 0
        c.shape = nil
    else
        c.border_width = beautiful.border_width
        c.shape = beautiful.client_shape
    end
end

-- mouse can change focus
client.connect_signal(
    "mouse::enter",
    function(c)
        c:emit_signal("request::activate", "mouse_enter", {raise = false})
    end
)

------------------------------------------- Other clinet updates -------------------------------------------

client.connect_signal(
    "manage",
    function(c)
        if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_offscreen(c)
        end
        update_client_decoration(c)
        c.maximized = false
    end
)

client.connect_signal(
    "focus",
    function(c)
        c.border_color = beautiful.border_focus
        update_client_decoration(c)
    end
)

client.connect_signal(
    "unfocus",
    function(c)
        c.border_color = beautiful.border_normal
        update_client_decoration(c)
    end
)

tag.connect_signal(
    "property::selected",
    function(t)
        for _, c in ipairs(t:clients()) do
            update_client_decoration(c)
        end
    end
)

client.connect_signal(
    "property::floating",
    function(c)
        if not c.fullscreen then
            if c.floating then
                c.ontop = true
            else
                c.ontop = false
            end
        end
        update_client_decoration(c)
    end
)

client.connect_signal("property::fullscreen", update_client_decoration)

------------------------------------------------------------------------------------------------------------
------------------------------------------------- STARTUP --------------------------------------------------
------------------------------------------------------------------------------------------------------------

-- Get back to old TAG if reloaded
gears.timer {
    timeout = 0,
    autostart = true,
    single_shot = true,
    callback = function()
        local f = io.open("/tmp/awesome-visible-tags", "r")
        if not f then
            return
        end

        local restore_map = {}
        local lines = {}
        for line in f:lines() do
            table.insert(lines, line)
            local screen_id, tag_name = line:match("^(%d+):(.+)$")
            if screen_id and tag_name then
                restore_map[tonumber(screen_id)] = tag_name
            end
        end
        f:close()

        for s in screen do
            local i = s.index
            local wanted = restore_map[i]
            if wanted then
                local found = false
                for _, t in ipairs(s.tags or {}) do
                    if t.name == wanted then
                        t:view_only()
                        found = true
                        break
                    end
                end
            end
        end

        os.remove("/tmp/awesome-visible-tags")
    end
}

gears.timer.delayed_call(
    function()
        -- startupp programs
        awful.spawn.with_shell("/home/gg/nixCore/scripts/startup.sh")

        -- Preload firefox
        local preload_tag = awful.tag.find_by_name(awful.screen.primary, "preload")
        if not preload_tag then
            return
        end
        gears.timer {
            timeout = 0.5,
            autostart = true,
            single_shot = true,
            callback = function()
                awful.spawn.easy_async_with_shell(
                    "pgrep -x firefox",
                    function(stdout)
                        if stdout == "" then
                            awful.spawn(
                                "firefox --new-instance --private-window about:blank",
                                {
                                    tag = preload_tag
                                }
                            )
                        end
                    end
                )
            end
        }
    end
)
