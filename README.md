# Horizon Suite – Focus

A clean, glassmorphism-style replacement for the default World of Warcraft objective tracker, built for the Midnight era. All settings are saved per character.

---

## Current Functionality

### Core tracker
- **Replaces the default objective tracker** when enabled; the Blizzard tracker is hidden so only Horizon Suite shows objectives.
- **Tracked quests** from your quest log and world quest watch list, grouped by category (Campaign, World, Calling, Legendary, Complete, etc.).
- **Collapsible panel**: click the header or use `/horizon collapse` to collapse/expand (header-only or full list).
- **Draggable panel** with position saved across sessions; optional **lock position** in options.
- **Scrollable content** when the list exceeds max height (mouse wheel).
- **Optional zone filter**: show only quests in your current zone.

### Quest display
- **Quest type icons** (campaign, world, legendary, calling, etc.) next to each title.
- **Zone labels** under each quest title.
- **Section headers** (e.g. Campaign, World Quests, Rares) with optional custom colors.
- **Objective progress** with distinct styling for completed objectives.
- **Quest item buttons** on the right of quests that have usable items (click to use).
- **Active-quest highlight**: optional bar or background highlight for the super-tracked quest.
- **Typography**: configurable font, header/title/objective/zone/section sizes, outline, and text shadow.

### World quests & map
- **World quests** from the map watch list are merged into the tracker.
- **Quests-on-map** for your current zone (and parent/child maps) appear as “nearby” and are included.
- **Map close sync**: when you close the world map after untracking world quests there, the tracker updates to match.

### Rare bosses
- **Rare bosses on the current map** (vignettes) can be shown in the tracker with “Available” as the objective.
- **Rare-added sound** when a new rare appears (optional).
- **Click rare** → super-track on map and open map; **right-click rare** → clear super-track.

### Mythic+ block
- **M+ block** (optional): when in a Mythic+ dungeon, shows timer, completion stage (e.g. 2/8), and affixes. Can be placed above or below the quest list.

### Floating quest item
- **Floating quest item button** (optional): Extra Action–style button for the super-tracked quest’s item, or the first quest with an item. Configurable size, anchor (left/right/top/bottom of tracker), and offset. Works in combat via secure templates.

### Interactions
- **Left-click quest** → set super-tracked (map pin).
- **Double-click quest** → open quest in Quest Log / map details.
- **Right-click quest** → remove from tracker (untrack).
- **Left-click untracked quest** (e.g. in tooltip) → add to tracker.
- **Mouse wheel** on the panel → scroll when content overflows.

### Animations & effects
- **Entry animations**: quests slide in and fade in when added; slide out and fade out when removed.
- **Collapse/expand** animation for the panel.
- **Objective progress flash**: green flash when an objective is completed.
- **Height animation**: panel height smoothly follows content (optional grow-up anchor).

### Options panel
- **Open via** `/horizon options` (or `/horizon config`) or the gear button on the tracker header.
- **Tabs**: Appearance, Layout, Display, Visibility, Effects.
- **Appearance**: Font, all font sizes, outline, shadow (X/Y/alpha), panel width, max content height, and full **quest/section color** matrix (per quest type and overrides for zone, objective, completed objective, highlight).
- **Layout**: Start collapsed, lock position, grow upward (fix bottom edge).
- **Display**: Quest count in header, header divider, super-minimal mode (hide “Objectives” header), section headers, zone labels, quest type icons, active quest highlight style, quest item buttons.
- **Visibility**: Filter by current zone, show rare bosses, rare-added sound.
- **Effects**: Enable/disable animations, objective progress flash.
- Options panel is movable; position is saved.

### Slash commands
| Command | Description |
|--------|-------------|
| `/horizon` | Show help and command list |
| `/horizon toggle` | Enable or disable the addon (restores Blizzard tracker when disabled) |
| `/horizon collapse` | Collapse or expand the panel |
| `/horizon options` | Open options (same as gear button) |
| `/horizon reset` | Clear test data and refresh from live quest log |
| `/horizon resetpos` | Reset panel position to default |
| `/horizon test` | Fill tracker with sample quest data (for preview) |
| `/horizon testsound` | Play the rare-added notification sound |

### Key binding
- **Collapse Tracker** can be bound in the Key Bindings UI under **Horizon Suite - Focus**.

### Technical
- **SavedVariables**: `ModernQuestTrackerDB` (position, collapsed state, all options).
- **Combat-safe**: toggling and moving are blocked in combat where required; layout refresh runs after combat if needed.
- **Interface**: 120001 / 120000 (current retail).

---

## Installation

1. Download or clone into `World of Warcraft\_retail_\Interface\AddOns\`.
2. Ensure the folder is named `ModernQuestTracker` (the TOC and namespace use this name; the title in-game is “Horizon Suite - Focus”).
3. Enable **Horizon Suite - Focus** in the AddOns list at the character selection screen.

---

## License

MIT License. See [LICENSE](LICENSE).
