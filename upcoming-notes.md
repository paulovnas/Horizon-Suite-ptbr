# Horizon Suite — Live log

*Local log for plans, bugs, and progress. Tell Cursor: "add to the log" or "log: ...".*

---

## How to use (for Cursor)

- **Log a bug:** Add under "Bugs" with status `[OPEN]` or `[FIXED]`, date, and short description.
- **Log a fix:** Add a line under "Changelog" and move/update the bug under "Bugs" to `[FIXED]` with what was done.
- **Log a plan:** Add under "Upcoming plans" with optional link to a .plan.md file.
- **Log backlog/idea:** Add under "Backlog / ideas".
- Use `YYYY-MM-DD` for dates. Keep entries one line when possible; add bullets only for detail.

---

## Changelog

- 2026-02-13 — Improved M+ design.
- 2025-02-13 — Focus collapse fix (EnsureFocusUpdateRunning in ToggleCollapse, early return in FullLayout when collapsed, #grouped >= 1 for showSections).

---

## Bugs

- [FIXED] Focus shows old completed achievements. Plan: skip in FocusAchievements.lua when GetAchievementInfo reports completed; optional "Show completed achievements" setting. → [focus_tracker_completed_quests_fix_8dcb85ec.plan.md](.cursor/plans/focus_tracker_completed_quests_fix_8dcb85ec.plan.md)
- [FIXED] Collapse on Focus not working. Fixed: EnsureFocusUpdateRunning in ToggleCollapse; early return in FullLayout when collapsed; #grouped >= 1 for showSections.

---

## Upcoming plans

- Pull unaccepted available quests in the current zone.
- Vertical spacing between quest entries and categories.
- Investigate "pop up quests" not appearing in the log.
- Improve performance: event-based instead of frame-by-frame polling.
- Track specific world quests even when world quests are turned off.

---

## Backlog / ideas

- Integration with Auctionator/Auctioneer for search materials.

---

## Reference

### Presence module review

*Which Presence banners have corresponding Blizzard frame removal, and where else we could use the system.*

- **Banner ↔ suppression:** Every Presence type that replaces a Blizzard UI has matching suppression/restore: ZoneTextFrame / SubZoneTextFrame (zone/subzone), LevelUpDisplay, RaidBossEmoteFrame, EventToastManagerFrame + AlertFrame (achievement, quest complete), WorldQuestCompleteBannerFrame (world quest). QUEST_ACCEPT and QUEST_UPDATE don't replace a default center banner; we only add our own or clear UIErrorsFrame.
- **Suppressed but not replaced:** BossBanner (boss kill), ObjectiveTrackerBonusBannerFrame (bonus objective), ObjectiveTrackerTopBannerFrame (scenario/top banner), and non-achievement/quest toasts in EventToastManagerFrame are hidden only — no Presence line.
- **Possible extensions:** (1) Add BOSS_DEFEATED (or reuse BOSS_EMOTE) and hook boss kill so BossBanner is replaced. (2) Add BONUS_OBJECTIVE and/or SCENARIO_COMPLETE to replace bonus/top tracker banners. (3) Optional TOAST/INFO type for other toasts (recipe, loot). (4) Document type → frame mapping in PresenceBlizzard.lua or README.
- **Full plan:** [presence_module_review_f6f8e1cc.plan.md](.cursor/plans/presence_module_review_f6f8e1cc.plan.md)
