# 🎮 Roblox Platform Detection Module
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Roblox](https://img.shields.io/badge/Roblox-Studio-blue)](https://www.roblox.com)

A lightweight, production-ready module for detecting user platforms (Desktop, Mobile, Console, VR) and console types (Xbox/PlayStation) in Roblox games. Features real-time updates, callback system, and global access through shared table.

---

## ✨ Features

- **Multi-Platform Detection**: Automatically detects Desktop, Mobile, Console, and VR platforms
- **Console Type Recognition**: Distinguishes between Xbox and PlayStation controllers
- **Real-Time Updates**: Automatically updates when platform changes (controller connection, VR toggle, etc.)
- **Callback System**: Register callbacks for platform and console type changes
- **Global Access**: All methods available through `shared` table - no require needed!
- **Safe & Robust**: Full error handling, nil checks, and safe callback execution
- **Performance Optimized**: Single RenderStepped connection, cached values, minimal overhead
- **Type-Safe**: Complete Luau type definitions

---

## 📦 Installation

1. Create a ModuleScript in ReplicatedStorage (e.g., `ReplicatedStorage.Modules.Platform`)
2. Copy the code into the module
3. Require it in your main client script:

```lua
-- In your main client script (e.g., Loading.client.lua)
local Platform = require(game.ReplicatedStorage.Modules.Platform)
-- That's it! The module will auto-initialize (require is required if you want to use it through shared in other scripts, the best place is ReplicatedFirst)
```

---

## 🚀 Usage

### Basic Usage (Direct Module Access)

```lua
local Platform = require(path.to.Module)

-- Get current platform
local platform = Platform.GetPlatform()  -- "Desktop", "Mobile", "Console", "VR"
local consoleType = Platform.GetConsoleType()  -- "Xbox", "PlayStation", or nil

-- Check platform type
if Platform.IsMobile() then
    print("Player is on mobile device")
elseif Platform.IsConsole() then
    print("Player is on console")
    if Platform.GetConsoleType() == "PlayStation" then
        print("Using PlayStation controller")
    end
end

-- Register callbacks
local callbackId = Platform.OnPlatformChanged(function(newPlatform, newConsoleType)
    print(`Platform changed to: {newPlatform}`)
    if newPlatform == "Console" then
        print(`Console type: {newConsoleType}`)
    end
end)

-- Remove callback when done
Platform.RemoveCallback(callbackId)
```

### Global Access ( [shared](https://create.roblox.com/docs/reference/engine/globals/RobloxGlobals#shared) )

```lua
-- Any script in the game can access platform info through shared!
local platform = shared.GetPlatform()
local consoleType = shared.GetConsoleType()

if shared.IsMobile() then
    -- Show mobile-optimized UI
    showTouchControls()
end

-- React to platform changes
shared.OnPlatformChanged(function(newPlatform)
    updateUIForPlatform(newPlatform)
end)
```

---

## 📖 API Reference

### Core Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `GetPlatform()` | `Platform` | Returns current platform (`"Desktop"`, `"Mobile"`, `"Console"`, `"VR"`) |
| `GetConsoleType()` | `ConsoleType` | Returns console type (`"Xbox"`, `"PlayStation"`, or `nil`) |
| `Compute(player?)` | `(Platform, ConsoleType)` | Forces platform recalculation |

### Boolean Checks

| Method | Description |
|--------|-------------|
| `IsDesktop()` | Returns true if platform is Desktop |
| `IsMobile()` | Returns true if platform is Mobile |
| `IsConsole()` | Returns true if platform is Console |
| `IsVR()` | Returns true if platform is VR |

### Callback System

| Method | Description |
|--------|-------------|
| `OnPlatformChanged(callback)` | Register callback for platform changes |
| `OnConsoleTypeChanged(callback)` | Register callback for console type changes |
| `RemoveCallback(callbackId)` | Remove registered callback |

### Update Methods

| Method | Description |
|--------|-------------|
| `Update(player?)` | Manually trigger platform update |
| `Refresh()` | Alias for Update() |

---

## 🔄 How It Works

The module detects platform using multiple signals:

1. **VR**: `UserInputService.VREnabled`
2. **Console**: Gamepad connected OR TenFootInterface without mouse
3. **Mobile**: Touch enabled without keyboard/mouse, or gyroscope/accelerometer
4. **Desktop**: Default fallback

Console type is detected by checking button mapping:
- PlayStation: ButtonX maps to "ButtonSquare" (□ button)
- Xbox: ButtonX maps to "X" or "X Button"

---

## 📄 License

**MIT License © 2025 @manee_too**
You may use, modify, and distribute this plugin freely.
Please include attribution to "@manee_too" in your game credits.

Full License: [LICENSE](https://github.com/maneetoo/Roblox-Platform-Detection/blob/main/LICENSE)

---
