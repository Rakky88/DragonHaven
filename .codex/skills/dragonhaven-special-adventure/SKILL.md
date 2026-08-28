---
name: dragonhaven-special-adventure
description: Design, implement, test, and visually review calendar-based DragonHaven Special Adventures, including recurrence, rewards, Special Chests, eggs, new dragon families, notifications, and release-safe persistence.
---

# DragonHaven Special Adventure

Use DragonHaven's data-driven Special Adventure catalog. Events are not globally limited: any number may exist or overlap, each with its own availability window, adventure duration, recurrence and rewards. A player may start each event instance once unless the user explicitly chooses another rule; a run started while available must remain finishable after its window closes.

## Required event brief

Before implementation, obtain or make an explicitly stated, low-risk proposal for every item that is not already supplied:

- name and localized name;
- exact first start and end date/time, timezone, and how long the adventure remains available;
- whether and how it repeats, including recurrence start and the availability length of recurring instances;
- adventure duration and which Expertise values reduce it;
- theme and a short localized story;
- complete reward bundle, which rewards the detail screen reveals, and which remain random or hidden;
- whether the reward chest contains an egg;
- for an egg: incubation duration, trade behavior, special identifying text, and its dragon lineage;
- notification wording and tap destination;
- achievement, if any.

Dates must be represented as Europe/Amsterdam wall times and tested at the inclusive start, just before the exclusive end, and across relevant daylight-saving offsets. Persist a stable event-instance key on start so aborting, closing the app, backup/restore, or expiry cannot reset participation.

## New dragon invariant

If the egg introduces a new dragon, create the complete family asset set: Hatchling, Wyrmling, Might, Arcana, Spirit, Mastery, any required atlas, and achievement art. Keep the egg clue non-spoiling unless the user requests otherwise. Exclude secret lineages from ordinary egg rolls and general completion requirements.

Every new dragon family must be shown to the user in the Android emulator before release. Exercise every form at realistic UI sizes, inspect transparency and safe margins, and show screenshots so the user can verify style, fit and absence of cut-off. Do not treat automated sprite tests as visual approval. Record requested corrections and repeat the emulator review until the user approves the sprites.

Use the imagegen skill for new raster sprites. Retain source prompts and report final asset paths and generation mode.

## Implementation and proof

- Show all guaranteed/revealed rewards and event story when the Adventure is tapped. Conditional rewards such as a Music Chest must reflect current capacity.
- Grant random rewards only on claim/open at the specified boundary; never pre-roll chest contents unless explicitly requested.
- Preserve special egg identity through inventory, nest, trade, backup, restore and hatching.
- Schedule a notification for every calendar event and notify immediately when gameplay creates a non-calendar Special Adventure. Route both through the default-on `Special Events` account preference, cancel known future schedules when it is disabled, and open Available Adventures when a notification is tapped.
- Add focused tests for windows, recurrence, one-start-per-instance, duration reduction, rewards, capacity behavior, persistence, chest contents, egg incubation, secret lineage exclusion, achievement unlock, audio mapping and sprite bounds.
- If a new tradeable chest/item is introduced, update and stage the server allowlists/migration without changing production until release authorization is given.
- A request to create an event is not by itself permission to publish a release or migrate production. Obtain fresh authorization immediately before those external mutations.
