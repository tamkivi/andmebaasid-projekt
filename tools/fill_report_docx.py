#!/usr/bin/env python3
from __future__ import annotations

from datetime import datetime
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION_START
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor

from sql_ddl import SQL_DDL


ROOT = Path(__file__).resolve().parents[1]
DST = ROOT / "Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx"
DIAGRAM_DIR = ROOT / "work" / "generated_diagrams"

AUTHORS = "Tristan Aik Sild, Gustav Tamkivi"
STUDY_GROUP = "IAIB23"
MATRICULATION_NUMBERS = "Tristan Aik Sild: 253782IAIB; Gustav Tamkivi: 253787IAIB"
AUTHOR_EMAILS = "Gustav Tamkivi: gustav@taltech.ee; Tristan Aik Sild: trists@taltech.ee"
UNIVERSITY = "TALLINNA TEHNIKAÜLIKOOL"
FACULTY = "Infotehnoloogia teaduskond"
INSTITUTE = "Tarkvarateaduse instituut"
COURSE = "Andmebaasid I, ITI0206"
SUPERVISOR = "Erki Eessaar"
TITLE = "Jõusaali rühmatreeningute ajakava, registreerimise ja osalemise funktsionaalne allsüsteem"
SYSTEM_NAME = "Jõusaali infosüsteem"


DIAGRAMS = [
    ("01_system_context.png", "Süsteemi kontekst: osapooled, Flask prototüüp, PostgreSQL ja esitatavad artefaktid."),
    ("02_use_cases.png", "Kasutusjuhtude kaart: juhataja, treeneri ja kliendi töövood."),
    ("03_core_er.png", "Põhiandmemudel: treeninguliik, treeningukord, registreering, osalemine, varustus ja seotud objektid."),
    ("04_registration_activity.png", "Registreerimise tegevusvoog koos kontrollide, mahutavuse ja ootejärjekorraga."),
    ("05_session_state.png", "Treeningukorra seisundimudel ja lubatud üleminekud."),
    ("06_registration_state.png", "Registreeringu seisundimudel ja ootejärjekorrast edendamine."),
    ("07_waitlist_sequence.png", "Ootejärjekorra edendamise järjestus pärast kinnitatud registreeringu tühistamist."),
    ("08_permission_flow.png", "Õiguste ja andmebaasirutiinide seos juhataja, treeneri ja kliendi vaates."),
    ("09_app_db_architecture.png", "Rakenduse ja andmebaasi arhitektuur: vaated lugemiseks, funktsioonid kirjutamiseks."),
    ("10_attendance_activity.png", "Osalemise märkimise tegevusvoog koos rolli, seisundi ja aja kontrollidega."),
]


ACTORS = [
    ("Juhataja", "Sisemine kasutaja", "Planeerib treeningukordi, avab registreerimise, tühistab treeningukordi ja vaatab täituvuse statistikat."),
    ("Treener", "Sisemine kasutaja", "Näeb enda juhendatavaid treeningukordi, avab osalejate nimekirja ja märgib kohalolu."),
    ("Klient", "Väline kasutaja", "Vaatab avatud ajakava, registreerub treeningukorrale, satub vajadusel ootejärjekorda ja tühistab enda registreeringu."),
    ("Süsteem", "Automaatne osapool", "Rakendab ootejärjekorra edendamist, seisundipiiranguid ja andmebaasi ärireegleid."),
]


CORE_OBJECTS = [
    ("Treeninguliik", "Korduv rühmatreeningu tüüp ehk mall, näiteks jooga või HIIT. Selle järgi saab planeerida konkreetseid treeningukordi."),
    ("Treeningukord", "Kalendris toimuv konkreetne rühmatreening kindla treeneri, ruumi, algusaja, lõpuaja, tähtaegade ja mahupiiranguga."),
    ("Ruum", "Stuudio või saal, mille mahutavus seab treeningukorra maksimaalse osalejate arvu ülempiiri."),
    ("Varustus", "Toetav põhiandmete objekt, mida kasutatakse kontrollimaks, kas ruum sobib konkreetse treeninguliigi treeningukorra läbiviimiseks."),
    ("Treeneri pädevus", "Seos, mis määrab, millist treeninguliiki treener tohib juhendada."),
    ("Klient", "Kasutajakontoga seotud osaleja, kes saab registreeruda avatud treeningukorrale."),
    ("Registreering", "Kliendi koht või ootejärjekorra kirje treeningukorral. Aktiivne seisund on kas KINNIT või OOTEJRK."),
    ("Osalemine", "Kinnitatud registreeringu kohalolu tulemus, mille märgib määratud treener või juhataja."),
]


USE_CASES = [
    ("Planeeri treeningukord", "Juhataja", "Juhataja valib aktiivse treeninguliigi, pädeva treeneri, ruumi, aja ja mahupiirangu. Andmebaas kontrollib pädevust, ruumi mahtu, nõutud varustust ja kattuvaid aegu."),
    ("Ava registreerimine", "Juhataja", "Kavandatud tulevane treeningukord muudetakse seisundisse AVATUD, et kliendid saaksid registreeruda."),
    ("Registreeru treeningukorrale", "Klient", "Klient valib avatud treeningukorra. Kui koht on olemas, tekib KINNIT registreering; kui koht puudub, tekib OOTEJRK rida."),
    ("Tühista registreering", "Klient, juhataja", "Klient saab enne tähtaega enda aktiivse registreeringu tühistada. Kui vabaneb kinnitatud koht, edendab andmebaas esimese ootel kliendi."),
    ("Tühista treeningukord", "Juhataja", "Juhataja saab kavandatud, avatud või suletud treeningukorra tühistada. Kõik aktiivsed registreeringud lähevad seisundisse TYH_SYS."),
    ("Märgi osalemine", "Treener, juhataja", "Määratud treener või juhataja märgib kinnitatud registreeringutele osales/ei osalenud tulemuse."),
    ("Vaata statistikat", "Juhataja", "Juhataja näeb täituvust, kinnitatud osalejate arvu, ootejärjekorda ja toimunud treeningukordade koondit."),
]


CRUD_MATRIX = [
    ("Planeeri kord", "R", "C", "R", "R", "-", "-", "-"),
    ("Ava reg.", "R", "U", "-", "-", "-", "-", "-"),
    ("Registreeru", "R", "R", "R", "-", "R", "C", "-"),
    ("Tühista reg.", "-", "R", "-", "-", "R", "U", "-"),
    ("Edenda ootel", "-", "R", "-", "-", "R", "U", "-"),
    ("Märgi osalemine", "-", "R", "-", "-", "R", "R", "C/U"),
    ("Tühista kord", "-", "U", "-", "-", "-", "U", "-"),
    ("Juhataja aruanne", "R", "R", "R", "R", "-", "R", "R"),
    ("Treeneri tunniplaan", "R", "R", "R", "R", "-", "R", "R"),
    ("Kliendi reg-d", "R", "R", "R", "-", "R", "R", "R"),
]


ROUTINES = [
    ("OP1 / fn_planeeri_treeningukord", "Juhataja", "Kasutus kasutusjuhtude poolt: Planeeri treeningukord. Eeltingimused: aktiivne treeninguliik, aktiivne ruum, ruumis olemas treeninguliigi kohustuslik varustus ja TREENER rolliga pädev treener. Järeltingimused: tekib KAVAND treeningukord. Tõrkeolukorrad: vale roll, kattuv aeg, ruumi mahu ületamine, nõutud varustuse puudumine või pädevuse puudumine."),
    ("OP2 / fn_ava_treeningukord", "Juhataja", "Kasutus kasutusjuhtude poolt: Ava registreerimine. Eeltingimused: treeningukord on KAVAND ja tulevikus. Järeltingimused: seisund muutub AVATUD. Tõrkeolukorrad: kirje puudub, seisund pole KAVAND või algus on möödas."),
    ("OP3 / fn_sulge_treeningukord", "Juhataja või määratud treener", "Kasutus kasutusjuhtude poolt: Sulge registreerimine. Eeltingimused: treeningukord on AVATUD ja tegutseja on juhataja või määratud treener. Järeltingimused: seisund muutub SULETUD. Tõrkeolukorrad: vale roll või liiga varane sulgemine treeneri poolt."),
    ("OP4 / fn_lopeta_treeningukord", "Juhataja või määratud treener", "Kasutus kasutusjuhtude poolt: Lõpeta treeningukord. Eeltingimused: treeningukord on SULETUD ja lõpu aeg on möödas. Järeltingimused: seisund muutub TOIMUNUD. Tõrkeolukorrad: vale roll, vale seisund või tulevane treeningukord."),
    ("OP5 / fn_registreeri_klient_treeningukorrale", "Klient", "Kasutus kasutusjuhtude poolt: Registreeru treeningukorrale. Eeltingimused: aktiivne klient ja AVATUD treeningukord tähtaja sees. Järeltingimused: tekib KINNIT või OOTEJRK registreering. Tõrkeolukorrad: topeltaktiivne registreering, möödunud tähtaeg või mitteaktiivne klient."),
    ("OP6 / fn_tyhista_registreering", "Klient või juhataja", "Kasutus kasutusjuhtude poolt: Tühista registreering. Eeltingimused: aktiivne registreering; klient tegutseb enda nimel või tegutseja on juhataja. Järeltingimused: registreering muutub TYH_KL või TYH_SYS; kinnitatud koha vabanemisel edendatakse ootejärjekord. Tõrkeolukorrad: vale omanik, möödunud tähtaeg või lõpetatud treeningukord."),
    ("OP7 / fn_edenda_ootejarjekorrast", "Süsteem", "Kasutus kasutusjuhtude poolt: Ootejärjekorrast edendamine registreeringu tühistamise järel. Eeltingimused: AVATUD treeningukorral on vaba koht ja OOTEJRK rida. Järeltingimused: esimene ootel registreering muutub KINNIT. Tõrkeolukorrad: vaba kohta või ootel rida pole."),
    ("OP8 / fn_marki_osalemine", "Treener või juhataja", "Kasutus kasutusjuhtude poolt: Märgi osalemine. Eeltingimused: kinnitatud registreering, alanud SULETUD või TOIMUNUD treeningukord ning määratud treener või juhataja. Järeltingimused: osalemise rida lisatakse või uuendatakse. Tõrkeolukorrad: vale roll, vale seisund või liiga varane märkimine."),
    ("OP9 / fn_tyhista_treeningukord", "Juhataja", "Kasutus kasutusjuhtude poolt: Tühista treeningukord. Eeltingimused: treeningukord on KAVAND, AVATUD või SULETUD. Järeltingimused: treeningukord muutub TYHIST ning aktiivsed registreeringud TYH_SYS. Tõrkeolukorrad: vale roll, puuduv kirje või juba toimunud treeningukord."),
]


