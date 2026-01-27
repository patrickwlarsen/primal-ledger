# Primal Ledger

A World of Warcraft TBC Anniversary addon that tracks Alchemy and Tailoring cooldowns across all your characters.

## Features

- **Account-wide tracking** - Track cooldowns across all your characters
- **Auto-detection** - Automatically detects professions and known crafts when you log in
- **Minimap button** - Click to toggle the cooldown window
- **Click to craft** - Click "Ready!" to open your profession window with the recipe selected
- **Current character first** - Your logged-in character always appears at the top of the list

## Tracked Cooldowns

### Tailoring
| Craft | Cooldown |
|-------|----------|
| Shadowcloth | 4 days |
| Spellcloth | 4 days |
| Primal Mooncloth | 4 days |
| Mooncloth | No cooldown |

### Alchemy
| Craft | Cooldown |
|-------|----------|
| Transmute: Primal Might | 20 hours |
| Transmute: Arcanite | No cooldown |
| Transmute: Undeath to Water | 24 hours |
| Transmute: Mithril to Truesilver | 20 hours |
| Transmute: Iron to Gold | 20 hours |

## Installation

1. Download or clone this repository
2. Copy the `PrimalLedger` folder to your WoW AddOns directory:
   ```
   World of Warcraft/_classic_/Interface/AddOns/PrimalLedger/
   ```
3. Restart WoW or type `/reload`

## Usage

- **Open the window**: Click the minimap button or type `/pl`
- **Update cooldowns**: Open your profession window (Alchemy/Tailoring) to sync cooldown data
- **Quick craft**: Click "Ready!" next to any available cooldown to open the craft window

## Slash Commands

| Command | Description |
|---------|-------------|
| `/pl` | Toggle the cooldown window |
| `/primalledger` | Toggle the cooldown window |
| `/pl reset` | Reset all tracked data |
| `/pl remove` | Remove current character from tracking |
