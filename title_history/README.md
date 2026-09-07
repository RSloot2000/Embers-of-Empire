# EoE Title History Research Archive

The validated runtime files described below were migrated into `mods/eoe-main` on 2026-09-03. This directory now retains research, source decisions, and the reusable blueprint; it is not loaded by the mod.

Runtime paths listed below are relative to `mods/eoe-main`. New title-history projects should be researched here, validated in a temporary overlay, and moved into the main mod after approval.

## Phase 1

Phase 1 adds the historical holder sequence for the Western Roman Empire from 395 to 476 and a claim for Julius Nepos through 480.

Runtime files migrated to the main mod:

- `history/titles/eoe_western_roman_empire.txt`
- `history/characters/eoe_western_roman_emperors.txt`
- `history/characters/eoe_wre_historical_families.txt`
- `common/dynasties/eoe_western_roman_dynasties.txt`
- `common/nicknames/eoe_historical_nicknames.txt`
- `localization/english/eoe_wre_history_l_english.yml`
- `research/western_roman_empire_sources.md`
- `research/title_history_candidates.md`
- `TITLE_HISTORY_BLUEPRINT.md`

Vanilla Honorius and Valentinian III are reused. Ten missing emperors plus Orestes are defined locally. Every custom character has a fixed dynasty: documented families are shared where supported, while isolated rulers use explicitly documented name-based fallbacks. A separate family file connects the Valentinianic, Anician, Procopian, Avitan, and Nepos lines. Contemporary Latin name forms, the `Augustulus` nickname, and a small set of directly sourced traits provide visible flavor without invented heraldry or biographies.

The hegemon title must not receive a separate static history. Event `br_augustus_of_wr.006` copies `e_western_roman_empire` history into `h_western_roman_empire` when the hegemon title is created.

Use `TITLE_HISTORY_BLUEPRINT.md` to decide which parts of this pattern apply to other historical titles. Holder history is central; government, laws, lieges, names, and scripted effects are conditional gameplay data rather than default historical decoration.

## Bosporan Kingdom

The Bosporan staging set adds the documented Tiberian-Julian sequence for `k_bosporus` from AD 8 through 341/342. It includes 18 holders, the Odrysian/Sapaean identity of Gepaepyris, separate fallbacks for rulers of uncertain descent, the Roman annexation of AD 63-68, and explicit handling of co-rulers and disputed successors.

- `history/titles/eoe_bosporan_kingdom.txt`
- `history/characters/eoe_bosporan_kings.txt`
- `history/characters/eoe_bosporan_families.txt`
- `common/dynasties/eoe_bosporan_dynasties.txt`
- `common/dynasty_houses/eoe_historical_dynasty_houses.txt`
- `common/coat_of_arms/coat_of_arms/eoe_historical_dynasty_coas.txt`
- `common/nicknames/eoe_historical_nicknames.txt`
- `localization/english/eoe_bosporan_history_l_english.yml`
- `research/bosporan_kingdom_sources.md`

This history belongs only to `k_bosporus`, the title created by EoE's restoration decision. Do not copy it to the unused `k_bosporan_kingdom` or `e_bosporus` definitions.

Bosporan display names use attested Greek forms. Eunikē extends the confirmed early family tree, Aspourgos and Sauromatēs I receive sourced epithets, and the Tiberian-Julian titulary formula appears as its motto. Ininthimeos has a numismatic CoA based on RPC VII.2 1840 and 1845; all other families retain procedural CoA generation.

## Gallic Empire

The Gallic staging set identifies `e_gaul` with the sovereign Gallic Empire from 260 through its reincorporation by Aurelian in 274. The single holder line contains Postumus, Marius, Victorinus, and Tetricus. Laelianus and Domitianus are rival claimants; Victoria remains a non-holder, and Tetricus Iunior is represented as Caesar and heir.

- `history/titles/eoe_gallic_empire.txt`
- `history/characters/eoe_gallic_emperors.txt`
- `common/dynasties/eoe_gallic_dynasties.txt`
- `common/nicknames/eoe_historical_nicknames.txt`
- `localization/english/eoe_gaul_history_l_english.yml`
- `research/gallic_empire_sources.md`

Display names use attested Latin forms. Postumus receives the coin-attested `Restitutor Galliarum` nickname. Exact days within uncertain years are documented gameplay conventions, and fallback dynasties do not assert otherwise unknown pedigrees.

No holder history is added to `k_gallia`, `k_septem_provinciae`, or `e_praetorian_gallia`. These are administrative structures rather than parallel sovereign dynasties. A later project may test appointed administrative succession, or republican/theocratic title forms where appropriate, for dioceses and their vicars.

## Imperial Pontificate

The pontificate staging set treats `d_pontificate` as the personal imperial office of *pontifex maximus* from the earliest valid date for vanilla Augustus through Gratian's death in 383. It reuses 57 vanilla Roman characters and adds no duplicate character, dynasty, nickname, localization, or coat of arms.

- `history/titles/eoe_pontificate.txt`
- `research/pontificate_sources.md`

Because CK3 permits only one title holder, senior or de facto primary Augusti represent periods of collegiate rule. Junior co-emperors and alternative tetrarchic lines are documented rather than presented as simultaneous holders. A short vacancy after Aurelian excludes Severina from a male priestly office.

The line begins on `3.1.1`, not AD 1 as initially proposed, because vanilla character 145290 is technically born on that date. It ends with `holder = 0` on `383.8.25`. The same vacant title remains available to EoE's restored `julianism` faith-head mechanics; those mechanics require a separate in-game succession test.

## Carausian Britannia

The Britannia staging set uses `k_britannia` as a Britannia-centred representation of the imperial secession led by Carausius and Allectus. Carausius holds the title from 286, Allectus from his coup in 293, and the title becomes vacant with the Roman reconquest in September 296.

- `history/titles/eoe_britannia.txt`
- `history/characters/eoe_britannia_usurpers.txt`
- `common/dynasties/eoe_britannia_dynasties.txt`
- `common/nicknames/eoe_historical_nicknames.txt`
- `localization/english/eoe_britannia_history_l_english.yml`
- `research/carausian_britannia_sources.md`

The two rulers use attested Latin names and separate fallback dynasties; no family relationship is implied. Carausius receives the coin-attested `Restitutor Britanniae` nickname. Other coin formulas remain research flavor, and EoE's existing `k_britannia` coat of arms is reused.

Magnus Maximus, Constantinus III, Syagrius, and the victorious Constantius Chlorus are deliberately excluded from the holder line. The staging changes no Britannia restoration, de jure, or Gallic Empire mechanics.

## Integration Status

All currently documented runtime files have been migrated to their matching paths under the main mod. Research files and `TITLE_HISTORY_BLUEPRINT.md` remain here. Recheck character IDs before each future integration, run Tiger against the complete main mod, and perform title-history tests with the actual DEV copy.