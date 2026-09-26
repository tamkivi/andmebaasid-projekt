# Kontroll pärast inimese tehtud esitamist

Kõik väljad on praegu täitmata. See kontrollnimekiri ei tõenda esitamist.

- [ ] Mauruse õige **ver1 / 27.09.2026** vastus on nähtav; failinimi on õige ning puudub veateade.
- [ ] Esitamise aeg on salvestatud koos ajavööndiga, nt `2026-09-27 20:15 EEST` (näide, mitte tegelik aeg).
- [ ] Kinnituskuvatõmmis näitab ülesannet, versiooni, faili ja kinnitust. Salvesta `upload-packet-2026-09-26/confirmation/maurus-ver1-YYYYMMDD-HHMMSS-EEST.png`.
- [ ] Laadi esitatud fail tagasi alla kausta `confirmation/download-back/`; ära kirjuta kontrollitud põhifaili üle.
- [ ] Tagasi laaditud faili SHA-256 kattub `READY-FILE/SHA-256.txt` väärtusega. Kui ei kattu, ära märgi kontrolli läbituks ega esita pimesi uuesti: võrdle failide sisu.
- [ ] Uuenda nii Developer-kausta kui paketi `NOTES-ver1.md`: `uploaded`, tegelik aeg, vastuse viide, kuvatõmmise asukoht, tagasi laaditud faili kontrollsumma ja võrdlustulemus.
- [ ] Gustav annab TalTechi vestluses ise teada „uploaded”.

SHA-256 võrdlemiseks Macis võib kasutada käsku `shasum -a 256` koos allalaaditud faili teega. Faili lihtsalt avamine ei tõenda, et õige fail esitati.
