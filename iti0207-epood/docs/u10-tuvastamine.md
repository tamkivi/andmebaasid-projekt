# Ü10: kasutaja tuvastamine

17.11.2026. Tehniline lisa. Lähtusin Ü10 juhendi versioonist 2 ning pgApexi
kohta käiva tunnijuhendi punktist 3. Realiseerisin kaupade halduri töökoha
andmebaasipoolse tuvastamise. Kontrollisin lahendust eraldi kohalikes
PostgreSQL 17.12 ja 18.6 andmebaasides. Kooliserver ja pgApexi
sisselogimisvorm on veel kontrollimata.

## Paroolid ja kasutajanimi

Parooliveerg `kasutajakonto.parool` oli juba tüüpi `varchar(60)` ning
[JSON-laadija](../sql/12_2_json_laadimine.sql) salvestas paroolid bcrypt-räsina.
Kulutegur on 12 ehk korduste arv 4096. Juhuslik sool sisaldub 60-märgilises
räsiväärtuses; eraldi soolaveergu ei ole vaja. Laadija ei muuda olemasolevate
kontode paroole.

Lisasin [ühekordse uuenduse](../sql/migrations/10_paroolide_rasimine.sql)
varasema paigalduse jaoks, kus võib veel olla avatekstilisi paroole.
WHERE-klausel jätab bcrypt-kujulised väärtused puutumata, et vältida räsi
uuesti räsimist. Praeguse laadijaga loodud andmebaasis muudab see null rida.
Enne uuendust tuleb teha varukoopia ning teada testkonto kasutajanime ja parooli.
Kuju järgi eristamisel on piir: täpselt bcrypt-räsi kujuline avatekstiline
parool jääks samuti muutmata. Muus vormingus varasemat räsi ei tunta ära;
seda uuendust tohib kasutada kirjeldatud avateksti ja bcrypti segule.
Kui pgcrypto on varem paigaldatud teise skeemi, tuleb see enne uuendust
viia skeemi `laiendused`; IF NOT EXISTS olemasolevat laiendust ümber ei paiguta.

Kasutajanimi on isiku meiliaadress. Juba olemasolev indeks `ux_isik_e_meil`
kasutab `lower(e_meil)` ja tagab tõstutundetu unikaalsuse. Meiliaadressile ei
olnud tavalist UNIQUE-kitsendust ega sellele veerule viitavat välisvõtit,
seega ei olnud midagi eemaldada ega uut indeksit lisada. Aadress salvestatakse
sisestatud tõstuga. Tuvastamisel kasutan sama `lower()`-funktsiooni. Ümbritsevaid
tühikuid ei eemaldata. Parool on tõstutundlik ning selle lõputühik loeb.

## Tuvastamisfunktsioon

[07_tuvastamine.sql](../sql/07_tuvastamine.sql) loob kommenteeritud funktsiooni
`public.f_on_kaubahaldur(p_kasutajanimi text, p_parool text)`. Esimene argument
on kasutajanimi ja teine avatekstiline parool; see järjekord on pgApexi jaoks
oluline. Valisin PL/pgSQL-keele, sest kasutaja leidmine, räsi arvutamine ja
võrdlemine on kolm järjestikust sammu. Funktsioon tagastab tõeväärtuse.

| Tingimus | Lubatud väärtus |
|---|---|
| Kasutajakonto | Olemas ja aktiivne |
| Isiku seisund | `EL` ehk elus |
| Töötaja | Isik on töötajate registris |
| Töötaja seisund | `KA` (katseajal), `TO` (tööl) või `PU` (puhkusel) |
| Roll | `KAUBAHALDUR` ning rolliliik on aktiivne |
| Rolli kehtivus | Algushetk on saabunud ja lõpuhetk veel saabumata |
| Kasutajanimi | Meiliaadressiga tõstutundetult võrdne |
| Parool | Arvutatud räsi on salvestatud räsiga võrdne |

