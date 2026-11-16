# Rutiinide samaaegsuse kontroll

Käivita ainult eraldi kohalikus testandmebaasis, kuhu on laaditud Ü5 andmed,
vaated, trigerid, rutiinid, statistika ja õigused. Vajalikud on Python 3, `psql` ning
`pgbench`. Ühendus kasutab Unixi soklit või aadressi `127.0.0.1`; tabelitele on vaja omaniku õigusi.
Test ei sobi rakenduserolli ühendusele.

```sh
PGUSER=katsetaja scripts/kontrolli_samaaegsust.sh kohalik_test 127.0.0.1 55432 /tmp/samaaegsuse-kontroll
```

Argumendid on andmebaasi nimi, kohalik host või soklikataloog, valikuline port (vaikimisi 56328)
ja valikuline logikataloog. Kui viimast ei anta, luuakse ajutine kataloog väljaspool
repositooriumi. Skript ei loo ega peata serverit. Iga katse valib vaba koodi vahemikust
`CON000`–`CON999` ja eraldi nimetuse. Failide `CON008` on asendatav näidiskood.
Müügis olnud kontrollkaupu ei saa elutsükli järgi enam kustutada; need säilivad
kuni eraldi testandmebaasi eemaldamiseni. Olemasolevaid kaupu ei muudeta.
Pärast katseid eemalda ainult selleks loodud testandmebaas.

| Katse | Esimene seanss | Teine seanss | Oodatav tulemus |
|---|---|---|---|
| S1 | OP6 muudab hinda | OP6 saadab sama vana `xmin`-i ja uue nimetuse | B ootab lukku, siis saab NULL-i; A väärtused säilivad |
| S2 | OP7 lisab kategooria ja kinnitab tehingu | OP6 kasutab enne lisamist loetud versiooni | B saab NULL-i |
| S3 mõlemas järjekorras | OP3 aktiveerib või OP8 eemaldab ainsa kategooria | Teine operatsioon | B ootab lukku ja saab trigeri vea; aktiivne kaup ei jää kategooriata |
| S4 | OP3 aktiveerib | OP3 aktiveerib sama kaupa | B ootab lukku ja saab NULL-i |
| S5 mõlemas järjekorras | OP2 kustutab või OP9 lisab variandi | Teine operatsioon | Kustutamine õnnestub; pärast kustutamist lisamist ei toimu ning orvuks jäänud varianti pole |
| S6 mõlemas järjekorras | Otsene aktiveeriv UPDATE või kategooria DELETE | Teine otsene muudatus | B ootab lukku ja saab trigeri vea ka rutiine kasutamata |

`*_a.sql` ja `*_b.sql` on vastavate seansside laused. Need alustavad tehingu,
mille kinnitab kontrolli käivitaja. S1 ja S2 jaoks annab käivitaja mõlemale seansile
sama `ver`-muutuja, mis loetakse enne A muudatust vaatest `v_kaubad_muutmiseks`.
Seansside eraldi läbimängimisel tuleb see väärtus anda `psql -v ver=...` abil ning
kinnitada A tehing alles pärast B lukuootuse kontrollimist kolmandas ühenduses.
S2 korral kinnitatakse A tehing enne B kutset.

Käivitaja kontrollib lukuootust `pg_stat_activity` kaudu, mitte kindla kestusega
pausi abil. Iga katse järel kontrollitakse kategooria olemasolu aktiivsel kaubal,
kauba ja telefoni üks-ühele seost, ajatempleid ning variantide viiteid.
Kaks 30-sekundilist koormustesti kasutavad kaheksat ühendust ja nelja lõime.
OP6 töökoormuse korral peab tõrkeid olema null. Seoste töökoormus püüab kinni
ainult nimetatud ärireeglite oodatud vead; muud kitsendusevead jäävad nähtavaks. Segatöökoormuses raporteeritakse
võimalikud ummikseisud eraldi ning muudel vigadel kontroll katkeb. Ummikseis
katkestab ühe tehingu; rakendus peab sellise tehingu tervikuna uuesti proovima.
