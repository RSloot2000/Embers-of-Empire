# Carausian Britannia Research

## Scope And Title Identity

This staging set gives EoE title `k_britannia` a holder line for the regime established by Carausius and continued by Allectus between 286 and 296. Both men claimed the imperial rank of Augustus and controlled Britannia together with changing positions in northern Gaul. They were not ordinary kings of a territorial Britannia.

EoE's title represents the restored Roman Diocese of Britannia. Using it for the Carausian regime is therefore an explicit Britannia-centred CK3 projection: the island was the regime's durable power base, Londinium was a principal mint, and Roman reconquest ended the separate regime. This historical projection does not redefine the title's restoration or de jure mechanics.

## Evidence Matrix

| Character | Name used | Encoded role | Origin and family | Reign and death | Visible flavor |
|---|---|---|---|---|---|
| Carausius | Marcus Aurelius Carausius | Holder from 286 | Described as a Menapian of humble origin; no relatives encoded | Proclaimed himself Augustus around 286/287; murdered by Allectus in 293 | `Restitutor Britanniae`, directly attested as a coin legend |
| Allectus | Allectus | Holder from 293 | Carausius's financial official; no family relationship encoded | Murdered Carausius, succeeded him, and died fighting the reconquest force in 296 | No personal epithet encoded |

`Mausaeus`, sometimes included in expanded modern forms of Carausius's name, is omitted because its reading and status are not secure enough for an endonymic display name. No praenomen or nomen is added to Allectus because his coins identify him only as Allectus.

## Date Conventions

- `286.1.1`: conventional start for Carausius. Ancient and modern chronologies divide between late 286 and 287.
- `293.1.1`: conventional date for Carausius's murder and Allectus's accession; the year is secure but the exact day is not.
- `296.9.1`: conventional September date for Allectus's battlefield death and the end of the regime during Constantius Chlorus's reconquest.

These dates make a coherent CK3 title sequence and must not be read as exact ancient calendar dates.

## Character Policy

Both characters use `roman` culture. Their personal religion is not securely known. `hellenic_pagan` is used conservatively because their public imperial imagery and titulature remained within traditional Roman religious language; this does not assert private pagan conviction or deny the presence of Christianity in late Roman Britain.

The birth dates `250.1.1` for Carausius and `255.1.1` for Allectus are technical estimates that make both men mature officials at accession. They are not attested birthdays.

Carausius and Allectus receive separate name-based fallback dynasties. These prevent a lowborn CK3 presentation but assert no ancient pedigree. Allectus was a subordinate who killed and replaced Carausius, not a relative or dynastic heir. No spouses, children, parents, or shared house are encoded.

Carausius receives `death_murder`; Allectus receives `death_battle`. Both encode well-established broad causes without inventing unsupported personal details.

## Coin Flavor

`RESTITUTOR BRITANNIAE`, “Restorer of Britain,” appears on Carausius's coinage and is encoded as his single CK3 nickname. It presents him as the defender and renewer of Britannia while supporting his claim to legitimate Roman rule.

The following attested or strongly interpreted Carausian formulas remain research flavor rather than additional CK3 labels:

- `PAX AVGGG`, which presented Carausius alongside Diocletian and Maximian as three Augusti.
- `CARAVSIVS ET FRATRES SVI`, another claim to collegial imperial legitimacy.
- `GENIVS BRITANNIAE` and `PACATOR ORBIS`.
- `EXPECTATE VENI`, drawing on Vergil's *Aeneid*.
- `RSR`, widely interpreted with the Vergilian phrase `Redeunt Saturnia Regna`.

No RSR dynasty motto is added, because the selected implementation uses only the directly readable `Restitutor Britanniae` nickname. The existing EoE title coat of arms is retained; coin iconography is not converted into invented family heraldry.

## Exclusions

- Magnus Maximus: proclaimed in Britain but ruled the wider western empire from Gaul; not a Britannia-centred successor to this regime.
- Constantinus III: proclaimed in Britain in 407 but transferred his army and government to Gaul; his reign belongs to the western imperial collapse.
- Syagrius: ruler around Soissons with no Britannian polity.
- Constantius Chlorus: leader of the reconquest, not successor to the separate Carausian title. The title becomes vacant in 296.
- Frankish auxiliaries, alleged relatives, and unsupported personal religions: insufficient evidence for character history.

## EoE Mechanics Boundary

The historical line ends centuries before every playable bookmark. This staging does not change `k_britannia`, `e_praetorian_albion`, the existing title coat of arms, `restore_britannia_dioceses_effect`, the Gallic restoration route, or Hibernia and Caledonia prerequisites.

Discovery identified existing mechanics that deserve a separate gameplay audit: Britannia restoration destroys several competing British titles, and the associated `e_britannia` capital assignment may not match the restored diocese region. These are not title-history defects and are deliberately not changed here.

## Sources

- *Panegyrici Latini* 8(5) and 6(7), contemporary Tetrarchic presentations of the revolt and reconquest.
- Aurelius Victor, *Liber de Caesaribus* 39.
- Eutropius, *Breviarium* 9.21-23.
- Orosius, *Historiae adversus paganos* 7.25.
- *Roman Imperial Coinage* V.2, Carausius and Allectus issues.
- *Roman Inscriptions of Britain*, including Carausian milestones RIB 2291-2292.
- P. J. Casey, *Carausius and Allectus: The British Usurpers* (1994).
- Sam Moorhead, “Carausius and Allectus,” in *The Oxford Handbook of Roman Britain* (2016).
- Encyclopaedia Britannica, “Roman Britain: The End of Roman Britain” and “Allectus,” for the three-year succession and reconquest summary.

## Remaining Runtime Review

- Verify the title-history view, Latin display names, separate fallback dynasties, nickname, and death tooltips in game.
- Restore the Britannia diocese through the Roman route and confirm that the ancient vacant history does not affect dynamic holders or de jure changes.
- Form the Gallic Empire and confirm its `k_britannia` reassignment still behaves as scripted.