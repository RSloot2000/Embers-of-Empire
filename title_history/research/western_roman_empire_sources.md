# Western Roman Empire: Phase 1 Research

## Scope

Phase 1 covers `e_western_roman_empire` from the permanent division in 395 through the end of the western imperial court. The mod's `h_western_roman_empire` copies this history when it is created, so it does not receive a duplicate history block.

The holder sequence follows control of the western imperial court. Junior co-emperors are not separate holders while a senior western emperor remains in office. Confirmed vacancies are represented with `holder = 0`.

## Holder Decisions

| Date | Holder | Decision |
|---|---|---|
| 395-01-17 | Honorius | Start at the death of Theodosius I and the conventional permanent division. |
| 423-08-15 | Vacant | Historical death date of Honorius. Vanilla currently uses 25 August. |
| 423-11-20 | Joannes | Included as the effective western ruler despite eastern non-recognition. |
| 425-05-01 | Vacant | Joannes was captured and executed in May or June; exact day is uncertain. |
| 425-10-23 | Valentinian III | Date of elevation as Augustus. |
| 455-03-17 | Petronius Maximus | Accession after Valentinian's assassination. |
| 455-05-31 | Vacant | Death during the Vandal approach to Rome. |
| 455-07-09 | Avitus | Proclamation as emperor. |
| 456-10-18 | Vacant | Deposition after defeat near Placentia. |
| 457-04-01 | Majorian | Proclamation by the army; chosen over his later formal elevation because this history follows effective rule. |
| 461-08-07 | Vacant | Majorian's execution. |
| 461-11-19 | Libius Severus | Accession date. |
| 465-11-14 | Vacant | Death date. |
| 467-04-12 | Anthemius | Accession date. |
| 472-07-11 | Olybrius | Takes the line when Anthemius is killed. |
| 472-11-02 | Vacant | Olybrius's death. |
| 473-03-05 | Glycerius | Accession date. |
| 474-06-24 | Julius Nepos | Nepos deposes Glycerius and takes Ravenna. |
| 475-08-28 | Vacant | Orestes takes Ravenna and Nepos flees to Dalmatia; Nepos receives a pressed claim. |
| 475-10-31 | Romulus Augustulus | Elevated by Orestes as effective ruler in Italy. |
| 476-09-04 | Vacant | Romulus is deposed. Nepos remains a claimant until his death in 480, not a restored holder. |

Constantius III is omitted from the holder sequence because he was Honorius's junior co-emperor for seven months in 421. CK3 title history supports one holder at a time, and replacing Honorius would misrepresent the senior western court.

## Character Data Policy

Vanilla character IDs `145227` (Honorius) and `145229` (Valentinian III) are reused. All other emperors are new because CK3 1.19.0.6 has no matching historical characters in `history/characters/roman.txt`.

Exact birth dates are unknown for most new characters. Conservative estimated years are used so the title-history portraits have plausible ages. Estimated dates must not be treated as confirmed biography. Glycerius is kept alive through the murder of Nepos in May 480. Romulus's death is placed after his last attestation to prevent him remaining alive at the 867 bookmark.

Every custom ruler has a stable dynasty so the title-history UI does not present emperors as lowborn. Documented families are used for the Anicii (Petronius Maximus and Olybrius) and Procopii (Anthemius). Orestes and Romulus share the Orestes fallback dynasty because their father-child relationship is secure. Joannes, Avitus, Majorian, Libius Severus, Glycerius, and Julius Nepos use conservative name-based fallback dynasties where no securely named gens can be assigned.

A fallback dynasty is a CK3 family identity, not evidence for a historical gens or a reconstructed pedigree. No unsupported parents, spouses, children, or cadet branches are added. Coats of arms remain procedurally generated because late Roman families did not possess documented medieval-style hereditary heraldry.

## Family And Flavor Additions

The expanded family file adds only relationships that materially connect the holder line in CK3's family UI. Placidia and Eudocia are daughters of Valentinian III and Licinia Eudoxia; Placidia is the wife of Olybrius and mother of Anicia Iuliana. Licinia Eudoxia is linked to her vanilla father Theodosius II (`70533`). Anthemius is linked to his father Procopius, wife Marcia Euphemia, and children Alypia, Marcianus, Anthemiolus, and Romulus. Avitus is linked to Agricola, Ecdicius, and Papianilla; Papianilla is married to Sidonius Apollinaris. Nepotianus is added as the confirmed father of Iulius Nepos.

Birth and death years for several non-holder relatives are approximate UI dates, not exact biographies. Marcellinus is documented as Nepos's maternal uncle but is not encoded because the unnamed mother needed to form that relationship is unknown. Huneric is not created merely to extend Eudocia's branch. These exclusions prevent a broad tree from becoming a chain of unsupported placeholder characters.

Contemporary Latin forms are preferred in new localization: Iohannes, Eparchius Avitus, Majorianus, Iulius Nepos, Marcianus, and Anicia Iuliana. Modern English forms remain searchable through this research note and comments. Existing vanilla keys are not overridden. Romulus displays as Romulus Augustus with the attested diminutive `Augustulus` represented as a nickname, avoiding duplicate text.

Majorianus receives `diligent` because contemporary and modern accounts specifically emphasize his conscientious administration and reform programme. Ecdicius receives a martial education for his documented command, and Sidonius receives `scholar` for his surviving literary work and intellectual career. No numerical skills or further personality traits are inferred from office, status, or success.

No Western Roman dynasty motto or custom coat of arms is added. The families predate hereditary medieval heraldry, and no sufficiently specific late-antique family emblem was established during this review.

## Sources

- CK3 1.19.0.6 vanilla `history/characters/roman.txt`: existing Honorius and Valentinian III IDs and biographies.
- CK3 1.19.0.6 vanilla `history/titles/00_other_titles.txt`: current Paradox date and syntax conventions.
- *The Prosopography of the Later Roman Empire*, vol. II: family identities and fifth-century careers.
- Sidonius Apollinaris, *Letters* and *Carmina*: the Avitus family, Sidonius, Ecdicius, and Anthemius's court.
- Encyclopaedia Britannica, "List of Roman emperors": https://www.britannica.com/topic/list-of-Roman-emperors-2043294
- Encyclopaedia Britannica, "Honorius": https://www.britannica.com/biography/Honorius-Roman-emperor
- Encyclopaedia Britannica, "Valentinian III": https://www.britannica.com/biography/Valentinian-III
- Encyclopaedia Britannica, "Julius Nepos": https://www.britannica.com/biography/Julius-Nepos
- Encyclopaedia Britannica, individual biographies for Petronius Maximus, Avitus, Majorian, Anthemius, Olybrius, Glycerius, and Romulus Augustulus.
- Livius.org, individual biographies for Honorius, Valentinian III, Majorian, and Anthemius.
- Wikipedia, "List of Roman emperors", used as a detailed chronology index whose cited scholarly references require follow-up before publication: https://en.wikipedia.org/wiki/List_of_Roman_emperors

## Remaining Research Before Publication

- Verify every exact accession/deposition day against a specialist chronology rather than an encyclopedia summary.
- Replace estimated birth and death dates where stronger evidence exists.
- Decide whether Joannes's execution should be represented in May or June 425.
- Confirm whether the game UI displays Nepos's historical claim after the title becomes vacant.