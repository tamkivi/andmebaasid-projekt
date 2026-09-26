# Ümberarvutuse kontroll

- Microsoft Excel avanes Microsoft 365 litsentsipakkumisega ja pakkus „Skip to read-only mode”; sisselogimist, ostu ega tellimust ei tehtud.
- Kohalik **LibreOfficeDev 26.8.0.0.alpha0** avas ja salvestas ajutise koopia XLSX-vormingus. Kõik 115 valemit said arvulise vahemälutulemuse.
- LibreOffice'i salvestus korraldas stiilitabeli ümber. Vormingu täpseks säilitamiseks kopeeriti põhifaili ainult LibreOffice'i loodud 115 arvulist valemitulemust. Kogu ülejäänud töövihiku XML-sisu säilis bait-baidilt; ainsad XML-erinevused on valemilahtrite vahemäluelemendid.
- Kõiki 115 tulemust võrreldi eraldi arvutusega (SUM, ROUND ning viited), lubatud arvulise tolerantsiga 1e-9. Valemitekstid vastavad mallile täpselt. Sisendid, identiteet, stiilid, mõõdud ja abirida säilisid; üks leht `ITI0207`.
- Põhifaili `data_only=True`: **115/115** numbrilist tulemust, puuduvad tühjad valemitulemused ja vealahtrid. `fullCalcOnLoad=True` säilis.
- Faili eelvaade kontrolliti enne muudatust. Vormingut ei muudetud; järelkontroll tõendas, et muutusid ainult arvutuste vahemälud.
- Varukoopia: `/Users/gustav/Developer/andmebaasid-projekt/iti0207-epood/docs/workload/Tamkivi_ITI0207_toomaht_2026_ver1_backup_before-recalc-20260926-1433.xlsx`.
- Enne: `1dee659a64312c14ae02b95edafa3e854787ad6cbe4eaf807c9f8e85d37e4f1d`.
- Pärast: `95c687f5e623633b89c70902969931e0cb1f5db8115c09d0c548dae6925703fe`.
- Suurus pärast: 8323 baiti.
- Esimene salvestuse ettevalmistus lükati automaatkontrollis tagasi varasema „report only” juhise tõttu. Uuema järelülesande Phase A3–A6 luba loeti uuesti üle ning sama piiratud toiming lubati seejärel. Blokeeringut ei jäänud.

Tööskriptid ja LibreOffice'i ajutised failid asusid `/private/tmp/iti0207-recalc-20260926/`, väljaspool git-tööpuud. Midagi ei lisatud git'i indeksisse.
