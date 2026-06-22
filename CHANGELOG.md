# Changelog

## v1.16.0

### New Features
- **Jewelcrafting support** - Added tracking for the **Brilliant Glass** craft (20-hour cooldown). Detected automatically when the Jewelcrafting window is opened or the craft is cast, shown in the tracker and Cooldowns tab with the Jewelcrafting icon, toggleable in Settings, and listed in the Sources tab (learned from trainer, requires 375 skill).

## v1.15.0

### New Features
- **Group shared cooldowns** - New setting to group all alchemy transmute cooldowns (Primal Might, diamonds, elemental transmutes) into a single "Transmutes" row per character in the tracker window
- **Custom tracker title** - New input field in Settings to set a custom tracker window title, with a checkbox to show/hide the title entirely
- **Profession icons in Cooldowns tab** - Each cooldown row now shows the profession icon next to the craft name, matching the tracker window

### Improvements
- **No transparency by default** - All UI elements now default to fully opaque; only the tracker window supports user-controlled transparency via the slider
- **Tracker transparency range** - Slider now goes from 0% to 100% (was 10%-100%), allowing fully transparent tracker backgrounds
- **Tracker UI scale** - UI scale setting now only affects the tracker window (renamed from "UI scale" to "Tracker UI scale")
- **Overview tab alignment** - Character names and profession icons are now displayed in an aligned table layout
- **Cooldowns tab text colors** - Craft names, timers, and status text now match the tracker window's color scheme
- **Streamlined header** - Removed the "Character | Professions" bar; tabs now sit directly below the header image
- **Auto-fit window height** - Main window automatically sizes to fit content when not manually resized

---

## v1.14.0

### New Features
- **UI scale setting** - New slider in Settings (50%-200%) that uniformly scales all Primal Ledger windows — text, icons, padding, and controls
- **Profession icons in tracker** - Each cooldown row in the tracker window now shows the profession icon next to the craft name
- **Clickable "Ready!" in tracker** - Left-click opens the profession window and selects the recipe, right-click opens the profession window (current character only)

### Improvements
- **Tracker title** - Renamed from "Primal Ledger" to "Cooldowns"
- **Recipe selection fix** - Left-clicking "Ready!" now properly selects the recipe in the profession UI, expands collapsed headers, and supports enchanting via the Craft API
- **Minimum window width** - Main window can no longer be resized narrower than the tab bar
- **Fixed "Show in combat" setting** - Tracker now properly hides when entering combat with the setting unchecked; fixed both a boolean storage issue with Classic's `GetChecked()` API and a timing issue where `InCombatLockdown()` wasn't set yet when the combat event fired

---

## v1.13.1

### Fixes
- **Fixed tracker crash on first login** - The "No tracked cooldowns" placeholder created a row with only `charText`, so when cooldown data arrived the existing row was reused but was missing `craftText` and `cdText`, causing a nil index error. Row fields are now created individually if missing.

---

## v1.13.0

### New Features
- **Enchanting profession support** - Enchanting is now a tracked profession, detected via the Craft window API
- **New tracked cooldown: Void Sphere** - Enchanting (350), 48-hour cooldown, learned from trainer
- **Trainer-learned recipe support in Sources tab** - Recipes learned from trainers now show "Learned from trainer" with skill requirement
- **Sources tab accordion layout** - Sources are now grouped by profession in collapsible accordion sections, all collapsed by default for a cleaner look

---

## v1.12.0

### New Features
- **Salt Shaker in Sources tab** - Salt Shaker now appears in the Sources tab with a clickable item link and source info ("Crafted by Engineers (250) or buy from AH")

### Fixes
- **Fixed Salt Shaker showing "Ready!" while on cooldown** - `GetContainerItemCooldown` could return no data or a short item-use cooldown, which overwrote the valid profession cooldown (2d 23h) with "Ready!". Item cooldown detection now preserves existing saved cooldowns that haven't expired yet, and filters out short durations (<60s)
- **Improved cooldown polling for item-based cooldowns** - `PollSpellCooldowns` no longer skips item-based cooldowns like Salt Shaker, providing a fallback detection mechanism via `GetSpellCooldown`

---

## v1.11.0

### New Features
- **New tracked cooldown** - Transmute: Primal Life to Earth (20 hours, learned via discovery)
- **Discovery recipe support in Sources tab** - Recipes learned through discovery now show "Learned via Discovery" with a hint to perform other TBC transmutes

