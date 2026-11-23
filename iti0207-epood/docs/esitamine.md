# Iseseisva töö esitamine

Esitamiskomplekti kuuluvad projekti aruanne, SQL-skriptide ZIP ning kaks
loogilist varukoopiat. Üks varukoopia sisaldab projektiandmebaasi `t253787`,
teine pgApexi rakenduse andmeid andmebaasist `pgapex3`.

## Uus paigaldus

Käivita [install.sql](../sql/install.sql) psql-is tühja PostgreSQL 17 või 18
projektiandmebaasi omanikuna. Paigalduskontol peab olema õigus luua
andmebaasis laiendusi ja serveris rolle. Testandmete allikas peab sisaldama
tabeleid `public.riik_jsonb` ja `public.isik_jsonb`.
Määra psql-i muutujad `apex_kasutaja`, `apex_parool`, `testandmete_host`,
`testandmete_dbname` ja `testandmete_port`. Hoia ühenduse andmed väljaspool
skripte ja käsuajalugu. Kohalikus katses määra alati JSON-allika kohalik
aadress, andmebaasi nimi ja port.

Paigaldus loob skeemiobjektid, laadib andmed, kogub statistika ja seab õigused.
Õiguste skript loob serveriülesed rollid `epood_rakendus` ning
`t253787_epood_kaubahaldur`. Enne käivitamist kontrolli, et kumbagi rollinime
veel ei kasutata. Olemasoleva skeemi uuendamiseks kasuta vastavaid
migratsiooniskripte.
Ühe andmebaasi varukoopia ei loo taastamisel serveriüleseid rolle.
Õigusi sisaldava varukoopia jaoks loo vajalikud rollid enne taastamist.

## Eraldi kontroll ja eemaldamine

Käivita [tests/run_all.sql](../sql/tests/run_all.sql) katseandmebaasis samade
lähteallika muutujatega. Trigerite ja rutiinide näidetes on oodatavad veateated
kirjas vastava katse juures. Rakenduse ühendust kontrollib
[kontrolli_rakenduse_kasutajat.sh](../scripts/kontrolli_rakenduse_kasutajat.sh)
ning samaaegseid toiminguid
[kontrolli_samaaegsust.sh](../scripts/kontrolli_samaaegsust.sh). Käivita need
üksnes eraldatud kohalikus katsekeskkonnas. Päringu plaani vaatamiseks käivita
[15_explain.sql](../sql/15_explain.sql).

[19_drop_objects.sql](../sql/19_drop_objects.sql) eemaldab projektiobjektid ja
rollid. Kontrolli eemaldamist eraldatud kohalikus katsekeskkonnas.

## Rakendus ja lõplikud varukoopiad

Seadista [kauba halduri lehed](u11-rakendus.md) pgApexis. Ühenda rakendus
piiratud õigustega ühenduskasutaja kaudu. Kontrolli lehti, autentimist ja
muutmistoimingute seost autenditud seansiga. Käivita õppeserveris
`queries2` disainikontroll ja vaata enne varundamist tulemused üle.

Tee `t253787` andmebaasist käsuga `pg_dump` loogiline varukoopia SQL-failina
või kohandatud vormingus. Ekspordi rakenduse andmed andmebaasist `pgapex3`
eraldi lihttekstis SQL-faili õppejõu määratud ulatuses. Vaata üle välisandmete
kasutajaseoste valikud ja rakenduse ühendusseaded. Kontrolli mõlema
varukoopia taastamist eraldi keskkonnas ning uuenda aruande rakenduse
andmeid ja sisukorda enne lõpliku PDF-i salvestamist.