EXTENDED_USE_CASES = [
    {
        "number": "2.1.1.1",
        "name": "Planeeri treeningukord",
        "actor": "Juhataja",
        "interests": [
            "Juhataja soovib avaldada ajakavas ainult selliseid treeningukordi, millel on sobiv ruum, pädev treener ja realistlik mahupiirang.",
            "Treener ja klient soovivad, et ajakavas ei oleks kattuvaid või hiljem tehniliselt parandamist vajavaid treeningukordi.",
        ],
        "trigger": "Juhataja otsustab lisada rühmatreeningu ajakavasse uue konkreetse treeningukorra.",
        "preconditions": "Juhataja on autenditud; aktiivne treeninguliik, ruum ja treener on andmebaasis registreeritud; ruumis on olemas treeninguliigi kohustuslik varustus nõutud koguses.",
        "postconditions": "Andmebaasis on registreeritud KAVAND seisundis treeningukord.",
        "scenario": [
            "Juhataja avab uue treeningukorra vormi.",
            "Süsteem kuvab aktiivsed treeninguliigid, ruumid ja treenerid.",
            "Juhataja valib treeninguliigi, treeneri, ruumi, algus- ja lõpuaja, registreerimise tähtaja, tühistamise tähtaja ning osalejate piiri.",
            "Süsteem kutsub andmebaasioperatsiooni OP1 / fn_planeeri_treeningukord.",
            "Andmebaas kontrollib juhataja rolli, treeneri pädevust, ruumi mahutavust, treeninguliigi kohustuslikke varustuse nõudeid ning treeneri ja ruumi kattuvaid aegu.",
            "Süsteem kuvab loodud treeningukorra juhataja treeningukordade ülevaates.",
        ],
        "extensions": [
            "Kui treeneril puudub pädevus, siis treeningukorda ei looda.",
            "Kui ruum või treener on samal ajal hõivatud, siis andmebaas katkestab operatsiooni.",
            "Kui osalejate piir ületab ruumi mahutavust, siis andmebaas tagastab vea.",
            "Kui valitud ruumis puudub treeninguliigi kohustuslik varustus või seda on nõutust vähem, siis operatsioon ebaõnnestub ja treeningukorda ei looda.",
        ],
        "operations": "Loeb treeninguliik, ruum, treeneri_padevus, varustus, ruumi_varustuse_omamine ja treeninguliigi_varustuse_noue; muudab treeningukord. Rutiin: OP1.",
    },
    {
        "number": "2.1.1.2",
        "name": "Ava registreerimine",
        "actor": "Juhataja",
        "interests": [
            "Juhataja soovib teha planeeritud treeningukorra klientidele nähtavaks ainult siis, kui see on veel tulevikus ja ärireeglitele vastav.",
            "Klient soovib näha ajakavas ainult neid treeningukordi, millele saab päriselt registreeruda.",
        ],
        "trigger": "Juhataja otsustab, et kavandatud treeningukord on valmis registreerimiseks.",
        "preconditions": "Treeningukord on KAVAND seisundis ning selle algusaeg ei ole möödas.",
        "postconditions": "Treeningukorra seisund on AVATUD ja see ilmub kliendi ajakava vaatesse.",
        "scenario": [
            "Juhataja avab treeningukordade haldusvaate.",
            "Süsteem kuvab treeningukorrad vaate v_juhataja_treeningukordade_ulevaade alusel.",
            "Juhataja valib kavandatud treeningukorra ja käivitab registreerimise avamise.",
            "Süsteem kutsub OP2 / fn_ava_treeningukord.",
            "Andmebaas kontrollib juhataja rolli, treeningukorra seisundit ja algusaega.",
            "Süsteem kuvab treeningukorra uue seisundi AVATUD.",
        ],
        "extensions": [
            "Kui treeningukord ei ole KAVAND seisundis, siis seisundimuutust ei tehta.",
            "Kui treeningukorra algusaeg on möödas, siis registreerimist ei avata.",
        ],
        "operations": "Loeb v_juhataja_treeningukordade_ulevaade; muudab treeningukord. Rutiin: OP2.",
    },
    {
        "number": "2.1.1.3",
        "name": "Registreeru treeningukorrale",
        "actor": "Klient",
        "interests": [
            "Klient soovib saada koha valitud rühmatreeningul või teada, et ta jäi ootejärjekorda.",
            "Jõusaal soovib vältida ületäituvust ja sama kliendi mitut aktiivset registreeringut samale treeningukorrale.",
        ],
        "trigger": "Klient valib avatud ajakavast treeningukorra ja soovib osaleda.",
        "preconditions": "Klient on aktiivne; treeningukord on AVATUD; registreerimise tähtaeg ei ole möödas.",
        "postconditions": "Tekib KINNIT registreering või täitunud treeningukorra korral OOTEJRK registreering.",
        "scenario": [
            "Klient avab avatud ajakava.",
            "Süsteem kuvab v_avalikud_treeningukorrad vaate alusel treeningukorrad koos vabade kohtade ja ootejärjekorra arvuga.",
            "Klient valib treeningukorra ja kinnitab registreerimise.",
            "Süsteem kutsub OP5 / fn_registreeri_klient_treeningukorrale.",
            "Andmebaas kontrollib aktiivset klienti, avatud seisundit, tähtaega ja topeltregistreeringut.",
            "Kui vabu kohti on, lisab andmebaas KINNIT registreeringu; kui kohti pole, lisab OOTEJRK registreeringu.",
            "Süsteem kuvab kliendile kinnitatud või ootejärjekorra teate.",
        ],
        "extensions": [
            "Kui klient on juba aktiivselt registreeritud, siis andmebaas keeldub topeltregistreeringust.",
            "Kui tähtaeg on möödas või treeningukord pole AVATUD, siis registreeringut ei looda.",
        ],
        "operations": "Loeb v_avalikud_treeningukorrad; muudab registreering. Rutiin: OP5.",
    },
    {
        "number": "2.1.1.4",
        "name": "Tühista registreering",
        "actor": "Klient või juhataja",
        "interests": [
            "Klient soovib vabastada koha, kui ta ei saa treeningukorrale tulla.",
            "Jõusaal soovib, et vabanenud koht läheks automaatselt esimesele ootel kliendile.",
        ],
        "trigger": "Klient või juhataja soovib aktiivse registreeringu tühistada.",
        "preconditions": "Registreering on KINNIT või OOTEJRK seisundis; klient tegutseb enda registreeringuga või tegutseja on juhataja.",
        "postconditions": "Registreering on TYH_KL või TYH_SYS seisundis; kinnitatud koha vabanemisel on esimene OOTEJRK registreering edendatud KINNIT seisundisse.",
        "scenario": [
            "Tegutseja avab registreeringu vaate.",
            "Süsteem kuvab registreeringud rollile sobivast vaatest.",
            "Tegutseja valib aktiivse registreeringu ja kinnitab tühistamise.",
            "Süsteem kutsub OP6 / fn_tyhista_registreering.",
            "Kui tühistati kinnitatud registreering, kutsub andmebaas OP7 / fn_edenda_ootejarjekorrast.",
            "Süsteem kuvab tühistatud ja vajadusel edendatud registreeringu tulemuse.",
        ],
        "extensions": [
            "Kui klient proovib tühistada võõrast registreeringut, siis operatsioon ebaõnnestub.",
            "Kui tühistamise tähtaeg on möödas, siis klient ei saa registreeringut tühistada.",
            "Kui ootejärjekorras ei ole klienti, siis edendamist ei toimu.",
        ],
        "operations": "Loeb v_kliendi_registreeringud; muudab registreering. Rutiinid: OP6 ja OP7.",
    },
    {
        "number": "2.1.1.5",
        "name": "Märgi osalemine",
        "actor": "Treener või juhataja",
        "interests": [
            "Treener soovib märkida, kes treeningukorral osales ja kes puudus.",
            "Juhataja soovib kasutada osalemise andmeid aruandluses ja täituvuse hindamisel.",
        ],
        "trigger": "Treeningukord on alanud või toimunud ning treener avab osalejate nimekirja.",
        "preconditions": "Treeningukord on SULETUD või TOIMUNUD; registreering on KINNIT; tegutseja on määratud treener või juhataja.",
        "postconditions": "Osalemise kirje on lisatud või uuendatud.",
        "scenario": [
            "Treener avab enda tunniplaani.",
            "Süsteem kuvab v_treeneri_tunniplaan vaate alusel treeneri treeningukorrad.",
            "Treener avab konkreetse treeningukorra osalejate nimekirja.",
            "Süsteem kuvab v_treeningukorra_osalejad vaate alusel kinnitatud osalejad.",
            "Treener märgib osales/ei osalenud väärtused.",
            "Süsteem kutsub iga muudetud rea kohta OP8 / fn_marki_osalemine.",
            "Andmebaas salvestab või uuendab osalemise tulemuse.",
        ],
        "extensions": [
            "Kui treeningukord on veel liiga varajases seisundis, siis osalemist ei märgita.",
            "Kui registreering ei ole KINNIT, siis andmebaas keeldub osalemise märkimisest.",
            "Kui tegutseja ei ole määratud treener ega juhataja, siis operatsioon ebaõnnestub.",
        ],
        "operations": "Loeb v_treeneri_tunniplaan ja v_treeningukorra_osalejad; muudab osalemine. Rutiin: OP8.",
    },
    {
        "number": "2.1.1.6",
        "name": "Tühista treeningukord",
        "actor": "Juhataja",
        "interests": [
            "Juhataja soovib tühistada treeningukorra, kui ruum, treener või korralduslik põhjus takistab tunni toimumist.",
            "Kliendid ja treenerid soovivad, et aktiivsed registreeringud ei jääks ekslikult kehtima.",
        ],
        "trigger": "Juhataja otsustab, et kavandatud, avatud või suletud treeningukord ei toimu.",
        "preconditions": "Treeningukord on KAVAND, AVATUD või SULETUD seisundis.",
        "postconditions": "Treeningukord on TYHIST seisundis ja kõik aktiivsed registreeringud on TYH_SYS seisundis.",
        "scenario": [
            "Juhataja avab treeningukordade haldusvaate.",
            "Juhataja valib tühistatava treeningukorra ja sisestab põhjuse.",
            "Süsteem kutsub OP9 / fn_tyhista_treeningukord.",
            "Andmebaas kontrollib juhataja rolli ja lubatud seisundit.",
            "Andmebaas muudab treeningukorra TYHIST seisundisse ja tühistab aktiivsed registreeringud süsteemselt.",
            "Süsteem kuvab tühistatud treeningukorra ning registreeringute arvu.",
        ],
        "extensions": [
            "Kui treeningukord on juba TOIMUNUD, siis seda enam ei tühistata.",
            "Kui tegutseja ei ole juhataja, siis andmebaas keeldub muudatusest.",
        ],
        "operations": "Loeb v_juhataja_treeningukordade_ulevaade; muudab treeningukord ja registreering. Rutiin: OP9.",
    },
    {
        "number": "2.1.1.7",
        "name": "Vaata statistikat",
        "actor": "Juhataja",
        "interests": [
            "Juhataja soovib näha treeninguliikide täituvust, kinnitatud osalejaid, ootejärjekorda ja osalemise tulemusi.",
            "Jõusaal soovib kasutada koondandmeid ajakava ja ruumikasutuse parandamiseks.",
        ],
        "trigger": "Juhataja soovib hinnata rühmatreeningute täituvust ja osalemist.",
        "preconditions": "Andmebaasis on treeningukorrad, registreeringud ja vajadusel osalemise read.",
        "postconditions": "Andmeid ei muudeta; juhataja saab aruande.",
        "scenario": [
            "Juhataja avab aruande vaate.",
            "Süsteem loeb v_treeningute_taituvuse_statistika vaadet.",
            "Süsteem kuvab treeninguliikide ja treeningukordade koondnäitajad.",
            "Juhataja kasutab tulemusi järgmiste treeningukordade planeerimisel.",
        ],
        "extensions": [
            "Kui mõnel treeninguliigil ei ole veel treeningukordi, siis seda ei kuvata täituvuse koondis või kuvatakse nullväärtustega sõltuvalt aruandest.",
        ],
        "operations": "Loeb v_treeningute_taituvuse_statistika; andmeid ei muuda.",
    },
]