Kõik tingimused peavad korraga kehtima. Muudel juhtudel on tulemus FALSE,
sealhulgas NULL-sisendi korral. Seisundid ja roll leitakse koodi, mitte nimetuse
või eeldatava tunnuse järgi. Uus töötaja seisund ei anna vaikimisi sissepääsu.
Rolli algushetk kuulub lubatud ajavahemikku, lõpuhetk ei kuulu.

Valisin ainult kaubahalduri rolli, sest ülesanne nõuab ühe töökoha realiseerimist.
Ainult juhataja rolliga töötaja ja üksnes kliendiks registreeritud isik ei saa
siia sisse logida.
Puhkusel töötaja lubasin sisse samamoodi nagu olemasolev `f_leia_tootaja`.
Seda abifunktsiooni ega Ü8 rutiine ja Ü9 trigereid ei muudetud. Tuvastamine
kontrollib lisaks rolliliigi aktiivsust, mida `f_leia_tootaja` eraldi ei kontrolli.
Selle funktsiooniga ei saa juhatajana sisse logida. Kauba lõpetamise ja
koondaruande senised andmebaasiõigused säilivad; rakenduse lehtede ja toimingute
pääsu tuleb kontrollida eraldi. Juhataja töökoha lisamine vajab eraldi pääsureeglit.

## Näidisräsi ja õigused

Kui sobivat kontot ei leita, kasutan eelnevalt juhusliku sisendi põhjal loodud
bcrypt-näidisräsi sama kuluteguriga 12. Ka tundmatu või sobimatu konto korral
arvutatakse esitatud paroolist räsi. TRUE eeldab siiski päris konto leidmist;
näidisräsi ei anna kellelegi sissepääsu. Nii vähendan kontode eristamist
vastamisaja põhjal, kuid täiesti võrdset aega see ei taga.

Funktsioon on STABLE ja SECURITY DEFINER, otsinguteega `public, pg_temp`.
Püsitabelid ning `laiendused.crypt` on skeemiga määratud. Avalikku skeemi tohib
objekte luua ainult usaldusväärne omanik. PUBLIC-i käivitusõigus eemaldatakse
funktsiooni loomisega samas tehingus. [Õiguste skript](../sql/16_rights.sql)
annab käivitusõiguse olemasolevale rollile `epood_rakendus`. Uut andmebaasi
kasutajat ei loodud. Rakenduseroll ei saa lugeda kontotabelit ega käivitada
skeemi `laiendused` funktsioone otse.

Tuvastamine ei asenda hilisemate toimingute volituste kontrolli. Ü8 rutiinid
kontrollivad endiselt neile antud töötaja meiliaadressi; pgApexis tuleb see võtta
sisselogitud kasutaja seansist, mitte kasutaja muudetavast väljast. Andmebaasi
ühise rakendusekonto olemasolev õiguste hulk iseenesest seda seost ei tõenda.

## Kontrollimine

[Kontrolltestid](../sql/tests/07_tuvastamine.sql) katavad funktsiooni omadused,
parooliveeru, indeksi ja räsikujud, õiged ja valed sisendid, puuduvad kontod,
mitteaktiivse konto, isiku ja töötaja seisundid, uue seisundi, rolli aktiivsuse
ja kehtivusaja ning meiliaadressi tõstuvariandi unikaalsusvea. Rollikoodi
muutmine sama tunnuse juures kontrollib koodipõhist otsustamist. Ajutine
samanimeline tabel ei varjuta päris isikutabelit. Migratsiooni kontroll võrdleb
kõiki seniseid räsiväärtusi ning kinnitab korduva käivitamise muutumatust.

[Loetavad näited](../sql/tests/07_tuvastamine_naited.sql) näitavad seitset
nimeliste argumentidega kutset ja oodatud tulemusi. Seal kasutatakse ainult
väljamõeldud testkontot. Testandmed ja muudatused võetakse ROLLBACK-iga tagasi.
[Õiguste kontroll](../sql/tests/16_rights.sql) kutsub tuvastamisfunktsiooni
rakenduserollina ning kinnitab, et räsiväärtuste lugemine ja crypt-funktsiooni
otsekutse annavad õiguste vea 42501. Lähteandmete paroole ei väljastata.

