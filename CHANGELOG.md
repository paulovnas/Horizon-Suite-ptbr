# Changelog

All notable changes to Horizon Suite - Focus are documented here.

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

- **Nearby quest detection** — Parent and child maps are considered when finding “nearby” quests, so quests in subzones and parent zones are included.

- **Active task quests** — Quests from `C_TaskQuest.IsActive` (e.g. bonus objectives, invasion points) are shown in the tracker under World Quests.

- **Zone change behaviour** — World quest cache is cleared on major zone changes (`ZONE_CHANGED_NEW_AREA`) but kept when moving between subzones, reducing flicker when moving within a zone.

- **Delayed refresh** — An extra refresh runs 1.5s after login and after zone changes so late-loading quest data is picked up.

### Fixes

- **TOC** — Version set to 0.6. SavedVariables corrected to a single line: `HorizonSuiteDB, ModernQuestTrackerDB`.

- **Debug overlay removed** — The development-only world quest cache indicator (bottom-left of screen when the map was open) has been removed from release builds.

- **World map hook polling** — Reduced from 30 retry timers to 5 when waiting for the world map to load; map show/hide hooks no longer reference the removed indicator.

### Technical

- World quest data flow uses `C_QuestLog.GetQuestsOnMap`, `C_TaskQuest.GetQuestsForPlayerByMapID`, and optional `WorldQuestDataProviderMixin.RefreshAllData` hook when available.
- Per-category collapse state is stored in `HorizonSuiteDB.collapsedCategories`.

---

## [0.5] and earlier

Initial release and earlier versions. See README.md for full feature list.
