# Primal Ledger

A World of Warcraft TBC Anniversary addon that tracks Alchemy and Tailoring cooldowns across all your characters.

## Features

- **Account-wide tracking** - Track cooldowns across all your characters
- **Auto-detection** - Automatically detects professions and known crafts
- **Minimap button** - Click to toggle the cooldown window
- **Keybinding support** - Set a custom keybind in Key Bindings > AddOns > Primal Ledger
- **ESC to close** - Press Escape to close the window
- **Click to craft** - Left-click "Ready!" to open profession window, right-click to select recipe
- **Current character first** - Your logged-in character always appears at the top of the list
- **Per-profession sync** - Opening a profession window refreshes cooldown data for that profession only
- **Sources tab** - View pattern sources with clickable item links, vendor targeting, and TomTom waypoints

## Tracked Cooldowns

### Tailoring

| Craft | Cooldown |
|-------|----------|
| Shadowcloth | 92 hours |
| Spellcloth | 92 hours |
| Primal Mooncloth | 92 hours |
| Mooncloth | No cooldown |

### Alchemy

| Craft | Cooldown |
|-------|----------|
| Transmute: Primal Might | 20 hours |
| Transmute: Arcanite | 48 hours |
| Transmute: Undeath to Water | 24 hours |
| Transmute: Mithril to Truesilver | 20 hours |
| Transmute: Iron to Gold | 20 hours |

## Installation

1. Download the latest release from the [Releases](https://github.com/patrickwlarsen/primal-ledger/releases) page
2. Extract the `PrimalLedger` folder to your WoW AddOns directory:
   ```
   World of Warcraft/_anniversary_/Interface/AddOns/
   ```
3. Restart WoW or type `/reload`

## Usage

- **Open the window**: Click the minimap button, type `/pl`, or use your keybind
- **Set a keybind**: ESC > Key Bindings > AddOns > Primal Ledger
- **Close the window**: Click the X button, press Escape, or use your keybind
- **Update cooldowns**: Open your profession window (Alchemy/Tailoring) to sync cooldown data
- **Quick craft**:
  - **Left-click** "Ready!" to open the profession window and select the recipe
  - **Right-click** "Ready!" to select the recipe in an already-open profession window
- **Sources tab**:
  - View where to obtain patterns for tailoring cooldown crafts
  - **Shift-click** item links to paste them in chat
  - **Click vendor name** to target the NPC
  - **Click TomTom** to set a waypoint (requires TomTom addon)

## Slash Commands

| Command | Description |
|---------|-------------|
| `/pl` | Toggle the cooldown window |
| `/primalledger` | Toggle the cooldown window |
| `/pl reset` | Reset all tracked data |
| `/pl remove` | Remove current character from tracking |

## Development

### Setup

```bash
npm install
cp config.example.json config.json
```

Edit `config.json` with your WoW AddOns folder path.

### Scripts

| Command | Description |
|---------|-------------|
| `npm run deploy` | Deploy addon to WoW folder (silent) |
| `npm run deploy:verbose` | Deploy addon with output |
| `npm run build` | Create release zip (silent) |
| `npm run build:verbose` | Create release zip with output |

### Manual Commands

```bash
node deploy.js          # deploy (verbose)
node deploy.js --silent # deploy (silent)
node build.js           # build (verbose)
node build.js --silent  # build (silent)
```

Release zips are saved to the `releases/` folder.

## License

MIT
