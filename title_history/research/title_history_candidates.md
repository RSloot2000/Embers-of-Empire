# EoE Historical Title Candidates

This matrix applies `TITLE_HISTORY_BLUEPRINT.md` to every custom EoE title. Priority reflects historical fit, source quality, CK3 representability, and expected player-facing value.

## Recommended Projects

| Priority | EoE title | Historical referent | Proposed history | Assessment |
|---|---|---|---|---|
| 1 | `k_bosporus` | Bosporan Kingdom | First-century rulers through the end of the documented client kingdom, with dynasties, Roman relations, and evidence notes from coinage and prosopography. | Excellent fit. This is a real sovereign kingdom centered on Kerch, matching the title capital and restoration decision. |
| Complete | `e_gaul` | Gallic Empire | Postumus, Marius, Victorinus, and Tetricus from 260 to 274. Laelianus and Domitianus are rival claimants; Victoria and Tetricus Iunior are non-holders. | Staged with Latin endonyms, documented conventional dates, and the coin-attested `Restitutor Galliarum` nickname. Soissons is excluded. |
| Complete | `d_pontificate` | Office of pontifex maximus | One representative imperial holder at a time from vanilla Augustus through Gratian, followed by vacancy on 25 August 383. | Staged as a personal landless office using vanilla characters. Co-Augusti and disputed end dating are documented; restored Julianist succession still requires an in-game mechanics test. |
| Complete | `k_britannia` | Carausian regime in Britain | Carausius from 286, Allectus from 293, and vacancy after the Roman reconquest in September 296. | Staged as an explicit Britannia-centred projection of an imperial secession. Later British proclamators and Constantius Chlorus are excluded. |

## Flavor-Only Research

These titles have historically attested officials, but ordinary holder history would imply sovereignty or hereditary territorial possession that did not exist.

| EoE titles | Historical material suitable for flavor | Recommendation |
|---|---|---|
| `e_praetorian_gallia`, `e_praetorian_italia`, `e_praetorian_illyricum`, `e_praetorian_oriens` | Named praetorian prefects, administrative reforms, capitals, changing jurisdictions. | Use decision/event flavor, tooltips, or a dedicated office system. Do not use territorial empire holder history by default. |
| `k_pannonia`, `k_italia_suburbicariae`, `k_italia_annonariae`, `k_hispania`, `k_septem_provinciae`, `k_gallia`, `k_africae`, `k_orientis`, `k_aegyptus`, `k_thessalonika2`, `k_macedon`, `k_daciae`, `k_nikaea2`, `k_asiae` | Vicars, governors, diocesan reforms, provincial capitals, military and ecclesiastical events. | These are Roman administrative regions. Do not present their officials as hereditary kings. In a later gameplay phase, test appointed administrative succession first and republican or theocratic title forms where historically and mechanically appropriate. |
| `k_mesopotamia_roman`, `k_roman_dacia`, `e_roman_dacia`, `k_germania`, `e_germania` | Roman occupations, governors, campaigns, abandonment, and restoration ideology. | These restoration titles do not represent continuous sovereign states. Avoid holder history unless a narrower historical polity is deliberately substituted and documented. |
| `k_hibernia`, `d_hibernia_superior`, `d_hibernia_inferior`, `k_caledonia`, `d_caledonia`, `e_praetorian_albion` | Irish and Pictish rulers, Roman geographic knowledge, expeditions, client relations. | Native rulers belong to vanilla/native titles, not invented Roman provincial titles. Use flavor text rather than duplicate holder lines. |

## Excluded From Historical Holder Work

| EoE title | Reason |
|---|---|
| `h_western_roman_empire` | Same state as `e_western_roman_empire`; its creation event copies the empire history. |
| `e_bosporus` | Currently defined but not formed or upgraded from `k_bosporus`. Duplicating the kingdom line would create two simultaneous versions of one state. |
| `k_imperium` | Alternate-history religious/imperial office that would duplicate Roman imperial holder lists. |
| `k_solar_throne` | Alternate-history Sol Invictus faith-head title without a continuous attested historical office. |
| `k_myrdidin` | Legendary/alternate-history title rather than an attested polity or office. |

## Source Starting Points

### Bosporus

- Encyclopaedia Britannica, "Kingdom of the Bosporus": Archaeanactid and Spartocid periods, later Roman-protected dynasty, and survival beyond AD 342.
- Roman Provincial Coinage Online: ruler identities, titulature, co-rulers, and dated coin issues.
- Prosopographia Imperii Romani and specialist Bosporan chronologies for disputed reign boundaries.

The first implementation should begin in AD 1 because CK3 title history does not provide a normal BCE chronology. It should not infer exact accession days from regnal years without documenting the conversion.

### Gaul

- Livius.org, "Gallic Empire": state history, archaeological context, and the sequence Postumus (260-269), Marius (269), Victorinus (269-271), and Tetricus (271-274).
- Coin evidence and modern imperial chronologies for the disputed months in 269 and the status of Laelianus.

### Pontificate

- Encyclopaedia Britannica, "pontifex" and "pontifex maximus": lifetime office, imperial association after Augustus, and later papal usage.
- Livius.org, "Pontifex Maximus": office history and Gratian's rejection in 381.
- Individual emperor chronologies to determine whether accession to the priesthood matched imperial accession.

### Britannia

- Encyclopaedia Britannica coverage of Roman Britain and Allectus: Carausius's regime and Allectus's rule until reconquest in 296.
- Coin catalogues and specialist studies for exact accession chronology and the extent of the regime in northern Gaul.

## Proposed Phase Order

1. Build `k_bosporus` as the first non-Roman-imperial sovereign-title test.
2. Review and integrate the staged `e_gaul` disputed-legitimacy empire history.
3. Review and integrate the staged `d_pontificate` personal-office history, then test its restored Julianist succession in game.
4. Review and integrate the staged `k_britannia` Carausian history, then regression-test the Roman and Gallic restoration routes in game.

This sequence exercises three distinct blueprint types without forcing administrative provinces into feudal holder history.