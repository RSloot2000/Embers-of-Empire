# Bosporan Kingdom Research

## Scope

This staging set covers EoE title `k_bosporus` from Aspurgus in AD 8 through the end of the secure Tiberian-Julian coin sequence in 341/342. EoE's restoration decision creates `k_bosporus`; the unused parallel definitions `k_bosporan_kingdom` and `e_bosporus` receive no duplicate history.

The title is treated as a sovereign Roman client kingdom. Roman protection is not represented as a CK3 `liege`, because it did not make the Bosporan king an ordinary landed vassal. The direct Roman incorporation of AD 63-68 is represented as `holder = 0`.

## Holder Decisions

| Date | Holder | Evidence decision |
|---|---|---|
| 8 | Aspurgus | Conventional start after Dynamis; sources vary between 7/8 and 8/10. |
| 38 | Gepaepyris | Numismatic evidence supports her sole rule after Aspurgus. |
| 39 | Mithridates | Inherited from Gepaepyris; deposed by Claudius around 44/45. |
| 45 | Cotys I | Installed by Claudius; deposed by Nero in 63. |
| 63 | Vacant | Kingdom incorporated into Moesia Inferior until 68. |
| 68 | Rhescuporis I | Kingdom restored by Galba to Cotys's son. Modern numbering also calls him Rhescuporis II. |
| 93-170 | Sauromates I through Eupator | Main numismatic chronology, with year-boundary dates where no day is known. |
| 170 | Vacant | The standard sequence has an unresolved gap before Sauromates II in 172. |
| 172-234 | Sauromates II through Cotys III | Main sequence; junior and overlapping co-rulers are excluded. |
| 234-322 | Ininthimeus through Rhadamsades | Main coin sequence; some rulers may not belong to the dynasty. |
| 322 | Rhescuporis VI | He appears as co-ruler from 314 but becomes the sole holder here after Rhadamsades. |
| 342 | Vacant | Secure continuous succession ends after Rhescuporis VI; later political control is too fragmentary for a continuous holder line. |

## Excluded And Disputed Rulers

- Polemon II and the proposed Rhescuporis I of AD 14-42 are excluded from the de facto line because the chronology conflicts with the numismatically supported sole rule of Gepaepyris and succession of Mithridates in 39.
- Sauromates III, Rhescuporis IV, Chedosbios, and Sauromates IV are junior or overlapping rulers and cannot share CK3 title ownership with the selected senior holder.
- Pharsanzes is treated as a rival during Rhescuporis V's reign, not the sole title holder.
- Douptounos, Gordas, and Mugel are not added after 341. Their isolated attestations do not establish continuity of the same kingdom, and Britannica describes alternating barbarian and Byzantine control after 342.

## Character Data Policy

All Bosporan holders are staged as new characters because neither vanilla CK3 1.19.0.6 nor EoE defines them. Only Aspurgus and Gepaepyris as parents of Mithridates and Cotys, and Cotys as father of Rhescuporis, are encoded as confirmed family links. Later genealogies are omitted because scholarship describes them as largely conjectural.

Gepaepyris retains her Odrysian birth dynasty and is assigned to its Sapaean house; marriage does not transfer her to the Tiberian-Julian dynasty. Ininthimeus, Theothorses, and Rhadamsades receive separate name-based fallback dynasties because their membership in the Tiberian-Julian line is uncertain. These fallbacks prevent a lowborn presentation but do not assert descent or a historical family name.

No speculative cadet branches are created within the Tiberian-Julian sequence. Dynasty and house coats of arms remain procedurally generated unless a specific historically sourced emblem or coin symbol is adopted later.

Culture is an approximation: the court was Hellenistic and Greco-Scythian, so `greek` is used for the dynasty. Gepaepyris uses EoE's `thracian` culture. All characters use `hellenic_pagan`, matching the documented Greek polytheism and an existing EoE faith key.

Most exact birth and death dates are unknown. Birth years are conservative gameplay estimates. Aspurgus and Gepaepyris must use `1.1.1` because CK3 cannot represent their BC births. A death at the next accession is a chronology placeholder unless independently known. Mithridates is kept alive until his attested death in 68; Cotys receives a technical post-deposition death estimate because his fate after 63 is unknown. These dates must not be read as confirmed biography.