Mõlemas versioonis läbisid kontrolli värske paigaldus, täielik
[SQL-komplekt](../sql/tests/run_all.sql), Ü9 paigalduse uuendus, kahe
avatekstilise testkonto räsimine, korduskäivitus, eemaldamine, null
projektiobjekti kontroll, uuesti ehitamine ja sama SQL-komplekt. Avateksti
uuendus muutis esimesel korral kaks rida ja teisel null rida. Näidetes on
endiselt 23 tahtlikku Ü8 ja Ü9 viga; kontrollisin ka nende sõnumite vastavust.
PostgreSQL 17-s läbisid kontrolli üheksa kahe seansi katset ja kaks
30-sekundilist koormustesti. Koormustestide tõrgete ja ummikseisude arv oli null.

Mõõtsin igas versioonis kümmet kutset juhtumi kohta. Tabelis on mediaan
millisekundites; tegu on kohaliku mõõtmisega, mitte täitmisaegade võrdsuse tõendiga.

| PostgreSQL | Olemasolev kasutaja, vale parool | Tundmatu kasutaja | Mitteaktiivne konto |
|---|---:|---:|---:|
| 17.12 | 212.961 | 213.171 | 213.879 |
| 18.6 | 214.074 | 213.177 | 213.038 |

## Paigaldamine, eemaldamine ja järgmised sammud

Uue paigalduse järjekord on `run_u5.sql`, `05_views.sql`, `07_tuvastamine.sql`,
`08_trigerid.sql`, `09_rutiinid.sql`, `14_statistics.sql` ja `16_rights.sql`.
Olemasoleval Ü9 paigaldusel tuleb pärast varundamist ja laienduse asukoha
kontrolli käivitada `migrations/10_paroolide_rasimine.sql`, seejärel
`07_tuvastamine.sql` ning anda tuvastamisfunktsiooni käivitusõigus olemasolevale
rakenduserollile faili `16_rights.sql` vastava GRANT-lausega. Kogu õiguste faili
uuesti ei käivitata, sest see loob rolli. Enne tuvastamise kasutamist peavad
senised avatekstilised paroolid olema räsitud; muu soolavorming võib anda vea.
[Eemaldamise skript](../sql/19_drop_objects.sql) kustutab tuvastamisfunktsiooni
enne tabeleid ja pgcrypto-laiendust. Kohalikud testikonteinerid koos nende
andmefailidega on eemaldatud.

Kooliserveris tuleb teha varukoopia, kontrollida pgcrypto asukohta, rakendada
uuendus ja kontrollida teadaolevat testkontot õige ning vale parooliga.
pgApexis tuleb valida autentimine andmebaasifunktsiooniga
`public.f_on_kaubahaldur`: kasutajanimi esimeseks ja parool teiseks argumendiks.
Rakenduse ühenduskasutaja tuleb seadistusest üle kontrollida. Kui see ei ole
omanik, tuleb anda talle vajalikud õigused olemasoleva `epood_rakendus` rolli
kaudu ja kontrollida õigusi selle kasutajana. Päris konto ning parool tuleb
luua ja määrata serveris, mitte SQL-failis. Sisselogimisvormis tuleb proovida
õiget ja valet parooli, suurtähtedega meiliaadressi, mitteaktiivset kontot ning
juhataja konto tagasilükkamist. Kaubahaldur ei tohi saada valida juhataja
meiliaadressi toimingu tegijaks. Neid rakenduse kontrolle siin ei tehtud.

Bcrypt kasutab paroolist kõige rohkem 72 baiti, mis ei tähenda 72 märki.
Rakenduses tuleb selle piiri ületamine keelata. Parool jõuab tuvastamisfunktsiooni
avatekstina; võrguliiklust tuleb kaitsta HTTPS-i ning vajaduse korral
andmebaasiühenduse TLS-iga. Nende seadistamine jääb selle töö kohalikust kontrollist
välja. Wordi dokumenti tuleb kanda Ü10 tekst ja ajakohased SQL-loendid, ühendada
varasemate parandustega ning värskendada sisukord. Kohalik kontroll ei tähenda
töö esitamist.
