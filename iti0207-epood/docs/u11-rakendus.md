# Ü11: kaupade halduri rakendus

17.11.2026. Tehniline lisa ja pgApexi lehtede ehitamise juhend. Valisin kauba
halduri töökoha. Valmistasin ette andmebaasi liidese ja kontrollisin seda eraldi
kohalikes PostgreSQL 17 ja 18 andmebaasides. Rakenduse lehti ei ole veel loodud.
Kooliserveri paigaldus, pgApexi lehed ja töö esitamine jäävad eraldi sammudeks.

Lähtusin Ü11 ametliku juhendi punktidest 1, 2 ja 3.2 ning projekti praeguse
analüüsidokumendi kasutusjuhtudest ja mittefunktsionaalsetest nõuetest.
pgApexi seadistuse kirjeldamisel kontrollisin [kolmanda versiooni avalikku
lähtekoodi](https://github.com/dmibiz/pgapex3). Koolis kasutatav versioon võib
sellest erineda. Allpool eristan valmis SQL-i veel kontrollimata kasutajaliidesest.

## Töökoht ja kasutusjuhud

| Kasutusjuht | Lehed | Lugemine | Muutmine |
|---|---|---|---|
| Tuvasta kasutaja | Sisselogimine | `public.f_on_kaubahaldur` | — |
| Registreeri nutitelefon | 5, seejärel 10 ja 11 | Klassifikaatorite valikuvaated, kategooria- ja variandivaade | OP1, OP7–OP10 |
| Unusta kaup | 9 | `public.v_ootel_kaubad` | OP2 |
| Muuda kaupa | 3, 4, 6, 10 ja 11 | `public.v_kaubad_muutmiseks`, `public.v_kauba_muutmise_vorm`, seosevaated | OP6–OP10 |
| Aktiveeri kaup | 7 | `public.v_kaubad_muutmiseks` | OP3 |
| Muuda kaup mitteaktiivseks | 8 | `public.v_aktiivsed_kaubad_haldurile` | OP4 |
| Vaata kõiki ootel või mitteaktiivseid kaupu | 4 | `public.v_kaubad_muutmiseks` | — |
| Vaata kõiki kaupu | 2 ja 3 | `public.v_kaupade_detailid_seostega` | — |

Kauba lõpetamine ja kaupade koondaruanne kuuluvad juhatajale. Aktiivsete kaupade
kataloogi vaatamine kuulub kliendihaldurile, uudistajale ja kliendile. Selle töökoha
menüüsse neid tegevusi ei lisata. Ühtegi lehte ei seota funktsiooniga
`public.f_lopeta_kaup` ega vaadetega `public.v_kaupade_koondaruanne` ja
`public.v_aktiivsed_kaubad`. Seniseid andmebaasiõigusi ei kitsendatud;
lehtede valik ei muuda ühist ühenduskontot eraldi juhataja- ja haldurikontoks.

## Andmebaasi liides

[09_1_rakenduse_liides.sql](../sql/09_1_rakenduse_liides.sql) lisab kaksteist
vaadet. Senised Ü7 vaated, Ü8 rutiinid, Ü9 trigerid ja Ü10 tuvastamisfunktsioon
jäid muutmata. Kõik uued vaated on kommenteeritud, turvabarjääriga, järjestatud
ja kolme toimeta muutmisreegliga. Rakendus saab nende kaudu ainult lugeda.
Seisundit kontrollitakse sisulise koodi järgi, mitte nimetuse ega tehnilise tunnuse järgi.

| Vaade | Põhjus |
|---|---|
| `public.v_ootel_kaubad` | OP3.1 nimekiri sisaldab ainult seisundit 1. |
| `public.v_aktiivsed_kaubad_haldurile` | OP6.1 nimekirjas on üks rida iga seisundis 2 kauba kohta ja registreerimise aeg. |
| `public.v_kauba_muutmise_vorm` | OP4.1 eeltäide annab OP6-le vajalikud klassifikaatorikoodid ja rea tegeliku versiooni tekstina. Sisaldab ainult ootel või mitteaktiivseid nutitelefone. |
| Kuus tehniliste andmete valikuvaadet | Vorm näitab aktiivse väärtuse nimetust ning edastab selle sisulise koodi. |
| `public.v_kategooriate_valikud_tyybiga` | Ühes valikus on kategooria ja tüübi nimetus; mõlemad peavad olema aktiivsed. |
| `public.v_seotud_kategooriate_valikud` | Eemaldamisel on valitavad ka suletud kategooriate seosed ja silt sisaldab tüüpi. |
| `public.v_kaupade_detailid_seostega` | OP8.1 ja OP8.2 ühine allikas koos kategooriate, värvide ja Jah/Ei väärtustega. |

Detailvaates kasutasin uuesti Ü7 detailvaadet ja kategoorialoendit. Värvid koondasin
eraldi enne ühendamist. Nii ei paljunda kaks kategooriat ja kaks värvi kaubarida.
Kategoorialoend sisaldab ka seosteta kaupa, seega on ühendamisel iga kauba jaoks
üks rida. Telefonikirjeta ja lõpetatud kaup jäävad nähtavaks. Seosteta kauba
loendid on tühjad stringid. Ajad ja töötajate nimed tulevad senisest detailvaatest.
HTML-i SQL-is ei koostata; tekstide HTML-erimärkide varjestamine jääb sisse.
`string_agg` kasutamise eest ei arvestata siin ise lisapunkte.

Lisasin ainult kaks õhukest vormifunktsiooni:
`public.f_registreeri_nutitelefon_vormist` ja `public.f_muuda_kaup_vormist`.
Need kutsuvad nimeliste argumentidega senist rutiini ja asendavad ainult kahe
märkeruudu NULL-i FALSE-iga. Muid kontrollimisi ega pildiaadressi teisendusi ei lisatud.
pgApex muudab tühja tekstivälja ise SQL-i NULL-iks. Tühikutest koosnev aadress
peab endiselt saama senise kitsenduse vea.

Vormi eeltäites esitan salvestatud FALSE-i NULL-ina, sest avalik pgApexi kood
märgib iga mittetühja eeltäitega märkeruudu valituks, ka FALSE-i korral.
Salvestatud TRUE jääb TRUE-ks. Valimata ruudu taastab vormifunktsioon FALSE-iks.
Need on sisendi ja esituse kohandused; Ü8 funktsiooni tähendus ei muutu.
Funktsioonid on SQL-keeles, `SECURITY INVOKER`, otsinguteega `public, pg_temp`.
PUBLIC-i käivitusõigus eemaldatakse loomisega samas tehingus.

## Paigaldamine projekti andmebaasi

Need sammud tuleb teha enda projekti andmebaasis. pgApexi metaandmebaasi
`pgapex3` projektitabeleid ega allolevat liidest ei paigaldata.

1. Tee projekti andmebaasist varukoopia ja kontrolli, et selle saab taastada.
2. Kui Ü10 pole veel paigaldatud, tee [Ü10 lisa](u10-tuvastamine.md) sammud.
   Kontrolli pgcrypto asukohta ja teadaoleva testkonto õiget ning valet parooli.
3. Käivita `sql/09_1_rakenduse_liides.sql` objektide omanikuna pärast `09_rutiinid.sql`.
4. Olemasoleval paigaldusel käivita ainult järgmine Ü11 õiguste plokk.
   Kogu `16_rights.sql` uuesti ei käivitata, sest see loob juba olemasoleva rolli.
5. Loo kasutajate halduses eraldi piiratud ühenduskasutaja `epood_u11_login`.
   Luba LOGIN ja INHERIT, anna liikmesus rollis `epood_rakendus`. Ära anna
   SUPERUSER-, CREATEDB-, CREATEROLE-, REPLICATION- ega BYPASSRLS-õigust,
   omandiõigusi ega täiendavaid liikmesusi. Määra parool interaktiivselt psql-is
   käsuga `\password epood_u11_login`; ära kirjuta seda faili ega käsurea argumenti.
6. Kontrolli just ühenduskasutajana vaadete lugemist ja funktsioonide käivitamist.
   Baastabelite lugemine ning muutmine ja funktsiooni `f_leia_tootaja` otsekutse
   peavad olema keelatud. Kontrolli ka päringut, mis tagastab null rida.

```sql
-- Rakenduse liides (Ü11).
GRANT SELECT ON public.v_ootel_kaubad,
    public.v_aktiivsed_kaubad_haldurile,
    public.v_kauba_muutmise_vorm,
    public.v_brandide_valikud,
    public.v_kaamerate_valikud,
    public.v_sisemalude_valikud,
    public.v_diagonaalide_valikud,
    public.v_protsessorite_valikud,
    public.v_ekraani_resolutsioonide_valikud,
    public.v_kategooriate_valikud_tyybiga,
    public.v_kaupade_detailid_seostega,
    public.v_seotud_kategooriate_valikud
    TO epood_rakendus;
GRANT EXECUTE ON FUNCTION public.f_registreeri_nutitelefon_vormist(character varying,character varying,numeric,text,
    character varying,character varying,character varying,boolean,boolean,numeric,numeric,
    integer,numeric,character varying,character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION public.f_muuda_kaup_vormist(text,character varying,character varying,character varying,
    numeric,text,character varying,character varying,character varying,boolean,boolean,
    numeric,numeric,integer,numeric,character varying,character varying) TO epood_rakendus;
```

Värske paigalduse järjekord on `run_u5.sql`, `05_views.sql`,
`07_tuvastamine.sql`, `08_trigerid.sql`, `09_rutiinid.sql`,
`09_1_rakenduse_liides.sql`, `14_statistics.sql`, `16_rights.sql`.
`run_u5.sql` laadib andmeid; see ei uuenda olemasoleva skeemi vaateid ega rutiine.
[Eemaldamise skript](../sql/19_drop_objects.sql) kustutab vormifunktsioonid enne
alusfunktsioone ja uued vaated enne nende aluseks olevaid Ü7 vaateid.
Seda skripti kasutati ainult kohaliku testandmebaasi eemaldamiseks.

## Rakenduse üldseadistus

Ava ise https://apex2.taltech.ee/pgapex3/. Loo rakendus nimega
„Kaupade haldus – kauba halduri töökoht”; vajaduse korral lisa nimele matriklinumber.
Vali projekti andmebaas, ühenduskasutajaks `epood_u11_login` ja sisesta selle parool
ainult seadistusvormi. Pärast SQL-i muutmist kasuta „Refresh database objects”.

Autentimise sinise nupu alt vali „User function”, skeem `public`, funktsioon
`f_on_kaubahaldur` ning sisselogimise mall. Kasutajanimi läheb esimeseks ja parool
teiseks argumendiks. Kasutajanimi on e-posti aadress; parool on tõstutundlik.
Kõigil allpool kirjeldatud lehtedel lülita sisse „Is authentication required”.
Avaleht peab olema rakenduse koduleht. Ka otse lehe aadressiga avamine peab
ilma autentimiseta viima sisselogimiseni. Lisa nähtav väljalogimise link.

Vali või kohanda ainult oma rakenduse malle: kasutajale nähtavad nupud ja lipikud
on eesti keeles. Sisselogimise tõrketeade peab olema „Sisselogimine ebaõnnestus.”.
Avalikus versioonis on keeldumise tekst püsivalt „Permission denied!”; kui kooli
versioonis seda oma malli kaudu muuta ei saa, jääb see tööriista piiranguks.
Ära muuda selle pärast jagatud pgApexi funktsioone ega teiste rakenduste malle.
Lähteprojekti kasutusjuht lubab kuni kolm sisselogimiskatset. Avaliku versiooni
sisselogimiskoodis katsete loendurit ei ole; kontrolli kooli versiooni tuge.
See nõue jääb täitmata, kui kasutatav versioon katseid ei piira.
Piira paroolisisend 72 baidiga, mitte 72 märgiga; tavaline HTML-i märgipiir
üksi ei kontrolli mitmebaidiste märkide korral seda nõuet. Kontrolli piir pärisvormis.

Allolevad numbrid on juhendi loogilised lehed, mitte ette teada pgApexi ID-d.
Loo esmalt tühjad lehed ning märgi nende tegelikud ID-d üles. Linkide ja
ümbersuunamiste jaoks kopeeri vastava lehe tegelik käivitusaadress.
Loomise järjekord: 1, 3, 6, 10, 11, 2, 4, 5, 7, 8, 9.
Nii on detaili- ja muutmisleht enne neile viitavate piirkondade loomist olemas.
Igal lehel on sama navigeerimispiirkond ja link tagasi avalehele.
Menüü järjekord on 1, 2, 4, 5, 7, 8, 9, 10, 11. Lehed 3 ja 6 avatakse reast.

## Leht 1 Avaleht

Lisa HTML-tekst „Kauba halduri töökoht. Siin saab registreerida nutitelefone,
muuta ootel või mitteaktiivse kauba andmeid ja seoseid ning muuta kauba seisundit.”.
Lisa lingid kõigi menüüs olevate tegevuste juurde. Registreerimise lingi juures
selgita: „Pärast telefoni salvestamist lisa kategooriad ja värvivariandid.
Aktiivseks muutmine on eraldi tegevus.”. Näita sisseloginud kasutajat ja
väljalogimise linki: HTML-piirkonnas kuvatakse `#APP_USER#` asemel kasutajanimi.
Väljalogimise lingi aadressiks kasuta `&LOGOUT_LINK&`. Andmeallikat sellel lehel ei ole.

## Lehed 2 Kõik kaubad ja 3 Kauba andmed

Loo leht 3 enne. Lehel 2 lisa „Report and Detail View”. Mõlema allikas on
`public.v_kaupade_detailid_seostega`, unikaalne veerg `kauba_kood`, detaili sihtleht
on leht 3. Aruande nimi on „Kõik kaubad”, detaili nimi „Kauba andmed”.
Määra mõlema piirkonna mall, nähtavus, järjekord ja vähemalt üks kuvatav veerg.
Lehekülje suurus on 20; leheküljenumbri URL-parameeter on `koik_lk`.

Aruande veerud selles järjekorras: `kauba_kood` → „Kauba kood”, `nimetus` →
„Nimetus”, `brand_nimetus` → „Bränd”, `seisundi_nimetus` → „Seisund”, `hind` →
„Hind (EUR, koos maksudega)”, `kirjeldus` → „Kirjeldus”. Rea detaililink läheb
lehele 3 võtmega `kauba_kood`. Kontrolli nii esimest kui ka viimast nimekirjalehte.

Detailis kuva kõik 21 veergu vaate järjekorras. Eelmistele lipikutele lisanduvad
„Pildi aadress”, „Eesmine kaamera (MP)”, „Tagumine kaamera (MP)”, „Sisemälu (GB)”,
„Ekraani diagonaal (tolli)”, „Protsessor”, „Ekraani resolutsioon (pikslit)”,
„Sõrmejäljelugeja”, „Veekindel”, „Kategooriad”, „Värvivariandid”,
„Registreerimise aeg”, „Viimase muutmise aeg”, „Registreerija” ja „Viimane muutja”.
Hoia kõigi tekstiveergude „Is text escaped” väärtus TRUE. Pildi aadressi võib
näidata aadressina; pildi kuvamine pole selle töökoha eeltingimus.
Eraldi alamvorme ei ole vaja, sest koondvaade sisaldab seoseid.
Lisa link tagasi lehele 2. Seda detaillehte ei kasutata muutmise vormina.

## Leht 4 Ootel või mitteaktiivsed kaubad

Lisa aruanne allikaga `public.v_kaubad_muutmiseks`. Kuva `kauba_kood`, `nimetus`,
`seisundi_nimetus`, `hind`, `kirjeldus`, `pildi_aadress`, `reg_aeg`; lipikud on
„Kauba kood”, „Nimetus”, „Seisund”, „Hind (EUR, koos maksudega)”, „Kirjeldus”,
„Pildi aadress” ja „Registreerimise aeg”. `xmin` jääb peitu.
Suurus 20, leheküljenumbri parameeter `muudetavad_lk`.

Lisa aruandesse kaks eraldi lingiveergu, mitte linki koodiveeru omadusena.
Esimese lingi tekst on „Muuda” ja aadress
`&APPLICATION_ROOT&/app/&APPLICATION_ID&/<lehe 6 ID või alias>?kauba_kood=%kauba_kood%`.
Teise lingi tekst on „Vaata” ja aadress
`&APPLICATION_ROOT&/app/&APPLICATION_ID&/<lehe 3 ID või alias>?kauba_kood=%kauba_kood%`.
Asenda nurksulgudes osa tegeliku lehe ID või aliasega. pgApex asendab
`%kauba_kood%` rea väärtusega. Kaubakood koosneb ainult suurtähtedest ja numbritest.
Lehel 6 loodav URL-i üksus peab kandma nime `kauba_kood`; lehe 3 detailvaade
kasutab sama nimega unikaalse veeru URL-parameetrit. „Vaata” kaudu saab enne
muutmist üle vaadata ka kategooriad ja variandid. Lisa eraldi link
„Aktiveeri kaup” lehele 7.

## Leht 5 Registreeri nutitelefon

Lisa „Form”, skeem `public`, funktsioon `f_registreeri_nutitelefon_vormist`.
Eeltäitmist ei ole. Nupu tekst „Salvesta telefon”. Väljade järjekord ja
funktsiooniparameetri järjekorranumber peavad vastama järgmisele tabelile.
Input name võib olla parameetri nimi; see peab olema lehe piires unikaalne.
Kõigil nähtavatel tekstidel on varjestamine sees, WYSIWYG väljas.

| Nr | Parameeter | Lipik | Tüüp ja kohustuslikkus |
|---|---|---|---|
| 1 | `p_kauba_kood` | Kauba kood * | TEXT, vähemalt kuus suurtähte või numbrit, alguses kolm tähte |
| 2 | `p_nimetus` | Nimetus * | TEXT |
| 3 | `p_hind` | Hind (EUR, koos maksudega) * | TEXT, positiivne arv, kümnenderaldajaks punkt |
| 4 | `p_kirjeldus` | Kirjeldus * | TEXTAREA |
| 5 | `p_pildi_aadress` | Pildi aadress | TEXT, valikuline, tühjaks võib jätta |
| 6 | `p_e_meil` | Tegija e-posti aadress | TEXT, peidetud, Default value `&USERNAME&`, ilma eeltäiteveeruta |
| 7 | `p_brandi_kood` | Bränd * | DROP_DOWN, kohustuslik |
| 8 | `p_on_veekindel` | Veekindel | CHECKBOX, valikuline, vaikimisi tühi |
| 9 | `p_on_sormejalelugeja` | Sõrmejäljelugeja | CHECKBOX, valikuline, vaikimisi tühi |
| 10 | `p_kaamera_kood_eesmine` | Eesmine kaamera (MP) * | DROP_DOWN, kohustuslik |
| 11 | `p_kaamera_kood_tagumine` | Tagumine kaamera (MP) * | DROP_DOWN, kohustuslik |
| 12 | `p_sisemalu_kood` | Sisemälu (GB) * | DROP_DOWN, kohustuslik |
| 13 | `p_diagonaali_kood` | Ekraani diagonaal (tolli) * | DROP_DOWN, kohustuslik |
| 14 | `p_protsessori_kood` | Protsessor * | DROP_DOWN, kohustuslik |
| 15 | `p_ekraani_resolutsiooni_kood` | Ekraani resolutsioon (pikslit) * | DROP_DOWN, kohustuslik |

Kuus valikuvaadet seadista nii; kaameravaadet kasutavad mõlemad kaameraväljad.

| Parameeter | Vaade skeemis public | Value column | Label column |
|---|---|---|---|
| `p_brandi_kood` | `v_brandide_valikud` | `brandi_kood` | `brandi_nimetus` |
| Mõlemad kaamerakoodid | `v_kaamerate_valikud` | `kaamera_kood` | `kaamera_nimetus` |
| `p_sisemalu_kood` | `v_sisemalude_valikud` | `sisemalu_kood` | `sisemalu_nimetus` |
| `p_diagonaali_kood` | `v_diagonaalide_valikud` | `diagonaali_kood` | `diagonaali_nimetus` |
| `p_protsessori_kood` | `v_protsessorite_valikud` | `protsessori_kood` | `protsessori_nimetus` |
| `p_ekraani_resolutsiooni_kood` | `v_ekraani_resolutsioonide_valikud` | `ekraani_resolutsiooni_kood` | `ekraani_resolutsiooni_nimetus` |

Edukas salvestamine tagastab kauba koodi. Määra Success message alloleva tabeli
järgi ja jäta „Redirect url” tühjaks: leht kuvatakse uuesti koos eduteatega.
Lisa link „Ava muudetavad kaubad” lehele 4; sealt ava uus kaup ja lisa lehtedel
10–11 kategooriad ning variandid. Tagastatud kaubakoodi jaoks pole avalikus
versioonis ümbersuunamisaadressi muutujat.
Kauba ning iga seose salvestamine on eraldi kinnitatud toiming; need ei moodusta
ühte ühist tagasipööratavat registreerimistehingut.

## Leht 6 Muuda kaupa

Lisa „Form”, funktsioon `public.f_muuda_kaup_vormist`. Lülita sisse „Prefill form”,
vali `public.v_kauba_muutmise_vorm`, lisa tingimus: URL-i parameeter `kauba_kood`
vastab vaate veerule `kauba_kood`. Nupu tekst „Salvesta muudatused”.

| Nr | Parameeter | Eeltäiteveerg | Lipik ja tüüp |
|---|---|---|---|
| 1 | `p_ver` | `ver` | Rea versioon, peidetud TEXT |
| 2 | `p_kauba_kood_vana` | `kauba_kood` | Algne kauba kood, peidetud TEXT |
| 3 | `p_kauba_kood_uus` | `kauba_kood` | Kauba kood *, TEXT |
| 4 | `p_nimetus` | `nimetus` | Nimetus *, TEXT |
| 5 | `p_hind` | `hind` | Hind (EUR, koos maksudega) *, TEXT |
| 6 | `p_kirjeldus` | `kirjeldus` | Kirjeldus *, TEXTAREA |
| 7 | `p_pildi_aadress` | `pildi_aadress` | Pildi aadress, valikuline TEXT |
| 8 | `p_e_meil` | — | Peidetud TEXT, Default value `&USERNAME&` |
| 9 | `p_brandi_kood` | `brandi_kood` | Bränd *, DROP_DOWN |
| 10 | `p_on_veekindel` | `on_veekindel` | Veekindel, valikuline CHECKBOX |
| 11 | `p_on_sormejalelugeja` | `on_sormejalelugeja` | Sõrmejäljelugeja, valikuline CHECKBOX |
| 12 | `p_kaamera_kood_eesmine` | `eesmise_kaamera_kood` | Eesmine kaamera (MP) *, DROP_DOWN |
| 13 | `p_kaamera_kood_tagumine` | `tagumise_kaamera_kood` | Tagumine kaamera (MP) *, DROP_DOWN |
| 14 | `p_sisemalu_kood` | `sisemalu_kood` | Sisemälu (GB) *, DROP_DOWN |
| 15 | `p_diagonaali_kood` | `diagonaali_kood` | Ekraani diagonaal (tolli) *, DROP_DOWN |
| 16 | `p_protsessori_kood` | `protsessori_kood` | Protsessor *, DROP_DOWN |
| 17 | `p_ekraani_resolutsiooni_kood` | `ekraani_resolutsiooni_kood` | Ekraani resolutsioon (pikslit) *, DROP_DOWN |

Kasuta samu valikuvaateid nagu lehel 5. `p_ver` on tavaline funktsiooniargument;
sellel vormil ei kasutata tabelivormi xmin-erivalikut. Ära täida tegija aadressi
kauba registreerija ega viimase muutja andmetega. Suletud klassifikaator ei ilmu valikusse;
sellise kauba salvestamiseks vali aktiivne väärtus. Brauser näitab sel juhul
valiku esimest väärtust; kontrolli enne salvestamist kõik valikud üle.

Määra Success message alloleva tabeli järgi ja jäta „Redirect url” tühjaks.
Leht kuvatakse uuesti koos eduteatega. Kui muutsid kauba koodi, ei leia vana
URL-parameeter enam rida ja vorm jääb tühjaks. Lisa link „Tagasi muudetavate
kaupade juurde” lehele 4 ning ava kaup sealt uue koodiga uuesti. Kategooriate ja
variantide muutmiseks lisa lingid lehtedele 10 ja 11. Pärast seose muutmist ava
leht 6 uuesti nimekirjast: seose muutmine uuendab kauba versiooni ja varem
avatud vorm võib olla aegunud. Vorm ei võimalda muuta registreerimisandmeid ega
kauba seisundit. Telefonikirjeta kauba jaoks selles vormis rida ei ole; ära esita
tühja vormi olemasoleva telefoni eduka eeltäitena.

## Lehed 7 Aktiveeri kaup, 8 Muuda kaup mitteaktiivseks ja 9 Unusta kaup

Igal lehel lisa „Tabular form”, mitte tavaline Form. Unikaalne veerg on
`kauba_kood`, suurus 20, vastavalt parameeter `aktiveeri_lk`, `peata_lk`, `unusta_lk`.
Lisa üks toimingunupp. Märgi „The final function parameter expects a value of
APP_USER variable”; jäta „The second function parameter expects an xmin value”
märkimata. Funktsioon saab `(kauba_kood, sisseloginud kasutajanimi)`.
Kasutajanimi võetakse siin serveri seansist, mitte vormiväljast.

| Leht | Allikas skeemis public | Kuva | Funktsioon skeemis public | Nupp |
|---|---|---|---|---|
| 7 | `v_kaubad_muutmiseks` | Kõik peale xmin-i | `f_aktiveeri_kaup` | Aktiveeri valitud kaup |
| 8 | `v_aktiivsed_kaubad_haldurile` | Kõik kuus veergu | `f_muuda_kaup_mitteaktiivseks` | Muuda valitud kaup mitteaktiivseks |
| 9 | `v_ootel_kaubad` | Kõik kuus veergu | `f_unusta_kaup` | Unusta valitud kaup |

Lipikud on samad nagu lehel 4. Lisa lehele 9 hoiatus „Unustamine kustutab ootel
kauba koos selle kategooriate ja variantidega.”. Luba kasutajal valida üks rida
korraga või juhenda seda tegema. Mitme rea puhul teeb pgApex eraldi kutse iga
rea kohta: hilisem viga ei võta varasemaid õnnestumisi tagasi. Pärast tõrget
värskenda nimekiri ja kontrolli tegelikku seisundit enne kordamist.
Nimekiri tuleb pärast toimingut uuesti avada või värskendada.

## Lehed 10 Kauba kategooriad ja 11 Kauba variandid

Kasutasin eraldi lehti, et iga seose muutmine oleks selgelt eraldi salvestamine.
Lehel 10 lisa aruanne allikaga `public.v_kauba_kategooriad`: kuva `kauba_kood`,
`kategooria_nimetus`, `kategooria_tyyp_nimetus`; lipikud „Kauba kood”,
„Kategooria”, „Kategooria tüüp”. Lehel 11 on allikas `public.v_kauba_variandid`,
kuva `kauba_kood` ja `varvi_nimetus`, lipikud „Kauba kood” ja „Värv”.
Suurus 20, parameetrid vastavalt `kategooriad_lk` ja `variandid_lk`.
Need aruanded näitavad kõiki paare, sealhulgas aktiivse ja lõpetatud kauba seoseid;
muutmisvormi kaubavalik sisaldab ainult ootel või mitteaktiivset kaupa.

Lisa kummalegi lehele kaks Form-piirkonda: lisamine ja eemaldamine.
Eeltäitmist ei kasutata. Kõik väljad peale peidetud tegija on kohustuslikud.
Iga piirkonna Input name peab olema unikaalne: lisa nimele eesliide `lisa_` või
`eemalda_`, parameetri järjekorranumber jääb samaks.

| Leht ja toiming | Funktsioon skeemis public | Nr 1 | Nr 2 | Nr 3 |
|---|---|---|---|---|
| 10 Lisa kategooria | `f_lisa_kaup_kategooriasse` | `p_kauba_kood`, DROP_DOWN | `p_kauba_kategooria_kood`, DROP_DOWN | `p_e_meil`, peidetud TEXT |
| 10 Eemalda kategooria | `f_eemalda_kaup_kategooriast` | sama | sama | sama |
| 11 Lisa variant | `f_lisa_kauba_variant` | `p_kauba_kood`, DROP_DOWN | `p_varv_kood`, DROP_DOWN | `p_e_meil`, peidetud TEXT |
| 11 Eemalda variant | `f_eemalda_kauba_variant` | sama | sama | sama |

Kaubavaliku allikas on `public.v_kaubad_muutmiseks`, Value column `kauba_kood`,
Label column `nimetus`, lipik „Kaup *”. Lõpetamata kaupade nimetused on unikaalsed;
kood on samal lehel aruandes nähtav. Kategooria lisamise allikas on
`public.v_kategooriate_valikud_tyybiga`, Value column `kategooria_kood`, Label
column `valiku_nimetus`, lipik „Kategooria *”. Värvi lisamise allikas on
`public.v_varvide_valikud`, Value column `varvi_kood`, Label column `varvi_nimetus`,
lipik „Värv *”.

Eemaldamisel kasuta kategooria valikuks `public.v_seotud_kategooriate_valikud`,
Value column `kategooria_kood`, Label column `valiku_nimetus`; värvi jaoks
`public.v_kauba_variandid`, Value column `varvi_kood`, Label column `varvi_nimetus`.
Nii saab eemaldada ka vahepeal suletud väärtusega olemasoleva seose. Kategooria
nimetuse juures on tüüp ja iga kategooria esineb valikus korra; värvivalik võib
eri kaupade tõttu korduda. Loendid pole sõltuvad kaubavalikust. Vali eemaldatav
paar aruande järgi; olematu paari eemaldamine annab NULL-i. Kui kooli versioon
toetab sõltuvat valikut, seo see valitud kaubakoodiga ja testi ka suletud väärtust.

Kõigi nelja vormi tegija Default value on `&USERNAME&`, Is visible on FALSE,
eeltäiteveerg puudub. Nuppude tekstid on vastavalt „Lisa kategooria”,
„Eemalda kategooria”, „Lisa variant” ja „Eemalda variant”. Määra iga vormi
Success message alloleva tabeli järgi ja jäta „Redirect url” tühjaks. Sama leht
kuvatakse uuesti koos teate ja värskendatud aruandega. Lisa link
„Tagasi muudetavate kaupade juurde” lehele 4.

## Vormide teated ja tegija tuvastamise piir

| Toiming | Eduteade (Success message) | Veateade (Error message) |
|---|---|---|
| Registreerimine | Telefon salvestatud. | Telefoni ei salvestatud. Kontrolli kohustuslikke välju, koodi ja nimetuse unikaalsust ning aktiivseid valikuid. |
| Muutmine | Muudatused salvestatud. | Muudatusi ei salvestatud. Ava kaup uuesti; vorm võib olla aegunud. Kontrolli sisendeid ja kauba muudetavat seisundit. |
| Aktiveerimine | Kaup aktiveeritud. | Kaupa ei aktiveeritud. Vali ootel või mitteaktiivne kaup ja määra sellele vähemalt üks kategooria. |
| Mitteaktiivseks muutmine | Kaup muudetud mitteaktiivseks. | Seisundit ei muudetud. Vali aktiivne kaup ja värskenda nimekiri. |
| Unustamine | Ootel kaup unustatud. | Kaupa ei unustatud. Kustutada saab ainult ootel kaupa. Värskenda nimekiri. |
| Kategooria lisamine | Kategooria lisatud. | Seost ei lisatud. Kontrolli kauba seisundit, kategooria ja tüübi aktiivsust ning seda, kas seos on juba olemas. |
| Kategooria eemaldamine | Kategooria eemaldatud. | Seost ei eemaldatud. Vali aruandes olemasolev paar ja muudetav kaup. |
| Variandi lisamine | Variant lisatud. | Varianti ei lisatud. Kontrolli värvi aktiivsust, kauba seisundit ja seda, kas variant on juba olemas. |
| Variandi eemaldamine | Variant eemaldatud. | Varianti ei eemaldatud. Vali aruandes olemasolev paar ja muudetav kaup. |

Kõigi muutmistoimingute tõrke juurde lisa ka „Kontrolli oma kasutaja kehtivaid
õigusi.”. NULL ei sisalda ebaõnnestumise täpset põhjust. Trigerite ja kitsenduste
vead jõuavad samuti seadistatud Error message alla; näiteks aktiveerimine ilma
kategooriata ja muus kui ootel seisundis kauba kustutamine annavad `check_violation`-vea.

Määra kõigile vormidele ja tabelivormi nuppudele tabelis toodud eduteated.
Avaliku versiooni tavaline Form lisab eduteate samas erandiplokis, kus kontrollib
NULL-tulemust. Ebaõnnestumisel võetakse eduteate lisamine tagasi ja kuvatakse
veateade. Ümbersuunamisel teated ei säili, seega jäta lehtede 5, 6, 10 ja 11
Form-piirkondade „Redirect url” tühjaks. Kinnita see käitumine kooli versioonis.

Success message ja Error message mahutavad kumbki kuni 255 märki, sealhulgas
lisatava õiguste kontrollimise lause. Input name ja leheküljenumbri URL-parameeter
tohivad sisaldada ainult ladina tähti A–Z ja a–z ning alakriipsu. Eespool toodud
nimed ja teated mahuvad nendesse piiridesse.

Peidetud `&USERNAME&` väljaga ei küsita töötajalt tema aadressi, kuid brauserist
tagasi saadetud väärtust saab muuta. Ü8 rutiin kontrollib aadressile vastava
kaubahalduri volitust, mitte selle aadressi võrdsust pgApexi seansi kasutajaga.
Seetõttu võib teine kehtiv kaubahaldur tavalises vormis jääda tegijaks.
Peidetud välja ei saa pidada turvapiiriks. Tabelivormi kolmel seisundinupul
võetakse tegija serveri seansist. Enne pärisandmetega kasutamist tuleb vormide
tegija sidumine kooli versioonis kontrollida ja lahendada; parooli kordusküsimist
ega uusi autentimisreegleid ei lisatud. Ka lehe peitmine menüüst ei anna
andmebaasi tasemel täiendavat kaitset.

## Mittefunktsionaalsed nõuded ja kontrollimata piirid

| Nõue | Lahendus või veel tehtav kontroll |
|---|---|
| Eesti keel | Lipikud ja teated eespool; kontrolli ka sisselogimise malli püsitekste. |
| Kirsipunane ja terashall | Kohanda oma malli värvid lähteprojekti Pantone 221 CV ja Cool Gray 8 järgi; ekraanivärvi vastavus tuleb eraldi kontrollida. |
| Avaleht ja ühtlane navigeerimine | Leht 1 viib kõikide töökoha tegevusteni. |
| Välisvõtmed valikust, nimetus koodi asemel | Valikuvaated annavad nimetuse ja sisulise koodi; tehnilisi tunnuseid ei näidata. |
| Kohustuslikud väljad, joondus ja erinev välimus | Tärn, ühesugune laius ja vasakjoondus; lugemisväljad halli taustaga, sisestusväljad heleda taustaga. |
| Ühikud ja maksud | Lipikutes EUR koos maksudega, MP, GB, tollid ja pikslid. |
| Kuupäevad ja ajad | Vaadetes Eesti aeg kujul DD.MM.YYYY HH24:MI:SS; sisestatavaid kuupäevi ega kalendrivalikut selles töökohas pole. |
| Süsteemi määratavad andmed | Seisund, ajad ja auditviited määravad rutiinid ning trigerid; vormide tegija seose piir on kirjeldatud eespool. |
| Rea üheselt eristamine | Kaubakood koos nimetusega; kategoorial koos tüübiga, paaride aruandes ka kaubakood. |
| Sorteerimine ja filtreerimine kõigi kuvatavate väljade järgi | Vaated annavad kindla järjestuse. Avalik pgApex ei paku aruande päringule vabalt valitavat sortimis- ja filtritingimust. Nõue jääb kasutajaliideses täitmata, kui kooli versioon lisatuge ei paku. Ära märgi seda kohaliku SQL-kontrolli põhjal täidetuks. |
| Nimelised argumendid ja parameetritud päringud | Meie funktsioonikutsed ja näited kasutavad nimelisi argumente; pgApex ise koostab positsioonilisi SQL-kutseid varjestatud literaalidega. See tööriista piir ei vasta lähteprojekti rangemale nõudele. Jagatud tööriista siin ei muudeta. |
| Vastus kuni 5 sekundiga | Mõõda pärast koolis ehitamist; kohalik test ei kinnita võrgu ja pgApexi vastamisaega. |
| Varukoopiad ja taastamine | Testi projekti andmete ja rakenduse metaandmete taastamist, seejärel korralda vähemalt igapäevane varundamine. |

## Kontrollimine ja rakenduse läbiproovimine

[Liidese kontrolltestid](../sql/tests/09_1_rakenduse_liides.sql) kontrollivad
seisundeid erinevate tehniliste tunnustega, talve- ja suveaega, eeltäidet ja
märkeruute, mõlema vormi positsioonilisi kutseid tüübita literaalidega,
suurtähtedega kasutajanime, suletud klassifikaatoreid, koondloendeid, õigusi ning üheksa
andmemuudatuse kutset. [Loetavad näited](../sql/tests/09_1_rakenduse_liides_naited.sql)
kasutavad ainult väljamõeldud testkontot ja võtavad muudatused tagasi.
Täielik SQL-komplekt sisaldab ka seniseid Ü7–Ü10 kontrolle ja parooliuuendust.

Kohalikes PostgreSQL 17 ja 18 andmebaasides kontrolliti värsket paigaldust,
Ü10 seisust uuendamist ainult uue liidese ning õiguste plokiga, eemaldamist,
null allesjäänud projektiobjekti ja uuesti ehitamist. Mõlemas versioonis tehti
kahe seansi ja koormuskatsed. Senistes näidetes on 23 tahtlikku viga, mille
sõnumeid võrreldi oodatuga. Uute näidete kustutamiskeeld püütakse kinni.
Kohalikud katseandmebaasid koos oma konteinerite ja andmefailidega eemaldati.

Pärast lehtede ehitamist tee järgmised katsed ja kirjuta tegelikud tulemused üles.

1. Õige ja vale parool, suurtähtedega e-posti aadress, puuduva ja mitteaktiivse
   konto keeld ning ainult juhataja rolliga konto keeld. Kontrolli otseviite kaitset
   ja väljalogimist ning kuni kolme sisselogimiskatse piiri. Konto puudumise
   põhjust kasutajale ei avaldata.
2. Registreeri telefon tühja pildiaadressi ja kahe valimata ruuduga. Mõlemad
   väärtused peavad detailis olema „Ei”. Märgi kumbki ruut eraldi ja kontrolli
   kordussalvestamist. Proovi korduvat koodi, korduvat nimetust ja vigast hinda.
3. Lisa ja eemalda kategooria ning variant. Proovi korduvat lisamist ja puuduva
   paari eemaldamist. Sulge valitud klassifikaator testandmetes: lisamine peab
   ebaõnnestuma, olemasolev seos peab aruandes säilima ja olema eemaldatav.
4. Ava sama kaup kahes brauserivormis. Salvesta ühes, seejärel teises: teine
   ei tohi esimest üle kirjutada. Kontrolli ka seose muutmise järel aegunud vormi.
5. Aktiveeri kategooriaga kaup; kategooriata aktiveerimine peab ebaõnnestuma.
   Muuda aktiivne kaup mitteaktiivseks. Proovi sama seisundimuudatust uuesti.
6. Unusta ootel kaup. Aktiivse, mitteaktiivse ja lõpetatud kauba unustamine
   peab ebaõnnestuma. Kontrolli kõigi vormide eduteadet eduka salvestamise järel
   ning ainult veateadet NULL-tulemuse ja erandi korral. Lehed 5, 6, 10 ja 11
   peavad jääma samale lehele ning seosearuanne peab uuenema. Muuda kauba koodi:
   lehe 6 vorm peab vana aadressi korral tühjenema; ava kaup uuesti lehe 4 lingist.
   Kontrolli ka lehe 4 linki „Vaata” koos kategooriate ja variantidega.
7. Kontrolli kõiki nelja seisundit, seosteta ja telefonikirjeta kauba detaili,
   kaht kategooriat ja kaht värvi ühel kaubal, ajavorminguid, lipikuid ja ühikuid.
8. Proovi muuta brauseri päringus peidetud tegija aadressi teise kehtiva halduri
   omaks. Dokumenteeri tulemus; ainult peidetud väli ei lahenda seda probleemi.
   Kontrolli eraldi, et tabelivormi nupp kasutab ikka seansi kasutajat.
9. Kontrolli iga nimekirja sortimis- ja filtrivõimalusi, lehekülgede vahetust,
   kõiki menüülinke ning vastamisaega. Märgi tööriista piirangud päris tulemuste järgi.

## Rakenduse varukoopia ja esitamine

Kui lehed on valmis ja kontrollitud, tee `pgapex3` andmebaasist pg_dump-utiliidiga
plain-vormingus SQL-koopia. Selle andmebaasi nimi on just `pgapex3`, mitte
projekti andmebaasi nimi. Kasuta enda lubatud ühendusviisi ja interaktiivset
parooliküsimist; SSH-ühenduse loomine ei ole selle juhendi osa.

```text
pg_dump --format=plain --no-owner --no-privileges --host=apex2.taltech.ee --username=<sinu_kasutaja> --dbname=pgapex3 --password --file=pgapex3-u11.sql
```

See on käsu mall: asenda kasutajanimi enda omaga. Ära kopeeri nurksulgudes nime
käsureale. Varukoopia sisaldab rakenduse kirjeldust ja võib sisaldada ühenduskonto
parooli. Hoia faili kaitstult, ära lisa seda repositooriumisse ning vaata enne
üleslaadimist sisu ja taastatavus üle. Kasuta ainult selleks rakenduseks eraldi
parooli, mitte mujal kasutatavat saladust. Kui koopias on teiste rakenduste või
inimeste andmeid, täpsusta õppejõuga lubatud ekspordi ulatus; ära muuda ega kustuta
nende kirjeldusi. Parooli mehaaniline eemaldamine võib koopia kasutamiskõlbmatuks
teha; vajaduse korral lepi kokku kontrollkonto ja muuda parool pärast hindamist.

Projekti esitamiseks tuleb õppekeskkonda üles laadida kõik nõutud osad,
sealhulgas rakenduse kirjeldus. Ülikooli serveris töötava pgApexi rakenduse puhul
ei tulene Ü11 juhendist eraldi kohustuslikku Teamsi ettenäitamist. Wordi dokumenti
tuleb kanda Ü11 kirjeldus ja SQL-loendid, ühendada varasemate parandustega ning
värskendada sisukord. Selle juhendi olemasolu, kohalik test ja haru avaldamine
ei tähenda veel valmis veebirakendust ega töö esitamist.