BUSINESS_RULES = [
    ("Ruum ei tohi üle täituda", "Trigger fn_kontrolli_treeningukorra_invariandid kontrollib, et maksimaalne_osalejate_arv <= ruum.mahutavus."),
    ("Ruum peab vastama kohustuslikele varustuse nõuetele", "Trigger fn_kontrolli_treeningukorra_invariandid kasutab fn_ruum_sobib_treeninguliigile kontrolli ja katkestab planeerimise, kui ruumis puudub treeninguliigi jaoks kohustuslik varustus või seda on nõutust vähem."),
    ("Treener peab olema pädev", "Trigger ja planeerimisfunktsioon kontrollivad treeneri aktiivset TREENER rolli ning treeneri_padevus kirjet."),
    ("Treeneril ei tohi olla kattuvaid tunde", "Trigger otsib sama treeneri tühistamata kattuvad treeningukorrad ja katkestab muudatuse."),
    ("Ruumil ei tohi olla kattuvaid tunde", "Trigger otsib sama ruumi tühistamata kattuvad treeningukorrad ja katkestab muudatuse."),
    ("Klient ei saa sama treeningukorda mitu korda aktiivselt broneerida", "Osaline unikaalne indeks uq_registreering_aktiivne_klient_kord lubab ühe KINNIT/OOTEJRK rea."),
    ("Registreerimine peab olema avatud ja tähtaja sees", "fn_registreeri_klient_treeningukorrale kontrollib AVATUD seisundit ja registreerimise_lopp tähtaega."),
    ("Kliendi tühistamine peab olema tähtaja sees", "fn_tyhista_registreering kontrollib tyhistamise_lopp väärtust ning lubab kliendil tühistada ainult enda registreeringu."),
    ("Ootejärjekord peab edendama esimest ootajat", "fn_edenda_ootejarjekorrast lukustab read, valib väikseima ootejarjekorra_nr ja muudab seisundiks KINNIT."),
    ("Seisundid muutuvad ainult lubatud suunas", "Treeningukorra ja registreeringu BEFORE triggerid keelavad otsesed lubamatud UPDATE käsud."),
    ("Osalemist saab märkida ainult kinnitatud registreeringule", "fn_kontrolli_osalemine kontrollib registreeringu, treeningukorra ja märgija sobivust."),
]


TABLES = [
    ("klient", "Kasutajakontoga seotud osaleja.", "PK e_meil, FK kasutajakonto."),
    ("treeninguliigi_seisundi_liik", "Treeninguliigi elutsükli klassifikaator.", "KOOST, AKTIIVNE, MITTEAKT, LOPETATUD."),
    ("treeninguliik", "Rühmatreeningu korduv mall.", "PK treeninguliigi_kood, UNIQUE nimetus, FK seisund."),
    ("ruum", "Saal või stuudio.", "PK ruumi_kood, UNIQUE nimetus, CHECK mahutavus > 0."),
    ("varustus", "Treeningu läbiviimiseks vajalik põhiandmete objekt.", "PK varustuse_kood, UNIQUE nimetus, aktiivsuse tunnus."),
    ("ruumi_varustuse_omamine", "Ruumi olemasolev varustus ja kogus.", "PK ruumi_kood + varustuse_kood, FK ruum ja varustus, CHECK kogus > 0."),
    ("treeninguliigi_varustuse_noue", "Treeninguliigi kohustuslik või soovituslik varustuse nõue.", "PK treeninguliigi_kood + varustuse_kood, FK treeninguliik ja varustus, CHECK minimaalne_kogus > 0."),
    ("treeneri_padevus", "Treeneri lubatud treeninguliigid.", "PK tootaja_e_meil + treeninguliigi_kood, FK tootaja ja treeninguliik."),
    ("treeningukorra_seisundi_liik", "Konkreetse treeningukorra elutsükkel.", "KAVAND, AVATUD, SULETUD, TOIMUNUD, TYHIST."),
    ("treeningukord", "Ajakavas toimuv konkreetne rühmatund.", "FK treeninguliik, treener, ruum, seisund; aja- ja mahupiirangud."),
    ("registreeringu_seisundi_liik", "Registreeringu elutsükkel.", "KINNIT, OOTEJRK, TYH_KL, TYH_SYS."),
    ("registreering", "Kliendi kinnitatud või ootejärjekorra kirje.", "PK registreeringu_kood, partial UNIQUE aktiivsele kliendile ja treeningukorrale."),
    ("osalemine", "Kohalolu tulemus.", "PK/FK registreeringu_kood, FK markija_e_meil."),
]


VIEWS = [
    ("v_avalikud_treeningukorrad", "Kliendile nähtav avatud ajakava koos vabade kohtade ja ootejärjekorraga."),
    ("v_kliendi_registreeringud", "Kliendi enda registreeringud, seisundid, ootejärjekorra number ja osalemise tulemus."),
    ("v_treeneri_tunniplaan", "Treeneri töölaud tulevaste ja toimunud treeningukordade vaatamiseks."),
    ("v_treeningukorra_osalejad", "Treeneri ja juhataja osalejate nimekiri koos kohalolu tulemustega."),
    ("v_juhataja_treeningukordade_ulevaade", "Juhataja haldusvaade kõigi treeningukordade täituvuse ja seisunditega."),
    ("v_treeningute_taituvuse_statistika", "Koondstatistika treeninguliigi kaupa."),
    ("v_treeninguliigid_kategooriatega", "Treeninguliikide loend koos kategooriatega."),
    ("v_ruumide_varustus", "Ruumide varustuse ülevaade juhataja planeerimisvormi ja kontrolli selgitamiseks."),
    ("v_treeninguliigi_varustuse_nouded", "Treeninguliikide kohustuslikud ja soovituslikud varustuse nõuded."),
]

STRATEGIC_STATEMENTS = [
    "Jõusaal pakub klientidele rühmatreeninguid kindlates ruumides ja kindlatel aegadel.",
    "Rühmatreeningu läbiviimiseks peab olema olemas sobiv treeninguliik, pädev treener ning piisava mahutavuse ja nõutud varustusega ruum.",
    "Klient saab osaleda ainult konkreetsel treeningukorral, mitte abstraktsel treeninguliigil.",
    "Kui treeningukorra kinnitatud kohad on täis, saab klient jääda ootejärjekorda.",
    "Kui kinnitatud osaleja tühistab registreeringu, peab süsteem edendama esimese ootel kliendi.",
    "Treener või juhataja märgib pärast treeningukorda osalemise tulemuse.",
]


PROCESS_EVENTS = [
    ("Juhataja otsustab avada uue rühmatunni", "Treeningukorra planeerimine ja registreerimise avamine"),
    ("Klient soovib rühmatunnis osaleda", "Registreerimine või ootejärjekorda paigutamine"),
    ("Kinnitatud klient loobub kohast", "Registreeringu tühistamine ja ootejärjekorra edendamine"),
    ("Treeningukord on toimunud", "Osalemise märkimine"),
    ("Ruum, treener või korralduslik põhjus muutub", "Treeningukorra tühistamine"),
]


LOCATIONS = [
    ("Jõusaali vastuvõtt / haldus", "Juhataja töökoht treeningukordade planeerimiseks ja aruandluseks."),
    ("Treeningusaal või stuudio", "Ruum, kus konkreetne treeningukord toimub ja mille mahutavus seab osalejate piiri."),
    ("Veebirakendus", "Klientide, treenerite ja juhataja ligipääs ajakavale, registreeringutele ja töövoogudele."),
    ("PostgreSQL andmebaas", "Põhiandmete, registreeringute, osalemise ja ärireeglite keskne talletuskoht."),
]


COMPETENCE_AREAS = [
    ("Juhataja", "Planeerib treeningukordi, avab/sulgeb registreerimist, tühistab kordi ja vaatab aruandeid."),
    ("Treener", "Näeb enda tunde ja märgib osalemist."),
    ("Klient", "Vaatab ajakava, registreerub ja tühistab enda registreeringuid."),
    ("Süsteem", "Rakendab automaatset ootejärjekorra edendamist ja seisundipiiranguid."),
]


SUBSYSTEMS = [
    ("Rühmatreeningute ajakava, registreerimise ja osalemise funktsionaalne allsüsteem", "Treeningukordade ja registreeringute register"),
    ("Kasutajate ja rollide halduse administratiivne allsüsteem", "Isikute, kasutajakontode ja töötajate register"),
    ("Klassifikaatorite halduse administratiivne allsüsteem", "Seisundite, rollide ja kategooriate klassifikaatorite register"),
]


NFRS = [
    ("modelleerimiskeel", "Mudelid ja selgitavad diagrammid esitatakse EAP mudelis ning Mermaid diagrammidena DOCX-is."),
    ("andmebaasisüsteem", "PostgreSQL; ärireeglid on jõustatud piirangute, indeksite, funktsioonide ja triggeritega."),
    ("arendusvahendid", "SQL genereeritakse Pythoniga; prototüüp on Flaski rakendus."),
    ("keel", "Dokumentatsioon, kasutajaliides ja andmebaasiobjektide nimed on eesti keeles; andmebaasi identifikaatorid on ASCII-kujul."),
    ("kasutajaliides", "Rollipõhine veebiprototüüp juhatajale, treenerile ja kliendile."),
    ("töökindlus", "Kriitilised kontrollid paiknevad andmebaasis, et vigased muudatused ei sõltuks ainult rakenduse kontrollidest."),
    ("turvalisus", "Rakendus kasutab kasutajakonto andmeid ja rollipõhiseid töövooge; tavapärased muutmised käivad andmebaasirutiinide kaudu."),
    ("andmekvaliteet", "Mahutavus, kattuvad ajad, pädevus, topeltregistreering ja seisundimuudatused kontrollitakse andmebaasis."),
]


