---
name: ""
overview: ""
todos: []
isProject: false
---

# Scenario Start Presence Notification

**Pipeline:** FEAT OPEN 2026-02-13 [P1] (Presence)

## Overview

Add a Presence notification when the player enters a scenario (Delves, world scenarios, party dungeons). Mirrors Quest Accept: event- or state-driven detection → cinematic toast.

## WoW Events

No definitive "scenario started" event documented. Candidates to test:

- SCENARIO_CRITERIA_UPDATE
- SCENARIO_UPDATE
- SCENARIO_POI_UPDATE
- SCENARIO_COMPLETED (for "end" / resetting state)

Use `/eventtrace` or similar in-game to confirm which fire on scenario enter.

## Data Sources (existing)


| API                           | Use                             |
| ----------------------------- | ------------------------------- |
| C_Scenario.IsInScenario       | Active check                    |
| C_Scenario.GetInfo            | name, currentStage              |
| C_Scenario.GetStepInfo        | stageName (first step)          |
| C_PartyInfo.IsDelveInProgress | Delve vs scenario               |
| addon.IsInPartyDungeon()      | Party dungeon vs world scenario |


## Presence Integration

- Add `SCENARIO_START` to TYPES in PresenceCore.lua; category = DELVES | DUNGEON | SCENARIO.
- Toast: title = scenario name or label; subtitle = first step or context.
- Delves: optionally include tier via GetActiveDelveTier().

## Detection Strategies

**A. Event-driven:** Register SCENARIO_CRITERIA_UPDATE (etc.); when fired, if transition from !IsScenarioActive to IsScenarioActive, show toast. Track `wasInScenario`.

**B. State transition (recommended):** On existing 5s Focus ticker (or Presence-only ticker), detect transition !IsScenarioActive → IsScenarioActive. Show toast, set wasInScenario = true. On exit, reset.

**C. Hybrid:** Ticker for reliability; events for faster detection when available.

## Files to Touch

- PresenceCore.lua — SCENARIO_START type, resolveColors for category
- PresenceEvents.lua — Event registration + OnScenarioStart; or wire into Focus ticker
- PresenceSlash.lua — `/horizon presence scenario` test; add to demo reel
- FocusScenario.lua — Expose GetScenarioDisplayInfo() for title/subtitle/category

## Options / Edge Cases

- Toggle: "Show scenario start notification" (can reuse showScenarioEvents).
- Debounce to avoid duplicate toasts on rapid events.
- On reload while in scenario: optionally suppress "start" toast.
- Delve vs scenario vs dungeon: use IsDelveActive / IsInPartyDungeon for correct label.
- Empty names: fallback to "Scenario" / "Delve".

