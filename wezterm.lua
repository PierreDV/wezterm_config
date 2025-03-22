local wezterm = require("wezterm")

local config = wezterm.config_builder()
local action = wezterm.action
local direction_keys = {
  h = "Left",
  j = "Down",
  k = "Up",
  l = "Right",
}

local function is_vim(pane)
  -- this is set by the plugin, and unset on ExitPre in Neovim
  return pane:get_user_vars().IS_NVIM == "true"
end

local function split_nav(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == "resize" and "META" or "CTRL",
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action({
          SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
        }, pane)
      else
        if resize_or_move == "resize" then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

config.font = wezterm.font("Fira Code")
config.font_size = 13.0
config.color_scheme = "catppuccin-mocha"
config.leader = { key = "s", mods = "CTRL" }

wezterm.on("update-right-status", function(window)
  window:set_right_status(window:active_workspace() .. "   ")
end)

config.keys = {
  { key = "-", mods = "LEADER", action = action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  {
    key = "\\",
    mods = "LEADER",
    action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  { key = "x", mods = "LEADER", action = action.CloseCurrentPane({ confirm = false }) },
  {
    key = "$",
    mods = "LEADER|SHIFT",
    action = action.PromptInputLine({
      description = wezterm.format({
        { Attribute = { Intensity = "Bold" } },
        { Foreground = { AnsiColor = "Fuchsia" } },
        { Text = "Enter new name for workspace" },
      }),
      action = wezterm.action_callback(function(_window, _pane, line)
        if line then
          wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
        end
      end),
    }),
  },
  {
    key = "w",
    mods = "LEADER",
    action = action.PromptInputLine({
      description = wezterm.format({
        { Attribute = { Intensity = "Bold" } },
        { Foreground = { AnsiColor = "Fuchsia" } },
        { Text = "Enter name for new workspace" },
      }),
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:perform_action(
            action.SwitchToWorkspace({
              name = line,
            }),
            pane
          )
        end
      end),
    }),
  },
  {
    key = "t",
    mods = "LEADER",
    action = action.SpawnTab("CurrentPaneDomain"),
  },
  {
    key = "s",
    mods = "LEADER",
    action = action.ShowLauncherArgs({
      flags = "WORKSPACES",
    }),
  },
  {
    key = "c",
    mods = "LEADER",
    action = action.ActivateCopyMode,
  },
  split_nav("move", "h"),
  split_nav("move", "j"),
  split_nav("move", "k"),
  split_nav("move", "l"),
}

for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "LEADER",
    action = action.ActivateTab(i - 1),
  })
end

return config