## Names, Family, And Epithets

Localized personal names prefer attested Greek forms while keeping ASCII-safe script keys: Aspourgos (modern Aspurgus), Gēpaipyris (Gepaepyris), Mithradatēs (Mithridates), Kotys (Cotys), Rhēskouporis (Rhescuporis), Sauromatēs (Sauromates), Rhoimētalkēs (Rhoemetalces), Ininthimeos (Ininthimeus), Teiranēs (Teiranes), Theothorsēs (Theothorses), Rhadamsadēs (Rhadamsades), and Eunikē (Eunice). Repeated royal names share one key so CK3 can retain regnal numbering.

Eunikē is added as Cotys I's wife and Rhēskouporis I's mother. CIRB 1118 identifies Rhēskouporis as the son of King Cotys and Queen Eunikē, and the royal abbreviations associated with Cotys and Eunikē also occur on Bosporan bronze coinage. Rhēskouporis I is linked as father of Sauromatēs I, and Sauromatēs I as father of Kotys II. Later parentage remains unencoded where it rests mainly on reconstructed coin succession.

Aspourgos receives the attested epithet `Philorōmaios`. Sauromatēs I receives `Ktistēs`, the personal honorific recorded in the Nicaean inscription associated with his benefactions. The fuller formula `Philokaisar, Philorōmaios, Eusebēs`, attested for early Tiberian-Julian rulers, is used as a dynasty motto-like titulary formula. CK3 allows only one active nickname, so the complete string is not stacked onto individual names.

The Ininthimeos dynasty receives the only custom coat of arms in this phase. It combines an eagle and a horse based on RPC VII.2 1840 and 1845. Those types show an eagle holding a wreath and a horseman respectively. The colors are a modern readability convention, not reconstructed ancient heraldic tinctures. Other dynasties retain procedural CoA generation because portraits, imperial busts, and uncertain deity figures do not translate cleanly into a specific family emblem.

No BC-born ancestors are added. CK3 cannot represent BC dates, and compressing Asander, Dynamis, and the earlier royal ancestry around `1.1.1` would make the family tree chronologically misleading.

## Sources

- Encyclopaedia Britannica, "Kingdom of the Bosporus": https://www.britannica.com/place/Kingdom-of-the-Bosporus
- Roman Provincial Coinage Online, Bosporus catalogue (645 indexed entries at research time): https://rpc.ashmus.ox.ac.uk/search/browse?q=Bosporus
- Roman Provincial Coinage Online, Ininthimeos types RPC VII.2 1834-1845; types 1840 and 1845 are the direct CoA references.
- *Corpus Inscriptionum Regni Bosporani* 1118: Eunikē, Cotys, and Rhescuporis family relationship.
- Helmuth Schneider, *Brill's New Pauly: Chronologies of the Ancient World* (2007), p. 112.
- Michael Mitchiner, *The Ancient & Classical World, 600 B.C.-A.D. 650* (1978), p. 69.
- Nina Frolova, "The Question of Continuity in the Late Classical Bosporus on the Basis of Numismatic Data" (1999), DOI 10.1163/157005799X00188.
- Nina Frolova and Stanley Ireland, "A Hoard of Bosporan Coins ... from Ancient Gorgippia" (1995), *The Numismatic Chronicle* 155, pp. 21-42.
- Tacitus, *Annals* 12.15-21, for the conflict between Mithridates and Cotys.
- Wikipedia, "List of kings of the Cimmerian Bosporus" and individual ruler pages, used as a chronology index to the specialist works above: https://en.wikipedia.org/wiki/List_of_kings_of_the_Cimmerian_Bosporus

## Remaining Review Before Publication

- Check the full sequence against a directly accessible specialist catalogue rather than relying on its chronology as reproduced in reference summaries.
- Decide whether the uncertain AD 38-45 sequence should use an explicit disputed-ruler alternative.
- Replace technical birth/death estimates where stronger prosopographical evidence exists.
- Verify in game how repeated names are regnally numbered in the title-history UI.