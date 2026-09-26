# Miks 29,1 ja 28,9 tundi erinevad?

**ET:** T16 liidab tegevuste kaupa ümardatud tunnid, E19 nädalate kaupa ümardatud tunnid; 0,2 tunni erinevus tuleb algsest mallist ja seda ei ole vaja parandada.

**EN:** T16 sums hours rounded by activity, while E19 sums hours rounded by week; the 0.2-hour difference comes from the original template and does not need fixing.

| Lahter | Malli valem / meetod | Tulemus |
|---|---|---:|
| S16 | SUM(S2:S15), minutid kokku | 1735 min |
| T2:T15 | ROUND(Srea/60,1), iga tegevus eraldi | 4,5; 0; 2,0; 0; 5,1; 0,8; 0; 0; 0; 0; 3,7; 1,3; 11,2; 0,5 h |
| T16 | SUM(T2:T15) | 29,1 h |
| B17:E17 | ROUND(nädala minutid/60,1) | 4,0; 6,8; 7,8; 10,3 h |
| E19 | SUM($B$17:E17) | 28,9 h |

1735 / 60 = 28,9166… tundi. Üks kord ümardades on see 28,9 h. Eraldi ümardatud tegevuste summa võib erineda. Mõlemad valemid vastavad 2026 mallile. `R19=ROUND(SUM($B$17:R17),0)` ümardab malli järgi täistunnini: 29 h. Tulevaste nädalate sisendite tühjus ei nõua kokkuvõttevalemite kustutamist.

Ära muuda sisendminuteid ega valemeid selleks, et numbrid võrdsustada. Tundide kogusumma ei ole punktide eesmärk.
