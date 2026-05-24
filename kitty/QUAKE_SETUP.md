# Kitty Quake-Style Terminal Setup

This configuration provides a Quake-style dropdown terminal for kitty.

## Features

- Fixed window size (100 columns × 30 rows)
- Top-positioned terminal window
- Quick toggle with global hotkey
- Dedicated session configuration

## Setup Instructions

### 1. Stage the Configuration

Run the stage-dotfiles.sh script to symlink all kitty configurations:

```bash
./stage-dotfiles.sh
```

This will create symlinks for:
- `~/.config/kitty/` (entire directory)
- `~/kitty-quake.sh` (toggle script)

### 2. Set Up Global Hotkey

You need to bind `~/kitty-quake.sh` to a global hotkey. Choose one of these methods:

#### Option A: Hammerspoon (Recommended for macOS)

Add to your `~/.hammerspoon/init.lua`:

```lua
hs.hotkey.bind({"cmd"}, "`", function()
    os.execute("~/kitty-quake.sh")
end)
```

#### Option B: BetterTouchTool

1. Open BetterTouchTool
2. Go to Keyboard → Add New Shortcut
3. Set trigger: `⌘` + `` ` ``
4. Action: "Execute Terminal Command"
5. Command: `~/kitty-quake.sh`

#### Option C: Alfred Workflow

1. Create new workflow
2. Add Hotkey trigger (`⌘` + `` ` ``)
3. Connect to "Run Script" action
4. Script: `~/kitty-quake.sh`

#### Option D: macOS Automator + System Preferences

1. Open Automator
2. Create new "Quick Action"
3. Add "Run Shell Script"
4. Paste: `~/kitty-quake.sh`
5. Save as "Kitty Quake Toggle"
6. Go to System Preferences → Keyboard → Shortcuts → Services
7. Find "Kitty Quake Toggle" and assign hotkey

### 3. Manual Launch (Testing)

You can test the Quake terminal manually:

```bash
kitty --session ~/.config/kitty/quake.session
```

Or with the toggle script:

```bash
~/kitty-quake.sh
```

## Configuration Details

### Window Settings

The following settings in `kitty.conf` control the Quake behavior:

```conf
remember_window_size     no
initial_window_width     100c
initial_window_height    30c
```

### Keyboard Shortcuts

Additional keyboard shortcuts are available within kitty:

- `⌘` + `` ` ``: Toggle window focus (when using OS-level hotkey manager)
- `⌘` + `⇧` + `ESC`: Quick hide/minimize

### Customization

To adjust window size, edit `kitty.conf`:

```conf
initial_window_width     120c    # Width in columns
initial_window_height    40c     # Height in rows
```

Or use percentage of screen:

```conf
initial_window_width     100%
initial_window_height    50%
```

## Troubleshooting

### Script doesn't execute

Make sure the script is executable:

```bash
chmod +x ~/kitty-quake.sh
```

### Window doesn't position correctly

macOS doesn't allow applications to fully control window positioning. For true Quake-style behavior, consider using a window manager like:

- **yabai** (tiling window manager)
- **Rectangle** (window management)
- **Hammerspoon** (automation)

### kitty command not found

Make sure kitty is installed and in your PATH, or modify the script to use the full path:

```bash
/Applications/kitty.app/Contents/MacOS/kitty
```

## Alternative: Using Hammerspoon for Better Control

For more advanced control (slide-in animation, true toggle), use Hammerspoon:

```lua
local kittyQuake = hs.application.find("kitty")
local quakeWindow = nil

function toggleKittyQuake()
    if not kittyQuake or not kittyQuake:isRunning() then
        -- Launch kitty
        hs.execute("open -na /Applications/kitty.app --args --session ~/.config/kitty/quake.session")
        hs.timer.doAfter(0.5, function()
            kittyQuake = hs.application.find("kitty")
            if kittyQuake then
                quakeWindow = kittyQuake:mainWindow()
                positionQuakeWindow()
            end
        end)
    else
        quakeWindow = kittyQuake:mainWindow()
        if quakeWindow then
            if kittyQuake:isFrontmost() then
                kittyQuake:hide()
            else
                kittyQuake:activate()
                positionQuakeWindow()
            end
        end
    end
end

function positionQuakeWindow()
    if quakeWindow then
        local screen = hs.screen.mainScreen()
        local screenFrame = screen:frame()
        quakeWindow:setFrame({
            x = screenFrame.x,
            y = screenFrame.y,
            w = screenFrame.w,
            h = screenFrame.h * 0.5  -- 50% of screen height
        })
    end
end

hs.hotkey.bind({"cmd"}, "`", toggleKittyQuake)
```

This provides:
- Proper window positioning
- True toggle behavior
- Automatic positioning on screen changes




