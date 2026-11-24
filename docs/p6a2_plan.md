# Proposed batch p6a-2: close the audit gaps (draft, not started)

Source: D-044. Goal: every capability row in the blueprint is reachable from the UI and wired before the ten translations are written, so p6b translates the final English text once. Two commits, each green on ci-analyser before main.

## p6a-2a: scripture moments and screens (items 1, 2, 3, 5, 7)

| # | Change | Files | Tests |
| --- | --- | --- | --- |
| 1 | **Daily verse and welcome-back.** The daily verse shows on the new Daily Run screen and the Weekly screen. A welcome-back verse card shows once on Home when `daily.welcomeBackDue`; dismissing it stores the day it was shown (optional Progress field, tolerant reader, no schema bump). | screens/home_screen, weekly_screen, providers/daily_provider, core/models/progress | Home shows the card after a missed day and not twice |
| 1 | **Milestones.** Pure rule `MilestoneRules`: era completed (all four tracks of an era have a star), an upgrade reaching level 5, first Gift spent. Each fires once (`milestonesSeen` in Progress) and shows a `milestone` verse card on the Result screen or in the Garage. | core/logic/milestone_rules (new), progress, result_screen, garage_screen | Rule tests per milestone; fires once |
| 1 | **Upgrade verse.** Each Garage upgrade tile expands to its `upgrade` verse (replaces the fixed reference). | garage_screen, widgets/upgrade_tile | Tile shows its own verse |
| 2 | **Daily Run screen.** Today's track, vehicle and wind; attempts used and the extra-attempt rule; streak; reminder switch (same setting as Settings); verse of the day; Start goes to the track intro. Home's Daily card opens it. | screens/daily_run_screen (new), routes, home_screen, app.dart | Locked-in setup shown; Start routes to intro; reminder switch persists |
| 3 | **Time Trial ghost toggle.** A persisted setting, shown as a switch on the Time Trial track list; the ghost car is not loaded when off. | core/models/settings, track_list_screen, race_provider | Toggle hides the ghost |
| 5 | **Rating prompt.** Progress gains `reviewAsked`. Rule: ask once, after a podium finish, never after a poor result, not before the third finished race. Result screen calls the review port after a short delay and records it. | progress, core/logic/review_rule (new), result_screen, ShellPorts | Asks once on a podium; never on a loss; never twice |
| 7 | **Vehicle choice.** The track intro and Quick Race get an owned-vehicle picker; the Daily and Weekly setups stay fixed. | track_intro_screen, widgets/vehicle_picker (new) | Picker changes the race vehicle; hidden in Daily |

## p6a-2b: wiring and shell (items 4, 6, 8, 9, 11)

| # | Change | Files | Tests |
| --- | --- | --- | --- |
| 4 | **Sound and haptics.** A `Feedback` provider joins the audio and haptics ports to the settings (switches and the two volumes apply live). A pure `RaceCue` detector turns simulation changes into cues: countdown, boost, contact, lap, finish. The race screen plays them; menu music starts and stops with the race. Sound files arrive at p7a, so until then calls are silent but haptics already work. | core/logic/race_cues (new), providers/feedback_provider (new), race_screen, boot.dart, ShellPorts | Cue detector tests; fake ports record cues; switches off means no calls |
| 6 | **Remove Ads affordance.** A small "Remove ads" link beside the banner opens the upgrade screen; the Settings row shows an "Ads removed" badge once owned. | widgets/screen_frame, settings_screen | Link only while a banner shows |
| 8 | **HUD text scale cap.** The race HUD clamps text scaling (1.3) so it never covers the track. | game/hud_layer | Large system font keeps the HUD inside the screen |
| 9 | **Widget build errors reach the fallback.** The error handler treats a build-time framework error as fatal and `ErrorWidget.builder` draws nothing, so the fallback screen shows. | utils/error_handler, boot.dart | A throwing widget shows the fallback |
| 11a | **Adaptive banner.** The shell publishes the banner's real height; `ScreenFrame` reads it instead of each screen's constant of 50. | app_services, app.dart, widgets/screen_frame, platform/ad_service, ad_banner | Frame reserves the published height; collapses at 0 |
| 11b | **Dust wall on pursuit tracks.** Red Sea Crossing and Babylon Gates draw the abstract wall in every mode. | game/effects, race_game | Wall drawn only on pursuit tracks |

## Item 10 (iOS tracking prompt): no code in this batch
The prompt comes from the UMP message you configure in AdMob (privacy and messaging, IDFA explainer). I add the step to the runbook at p7c and verify the order on the first TestFlight build at p7b.

## Decisions I need from you
1. **Pursuit wall (11b).** Visual only (safe, keeps the balance numbers and replay hashes), or does it also slow cars it catches (changes the race and the balance simulation)? I recommend visual only now.
2. **Adaptive banner (11a).** Worth the extra change before the first phone test, or keep 320 by 50 until later? It earns a little more but touches every menu screen.
3. **Milestone cards.** One card per milestone, shown once and kept in the Verse library. OK?

## Order and checks
Build p6a-2a, then p6a-2b, each pushed to ci-analyser and moved to main only when green. Decision entries D-045 and D-046. Then Test APK 1b only if you want one before p6b; otherwise p6b follows.