ENTITY_DEFINITIONS = [
    ("Kasutajakonto", "Isikute ja rollidega seotud register", "Rakendusse sisselogimiseks kasutatav konto."),
    ("Töötaja", "Isikute ja rollidega seotud register", "Sisemine kasutaja, kes võib olla juhataja või treener."),
    ("Klient", "Treeningukordade ja registreeringute register", "Väline osaleja, kes saab treeningukorrale registreeruda."),
    ("Treeninguliik", "Treeningukordade ja registreeringute register", "Rühmatreeningu korduv mall või tüüp."),
    ("Ruum", "Treeningukordade ja registreeringute register", "Stuudio või saal, mille mahutavus piirab treeningukorda."),
    ("Varustus", "Treeningukordade ja registreeringute register", "Toetav põhiandmete objekt, mis aitab hinnata ruumi sobivust treeninguliigile."),
    ("Ruumi varustuse omamine", "Treeningukordade ja registreeringute register", "Seos, mis talletab, millist varustust ja kui palju konkreetses ruumis on."),
    ("Treeninguliigi varustuse nõue", "Treeningukordade ja registreeringute register", "Seos, mis talletab treeninguliigi kohustusliku või soovitusliku varustuse nõude."),
    ("Treeneri pädevus", "Treeningukordade ja registreeringute register", "Seos treeneri ja treeninguliigi vahel, mis lubab treeneril seda liiki juhendada."),
    ("Treeningukord", "Treeningukordade ja registreeringute register", "Kalendris toimuv konkreetne rühmatreening."),
    ("Registreering", "Treeningukordade ja registreeringute register", "Kliendi kinnitatud või ootejärjekorra koht treeningukorral."),
    ("Osalemine", "Treeningukordade ja registreeringute register", "Treeningukorra järel märgitav kohalolu tulemus."),
    ("Seisundi liik", "Klassifikaatorite register", "Treeninguliigi, treeningukorra või registreeringu lubatud seisund."),
]


ATTRIBUTE_DEFINITIONS = [
    ("isik", "eesnimi", "Isiku ametlik eesnimi. {@Kohustuslik. Väärtus ei tohi olla tühi.}", "Mari"),
    ("isik", "perenimi", "Isiku ametlik perekonnanimi. {@Kohustuslik. Väärtus ei tohi olla tühi.}", "Tamm"),
    ("kasutajakonto", "e_meil", "Kasutaja autentimiseks ja teavitamiseks kasutatav e-posti aadress. {@Kohustuslik. Peab sisaldama märki @ ja olema kontode hulgas kordumatu.}", "klient@jousaal.ee"),
    ("kasutajakonto", "parooli_rasi", "Kasutaja parooli turvaline räsi. {@Kohustuslik. Selge tekstina parooli ei talletata.}", "pbkdf2:sha256:..."),
    ("tootaja", "e_meil", "Töötajat tuvastav kasutajakonto e-posti aadress. {@Kohustuslik. Töötaja peab olema seotud olemasoleva kasutajakontoga.}", "treener@jousaal.ee"),
    ("tootaja", "seisundi_kood", "Töötaja kasutatavuse seisund. {@Kohustuslik. Lubatud väärtus pärineb töötaja seisundite klassifikaatorist.}", "AKTIIVNE"),
    ("klient", "e_meil", "Klienti tuvastav kasutajakonto e-posti aadress. {@Kohustuslik. Klient peab olema seotud olemasoleva kasutajakontoga.}", "klient@jousaal.ee"),
    ("klient", "registreerimise_aeg", "Kliendiks registreerimise aeg. {@Kohustuslik. Ei tohi olla tulevikus sisestushetkest hilisem.}", "2026-05-20 09:00"),
    ("treeninguliik", "treeninguliigi_kood", "Treeninguliigi äriline kood. {@Kohustuslik. Positiivne täisarv. Väärtus peab olema treeninguliikide hulgas kordumatu.}", "1000"),
    ("treeninguliik", "nimetus", "Kliendile ja juhatajale nähtav treeninguliigi nimi. {@Kohustuslik. Väärtus ei tohi olla tühi ja peab olema treeninguliikide hulgas kordumatu.}", "Jooga algajatele"),
    ("treeninguliik", "kestus_minutites", "Tavapärane kestus minutites. {@Kohustuslik. Täisarv vahemikus 15 kuni 240.}", "60"),
    ("treeninguliik", "seisundi_kood", "Treeninguliigi elutsükli seisund. {@Kohustuslik. Lubatud väärtus pärineb treeninguliigi seisundite klassifikaatorist.}", "AKTIIVNE"),
    ("ruum", "ruumi_kood", "Ruumi lühikood. {@Kohustuslik. Väärtus peab olema ruumide hulgas kordumatu.}", "SAAL_A"),
    ("ruum", "nimetus", "Ruumile kasutajaliideses kuvatav nimi. {@Kohustuslik. Väärtus ei tohi olla tühi.}", "Saal A"),
    ("ruum", "mahutavus", "Maksimaalne füüsiline osalejate arv ruumis. {@Kohustuslik. Positiivne täisarv.}", "12"),
    ("varustus", "varustuse_kood", "Varustuse lühikood. {@Kohustuslik. Väärtus ei tohi olla tühi ja peab olema varustuse hulgas kordumatu.}", "MATID"),
    ("varustus", "nimetus", "Varustuse kasutajale arusaadav nimetus. {@Kohustuslik. Väärtus ei tohi olla tühi ja peab olema varustuse hulgas kordumatu.}", "Treeningmatid"),
    ("ruumi_varustuse_omamine", "kogus", "Ruumis olemas oleva varustuse kogus. {@Kohustuslik. Positiivne täisarv.}", "12"),
    ("treeninguliigi_varustuse_noue", "minimaalne_kogus", "Treeninguliigi jaoks vajalik minimaalne varustuse kogus. {@Kohustuslik. Positiivne täisarv.}", "6"),
    ("treeninguliigi_varustuse_noue", "on_kohustuslik", "Tõeväärtus, kas puuduv varustus peab treeningukorra planeerimise peatama. {@Kohustuslik. Jah väärtus blokeerib sobimatu ruumi; ei väärtus on soovituslik.}", "true"),
    ("treeneri_padevus", "tootaja_e_meil", "Pädeva treeneri e-posti aadress. {@Kohustuslik. Viitab aktiivsele töötajale, kellel on treeneri roll.}", "treener@jousaal.ee"),
    ("treeneri_padevus", "treeninguliigi_kood", "Treeninguliik, mida treener võib juhendada. {@Kohustuslik. Viitab olemasolevale aktiivsele treeninguliigile.}", "1000"),
    ("treeneri_padevus", "alates", "Kuupäev, millest alates pädevus kehtib. {@Kohustuslik. Ei tohi olla hilisem kui pädevuse lõppkuupäev.}", "2026-01-01"),
    ("treeneri_padevus", "kuni", "Kuupäev, milleni pädevus kehtib. {@Valikuline. Puuduv väärtus tähendab tähtajatut pädevust.}", "2026-12-31"),
    ("treeningukord", "treeningukorra_kood", "Kalendris toimuva treeningukorra kood. {@Kohustuslik. Positiivne täisarv. Väärtus peab olema treeningukordade hulgas kordumatu.}", "5001"),
    ("treeningukord", "alguse_aeg", "Konkreetse treeningukorra alguse ajatempel. {@Kohustuslik. Algus peab olema enne lõppu.}", "2026-06-01 18:00"),
    ("treeningukord", "lopu_aeg", "Konkreetse treeningukorra lõpu ajatempel. {@Kohustuslik. Lõpp peab olema pärast algust.}", "2026-06-01 19:00"),
    ("treeningukord", "maksimaalne_osalejate_arv", "Selle treeningukorra lubatud osalejate arv. {@Kohustuslik. Positiivne täisarv, mis ei tohi ületada ruumi mahutavust.}", "10"),
    ("treeningukord", "seisundi_kood", "Treeningukorra elutsükli seisund. {@Kohustuslik. Lubatud väärtus pärineb treeningukorra seisundite klassifikaatorist.}", "AVATUD"),
    ("registreering", "registreeringu_kood", "Kliendi registreeringu kood. {@Kohustuslik. Positiivne täisarv. Väärtus peab olema registreeringute hulgas kordumatu.}", "9001"),
    ("registreering", "seisundi_kood", "Registreeringu seisund. {@Kohustuslik. Lubatud väärtus pärineb registreeringu seisundite klassifikaatorist.}", "KINNIT"),
    ("registreering", "ootejarjekorra_nr", "Ootejärjekorras oleva kliendi järjekorranumber. {@Valikuline. Positiivne täisarv ainult ootejärjekorras oleva registreeringu korral.}", "1"),
    ("osalemine", "osales", "Tõeväärtus, kas klient osales treeningukorral. {@Kohustuslik. Väärtus on jah või ei.}", "true"),
    ("osalemine", "markimise_aeg", "Osalemise märkimise aeg. {@Kohustuslik. Ei tohi olla enne treeningukorra algust.}", "2026-06-01 19:05"),
]


POSTGRESQL_REQUIREMENTS = [
    ("Domeenid", "SQL loob domeenid kood_10 ja e_meil_aadress."),
    ("Tabelid", "SQL loob üle seitsme tabeli, sh klient, treeninguliik, ruum, varustus, treeningukord, registreering ja osalemine."),
    ("Vaated", "SQL loob vähemalt neli vaadet; projektis on üheksa rakenduse, põhiandmete ja aruandluse vaadet."),
    ("Triggerid", "SQL loob triggerid rolli, seisundimuutuste, invariandi ja osalemise kontrolliks."),
    ("Rutiinid", "SQL loob vähemalt neli rakendusest kutsutavat funktsiooni; projektis on neid üle üheksa."),
    ("Indeksid", "SQL lisab välisvõtmete veergude indeksid ja osalise unikaalse indeksi aktiivsele registreeringule."),
    ("Testandmed", "SQL lisab testandmed kõigisse põhitabelitesse ja klassifikaatoritesse."),
    ("Rollid ja õigused", "SQL loob rakenduse ja vaatleja rollid ning annab õigused DO-plokkides, mis taluvad piiratud õigustega keskkonda."),
]


