# Changelog

All notable changes to Horizon Suite are documented here.

---

## [1.0.0] – 2026-02-13

### New Features

- **Modular architecture** — Horizon Suite is now a core addon with pluggable modules. The Focus (objective tracker) is the first module. A new **Modules** category in options lets you enable or disable each suite. Use `/horizon toggle` or Options → Modules → Enable Focus module to turn the tracker on or off. Additional suites will appear as modules in the same options panel. SavedVariables remain compatible; existing installs default to Focus enabled.

- **Presence module** — Cinematic zone text and notifications. Replaces default zone/subzone text, level-up, boss emotes, achievements, quest accept/complete/update, and world quest banners with styled notifications. Priority queueing, smooth entrance/exit animations, and "Discovered" lines for zone discoveries. Enable in Options → Modules → Enable Presence module. Test with `/horizon presence` (e.g. `/horizon presence zone`, `/horizon presence all`). Blizzard frames are fully restored when Presence is disabled. (Renamed from Vista; `/horizon vista` is now `/horizon presence`.)

### Improvements

- **Options panel UX overhaul** — Cinematic, modern, minimalistic redesign: softer colour palette with low-contrast borders and dividers; pill-shaped search input; taller sidebar tabs with hover states; minimal X close button; section cards with inset backgrounds; refined toggles, sliders, dropdowns, and colour swatches; subtle dividers between colour-matrix sections; consistent hover feedback on buttons and tabs.

- **Search bar redesign** — Custom-styled search input without Blizzard template: search icon (spyglass) on the left, integrated clear button (visible only when typing), subtle focus state with accent-colour border, and tighter visual connection to the results dropdown.

---

## [0.7.1] – 2026-02-13

### Improvements

- **Zone labels** — Refined how quest zone names are chosen so objectives show clearer, more accurate zone labels, especially when quests span parent/child maps.

- **Mythic+ integration** — Improved how Mythic+ objectives and blocks behave in the tracker and options, with clearer descriptions and more consistent behaviour.

- **Options usability** — Polished several option labels and descriptions (including Mythic+ and zone-related settings) to better explain what they do and how they interact.

- **Options panel overhaul** — Fixed search so clicking a result now switches to the correct category and scrolls to that setting. Settings are reorganized into eight categories (Layout, Visibility, Display, Features, Typography, Appearance, Colors, Organization) for easier discovery. Toggles use a rounded pill style; search results show category and section with the option name emphasised.

- **World quest map fallback removed** — World quests are now sourced only from live APIs (`GetTasksTable`, `C_QuestLog.GetQuestsOnMap`, `C_TaskQuest` map APIs, and waypoint fallback) without requiring the world map to be open. The previous map-open cache and heartbeat fallback have been removed.

---

## [0.7.0] – 2026-02-13

### Improvements

- **Version 0.7.0** — Release bump.

---

## [0.6.9] – 2026-02-13

### New Features

- **Nearby group toggle** — Toggle to show or hide the nearby group section, with key binding support. Key bindings can be set in the game’s Key Bindings → AddOns → Horizon Suite. Animation and behaviour for the nearby group section have been enhanced.

- **Dungeon support** — Quest tracking now supports Dungeon quests so dungeon objectives appear correctly in the tracker.

- **Delve support** — Delve quests are supported with updated event handling so Delve objectives are tracked and displayed.

### Improvements

- **Floating quest item button** — Styling, text case options, and UI layout improved. Button behaviour and layout (e.g. icon, label, progress) are more consistent and configurable.

- **Quest caching** — Quest ID retrieval and caching logic refactored for better reliability. Event handling and debugging around quest updates have been improved.

- **README** — Documentation revised for clarity and formatting.

---

## [0.6.6] – 2026-02-11

### New Features

- **Weekly quests** — New category for weekly (recurring) quests with its own section in the tracker. Weekly quests in your current zone are auto-added like world quests. Quest classification now uses a single source of truth for determining world quests.

- **Daily quests** — Daily quests are supported with their own section and labeling. Daily quests in your current zone are auto-added to the tracker. Quests that are available to accept but not yet accepted show an **"— Available"** label.

