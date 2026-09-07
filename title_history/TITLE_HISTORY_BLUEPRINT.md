# Historical Title Blueprint

Use the Western Roman Empire staging files as the reference implementation for future historical titles.

## 1. Classify The Title

Before writing history, classify the title as one of these:

- Sovereign polity: holder history is normally appropriate.
- Vassal polity: holder and historical `liege` changes may be appropriate.
- Territorial office: only use holder history if the office was held personally and maps coherently to a CK3 title.
- Administrative region: usually no holder history; governors belong to offices or characters, not hereditary landed-title history.
- Restoration or ceremonial title: historical predecessors may be useful, but operational fields must not alter how the restored title works.

- Personal or priestly office: holder history is appropriate when named holders can be represented coherently, including for a landless title. Keep historical tenure separate from gameplay succession, inheritance, faith-head appointment, and restoration rules.

For a Roman diocese or comparable appointed jurisdiction, do not assume that avoiding feudal holder history means avoiding title mechanics entirely. A later gameplay project may test administrative appointment first, with republican or theocratic title/government forms where the historical office and CK3 engine support them. Keep that design separate from sovereign title-history staging and verify succession behavior in game before assigning historical officials.

For one personal office shared or claimed by co-rulers, CK3's single-holder restriction requires an explicit selection policy. Prefer the senior or de facto primary office-holder, document omitted colleagues, and do not manufacture rapid succession merely to display simultaneous tenure. A historical holder line that ends before all bookmarks may coexist with later restoration or faith-head use of the same title, provided the final vacancy and runtime creation path are both tested.

When a CK3 territorial title is used to approximate a historically imperial secession, state the substitution explicitly. The historical regime must have a strong geographical centre matching the title, the holder line must end when that separate regime ends, and rulers whose careers quickly moved to a broader polity should not be appended merely because they were proclaimed in the same region. Do not let this historical projection silently change restoration, de jure, or title-creation mechanics.

## 2. Title History Fields

| Field | Use | Rule |
|---|---|---|
| `holder` | Yes | Core historical succession. Use `holder = 0` for a real vacancy or abolition. |
| `liege` | Conditional | Only for a real title whose political subordination changed. Not for alliances or nominal recognition. |
| `government` | Rare | Affects gameplay setup; do not use merely to describe a historical constitution. |
| `succession_laws` | Rare | Affects gameplay setup; use only when the title exists at a playable bookmark and evidence maps to a CK3 law. |
| `de_jure_liege` | Rare | Changes the landed-title hierarchy. Treat as map/design work, not biographical history. |
| `name` | Conditional | Use only for a documented historical rename represented by localization. |
| `effect` | Exceptional | Runtime setup, not historical prose. Every effect requires a concrete gameplay reason and vanilla precedent. |
| `change_development_level` | Counties only | Province development, never empire-level title history. |

For `e_western_roman_empire`, only `holder` is appropriate. The title is vacant long before every playable bookmark, while its restoration government, laws, de jure structure, name, capital, and coat of arms are controlled elsewhere in EoE.

## 3. Supporting Character History

Every custom holder must have:

- A unique, collision-checked character ID.
- A localized display-name key.
- Culture and faith supported by the target load order.
- Birth and death dates that bracket the reign.
- A fixed dynasty so a historical ruler is not presented as lowborn.
- Confirmed parents and spouses only when supported by evidence.
- A historical death reason when known and represented by a valid CK3 reason.
- `disallow_random_traits = yes` when no defensible personality traits are supplied.

Prefer a contemporary endonym or period spelling over a modern English form when it is securely attested and readable. Keep script keys ASCII-safe and put diacritics or original-language characters only in localization. Preserve an existing vanilla/EoE name key when replacing it would break references or regnal numbering. Record common modern forms as research aliases.

Use a documented family or gens when available. Otherwise create a clearly documented fallback dynasty from the ruler's surname or cognomen, or from the given name when neither exists. A fallback supplies CK3 identity only and must not be presented as evidence of shared descent. Share a fallback only between confirmed relatives.

Use `dynasty_house` only for a historically identifiable branch within a broader dynasty. Do not invent cadet branches from chronology or repeated names. Leave CoA generation procedural unless a sourced historical emblem, seal, or coin symbol can be represented without implying an anachronistic medieval coat of arms.

Do not invent education, skills, personality traits, DNA, or family links just to make a dead ruler look complete.

## 4. Flavor Priority

Apply flavor in this order: confirmed family and death reason; attested epithet; directly sourced trait or expertise; sourced titulary formula or motto; sourced visual emblem. CK3 character history has no general visible biography field, and nickname descriptions are not a substitute for one.

Use only one nickname per character and prefer a personal, attested epithet over a modern descriptive label. Do not convert reign length, office, military success, or later reputation automatically into personality traits or numerical skills.

A dynasty or house motto must use an explicit `motto` field and a localized key. An official repeated titulary formula may be used when documented as such, but invented Latin slogans are not historical flavor.

Custom CoA definitions must use the exact dynasty or house key and existing validated pattern/emblem assets. Treat coin, seal, or inscription imagery as a modern visual interpretation and document the source and any non-historical color choices. Prefer procedural generation when no specific emblem survives.

## 5. Succession Policy

- A title can have only one holder at a time.
- Use the de facto ruler for overlapping rival claims unless the project explicitly adopts a de jure list.
- Represent a displaced but recognized emperor with a character claim, not simultaneous title ownership.
- Omit junior co-emperors from the single holder line while the senior ruler remains in office; document them in research notes.
- Record genuine interregna as `holder = 0`.
- State how disputed accessions and approximate dates were resolved.

## 6. Evidence Levels

- Confirmed: supported by vanilla data or at least one reliable biographical/chronological source.
- Approximate: source gives only a year or range; use a conventional CK3 date and mark it in research.
- Disputed: sources disagree; document the alternatives and chosen gameplay convention.
- Excluded: plausible but too weak, subjective, or mechanically misleading to encode.

## 7. Required Files

For a title that needs new holders, stage:

- `history/titles/<mod>_<title>.txt`
- `history/characters/<mod>_<holders>.txt`
- `localization/english/<mod>_<title>_l_english.yml`
- `research/<title>_sources.md`

Add `common/dynasties/` for every new holder dynasty and `common/dynasty_houses/` only for supported branches. Add dynasty and house localization in the same change.

Add `common/nicknames/` only for attested epithets and `common/coat_of_arms/coat_of_arms/` only for sourced visual interpretations. Non-holder relatives may use a separate character-history file when this keeps holder definitions readable.

## 8. Validation

1. Check exact title and character IDs across vanilla, EoE, compatches, and source mods.
2. Verify every holder exists and is alive on accession.
3. Verify dates are strictly increasing and vacancies are intentional.
4. Verify every custom name and dynasty key is localized.
5. Verify family references, marriage dates, parent ages, and absence of ancestry cycles.
6. Verify repeated endonym keys still produce one regnal-name sequence.
7. Preserve UTF-8 BOM where Tiger expects it.
8. Overlay staging files onto a temporary full EoE copy and run the px-toolkit Tiger version matching CK3.
9. Filter Tiger output to the staged files; do not confuse legacy EoE reports with new defects.
10. Before integration, repeat collision checks because the main mod may have changed in parallel.
11. After integration, test names, family trees, nicknames, death tooltips, mottos, CoA rendering, title history, and restored-title behavior in a fresh DEV runtime.
12. For non-hereditary administrative titles, separately test appointment, removal, government conversion, inheritance prevention, and restoration-decision compatibility.