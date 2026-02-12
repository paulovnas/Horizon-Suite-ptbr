# 🌌 Horizon Suite - Focus

**Horizon Suite - Focus** is a cinematic replacement for the default World of Warcraft objective tracker. Built for the Midnight era, it moves away from the static, cluttered list of the past and gives you total agency over how and when your goals appear on your screen.

<p align="center">
  <img width="383" alt="Horizon Suite Preview" src="https://github.com/user-attachments/assets/72072df2-7ba3-4205-a984-df561eaf3ed4" />
</p>

---

## 🧠 Intelligent Features

The logic that drives your efficiency.

**Spatial Awareness**
- **Current Zone Filter** - Automatically hides quests that aren't in your immediate area to cut through the noise.
- **Proximity Priority** - Dynamically floats "Nearby" quests to the top of the list so you never have to hunt for your next objective. Quest grouping into "Current Zone" works correctly in sub-zones and micro-dungeons (e.g. Foundation Hall within Dornogal) on initial load, without needing to open the map first.

**Dynamic Scanning**
- **Scenario Events** - Surfaces active scenario activities (main step and bonus steps) in a dedicated SCENARIO EVENTS section, always pinned to the top of the tracker. Supports Twilight's Call–style events with time remaining and cinematic progress bars. If a scenario row maps to a quest already in the list, the scenario row is shown and the duplicate quest row is suppressed (Options → Content).
- **Rare Boss Tracker** - Scans for nearby Rare vignettes and adds them to the tracker with a single click to super-track on the map. Optional sound when a rare is added (Options → Content).
- **World Map Sync** - Opening the world map automatically pulls active World Quests and Available quests into your tracker, keeping your UI in sync with your planning.
- **Weeklies & Dailies in Zone** - Weekly and daily quests that appear in your current zone are auto-added to the tracker (WEEKLY QUESTS and DAILY QUESTS sections). Quests you have not yet accepted show an "— Available" label so you can see what is ready to pick up.

**Combat & Utility**
- **Hide in Combat** - Automatically vanishes the tracker during encounters to clear your screen for mechanics.
- **Secure Quest Items** - High-performance quest item buttons built on secure templates, ensuring they work flawlessly mid-fight.
- **ATT Integration** - Full support for All The Things. Displays collection data directly within your objectives.

*Special thanks to the All The Things team for their incredible community data.*

---

## 🎨 Formatting & UI Design

The aesthetic that defines your interface.

**Visual Hierarchy**
- **Quest Type Icons** - Distinct, high-fidelity icons for Campaign, World Quests, Weekly (recurring), Legendaries, and Callings for instant identification.
- **Weekly & Daily Quests** - Recurring weekly and daily quests appear in "WEEKLY QUESTS" and "DAILY QUESTS" sections. Zone weeklies and dailies are auto-added like world quests. Quests available to accept but not yet accepted are labeled "— Available".
- **Turn-in Highlights** - Quests "Ready for Turn-in" receive a unique visual highlight, giving you a clear signal that it's time to head back to the hub.
- **Category Collapsing** - Granular control over your screen space. Collapse specific sections (like World Quests or Weekly Quests) while keeping your main Campaign visible.
- **Focus sort mode** - In Options → Categories, choose how entries are ordered within each category: Alphabetical, Quest Type, Zone, or Quest Level.

**Total Customization**
- **The Color Matrix** - Define your own hex-code reality. Customize the colors for every quest category (Default, Campaign, Legendary, World, Scenario, Weekly, Daily, Complete, Rare) and objective state via `/horizon options`. Scenario events use a distinct deep blue by default.
- **Typography Suite** - Total control over fonts, sizes, outlines, and text shadows for Headers, Titles, and Objectives.
- **Compact mode** - Reduce spacing between quest entries for a denser list.
- **Quest level display** - Show quest level next to the title.
- **Completed count** - Show X/Y objective progress in the quest title.
- **Objective numbers** - Prefix objectives with 1., 2., 3.
- **Dim non-super-tracked** - Slightly dim quests that are not super-tracked.
- **Panel & content height** - Resize the tracker via the bottom-right grip; max content height is saved in Options → General.
- **Shadow customization** - Options → Style: shadow X/Y offset and alpha.
- **Backdrop opacity** - Control tracker panel background opacity (0–1).
- **Border visibility** - Toggle the panel border on or off.
- **Highlight alpha & bar width** - Style the super-tracked quest bar or background (2–6 px bar width).
- **Section header colors** - Options → Colors: category label colors.

**Fluid Motion**
- **Entry/Exit Animations** - Quests slide and fade into view with modern, smooth transitions.
- **Objective Flash** - A subtle green pulse provides tactile feedback the moment you complete a requirement.
- **Adaptive Layout** - Smoothly animates height changes and supports "Grow Upward" anchoring to protect your action bar space.
- **Mythic+ block** - Options → Content: show timer, completion %, and affixes when in a Mythic+ dungeon (position: top or bottom).
- **Scenario Events** - Options → Content: show or hide the SCENARIO EVENTS section (always pinned first when visible). Scenario entries always display time remaining when timer data exists. Cinematic scenario bar, bar opacity, and bar height can be customized.

---

## 🕹️ Controls & Commands

| Command | Action |
|---------|--------|
| `/horizon options` | Open the full customization suite |
| `/horizon collapse` | Toggle the entire tracker or specific categories |
| `/horizon test` | Populate the tracker with sample data to help you style |
| `/horizon testitem` | Inject one debug quest with a quest item (real quests stay); use to test per-row and floating quest item buttons without a live quest item |
| `/horizon reset` | Clear test data and return to live quests (use after `/horizon test` or `/horizon testitem`) |
| `/horizon resetpos` | Snap the tracker back to its default center position |

**Mouse Interactions**
| Action | Result |
|--------|--------|
| **Left-Click** | Set as Super-Tracked (Map Pin) (or open quest log if "Click title to open quest log" is on) |
| **Double-Click** | Open Quest Log or Map details |
| **Right double-click** | Abandon quest (with confirmation) when "Right double-click to abandon" is enabled |
| **Right-Click** | Remove from tracker / Untrack |

**Instance visibility** - Options → General: show or hide the tracker in dungeon, raid, battleground, and arena.
**Grow upward** - Anchor the tracker by its bottom edge so the list expands upward.
**Lock position** - Prevent dragging to reposition the tracker.
**Start collapsed** - Objectives panel starts collapsed (header only) until you expand it.
**Super-minimal mode** - Hide the OBJECTIVES header for a pure text list.
**Options search** - Use the search box in the options panel to find settings by name or description.
**Category reorder** - Options → Categories: drag to reorder Focus category order. SCENARIO EVENTS is always pinned first and cannot be moved.

Key binding available: Collapse Tracker can be bound in Key Bindings under Horizon Suite - Focus.

---

## 📥 Installation

1. Download the repository and extract the `HorizonSuite` folder.
2. Place it in your `World of Warcraft\_retail_\Interface\AddOns\` directory.
3. Enable **Horizon Suite - Focus** in your AddOn list.
4. Type `/horizon options` to begin tailoring your experience.

---

## 💖 Support the Project

Horizon is built for players who want a more intentional WoW experience. If this addon has cleaned up your UI, consider supporting its development for the Midnight expansion.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/T6T71TX1Y1)

---

## License

MIT License. See [LICENSE](LICENSE).
