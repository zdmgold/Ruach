# Scripture sources

Provenance for every scripture file used by Ruach. Each source is downloaded by `tools/scripture/fetch.py` from `raw.githubusercontent.com` at the commit below and must match the SHA-256 or the build fails. Licence status is what the source itself states; items marked "to be re-confirmed" are checked again before release (blueprint section 5).

| Language | Translation | Licence as stated | Repository | Commit | File | SHA-256 | Date | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| English | Berean Standard Bible | Public domain (per repo) | https://github.com/seven1m/open-bibles | `8b330654ade6` | `eng-bsb.usfx.xml` | `7bf75004ecbc8901f179bd36078cf48fa4eb34cb2894791342ac840bcbf586fb` | 2026-11-19 | Extracted; verified by `tools/scripture/verify.py` |
| Spanish | Reina-Valera 1909 | Public domain (per repo) | https://github.com/seven1m/open-bibles | `8b330654ade6` | `spa-rv1909.usfx.xml` | `b59592def67de45f223da447ea376627e586c6568531171019084117df503151` | 2026-11-19 | Extracted; verified by `tools/scripture/verify.py` |
| French | Louis Segond 1910 | "Public Domain" in file; origin unverified | https://github.com/Beblia/Holy-Bible-XML-Format | `61622da8959f` | `FrenchBible.xml` | `ce46424902e4a35dfaf0afb83a4d91a3baa5ae16ac128f34af17e15d32c5786c` | 2026-11-19 | Extracted; verified by `tools/scripture/verify.py` |
| German | Luther 1912 | "We believe ... Public Domain" in file | https://github.com/seven1m/open-bibles | `8b330654ade6` | `deu-luther1912.osis.xml` | `5df33f4bf3e086b6490b467cf8ddbf4cf95126b2826efaddf17b223ddd07f92b` | 2026-11-19 | Extracted; verified by `tools/scripture/verify.py` |
| Portuguese (Brazil) | Bíblia Livre | CC BY 3.0 Brazil (per repo) | https://github.com/scrollmapper/bible_databases | `59b18c5af584` | `formats/json/PorBLivre.json` | `21b726be1a30abf1bb41dbf06c4bfceda258d5d5f667778713c1803d2dd16f7a` | 2026-11-19 | Extracted; verified by `tools/scripture/verify.py` |
| Arabic | Smith and Van Dyck 1865 | "Public Domain" in file | https://github.com/Beblia/Holy-Bible-XML-Format | `61622da8959f` | `ArabicSVDBible.xml` | `bb7701321cdb8b81cb4f23bd70d9fb287502d795921d9604114bb5460fe32f73` | 2026-11-19 | Extracted; verified by `tools/scripture/verify.py` |
| Hindi | Indian Revised Version 2019 | © Bridge Connectivity Solutions; CC BY-SA 4.0 to be re-confirmed | https://github.com/Beblia/Holy-Bible-XML-Format | `61622da8959f` | `HindiIRVBible.xml` | `a21d22e84fe97f01003723d9b07fc04fdd7ca93b2ca3bb8171eae77efdac2dc8` | 2026-11-19 | Extracted; verified by `tools/scripture/verify.py` |
| Japanese | Kougo-yaku 1954/55 | Public domain per repo; not independently confirmed | https://github.com/seven1m/open-bibles | `8b330654ade6` | `jpn-kougo.osis.xml` | `6930015f5d0faf49f3038a7e2f482aeb45939510b6acb8a8fb1945640c1d91b6` | 2026-11-19 | Extracted; verified by `tools/scripture/verify.py` |
| Korean | Korean Revised Version 1961 | Public domain per file (copyright expired 2011-12-31) | https://github.com/seven1m/open-bibles | `8b330654ade6` | `kor-korean.osis.xml` | `fa55e0dcd7ee1dd3cced563b1e3108c01c6bd774f095a3e773996c4b0a2e7f24` | 2026-11-19 | Extracted; verified by `tools/scripture/verify.py` |
| Simplified Chinese | Chinese Union Version | Public domain (per repo) | https://github.com/seven1m/open-bibles | `8b330654ade6` | `chi-cuv-simp.usfx.xml` | `bea9f6e4fd35b70a67e3978ce8b9dc0ad853078e67472653cf1b34f357ae3abf` | 2026-11-19 | Extracted; verified by `tools/scripture/verify.py` |
| Hebrew | Westminster Leningrad Codex (Old Testament) | Free to copy; cite version (tanach.us) | https://github.com/scrollmapper/bible_databases | `59b18c5af584` | `formats/json/WLC.json` | `9e126b91beee6feb87378b7bb84092093c2f76752cf0f043f3c81b611a3473fa` | 2026-11-19 | Extracted; verified by `tools/scripture/verify.py` |
| Hebrew | Delitzsch Hebrew New Testament 1885 | "Public Domain" in file | https://github.com/Beblia/Holy-Bible-XML-Format | `61622da8959f` | `Hebrew1885Bible.xml` | `3c3011a438eae86627dac6996abf76a1c45ddb4edc3743031fa9fddc8b3fd0ff` | 2026-11-19 | Extracted; verified by `tools/scripture/verify.py` |

Hebrew uses two files: the Old Testament from the Westminster Leningrad Codex and the New Testament from the 1885 Delitzsch translation. All 66 books of the Protestant canon are used for every language; no other books are read.

## Corrections applied by script

Every correction lives in `CORRECTIONS` in `tools/scripture/parse.py` and is counted when it runs.

| Language | Correction | Why |
| --- | --- | --- |
| French | Doubled apostrophes (`''`) become one | Listed in the plan from an earlier mirror. The pinned file contains none, so this changes nothing today. |
| Hindi | Footnote anchors (`#`) are removed | The mirror leaves `#` markers inside verse text. |

Other normalisation, applied to every language: non-breaking spaces become spaces and runs of whitespace collapse to one space. Japanese furigana annotations are dropped, footnotes and section headings are not part of verse text.

## Known gaps

| Language | Gap | Effect |
| --- | --- | --- |
| Hindi | The mirror has no text for 1 Kings 18 (an empty chapter) and is missing 46 verses against the Portuguese file | No curated verse is affected (verses are only chosen when present in all 11 languages). The Hindi full-Bible pack (p8a) needs a second Hindi source or a documented gap. |
| Several | Verse numbering differs between sources in many chapters (for example in the Psalms, where some sources number the title as verse 1, and in Acts 28) | Curated verses are only chosen from chapters with the same verse count in all 11 languages, plus one checked exception (Acts 28:15). The reader's per-language verse maps are built in p8a. |
| Hebrew | The Old Testament is pointed with cantillation; the New Testament is unpointed | Both display correctly; the mix is cosmetic. |
| Portuguese | The source states CC BY 3.0 Brazil, not 4.0 as the plan said | Notice uses 3.0 (decision D-024). |

## Curated verses

`tools/scripture/candidates.json` lists candidate references per moment in priority order; `tools/scripture/curate.py` keeps the first ones that exist in all 11 languages with matching verse counts, fills the quotas (6, 16, 20, 30, 40, 40, 60, 120 = 332 verses, none used twice), writes `curated.json`, and writes `app/assets/verses/<language>.json.gz`.