STATE_TRANSITIONS_SESSION = [
    ("CREATE", "KAVAND", "Juhataja planeerib treeningukorra."),
    ("KAVAND", "AVATUD", "Juhataja avab registreerimise."),
    ("AVATUD", "SULETUD", "Juhataja või määratud treener sulgeb registreerimise."),
    ("SULETUD", "TOIMUNUD", "Treener või juhataja märgib treeningukorra toimunuks."),
    ("KAVAND/AVATUD/SULETUD", "TYHIST", "Juhataja tühistab treeningukorra."),
]


STATE_TRANSITIONS_REGISTRATION = [
    ("CREATE", "KINNIT", "Klient registreerub ja koht on vaba."),
    ("CREATE", "OOTEJRK", "Klient registreerub, kuid kohad on täis."),
    ("OOTEJRK", "KINNIT", "Süsteem edendab esimese ootel kliendi."),
    ("KINNIT/OOTEJRK", "TYH_KL", "Klient tühistab enda registreeringu."),
    ("KINNIT/OOTEJRK", "TYH_SYS", "Treeningukord tühistatakse või juhataja tühistab registreeringu."),
]


def set_cell_shading(cell, fill: str) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), fill)
    tc_pr.append(shd)


def set_cell_text(cell, text: str, bold: bool = False) -> None:
    cell.text = ""
    paragraph = cell.paragraphs[0]
    run = paragraph.add_run(text)
    run.bold = bold
    run.font.size = Pt(9)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER


def style_document(doc: Document) -> None:
    section = doc.sections[0]
    section.top_margin = Inches(0.8)
    section.bottom_margin = Inches(0.8)
    section.left_margin = Inches(0.9)
    section.right_margin = Inches(0.9)

    styles = doc.styles
    styles["Normal"].font.name = "Arial"
    styles["Normal"].font.size = Pt(10)
    styles["Normal"].paragraph_format.space_after = Pt(5)
    styles["Normal"].paragraph_format.line_spacing = 1.08

    for name, size in [("Heading 1", 15), ("Heading 2", 12.5), ("Heading 3", 11), ("Heading 4", 10)]:
        style = styles[name]
        style.font.name = "Arial"
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = RGBColor(0, 0, 0)
        style.paragraph_format.space_before = Pt(10)
        style.paragraph_format.space_after = Pt(5)

    code = styles.add_style("SqlCode", 1)
    code.font.name = "Courier New"
    code.font.size = Pt(6.5)
    code.paragraph_format.space_after = Pt(0)
    code.paragraph_format.line_spacing = 1.0


def add_title_page(doc: Document) -> None:
    for text, size, bold in [
        (UNIVERSITY, 12, True),
        (FACULTY, 11, False),
        (INSTITUTE, 11, False),
    ]:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(text)
        r.font.name = "Arial"
        r.font.size = Pt(size)
        r.bold = bold

    doc.add_paragraph()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(TITLE)
    r.bold = True
    r.font.name = "Arial"
    r.font.size = Pt(18)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("Andmebaaside projekt")
    r.font.name = "Arial"
    r.font.size = Pt(12)

    doc.add_paragraph()
    details = [
        ("Õppeaine", COURSE),
        ("Autorid", AUTHORS),
        ("Õpperühm", STUDY_GROUP),
        ("Matriklinumbrid", MATRICULATION_NUMBERS),
        ("E-post", AUTHOR_EMAILS),
        ("Juhendaja", SUPERVISOR),
        ("Koostatud", datetime.now().strftime("%d.%m.%Y")),
    ]
    table = doc.add_table(rows=1, cols=2)
    table.style = "Table Grid"
    for label, value in details:
        row = table.add_row().cells
        set_cell_text(row[0], label, True)
        set_cell_text(row[1], value)
    table._tbl.remove(table.rows[0]._tr)

    doc.add_section(WD_SECTION_START.NEW_PAGE)


def add_toc(doc: Document) -> None:
    doc.add_heading("Sisukord", level=1)
    for item in [
        "Sissejuhatus",
        "1 Strateegiline analüüs",
        "1.1 Terviksüsteemi üldvaade",
        "1.2 Rühmatreeningute funktsionaalse allsüsteemi eskiismudelid",
        "1.3 Treeningukordade ja registreeringute registri eskiismudelid",
        "2 Detailanalüüs",
        "2.1 Rühmatreeningute funktsionaalse allsüsteemi detailanalüüs",
        "2.2 Funktsionaalse allsüsteemi vajatavate registrite detailanalüüs",
        "2.3 CRUD maatriks",
        "3 Füüsiline disain",
        "4 Realisatsioon PostgreSQLis",
        "4.20 Rakenduse prototüüp",
        "4.21 Kontroll ja valideerimine",
        "4.22 Kaitsmise selgitus",
        "5 Realisatsioon Oracles",
        "6 Tehisintellekti kasutus",
        "7 Kasutatud materjalid",
        "Lisa A. SQL skript",
    ]:
        doc.add_paragraph(item, style="List Bullet")


def add_table(doc: Document, caption_state: dict[str, int], caption: str, headers: list[str], rows: list[tuple[str, ...]]) -> None:
    caption_state["table"] += 1
    p = doc.add_paragraph()
    r = p.add_run(f"Tabel {caption_state['table']}. {caption}")
    r.bold = True
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    table.autofit = True
    for cell, header in zip(table.rows[0].cells, headers):
        set_cell_shading(cell, "D9EAF7")
        set_cell_text(cell, header, True)
    for row_values in rows:
        row = table.add_row().cells
        for cell, value in zip(row, row_values):
            set_cell_text(cell, value)
    doc.add_paragraph()


def add_figure(doc: Document, caption_state: dict[str, int], filename: str, caption: str) -> None:
    path = DIAGRAM_DIR / filename
    if not path.exists():
        raise FileNotFoundError(f"Puudub Mermaid diagrammi PNG: {path}")
    if filename in {"07_waitlist_sequence.png"}:
        doc.add_page_break()
    caption_state["figure"] += 1
    width = Inches(3.4) if filename == "10_attendance_activity.png" else Inches(6.6)
    doc.add_picture(str(path), width=width)
    last = doc.paragraphs[-1]
    last.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(f"Joonis {caption_state['figure']}. {caption}")
    r.italic = True
    doc.add_paragraph()


def add_bullets(doc: Document, items: list[str]) -> None:
    for item in items:
        doc.add_paragraph(item, style="List Bullet")


def create_numbered_sequence(doc: Document) -> str:
    numbering = doc.part.numbering_part.element
    abstract_num_id = None
    for abstract in numbering.findall(qn("w:abstractNum")):
        for style in abstract.iter(qn("w:pStyle")):
            if style.get(qn("w:val")) == "ListNumber":
                abstract_num_id = abstract.get(qn("w:abstractNumId"))
                break
        if abstract_num_id is not None:
            break
    if abstract_num_id is None:
        abstract_num_id = "7"

    existing_ids = [
        int(num.get(qn("w:numId")))
        for num in numbering.findall(qn("w:num"))
        if num.get(qn("w:numId")) and num.get(qn("w:numId")).isdigit()
    ]
    num_id = str(max(existing_ids, default=0) + 1)
    num = OxmlElement("w:num")
    num.set(qn("w:numId"), num_id)
    abstract = OxmlElement("w:abstractNumId")
    abstract.set(qn("w:val"), abstract_num_id)
    num.append(abstract)
    lvl_override = OxmlElement("w:lvlOverride")
    lvl_override.set(qn("w:ilvl"), "0")
    start_override = OxmlElement("w:startOverride")
    start_override.set(qn("w:val"), "1")
    lvl_override.append(start_override)
    num.append(lvl_override)
    numbering.append(num)
    return num_id


def add_numbered_list(doc: Document, items: list[str]) -> None:
    num_id = create_numbered_sequence(doc)
    for item in items:
        p = doc.add_paragraph(str(item), style="List Number")
        p_pr = p._p.get_or_add_pPr()
        num_pr = p_pr.get_or_add_numPr()
        ilvl = num_pr.get_or_add_ilvl()
        ilvl.set(qn("w:val"), "0")
        num = num_pr.get_or_add_numId()
        num.set(qn("w:val"), num_id)


def add_paragraphs(doc: Document, texts: list[str]) -> None:
    for text in texts:
        doc.add_paragraph(text)


def add_labeled_paragraph(doc: Document, label: str, text: str) -> None:
    p = doc.add_paragraph()
    p.add_run(f"{label}: ").bold = True
    p.add_run(text)


def add_extended_use_case(doc: Document, use_case: dict[str, object]) -> None:
    doc.add_heading(f"{use_case['number']} Kasutusjuht: {use_case['name']}", level=4)
    add_labeled_paragraph(doc, "Primaarne tegutseja", str(use_case["actor"]))
    doc.add_paragraph("Osapooled ja nende huvid:")
    add_bullets(doc, list(use_case["interests"]))
    add_labeled_paragraph(doc, "Käivitav sündmus", str(use_case["trigger"]))
    add_labeled_paragraph(doc, "Eeltingimused", str(use_case["preconditions"]))
    add_labeled_paragraph(doc, "Järeltingimused", str(use_case["postconditions"]))
    doc.add_paragraph("Stsenaarium (tüüpiline sündmuste järjestus):")
    add_numbered_list(doc, list(use_case["scenario"]))
    doc.add_paragraph("Laiendused või alternatiivne sündmuste käik:")
    add_bullets(doc, list(use_case["extensions"]))
    add_labeled_paragraph(doc, "Andmebaasioperatsioonid", str(use_case["operations"]))