### Fixes
- **Fixed wildly incorrect cooldown timers (e.g. 20527 days)** - Added sanity checks to prevent bogus `GetSpellCooldown()` start values from corrupting stored cooldown data, and a runtime guard that auto-resets any stored cooldown exceeding 7 days
- **Migrated stale cooldown data from v1.10.0** - On startup, any cooldown values still stored in old `GetTime()` format (session-relative) are automatically cleaned up
- **Fixed shared cooldowns marking all alchemy transmutes as known** - Casting any transmute triggered shared cooldowns on all transmutes, which the polling code interpreted as the character knowing every transmute recipe. Cooldown polling now only updates cooldowns for crafts already detected via the profession window scan
- **Fixed cooldown timers becoming invalid after relog/reload** - Cooldowns are now stored as epoch timestamps (`time()`) instead of session-relative values (`GetTime()`), so they persist correctly across client restarts and UI reloads

---

## v1.10.0

### New Features
- **Automatic cooldown detection via polling** - Cooldowns are now detected on login by polling `GetSpellCooldown()` for all tracked spells, without needing to open the profession window
  - Catches cooldowns started before the addon was installed or that the event system missed
  - Listens to `SPELL_UPDATE_COOLDOWN` event for real-time updates
  - Filters out GCDs and spell locks (ignores durations under 60 seconds)
  - Includes WoW client overflow fix for start time values
- **Show seconds setting** - New toggle in Settings to display seconds remaining on cooldown timers (e.g., `2h 15m 30s` instead of `2h 15m`)

---

## v1.9.0

### New Features
- **Resizable tracker window** - Drag the bottom-right grip to resize; size is saved between sessions
  - Content width follows the window width; minimum width matches the content's natural size
  - Hidden when the tracker is locked
- **Alchemy & leatherworking sources** - Sources tab now includes vendor/trainer info and TomTom waypoints for all vendor-sold alchemy transmute recipes (Primal Might, Air to Fire, Earth to Water, Water to Air, Earthstorm Diamond, Skyfire Diamond)
- **New tracked cooldown** - Transmute: Primal Water to Air
- **Credits section** - Guild and contributor credits added to Settings

### Fixes
- **Tracker transparency** - Opacity slider now only affects the background; text remains fully readable at all transparency levels
- **Combat + group visibility** - "Show in combat" now correctly hides the tracker in combat even when "Show in party/raid" is checked
- **Default tracker position** - New installs center the tracker on screen instead of near the minimap
- **Last row separator removed** - No more stray horizontal line below the last cooldown entry

---

## v1.8.0

### New Features
- **Tracker table layout** - Cooldown tracker window redesigned with aligned columns (Character, Craft, Cooldown)
  - Bold separator lines between different characters
  - Striped/faint separator lines between rows of the same character
- **Tracker transparency slider** - Adjust the tracker window opacity from 10% to 100% in Settings
- **Lock/Unlock button** - Hover over the tracker window to reveal a Lock/Unlock button (bottom-right)
  - Locked: window cannot be dragged, close button hidden
  - Unlocked: window is draggable, close button visible
- **Tracker visibility checkboxes** - Replaced the display mode dropdown with granular checkboxes:
  - Show in combat
  - Show in party/raid

### Removed
- **Display mode dropdown** - Replaced by individual visibility checkboxes
- **Tooltip help button** - No longer needed with self-explanatory checkboxes

---

## v1.7.0

### New Features
- **Cooldown Tracker Window** - Persistent, semi-transparent overlay showing live countdowns for all tracked cooldowns across all characters
  - Displays "Available" in green when a cooldown is ready
  - Draggable with saved position (remembers where you put it between sessions)
  - Close button to dismiss without changing settings
- **Tracker Display Mode** - Dropdown in Settings to control tracker visibility:
  - **Static** - Show tracker at all times (default)
  - **Conditional** - Automatically hide tracker when in a party, raid, or combat
- **Salt Shaker tracking** - Track the Salt Shaker item cooldown (2d 23h) for Leatherworkers
  - Automatically detected via bag scanning when the item is in your inventory

### Removed
- **Login notification window** - Replaced by the always-visible tracker window
- **Mooncloth** cooldown (no cooldown in TBC Anniversary)
- **Old-world transmutes** - Removed Transmute: Arcanite, Mithril to Truesilver, and Iron to Gold

