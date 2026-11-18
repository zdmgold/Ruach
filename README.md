# Ruach

Ruach: Bible Car Racing Game. A free 2D top-down racing game for Android and iOS, built with Flutter and Flame. Chariot races, Exodus-style escapes and modern cars on biblical tracks, with scripture verse cards in 11 languages.

- Bundle ID: `com.zdmgold.ruach`
- Audience: general, age 13 and over
- Scripture: public-domain and openly licensed translations only; notices are listed in the app and in `docs/scripture_sources.md`

## Repository layout

| Path | What it is |
| --- | --- |
| `app/` | The Flutter and Flame application |
| `website/` | Static marketing, privacy and support site, plus later the downloadable Bible packs |
| `tools/` | Scripture extraction, audio synthesis and check scripts |
| `docs/` | `decisions.md` (the running decision log), `scripture_sources.md`, runbook |
| `store_submission/` | Store listings, data-safety answers, screenshot plan |
| `.github/workflows/` | `check.yml` on every push; builds and emulator runs are manual only |

## For a new contributor or agent

1. Read the Ruach Master Blueprint (kept in the Claude project files). It is the source of truth for scope, architecture and the batch plan.
2. Read `docs/decisions.md` from the top. It records every decision made while building and says which batch comes next.
3. Work one batch at a time, push it to the `ci-analyser` branch, wait for `check.yml` to pass, then push the same commit to `main`.

## Status

See the batch table in `docs/decisions.md`.