def add_report_content(doc: Document) -> None:
    state = {"table": 0, "figure": 0}

    add_toc(doc)

    doc.add_heading("Sissejuhatus", level=1)
    add_paragraphs(doc, [
        f"Projekt käsitleb süsteemi „{SYSTEM_NAME}” funktsionaalset allsüsteemi „{TITLE}”. "
        "Allsüsteemi eesmärk on hallata rühmatreeningute tegelikku tööprotsessi: juhataja planeerib konkreetsed treeningukorrad, "
        "avab registreerimise, klient registreerub või satub ootejärjekorda, süsteem edendab vabanenud kohale esimese ootel kliendi "
        "ning treener märgib pärast tundi osalemise.",
        "Varasem treeningukaardi keskne lahendus oli liiga lähedal töövihiku näitele, sest selle põhisisu oli treeningu nimetuse, "
        "kategooria ja seisundi haldus. Uues lahenduses ei ole põhiobjekt kirjelduskaart, vaid kalendris toimuv treeningukord koos "
        "ruumi, treeneri pädevuse, mahutavuse, registreeringute, ootejärjekorra ja osalemisega.",
        "Projekt ei hõlma makseid, liikmepakette, inventari, toitumiskavasid, palgaarvestust ega täiemahulist personalihaldust. "
        "Varustust käsitletakse ainult ruumi sobivuse põhiandmena, mitte inventari elutsükli või hoolduse allsüsteemina. "
        "Need teemad on teadlikult välja jäetud, et hoida fookus andmebaasi poolt kontrollitaval ajakava, registreerimise ja osalemise protsessil.",
    ])

    doc.add_heading("1 Strateegiline analüüs", level=1)
    doc.add_heading("1.1 Terviksüsteemi üldvaade", level=2)
    doc.add_heading("1.1.1 Organisatsiooni eesmärgid", level=3)
    add_bullets(doc, [
        "Pakkuda klientidele korrastatud ja usaldusväärset rühmatreeningute ajakava.",
        "Kasutada treenerite pädevust, ruume ja ruumide varustust viisil, mis väldib kattuvaid broneeringuid, ületäituvust ja sobimatuid ruumivalikuid.",
        "Anda juhatajale ülevaade treeningukordade täituvusest ja osalemisest.",
    ])
    doc.add_heading("1.1.2 Infosüsteemi eesmärgid", level=3)
    add_bullets(doc, [
        "Talletada treeninguliigid, ruumid, varustuse nõuded, treenerite pädevused, treeningukorrad, registreeringud ja osalemised ühtses andmebaasis.",
        "Jõustada ärireeglid PostgreSQLi piirangute, indeksite, funktsioonide ja triggeritega.",
        "Pakkuda Flaski prototüübis erinevaid töövooge juhatajale, treenerile ja kliendile.",
    ])
    doc.add_heading("1.1.3 Lausendid", level=3)
    add_bullets(doc, STRATEGIC_STATEMENTS)
    doc.add_heading("1.1.4 Põhiobjektid", level=3)
    add_table(doc, state, "Terviksüsteemi põhiobjektid", ["Objekt", "Selgitus"], CORE_OBJECTS)
    doc.add_heading("1.1.5 Mõned põhiprotsessid ja neid käivitavad sündmused", level=3)
    add_table(doc, state, "Põhiprotsessid ja käivitavad sündmused", ["Sündmus", "Põhiprotsess"], PROCESS_EVENTS)
    doc.add_heading("1.1.6 Tegutsejad", level=3)
    add_table(doc, state, "Tegutsejad ja nende rollid", ["Tegutseja", "Tüüp", "Vastutus"], ACTORS)
    doc.add_heading("1.1.7 Asukohad", level=3)
    add_table(doc, state, "Asukohad ja loogilised tööpaigad", ["Asukoht", "Selgitus"], LOCATIONS)
    doc.add_heading("1.1.8 Terviksüsteemi tükeldus allsüsteemideks", level=3)
    add_table(doc, state, "Organisatsiooni pädevusalad", ["Pädevusala", "Vastutus"], COMPETENCE_AREAS)
    add_table(doc, state, "Funktsionaalsed allsüsteemid ja teenindatavad registrid", ["Funktsionaalne allsüsteem", "Register"], SUBSYSTEMS)
    add_figure(doc, state, *DIAGRAMS[0])
    add_paragraphs(doc, [
        "Rakendus on Flaski prototüüp, mis kasutab PostgreSQL andmebaasi. Lugemiseks kasutatakse rollipõhiseid vaateid ning "
        "tavapärased kirjutavad töövood kutsuvad andmebaasi funktsioone. Andmebaasi triggerid, osalised indeksid ja kontrollid "
        "keelavad vigased seisundimuudatused, kattuvad ajad, mahutavuse rikkumised ja varustuse nõuetele mittevastava ruumi valiku ka siis, kui keegi prooviks rakendusest mööda minna.",
    ])

    doc.add_heading("1.2 Rühmatreeningute ajakava, registreerimise ja osalemise funktsionaalse allsüsteemi eskiismudelid", level=2)
    doc.add_heading("1.2.1 Eesmärgid", level=3)
    add_bullets(doc, [
        "Juhataja saab planeerida konkreetseid treeningukordi koos treeneri, ruumi ja mahupiiranguga.",
        "Planeerimisel kontrollib andmebaas lisaks mahutavusele ja pädevusele, et valitud ruumis oleks treeninguliigi kohustuslik varustus.",
        "Klient saab registreeruda avatud treeningukorrale ja näha, kas ta on kinnitatud või ootejärjekorras.",
        "Treener saab näha enda tunde ja märkida osalemist.",
    ])
    doc.add_heading("1.2.2 Seosed pädevusalade ja registritega", level=3)
    add_table(doc, state, "Allsüsteemi seosed pädevusalade ja registritega", ["Pädevusala", "Register/vaade", "Seos"], [
        ("Juhataja", "Treeningukordade ja registreeringute register", "Loob ja muudab treeningukordi, vaatab statistikat."),
        ("Treener", "Treeningukordade ja registreeringute register", "Loeb enda tunniplaani ja märgib osalemist."),
        ("Klient", "Treeningukordade ja registreeringute register", "Loeb avatud ajakava ning loob või tühistab registreeringuid."),
    ])
    doc.add_heading("1.2.3 Allsüsteemi funktsionaalsed nõuded", level=3)
    add_figure(doc, state, *DIAGRAMS[1])
    add_table(doc, state, "Olulisemad kasutusjuhud", ["Kasutusjuht", "Tegutseja", "Sisu"], USE_CASES)
    doc.add_heading("1.2.4 Allsüsteemi mittefunktsionaalsed nõuded", level=3)
    add_table(doc, state, "Mittefunktsionaalsed nõuded", ["Tüüp", "Nõue"], NFRS)
    doc.add_heading("1.2.5 Allsüsteemi kahe elementaarse äriprotsessi tegevusdiagrammid", level=3)
    add_figure(doc, state, *DIAGRAMS[3])
    add_figure(doc, state, *DIAGRAMS[9])
    add_figure(doc, state, *DIAGRAMS[6])
    add_paragraphs(doc, [
        "Registreerimise töövoog on äriliselt oluline, sest see seob mitu objekti ja mitu reeglit: klient, avatud treeningukord, "
        "tähtaeg, mahutavus, aktiivne registreering ja ootejärjekord. Ootejärjekorra edendamine toimub ühes andmebaasi transaktsioonis, "
        "kus treeningukord ja edendatav registreering lukustatakse.",
    ])

    doc.add_heading("1.3 Treeningukordade ja registreeringute registri eskiismudelid", level=2)
    doc.add_heading("1.3.1 Eesmärgid", level=3)
    add_paragraphs(doc, [
        "Põhiregister on Treeningukordade ja registreeringute register. Selle eesmärk on talletada konkreetsed treeningukorrad, nende registreeringud, ootejärjekord ja osalemise tulemused.",
    ])
    doc.add_heading("1.3.2 Registrit kasutavad pädevusalad", level=3)
    add_table(doc, state, "Registrit kasutavad pädevusalad", ["Pädevusala", "Kasutus"], COMPETENCE_AREAS)
    doc.add_heading("1.3.3 Registrit teenindavad funktsionaalsed allsüsteemid", level=3)
    add_bullets(doc, [
        "Rühmatreeningute ajakava, registreerimise ja osalemise funktsionaalne allsüsteem teenindab põhiregistrit.",
        "Kasutajate ja rollide halduse administratiivne allsüsteem toetab isikute, töötajate ja klientide identiteeti.",
    ])
    doc.add_heading("1.3.4 Infovajadused, mida register aitab rahuldada", level=3)
    add_bullets(doc, [
        "Millised treeningukorrad on avatud ja mitu kohta on vabad?",
        "Millised kliendid on kinnitatud või ootejärjekorras?",
        "Millise treeneri, ruumi ja ruumi varustusega treeningukord toimub?",
        "Milline on treeninguliikide täituvus ja osalemise tulemus?",
    ])
    doc.add_heading("1.3.5 Seosed teiste registritega", level=3)
    add_bullets(doc, [
        "Isikute ja kasutajakontode register annab kliendi ja töötaja identiteedi.",
        "Töötajate rollide register määrab juhataja ja treeneri õigused.",
        "Klassifikaatorite register määrab seisundite ja kategooriate lubatud väärtused.",
        "Varustuse põhiandmed seovad treeninguliigi nõuded ruumis olemas oleva varustusega.",
    ])
    doc.add_heading("1.3.6 Ärireeglid", level=3)
    add_table(doc, state, "Registri ärireeglid", ["Reegel", "Andmebaasi mehhanism"], BUSINESS_RULES)
    doc.add_heading("1.3.7 Registri kontseptuaalne eskiismudel", level=3)
    add_figure(doc, state, *DIAGRAMS[2])
    add_table(doc, state, "Põhiobjektid", ["Objekt", "Selgitus"], CORE_OBJECTS)
    add_paragraphs(doc, [
        "Põhiobjektide arv ja omavahelised seosed näitavad, et lahendus ei ole enam ühe treeningukaardi CRUD. Treeninguliik on mall, "
        "treeningukord on konkreetne sündmus, registreering on kliendi osalemissoov või ootejärjekorra koht ning osalemine on pärast "
        "tundi märgitav tulemus. Ruum, ruumi varustus ja treeneri pädevus annavad protsessile piirangud, mida andmebaas saab sisuliselt kontrollida.",
    ])

    doc.add_heading("2 Detailanalüüs", level=1)
    doc.add_heading("2.1 Rühmatreeningute ajakava, registreerimise ja osalemise funktsionaalse allsüsteemi detailanalüüs", level=2)
    doc.add_heading("2.1.1 Allsüsteemi täpsustunud funktsionaalsed nõuded", level=3)
    add_paragraphs(doc, [
        "Laiendatud kasutusjuhud eristavad lugemisoperatsioone ja andmeid muutvaid operatsioone tekstiliselt. Lugemiseks kasutatakse vaateid; muutmiseks kasutatakse PostgreSQL funktsioone.",
    ])
    add_table(doc, state, "Täpsustatud kasutusjuhud ja andmebaasioperatsioonid", ["Kasutusjuht", "Lugemisoperatsioonid", "Muutmisoperatsioonid"], [
        ("Planeeri treeningukord", "treeninguliik, ruum, treeneri_padevus, varustus, ruumi_varustuse_omamine, treeninguliigi_varustuse_noue", "fn_planeeri_treeningukord"),
        ("Ava/sulge/lõpeta/tühista treeningukord", "v_juhataja_treeningukordade_ulevaade", "fn_ava_treeningukord, fn_sulge_treeningukord, fn_lopeta_treeningukord, fn_tyhista_treeningukord"),
        ("Registreeru treeningukorrale", "v_avalikud_treeningukorrad", "fn_registreeri_klient_treeningukorrale"),
        ("Tühista registreering", "v_kliendi_registreeringud", "fn_tyhista_registreering ja fn_edenda_ootejarjekorrast"),
        ("Märgi osalemine", "v_treeningukorra_osalejad", "fn_marki_osalemine"),
        ("Vaata aruandeid", "v_treeningute_taituvuse_statistika", "-"),
    ])
    add_paragraphs(doc, [
        "Järgnevalt on samad kasutusjuhud esitatud laiendatud formaadis. Kirjeldused seovad tegutseja eesmärgi, eel- ja järeltingimused, tüüpilise sündmuste järjestuse, alternatiivid ning andmebaasioperatsioonid.",
    ])
    for use_case in EXTENDED_USE_CASES:
        add_extended_use_case(doc, use_case)

    doc.add_heading("2.2 Rühmatreeningute funktsionaalse allsüsteemi vajatavate registrite detailanalüüs", level=2)
    doc.add_heading("2.2.1 Kontseptuaalne andmemudel", level=3)
    doc.add_heading("2.2.1.1 Olemi-suhte diagrammid", level=4)
    add_paragraphs(doc, ["Kontseptuaalne mudel sisaldab üle seitsme olemitüübi ning kajastab ainult neid objekte, mille andmeid on vaja talletada või mille kaudu jõustatakse ärireegleid."])
    add_figure(
        doc,
        state,
        DIAGRAMS[2][0],
        "Detailanalüüsi põhiandmemudel: treeninguliik, treeningukord, registreering, osalemine, varustus ja seotud objektid.",
    )
    doc.add_page_break()
    doc.add_heading("2.2.1.2 Olemitüüpide definitsioonid", level=4)
    add_table(doc, state, "Olemitüüpide definitsioonid", ["Olemitüübi nimi", "Kuuluvus registrisse", "Definitsioon"], ENTITY_DEFINITIONS)
    doc.add_heading("2.2.1.3 Atribuutide definitsioonid", level=4)
    add_paragraphs(doc, [
        "Atribuutide definitsioonides on loogelistes sulgudes esitatud piirangud. Tähis @Kohustuslik tähendab, et väärtus peab olema olemas; @Valikuline tähendab, et väärtus võib ärireegliga lubatud juhul puududa.",
    ])
    add_table(doc, state, "Atribuutide definitsioonid", ["Olemitüüp", "Atribuut", "Definitsioon", "Näiteväärtus"], ATTRIBUTE_DEFINITIONS)
    doc.add_heading("2.2.2 Andmebaasioperatsioonide lepingud", level=3)
    add_table(doc, state, "Andmebaasirutiinide lepingud", ["Rutiin", "Tegutseja", "Eeltingimused, järeltingimused ja vead"], ROUTINES)
    add_paragraphs(doc, [
        "Operatsioonilepingud on realiseeritud PostgreSQL funktsioonidena. Rakendus võib enne vormi saatmist teha kasutajakogemust parandavaid kontrolle, "
        "kuid lõplik otsus jääb andmebaasile. Vea korral tagastab PostgreSQL erindi, mille Flask kuvab kasutajale eestikeelse teatena.",
    ])
    doc.add_heading("2.2.3 Registri põhiobjekti seisundidiagramm", level=3)
    add_figure(doc, state, *DIAGRAMS[4])
    add_table(doc, state, "Treeningukorra lubatud seisundimuudatused", ["Algseisund", "Lõppseisund", "Sündmus ja tegutseja"], STATE_TRANSITIONS_SESSION)
    add_figure(doc, state, *DIAGRAMS[5])
    add_table(doc, state, "Registreeringu lubatud seisundimuudatused", ["Algseisund", "Lõppseisund", "Sündmus ja tegutseja"], STATE_TRANSITIONS_REGISTRATION)

    doc.add_page_break()
    doc.add_heading("2.3 CRUD maatriks", level=2)
    add_table(
        doc,
        state,
        "CRUD-maatriks põhiobjektide ja kasutusjuhtude lõikes",
        ["Kasutusjuht", "Liik", "Kord", "Ruum", "Pädevus", "Klient", "Reg.", "Osal."],
        CRUD_MATRIX,
    )
    add_table(
        doc,
        state,
        "Varustuse toetavate põhiandmete kasutus planeerimisel",
        ["Tabel", "Kasutusjuht", "CRUD", "Selgitus"],
        [
            ("varustus", "Treeningukorra planeerimine", "R", "Planeerimise kontroll loeb, kas varustus on aktiivne."),
            ("ruumi_varustuse_omamine", "Treeningukorra planeerimine", "R", "Kontroll loeb, milline varustus ja kogus on valitud ruumis."),
            ("treeninguliigi_varustuse_noue", "Treeningukorra planeerimine", "R", "Kontroll loeb treeninguliigi kohustuslikud ja soovituslikud nõuded."),
        ],
    )
    add_paragraphs(doc, [
        "Maatriks näitab, et kasutusjuhud ei piirdu ühe treeningukaardi lugemise ja muutmisega, vaid puudutavad mitut põhiobjekti ning mitut andmeid muutvat operatsiooni. "
        "Varustuse tabelid on planeerimise operatsiooni poolt loetavad toetavad põhiandmed.",
    ])

    doc.add_heading("3 Füüsiline disain", level=1)
    doc.add_heading("3.1 Rühmatreeningute funktsionaalse allsüsteemi vajatavate registrite füüsiline disain", level=2)
    add_figure(doc, state, *DIAGRAMS[7])
    add_table(doc, state, "Olulisemad tabelid ja piirangud", ["Tabel", "Eesmärk", "Võtmed ja piirangud"], TABLES)
    add_table(doc, state, "Rakenduse ja aruandluse vaated", ["Vaade", "Kasutus"], VIEWS)
    add_figure(doc, state, *DIAGRAMS[8])
    add_paragraphs(doc, [
        "Füüsiline mudel kasutab eraldi klassifikaatoreid treeninguliigi, treeningukorra ja registreeringu seisunditele. "
        "Aktiivse registreeringu topelttegemise keelab osaline unikaalne indeks. Ruumi ja treeneri kattuvused on triggeripõhised, "
        "sest see ei eelda PostgreSQL laienduste paigaldamist. Ootejärjekorra edendamine toimub funktsioonis, mis lukustab korraga "
        "vajalikud read ja väldib sama koha mitmekordset jagamist.",
    ])

    doc.add_heading("4 Realisatsioon PostgreSQLis", level=1)
    doc.add_heading("4.1 Andmebaasi loomine", level=2)
    add_paragraphs(doc, ["Andmebaas luuakse PostgreSQLis. Esitatav skript eeldab olemasolevat andmebaasi ning loob vajalikud objektid public skeemis."])
    doc.add_heading("4.2 Skeemid", level=2)
    add_paragraphs(doc, ["Käesolevas prototüübis kasutatakse public skeemi. Rakenduse ja vaatleja rollidele antakse õigused sellele skeemile."])
    doc.add_heading("4.3 Domeenid", level=2)
    add_paragraphs(doc, ["SQL loob domeenid kood_10 ja e_meil_aadress, mida kasutatakse klassifikaatorikoodide ja e-posti aadresside järjepidevaks kirjeldamiseks."])
    doc.add_heading("4.4 Tabelid ja arvujada generaatorid", level=2)
    add_table(doc, state, "PostgreSQL tabelid ja põhipiirangud", ["Tabel", "Eesmärk", "Võtmed ja piirangud"], TABLES)
    doc.add_heading("4.5 Vaated", level=2)
    add_table(doc, state, "PostgreSQL vaated", ["Vaade", "Kasutus"], VIEWS)
    doc.add_heading("4.6 Protseduursed keeled", level=2)
    add_paragraphs(doc, ["Projekt kasutab PostgreSQL PL/pgSQL funktsioone triggerite ja rakendusest kutsutavate rutiinide realiseerimiseks."])
    doc.add_heading("4.7 Trigeri funktsioonid ja trigerid", level=2)
    add_bullets(doc, [
        "fn_kontrolli_treeneri_padevust kontrollib, et pädevuse saab anda ainult treenerile.",
        "fn_kontrolli_treeningukorra_invariandid kontrollib ruumi mahtu, treeneri pädevust, ruumi varustuse sobivust ning treeneri ja ruumi kattuvusi.",
        "fn_kontrolli_treeningukorra_seisund ja fn_kontrolli_registreeringu_seisund keelavad lubamatud seisundimuutused.",
        "fn_kontrolli_osalemine lubab kohalolu märkida ainult sobivas seisundis kinnitatud registreeringule.",
    ])
    doc.add_heading("4.7.1 Trigerite testimise laused", level=3)
    add_paragraphs(doc, ["SQL skript sisaldab DO-plokke, mis proovivad eeldatavalt vigaseid lisamisi: ruumi mahu ületamist, treeneri kattuvust, ruumi kattuvust, varustuse nõude rikkumist ja topeltregistreeringut. Live-validaator käivitab täiendavad käitumistestid eraldi ajutises andmebaasis."])
    doc.add_heading("4.8 Reeglid", level=2)
    add_paragraphs(doc, ["PostgreSQL CREATE RULE objekte ei kasutata. Hindamismudeli sisulised ärireeglid on realiseeritud CHECK/FK piirangute, triggerite, osaliste indeksite ja funktsioonidega."])
    doc.add_heading("4.8.1 Reeglite testimise laused", level=3)
    add_paragraphs(doc, ["Eraldi CREATE RULE testlauseid ei ole, sest CREATE RULE objekte ei kasutata. Sama ärireeglite käitumine on kaetud triggerite ja rutiinide testidega."])
    doc.add_heading("4.9 Rutiinid", level=2)
    add_table(doc, state, "Rakendusest kutsutavad rutiinid", ["Rutiin", "Tegutseja", "Eeltingimused, järeltingimused ja vead"], ROUTINES)
    doc.add_heading("4.9.1 Rutiinide testimise laused", level=3)
    add_paragraphs(doc, ["Validaatori live SQL režiim kutsub registreerimise, tühistamise, ootejärjekorra edendamise ja treeningukorra planeerimise funktsioone. Varustuse sobivust kontrollitakse fn_ruum_sobib_treeninguliigile abifunktsiooni kaudu. SQL skript sisaldab ka demoandmeid, mille põhjal saab rutiine käsitsi välja kutsuda."])
    doc.add_heading("4.10 Indeksid", level=2)
    doc.add_heading("4.10.1 Välisvõtmete veergudele lisatavad indeksid", level=3)
    add_paragraphs(doc, ["SQL lisab indeksid välisvõtmete veergudele, sh treeningukord.treeninguliigi_kood, treeningukord.treener_e_meil, treeningukord.ruumi_kood, registreering.treeningukorra_kood, registreering.klient_e_meil ning varustuse seostabelite varustuse_kood veerud."])
    doc.add_heading("4.10.2 Täiendavad sekundaarsed indeksid", level=3)
    add_paragraphs(doc, ["Täiendav osaline unikaalne indeks uq_registreering_aktiivne_klient_kord keelab sama kliendi mitu aktiivset registreeringut samale treeningukorrale."])
    doc.add_heading("4.10.3 Funktsioonil põhinevad indeksid", level=3)
    add_paragraphs(doc, ["Funktsioonil põhinevaid indekseid ei kasutata, sest päringud ja piirangud on lahendatud tavaliste ning osaliste indeksitega."])
    doc.add_heading("4.11 Klassifikaatorite väärtustamine", level=2)
    add_paragraphs(doc, ["SQL väärtustab riigi, isiku seisundi, töötaja seisundi, töötaja rolli, treeninguliigi seisundi, treeningukorra seisundi, registreeringu seisundi ja treeningu kategooria klassifikaatorid ning lisab varustuse põhiandmed."])
    doc.add_heading("4.12 JSON formaadis lähteandmete laadimine", level=2)
    add_paragraphs(doc, ["SQL skript demonstreerib JSON-vormingus lähteandmete laadimist ruumi testandmete juures. Plokk kasutab PostgreSQL funktsiooni jsonb_to_recordset, teisendab JSON massiivi veergudeks ning lisab saadud read tabelisse ruum. Ülejäänud demoandmed lisatakse loetavuse huvides tavaliste INSERT lausetega."])
    doc.add_heading("4.13 Täiendavate testandmete lisamine", level=2)
    add_paragraphs(doc, ["SQL lisab testandmed kõigisse põhitabelitesse: ruumid, varustus, treeninguliikide varustuse nõuded, ruumide varustus, treenerid, kliendid, treeninguliigid, pädevused, treeningukorrad, registreeringud ja osalemised. Demoandmetes on ka täis treeningukord, ootejärjekorra näide ning ruum, mis ei sobi jõutreeningu varustuse nõude tõttu."])
    doc.add_heading("4.14 Andmebaasi statistika kogumine", level=2)
    add_paragraphs(doc, ["Andmebaasi statistika kogumiseks käivitab skript pärast objektide ja testandmete loomist käsu ANALYZE. See loob optimeerijale värske statistika demoandmete põhjal."])
    doc.add_heading("4.15 Päringu täitmisplaani näide", level=2)
    add_paragraphs(doc, ["Päringuplaani kontrolliks sobib näiteks EXPLAIN SELECT * FROM v_avalikud_treeningukorrad WHERE vabu_kohti > 0. Vaade kasutab treeningukorra ja registreeringu indekseid ning koondab kinnitatud/ootejärjekorra loendusi."])
    doc.add_heading("4.16 Rollid ja kasutajad", level=2)
    add_paragraphs(doc, ["SQL proovib luua rollid jousaali_rakendus ja jousaali_vaatleja. Kui kasutajal puudub CREATE ROLE õigus, annab skript NOTICE teate ega katkesta põhiskeemi loomist."])
    doc.add_heading("4.17 Üleliigsete õiguste äravõtmine", level=2)
    add_paragraphs(doc, ["Skript proovib eemaldada PUBLIC rollilt public skeemi CREATE õiguse. Kui käivitajal puudub selleks õigus, väljastatakse NOTICE ning põhiskeemi loomist ei katkestata. Prototüübi lihtsustamiseks jääb rakenduse rollile tabelite kirjutusõigus, kuid tavapärased töövood kasutavad funktsioone ja ärireeglid jäävad andmebaasis jõusse."])
    doc.add_heading("4.18 Õiguste jagamine", level=2)
    add_paragraphs(doc, ["Rakenduse roll saab skeemi kasutusõiguse, tabelite lugemisõiguse, järjestuste kasutusõiguse ja funktsioonide käivitamise õiguse. Vaatleja roll saab lugemisõiguse."])
    doc.add_heading("4.19 Andmebaasiobjektide kustutamine", level=2)
    add_paragraphs(doc, ["Kustutamislaused tuleb käivitada vastupidises sõltuvusjärjekorras: õigused, vaated, triggerid, funktsioonid, tabelid, domeenid, rollid. Esitatav loomisskript sisaldab kustutamise näidisplokki kommentaaridena, et tavapärane käivitamine ei kustutaks loodud hindamisandmebaasi."])

    doc.add_heading("4.20 Rakenduse prototüüp", level=2)
    add_paragraphs(doc, [
        "Flaski prototüübis on kolm nähtavat töövoogu. Juhataja saab näha ja planeerida treeningukordi, avada või sulgeda registreerimist, "
        "tühistada treeningukorra ning vaadata täituvuse statistikat. Treener näeb enda treeningukordi, avab osalejate nimekirja ja märgib "
        "osalemist. Klient näeb avatud ajakava, registreerub treeningukorrale, näeb kas ta on kinnitatud või ootejärjekorras ning saab enda "
        "registreeringu enne tähtaega tühistada.",
        "Juhataja planeerimisvorm kuvab ruumide varustuse kokkuvõtte ning treeninguliikide varustuse nõuded. Kui valitud ruum ei sobi, tagastab andmebaas eestikeelse vea ja rakendus kuvab selle vormil.",
        "Tavapärased kirjutavad marsruudid ei tee otse INSERT/UPDATE/DELETE käske tabelitesse treeningukord, registreering ja osalemine. "
        "Need kutsuvad funktsioone fn_planeeri_treeningukord, fn_ava_treeningukord, fn_sulge_treeningukord, fn_lopeta_treeningukord, "
        "fn_registreeri_klient_treeningukorrale, fn_tyhista_registreering, fn_tyhista_treeningukord ja fn_marki_osalemine.",
    ])

    doc.add_heading("4.21 Kontroll ja valideerimine", level=2)
    add_bullets(doc, [
        "Staatiline validaator kontrollib nõutud tabeleid, funktsioone, vaateid, triggereid, osalist unikaalset indeksit ja Mermaid diagramme.",
        "DOCX kontroll otsib uue projekti võtmetermineid: rühmatreeningute ajakava, treeningukord, registreering, ootejärjekord, osalemine, ruum, varustus ja treeneri pädevus.",
        "Rakenduse kontroll otsib, et kirjutavad marsruudid kutsuvad andmebaasi funktsioone ja et rakenduse ZIP ei sisalda venv, .env, __pycache__, .class või .jar faile.",
        "Validaator toetab valikulisi live SQL teste keskkonnamuutujaga RUN_LIVE_SQL_TESTS=1, et tõestada kattuvuste, mahutavuse, varustuse sobivuse, topeltregistreeringu, ootejärjekorra ja seisundite käitumist tegelikus PostgreSQL andmebaasis.",
    ])

    doc.add_heading("4.22 Kaitsmise selgitus", level=2)
    add_paragraphs(doc, [
        "Projekt ei käsitle enam treeningut kui töövihiku laadset kirjelduskaarti. Põhiobjekt on konkreetne treeningukord koos ruumi, "
        "treeneri, registreeringute, ootejärjekorra ja osalemisega. Andmebaas kontrollib mahutavust, kattuvaid aegu, treeneri pädevust, "
        "kohustuslikku varustust, registreerimise tähtaegu, seisundimuutusi ja ootejärjekorra edendamist.",
        "Lisaks mahutavusele ja pädevusele kontrollib andmebaas ka seda, et treeningukorra ruumis oleks treeninguliigi jaoks nõutav varustus. See ei muuda projekti inventarihalduseks, vaid lisab ajakava planeerimisele sisulise ruumi sobivuse reegli.",
        "Vaba teema tugevus tuleb sellest, et protsessil on mitu osalist, mitu töökohta ja mitu üksteisest sõltuvat ärireeglit. "
        "Juhataja, treener ja klient näevad erinevaid vaateid ja saavad teha erinevaid toiminguid, kuid sisulised reeglid paiknevad andmebaasis.",
    ])

    doc.add_heading("5 Realisatsioon Oracles", level=1)
    add_paragraphs(doc, ["Ei rakendu. Projekt realiseeritakse PostgreSQLis ja Oracle skripti ega Oracle APEX rakendust ei esitata."])

    doc.add_heading("6 Tehisintellekti kasutus", level=1)
    add_paragraphs(doc, [
        "Projekti koostamisel kasutati tehisintellekti abi analüüsi, SQL-skeemi, Mermaid diagrammide, DOCX generaatori ja validaatori iteratiivseks parandamiseks. Tehisintellekti kasutati kavandite ja kontrollnimekirjade koostamiseks, koodi muutmiseks ning vigade otsimiseks.",
        "Kõik lõplikud otsused projekti skoobi, andmemudeli, ärireeglite ja esitatavate failide kohta kontrolliti projekti nõuete, lokaalse buildi, staatilise validaatori ning live SQL testidega. Vastutus lõpliku töö õigsuse eest jääb autoritele.",
    ])

    doc.add_heading("7 Kasutatud materjalid", level=1)
    add_bullets(doc, [
        "Erki Eessaare Andmebaasid I kursuse projektijuhendid ja mallid: AB_projekt_Nullist_tegemiseks_2026.doc ning Projekti_juhend_ITI0206_2026.",
        "Craig Larman. Applying UML and Patterns. Kasutusjuhtude, tegevusdiagrammide, seisundidiagrammide ja operatsioonilepingute vormistuslik taust.",
        "AKIT terminibaas mittefunktsionaalsete nõuete mõistete selgitamiseks.",
        "PostgreSQL dokumentatsioon PL/pgSQL, triggerite, vaadete, indeksite ja piirangute kohta.",
    ])

    doc.add_heading("Lisa A. SQL skript", level=1)
    add_paragraphs(doc, [
        "Allpool on projektis genereeritav PostgreSQL skript. Sama sisu kirjutatakse buildi käigus faili jousaali_skript.sql ja submission_files/skript.sql.",
    ])
    for line in SQL_DDL.strip().splitlines():
        p = doc.add_paragraph(style="SqlCode")
        p.add_run(line)


def main() -> None:
    missing = [name for name, _ in DIAGRAMS if not (DIAGRAM_DIR / name).exists()]
    if missing:
        raise FileNotFoundError(
            "Puuduvad Mermaid PNG diagrammid: "
            + ", ".join(missing)
            + ". Käivita enne DOCX genereerimist tools/render_diagrams.py."
        )

    doc = Document()
    style_document(doc)
    doc.core_properties.title = TITLE
    doc.core_properties.author = AUTHORS
    add_title_page(doc)
    add_report_content(doc)
    doc.save(DST)
    print(f"Wrote {DST}")


if __name__ == "__main__":
    main()