### Tracked Cooldowns
**Tailoring:** Shadowcloth, Spellcloth, Primal Mooncloth

**Leatherworking:** Salt Shaker

**Alchemy:** Transmute Primal Might, Transmute Undeath to Water, Transmute Primal Mana to Fire, Transmute Primal Shadow to Water, Transmute Primal Air to Fire, Transmute Primal Water to Shadow, Transmute Earthstorm Diamond, Transmute Skyfire Diamond

---

## v1.6.1

### Removed
- **Keybinding support** - Removed custom keybind feature (use the minimap button or `/pl` to toggle the window)

### Fixed
- Fixed Bindings.xml causing "Unrecognized XML: Binding" errors on load

---

## v1.6.0

### New Features
- **Header image** - Custom Outland-themed header banner at the top of the main window
- **Outland color theme** - Full UI restyled with a dark bronze/fiery color scheme matching the header art
- **CD Tracking window** - Moved from its own tab to a standalone window, accessible via a button in Settings
- **Improved craft export** - Two-step export flow:
  - Selection window shows all crafts with checkboxes (all checked by default)
  - Uncheck crafts you don't want, then click Export
  - Text window shows only the selected crafts, formatted for Discord

### Improvements
- Reduced tab count from 5 to 4 (Overview, Cooldowns, Sources, Settings)
- All UI elements (borders, separators, tabs, buttons, text) use a consistent warm color palette
- Notification window restyled to match the Outland theme

---

## v1.5.0

### New Features
- **Settings Tab** - New tab with addon configuration options
  - Toggle login notification popup on/off
  - Reset Data button with confirmation dialog to wipe all tracked data
- **CD Tracking Tab** - Control which cooldown crafts are tracked
  - Per-cooldown checkboxes grouped by profession (Tailoring / Alchemy)
  - Disabled cooldowns are hidden from the Cooldowns tab and login notifications
  - Settings persist across all characters and sessions
- **Craft Export** - Export button on profession windows for sharing crafts to Discord
  - Appears in the top-right of the TradeSkill and Craft (Enchanting) windows
  - Generates Discord-formatted text with all recipes grouped by category
  - Copyable text box with select-all support

---

## v1.4.0

### New Features
- **Settings Tab** - Initial settings tab with notification toggle and data reset
- **CD Tracking Tab** - Initial cooldown tracking filter

---

## v1.3.0

### New Features
- **Login Notifications** - On login, a notification popup shows all ready cooldowns across all your characters
- **TBC Alchemy Transmutes** - Added 7 new transmutes:
  - Transmute: Primal Mana to Fire
  - Transmute: Primal Shadow to Water
  - Transmute: Primal Air to Fire
  - Transmute: Primal Water to Shadow
  - Transmute: Primal Earth to Water
  - Transmute: Earthstorm Diamond
  - Transmute: Skyfire Diamond

---

## v1.2.0

### New Features
- **Sources Tab** - New tab showing where to obtain patterns for tailoring cooldown crafts
  - Clickable item links for patterns (hover to preview, shift-click to link in chat)
  - Clickable vendor names to target NPCs
  - TomTom waypoint integration (click to set waypoint)

### Improvements
- Updated tailoring cooldown durations to 92 hours (was incorrectly set to 96 hours)

### Data Added
- Pattern source information for Primal Mooncloth, Shadowcloth, and Spellcloth
- Vendor NPC data with TomTom coordinates for Shattrath City

---

## v1.1.0

### New Features
- **ESC to Close** - Press Escape to close the Primal Ledger window

### Improvements
- Expanded profession detection for future cooldown support

---

## v1.0.1

### Improvements
- UI no longer wipes data when opened - shows saved data immediately
- Opening a profession window now only refreshes data for that specific profession

---

## v1.0.0

### Initial Release
- Account-wide cooldown tracking for Alchemy and Tailoring
- Auto-detection of professions and known crafts
- Minimap button to toggle the cooldown window
- Click-to-craft: Left-click "Ready!" to open profession, right-click to select recipe
- Current character always appears at the top of the list
- Slash commands: `/pl`, `/pl reset`, `/pl remove`

### Tracked Cooldowns
**Tailoring:** Shadowcloth, Spellcloth, Primal Mooncloth, Mooncloth

**Alchemy:** Transmute Primal Might, Transmute Arcanite, Transmute Undeath to Water, Transmute Mithril to Truesilver, Transmute Iron to Gold