- **Focus sort mode** — In Options → Categories, you can choose how entries are ordered within each category: **Alphabetical**, **Quest Type**, **Zone**, or **Quest Level**. A new options section controls sorting within categories.

### Improvements

- **Quest caching** — Quest caching logic improved for your current zone and parent maps so quests display correctly without needing to open the map first.

- **Quest bar layout** — Left offset for quest bars adjusted for more consistent layout.

- **Database refactor** — All references updated from `HorizonSuiteDB` to `HorizonDB` for consistency. Options panel and quest tracking aligned to the new saved variable name; TOC and changelog updated accordingly.

---

## [0.6.5] – 2025-02-10

### New Features

- **Hide in combat** — New option in General (Combat section): when enabled, the tracker panel and floating quest item button are hidden while in combat. When combat ends, visibility is restored according to your existing settings (instance visibility, collapsed state, quest content). When **Animations** is enabled, the tracker and floating button fade out over ~0.2s on entering combat and fade in on leaving combat.

- **Focus category order** — The order of categories in the Focus list (Campaign, World Quests, Rares, etc.) can now be customised. In the options popout (Appearance), reorder categories via drag-and-drop; the new order is saved and used for section headers and section header colors. Use "Reset order" to restore the default order.

### Improvements

- **Settings panel** — The options/settings UI has been updated for clearer layout and easier navigation.

- **New settings** — A range of new options have been added across General, Appearance, and other sections so you can tailor the tracker and behaviour to your preference.

---

## [0.6] – 2025-02-09

### New Features

- **World quest tracking** — World quests in your current zone now appear in the tracker automatically, using both `C_QuestLog` and `C_TaskQuest` data. No need to track every WQ manually.

- **Cross-zone world quest tracking** — World quests you track via the map watch list stay in the tracker when you leave their zone. They are shown with an **[Off-map]** label and their zone name. Use **Shift+click** on a world quest entry to add it to your watch list so it appears on other maps.

- **World map cache** — Opening the world map caches quest data for the viewed map and your current zone. World quests appear more reliably and update when you change map or close the map.

- **Map-close sync** — Closing the world map after untracking world quests there updates the tracker immediately so untracked WQs are removed.

- **Per-category collapse** — Section headers (Campaign, World Quests, Rares, etc.) can be clicked to collapse or expand that category. Collapse state is saved per category. Collapsing uses a short staggered slide-out animation.

- **Combat-safe scrolling** — Mouse wheel scrolling on the tracker is disabled during combat to avoid taint.

### Improvements

- **Focus category reorder UX** — The category order list in options now uses live drag-and-drop: a ghost row follows the cursor, an insertion line shows the drop position, the list auto-scrolls when dragging near the edges, and Reset order updates the list immediately. All Focus groups (Campaign, Important, Quests, etc.) are always shown.

- **Nearby quest detection** — Parent and child maps are considered when finding “nearby” quests, so quests in subzones and parent zones are included.

- **Active task quests** — Quests from `C_TaskQuest.IsActive` (e.g. bonus objectives, invasion points) are shown in the tracker under World Quests.

- **Zone change behaviour** — World quest cache is cleared on major zone changes (`ZONE_CHANGED_NEW_AREA`) but kept when moving between subzones, reducing flicker when moving within a zone.

- **Delayed refresh** — An extra refresh runs 1.5s after login and after zone changes so late-loading quest data is picked up.

### Fixes

- **TOC** — Version set to 0.6. SavedVariables corrected to a single line: `HorizonDB`.

- **Debug overlay removed** — The development-only world quest cache indicator (bottom-left of screen when the map was open) has been removed from release builds.

- **World map hook polling** — Reduced from 30 retry timers to 5 when waiting for the world map to load; map show/hide hooks no longer reference the removed indicator.

### Technical

- World quest data flow uses `C_QuestLog.GetQuestsOnMap`, `C_TaskQuest.GetQuestsForPlayerByMapID`, and optional `WorldQuestDataProviderMixin.RefreshAllData` hook when available.
- Per-category collapse state is stored in `HorizonDB.collapsedCategories`.

---

## [0.5] and earlier

Initial release and earlier versions. See README.md for full feature list.
