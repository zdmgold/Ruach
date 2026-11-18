# Ruach decision log

**Read this file first when picking up the project.** Before it, read the Ruach Master Blueprint in the Claude project files. The blueprint says what to build; this file says what was decided while building, what is finished, and what is next.

## How to use this log

- Append a new entry at the bottom of "Decisions" whenever a choice is made that the blueprint does not already settle, or whenever a build fact overrides the blueprint. Number entries D-001, D-002 and so on. Never rewrite an old entry; add a new one that supersedes it.
- Update the "Batch status" table at the end of every batch, in the same commit as the batch.
- Update "Open items" when something is requested from the owner or resolved.
- Never write secrets (tokens, passwords, keystore contents) into this file or anywhere in the repo.
- Delivery flow for every batch: commit to `ci-analyser`, read the `check` workflow result and logs through the GitHub API, fix on that branch until green, then push the same commit to `main`. Commit messages read `batch-id: purpose`.

## Locked identity (from blueprint section 1)

| Field | Value |
| --- | --- |
| Name | Ruach |
| Store title | Ruach: Bible Car Racing Game |
| Bundle and application ID | com.zdmgold.ruach |
| Signing key alias | Ruach |
| Remove Ads product ID | com.zdmgold.ruach.removeads |
| Store category | Games, Racing |
| Stack | Flutter and Flame, Dart |
| Languages | en, es, fr, de, pt-BR, ar, hi, ja, ko, zh-Hans, he |
| Audience | General, 13 and over |
| Cheapest target device | Redmi A5 profile (3 GB, 720x1640) |

All rows marked Proposed in blueprint section 1 were confirmed by the owner on 2026-11-18, including all 16 tracks at launch.

## Batch status

| Batch | Status | Notes |
| --- | --- | --- |
| p0 | Done | `.gitignore` pushed to main on its own so the empty repo stays clean |
| p1a | Done | Repo files, docs, check workflow, bootstrap workflow, check scripts; check.yml green on ci-analyser |
| p1b | Next | Run the manual bootstrap workflow, then edit manifests, gradle, plist, pubspec and analysis options |
| p1c to p8c | Not started | See blueprint section 10 |

## Open items

| # | Item | Status |
| --- | --- | --- |
| 1 | Repository and access token | Received 2026-11-18. The token was pasted into chat, so revoke it when the build is finished and issue a new one for any later work |
| 2 | Cloudflare Pages project and site URL | Pending, needed after p1c and before p2f |
| 3 | Name clearance search for Ruach (Play, App Store, USPTO, EUIPO TMview, WIPO) | Pending from owner |
| 4 | Native reviewers for non-English languages | Pending; unreviewed languages are listed below once translated |
| 5 | Signing passwords | Requested at p7b only; a fresh password should be generated for the real keystore |
| 6 | Apple team ID and App Store Connect key | Needed at p7b for iOS |
| 7 | Production AdMob IDs | Needed before release; test IDs only until then |
| 8 | Repository license choice | Pending |

## Decisions

### D-001: decision log file name
The blueprint called this file `docs/decision.md`. The owner asked for `docs/decisions.md`. The file is `docs/decisions.md`, and every blueprint reference to `decision.md` means this file.

### D-002: Flutter version pin
The sandbox cannot run Flutter, so the exact version cannot be read locally. `check.yml` starts on the stable channel and prints `flutter --version`. After the first green run that has the app present, pin the exact version in `check.yml`, `build_and_deploy.yml` and `emulator.yml`, and record it here.

### D-003: check workflow tolerates an app-less repo
Until `app/pubspec.yaml` exists (p1b), `check.yml` runs only the repository-level checks and skips the Flutter steps, so p1a can go green on its own.

### D-004: bootstrap workflow
Flutter platform folders are generated on a GitHub runner by the manual `bootstrap.yml` workflow (`flutter create --org com.zdmgold --project-name ruach --platforms android,ios app`), because the sandbox has no Flutter SDK. It refuses to run if `app/` already exists.

### D-005: git author
Commits use the author `zdmgold <zdmgold@users.noreply.github.com>`.

### D-006: Test ad IDs
Google's sample AdMob IDs are copied from AdMob's documentation at p2f and recorded here then. None are recorded yet.

## Unreviewed languages

None translated yet. Non-English languages arrive at p6b and are listed here as unreviewed until a native speaker confirms them.
