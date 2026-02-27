# 🎮 Roblox Platform Detection Module
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Roblox](https://img.shields.io/badge/Roblox-Studio-blue)](https://www.roblox.com)
[![Version](https://img.shields.io/badge/version-2.0-green)](https://github.com/maneetoo/Roblox-Platform-Detection)

A lightweight, production-ready module for detecting user platforms (Desktop, Mobile, Tablet, Console, VR) and console types (Xbox/PlayStation) in Roblox games. Features real-time updates, callback system, and global access through shared table.

---

## ✨ Features

- **Complete Platform Detection**: Automatically detects Desktop, Mobile, Tablet, Console, and VR platforms
- **Smart Console Recognition**: Distinguishes between Xbox and PlayStation with button mapping analysis
- **Tablet Optimization**: Smart aspect ratio detection separates tablets from phones
- **Real-Time Updates**: Auto-detects platform changes (controller connection, VR toggle, etc.)
- **Modern Callback System**: Clean connection objects with `Disconnect()` method
- **Global Access**: All methods available through `shared` table - no require needed!
- **Enterprise-Grade Safety**: Full error handling, nil checks, and safe callback execution
- **Highly Configurable**: Toggle tablet detection, adjust aspect ratio thresholds
- **Performance Optimized**: Smart caching, early returns, minimal overhead
- **Type-Safe**: Complete Luau type definitions with `--!strict` mode

---

## 📦 Installation

1. Create a ModuleScript in ReplicatedStorage (e.g., `ReplicatedStorage.Modules.Platform`)
2. Copy the code into the module
3. Require it once in your main client script:

```lua
-- In your main client script (best in ReplicatedFirst)
local Platform = require(game.ReplicatedStorage.Modules.Platform)
-- Module auto-initializes! No further setup needed
```

---

## 🚀 Usage

### Direct Module Access

```lua
local Platform = require(path.to.Module)

-- Get current platform
local platform = Platform.GetPlatform()  -- "Desktop", "Mobile", "Tablet", "Console", "VR"
local consoleType = Platform.GetConsoleType()  -- "Xbox", "PlayStation", or nil

-- Check platform type
if Platform.IsTablet() then
    print("📱 Player on tablet - optimizing UI for larger touch screen")
elseif Platform.IsMobile() then
    print("📞 Player on phone - using compact UI layout")
elseif Platform.IsConsole() then
    print("🎮 Player on console - showing controller hints")
    if Platform.GetConsoleType() == "PlayStation" then
        print("Using PlayStation buttons (□ △ ○ X)")
    end
end

-- React to platform changes (modern way with connections)
local connection = Platform.OnPlatformChanged(function(newPlatform, newConsoleType)
    print(`Platform changed to: {newPlatform}`)
    updateUIForPlatform(newPlatform, newConsoleType)
end)

-- Clean up when done (e.g., when UI is destroyed)
connection:Disconnect()
```

### Global Access via [shared](https://create.roblox.com/docs/reference/engine/globals/RobloxGlobals#shared)

```lua
-- ANY script in the game can access platform info through shared!
-- No require needed - perfect for UI elements, controls, etc.

-- Check current platform anywhere
if shared.PlatformUtils.IsMobile() then
    showMobileControls()
elseif shared.PlatformUtils.IsTablet() then
    showTabletLayout()  -- More space than phone!
end

-- React to changes globally
shared.PlatformUtils.OnPlatformChanged(function(platform, consoleType)
    -- Update UI, controls, input handling
    if platform == "VR" then
        enableVRMode()
    end
end)

-- Get console type for controller prompts
if shared.PlatformUtils.IsConsole() then
    local buttons = shared.PlatformUtils.GetConsoleType() == "PlayStation" 
        and {"□", "△", "○", "✕"} 
        or {"X", "Y", "B", "A"}
    showButtonHints(buttons)
end
```

### Advanced Configuration

```lua
-- At the top of the module, you can adjust detection settings:
local TABLET_CHECK = true  -- Set false to disable tablet detection
local TABLET_ASPECT_RATIO_THRESHOLD = 1.5  -- Adjust for different devices
```

---

## 📖 API Reference

### 📊 Platform Detection

| Method | Return Type | Description |
|--------|-------------|-------------|
| `GetPlatform()` | `Platform` | Returns current platform (`"Desktop"`, `"Mobile"`, `"Tablet"`, `"Console"`, `"VR"`) |
| `GetConsoleType()` | `ConsoleType` | Returns console type (`"Xbox"`, `"PlayStation"`, or `nil`) |
| `Compute(player?)` | `(Platform, ConsoleType)` | Forces platform recalculation with optional player parameter |
| `Update(player?)` | `Platform` | Manually trigger update and callbacks if changed |

### ✅ Platform Checks

| Method | Description |
|--------|-------------|
| `IsDesktop()` | Returns `true` if platform is Desktop (PC/Mac) |
| `IsMobile()` | Returns `true` if platform is Mobile (phone) |
| `IsTablet()` | Returns `true` if platform is Tablet (iPad, Android tablets) |
| `IsConsole()` | Returns `true` if platform is Console (Xbox/PlayStation) |
| `IsVR()` | Returns `true` if platform is VR (Oculus, Vive, etc.) |

### 🔌 Callback System

| Method | Return Type | Description |
|--------|-------------|-------------|
| `OnPlatformChanged(callback)` | `CallbackPlatformConnection` | Register callback for platform changes (returns connection with `Disconnect()`) |
| `OnConsoleTypeChanged(callback)` | `CallbackPlatformConnection` | Register callback for console type changes (returns connection with `Disconnect()`) |
| `RemoveCallback(callbackId)` | `nil` | Legacy method - remove callback by ID |

### 📦 Connection Object

```lua
export type CallbackPlatformConnection = {
    Disconnect: () -> (),  -- Clean up the callback
    _id: number,            -- Internal ID
    _type: "platform" | "consoleType"  -- Internal type
}
```

---

## 🔄 How It Works

### Detection Logic Flow

```lua
Priority Detection Chain:
1. VR → UIS.VREnabled
2. Console → GamepadEnabled OR TenFootInterface without mouse
   └─ Xbox vs PlayStation → Button mapping (ButtonSquare = PlayStation)
3. Mobile/Tablet → TouchEnabled AND (no keyboard/mouse OR gyroscope/accelerometer)
   └─ Tablet vs Phone → Screen aspect ratio analysis
4. Desktop → Default fallback when nothing else matches
```

### Tablet Detection Algorithm

The module uses sophisticated aspect ratio analysis to differentiate tablets from phones:

```lua
local aspectRatio = max(width, height) / min(width, height)
-- Typical values:
-- Phones: 1.8 - 2.2 (tall screens)
-- Tablets: 1.3 - 1.6 (squarer screens)
-- iPads: ~1.33 (4:3 ratio)

if aspectRatio < TABLET_ASPECT_RATIO_THRESHOLD (default 1.5) then
    platform = "Tablet"  -- Squarer screen = Tablet
else
    platform = "Mobile"  -- Taller screen = Phone
end
```

### Real-Time Updates

The module monitors multiple signals for instant platform change detection:

- **Gamepad Connections**: Immediate update when controller connects/disconnects
- **Input Methods**: Tracks VR, Touch, Keyboard, Mouse, Gyroscope states
- **Ten-Foot Interface**: Monitors TV/big screen mode every 2 seconds
- **Property Changes**: Listens to all relevant UserInputService properties

### Platform Detection Details

| Platform | Detection Criteria | Use Case |
|----------|-------------------|----------|
| **VR** | `UIS.VREnabled = true` | Enable VR-specific UI/controls |
| **Console** | Gamepad + TenFoot OR no mouse | Show controller hints, big UI |
| **Tablet** | Touch + aspect ratio < 1.5 | Optimized touch layout |
| **Mobile** | Touch + aspect ratio ≥ 1.5 | Compact mobile UI |
| **Desktop** | None of the above | Standard PC/Mac interface |

---

## 📄 License

**MIT License © 2026 @manee_too**

You may use, modify, and distribute this module freely.
Please include attribution to "@manee_too" in your game credits.

Full License: [LICENSE](https://github.com/maneetoo/Roblox-Platform-Detection/blob/main/LICENSE)
