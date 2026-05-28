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
from PIL import Image

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
    ("01_system_context.png", "Süsteemi kontekst: fokuseeritud rühmatreeningute registreeringute allsüsteem ja esitatavad artefaktid."),
    ("02_use_cases.png", "Kasutusjuhtude kaart: registreeringu, treeningukorra ja osalemise olulised töövood."),
    ("03_core_er.png", "Kontseptuaalse andmemudeli ülevaade: registreering kui keskne elutsükli objekt koos seansside, treeninguliikide, osalemise ja rollidega."),
    ("04_registration_activity.png", "Registreeringu esitamise ja tühistamise tegevusvoog koos mahutavuse ja ootejärjekorraga."),
    ("05_session_state.png", "Treeningukorra seisundimudel ja ajatingimustega seotud üleminekud."),
    ("06_registration_state.png", "Registreeringu seisundimudel ja iga siirdega seotud kasutusjuht."),
    ("07_waitlist_sequence.png", "Ootejärjekorra edendamise järjestus pärast kinnitatud registreeringu tühistamist."),
    ("08_permission_flow.png", "Õiguste ja andmebaasirutiinide seos juhataja, treeneri ja kliendi vaates."),
    ("09_app_db_architecture.png", "Rakenduse ja andmebaasi arhitektuur: vaated lugemiseks, funktsioonid kirjutamiseks."),
    ("10_attendance_activity.png", "Osalemise märkimise tegevusvoog koos rolli, seisundi ja aja kontrollidega."),
    ("11_people_register.png", "Isikute registri kontseptuaalne skeem koos töötajate, klientide ja rolli omamistega."),
    ("12_training_sessions_register.png", "Treeningukordade registri kontseptuaalne skeem koos ruumi, treeninguliigi ja pädevusega."),
    ("13_registrations_register.png", "Registreeringute registri kontseptuaalne skeem koos ootejärjekorraga."),
    ("14_attendance_register.png", "Osalemiste registri kontseptuaalne skeem."),
    ("15_classifiers_register.png", "Klassifikaatorite registri kontseptuaalne skeem koos seisundi, rolli ja riigi klassifikaatoritega."),
]


ACTORS = [
    ("Juhataja", "Sisemine kasutaja", "Planeerib treeningukordi, avab registreerimise, tühistab treeningukordi ja vaatab täituvuse statistikat."),
    ("Töötajate haldur", "Sisemine kasutaja", "Haldab töötajate andmeid ja töötajatega seotud rolli omamisi."),
    ("Klassifikaatorite haldur", "Sisemine kasutaja", "Haldab süsteemis kasutatavaid klassifikaatori väärtuseid."),
    ("Treener", "Töötaja spetsialiseerumine ja tegutseja", "Treener on töötaja rollipõhine põhiobjekt selles allsüsteemis: ta juhendab treeningukordi, tal on pädevused ja ta märgib osalemist."),
    ("Klient", "Väline kasutaja", "Vaatab avatud ajakava, registreerub treeningukorrale, satub vajadusel ootejärjekorda ja tühistab enda registreeringu."),
    ("Süsteem", "Automaatne osapool", "Rakendab ootejärjekorra edendamist, seisundipiiranguid ja andmebaasi ärireegleid."),
    ("Aeg", "Väline käivitaja/tingimus", "Registreerimise ja tühistamise tähtajad ning treeningukorra algus/lõpp mõjutavad, millised toimingud on lubatud."),
]


CORE_OBJECTS = [
    ("Registreering", "Keskne põhiobjekt. See väljendab kliendi soovi osaleda konkreetsel treeningukorral ja liigub seisundites KINNIT, OOTEJRK, TYH_KL või TYH_SYS."),
    ("Treeningukord", "Põhiobjekt, millele registreeringud tekivad. Sellel on oma seisundid KAVAND, AVATUD, SULETUD, TOIMUNUD ja TYHIST."),
    ("Treeninguliik", "Põhiandmete põhiobjekt ehk hallatav rühmatreeningu kataloogimõiste. Sellel on kirjeldus, tavapärane kestus, kasutatavuse seisund, varustuse nõuded ja seosed treeneri pädevustega."),
    ("Isik", "Põhiobjekt, mis seob kliendi ja töötaja rollid ühe tegeliku inimesega."),
    ("Töötaja", "Põhiobjekt ja isiku spetsialiseerumine organisatsioonis. Töötaja elutsükkel kirjeldab, kas isik saab süsteemis töötaja rollis tegutseda."),
    ("Klient", "Põhiobjekt ja isiku spetsialiseerumine teenuse kasutajana. Klient saab esitada, vaadata ja tühistada enda registreeringuid."),
    ("Treener", "Põhiobjekt ja töötaja spetsialiseerumine valitud allsüsteemis. Treeneri äriline tähendus tekib juhendatavatest treeningukordadest, pädevustest, ajakavast ja osalemise märkimisest."),
    ("Klassifikaator", "Põhiobjekt, mis koondab süsteemis kasutatavad kontrollitud väärtused, näiteks seisundid, rollid ja riigid."),
]


SUPPORTING_CONCEPTS = [
    ("Osalemine", "Sõltuv elutsükliga tulemusobjekt", "Kohalolu tulemus tekib kinnitatud registreeringu põhjal, kuid sellel on oma ärisündmus: märkimine, muutmine ja tulemuse kasutamine aruandluses."),
    ("Ootejärjekorra koht", "Sõltuv suhteobjekt", "Järjekorranumber kuulub OOTEJRK seisundis registreeringule ja kaob edendamisel või tühistamisel."),
    ("Ruum", "Toetav ressursiobjekt", "Ruumil on oma äriline olemasolu, mahutavus ja kasutatavus, kuid selles töös toetab ta treeningukorra planeerimist."),
    ("Varustus", "Toetav ressursi- ja põhiandmete objekt", "Varustus kirjeldab ruumi sobivuse kontrolliks vajalikku vahendit, kuid töö ei modelleeri inventari hooldust ega varude elutsüklit."),
    ("Treeneri pädevus", "Sõltuv elutsükliga suhteobjekt", "Seob treeneri treeninguliigiga ning kirjeldab, millisel ajavahemikul treener võib seda treeninguliiki juhendada."),
    ("Varustuse nõue", "Suhteobjekt", "Seob treeninguliigi vajaliku varustuse ja minimaalse kogusega."),
    ("Ruumi varustatus", "Suhteobjekt", "Seob ruumi seal olemas oleva varustuse ja kogusega."),
]


CLASSIFIERS = [
    ("Seisund", "Klassifikaator", "Kirjeldab registreeringu, treeningukorra, isiku või töötaja hetkeseisu."),
    ("Roll", "Klassifikaator", "Kirjeldab töötaja tegutsemisõigust, näiteks JUHATAJA või TREENER."),
    ("Riik", "Klassifikaator", "Toetab isiku andmete üheselt mõistetavat kirjeldamist."),
]


USE_CASES = [
    ("Vaata vabu treeningukordi", "Klient", "Klient näeb treeningukordi, millele saab tähtaja ja seisundi järgi veel registreeruda."),
    ("Esita registreering", "Klient", "Klient esitab osalemissoovi konkreetsele treeningukorrale; tulemuseks on kinnitatud registreering või ootejärjekorra koht."),
    ("Vaata enda registreeringuid", "Klient", "Klient näeb enda kinnitatud, ootel, tühistatud ja osalemise tulemusega seotud registreeringuid."),
    ("Tühista enda registreering", "Klient", "Klient muudab enda aktiivse registreeringu tühistatuks, kui tähtaeg lubab."),
    ("Edenda ootel registreering", "Süsteem", "Kui kinnitatud koht vabaneb, muutub esimene ootel registreering kinnitatuks."),
    ("Vaata treeningukorra registreeringuid", "Treener, juhataja", "Treener või juhataja näeb konkreetse treeningukorra kinnitatud ja ootel registreeringuid."),
    ("Märgi osalemine", "Treener, juhataja", "Treener või juhataja märgib kinnitatud registreeringule osalemise tulemuse."),
    ("Sulge registreerimine", "Juhataja, treener, Aeg", "Registreerimine lõpetatakse käsitsi või tähtaja tingimuse põhjal; treener saab sulgeda alles pärast registreerimise lõppu."),
    ("Lõpeta treeningukord", "Treener, juhataja, Aeg", "Pärast treeningukorra lõppu märgitakse kord toimunuks ning osalemise märkimine jääb lubatuks."),
    ("Tühista treeningukord", "Juhataja", "Juhataja tühistab kavandatud, avatud või suletud treeningukorra ning aktiivsed registreeringud muutuvad süsteemselt tühistatuks."),
    ("Planeeri treeningukord", "Juhataja", "Juhataja loob konkreetse treeningukorra koos ruumi, aja, mahupiirangu ja treeneri rollis töötajaga."),
    ("Ava registreerimine", "Juhataja", "Kavandatud tulevane treeningukord muudetakse seisundisse AVATUD, et kliendid saaksid registreeruda."),
    ("Vaata treeningukordade täituvuse statistikat", "Juhataja", "Juhataja näeb treeningukordade täituvust, kinnitatud osalejate arvu, ootejärjekorda ja toimunud treeningukordade koondit."),
]


CRUD_HEADERS = [
    "Olemitüüp",
    "Vaata vabu treeningukordi",
    "Esita registreering",
    "Vaata enda registreeringuid",
    "Tühista enda registreering",
    "Edenda ootel registreering",
    "Vaata treeningukorra registreeringuid",
    "Märgi osalemine",
    "Sulge registreerimine",
    "Lõpeta treeningukord",
    "Tühista treeningukord",
    "Planeeri treeningukord",
    "Ava registreerimine",
    "Vaata treeningukordade täituvuse statistikat",
    "Kokku",
]

CRUD_MAIN_MATRIX = [
    ("Isik", "", "", "R", "R", "", "R", "R", "", "", "", "", "", "", "R"),
    ("Kasutajakonto", "", "R", "R", "R", "", "R", "R", "R", "R", "R", "R", "R", "", "R"),
    ("Töötaja", "", "", "", "", "", "R", "R", "R", "R", "R", "R", "R", "", "R"),
    ("Klient", "", "R", "R", "R", "", "R", "R", "", "", "", "", "", "", "R"),
    ("Treener", "R", "", "", "", "", "R", "R", "R", "R", "R", "R", "", "", "R"),
    ("Töötaja rolli omamine", "", "", "", "", "", "R", "R", "R", "R", "R", "R", "R", "", "R"),
    ("Treeningukord", "R", "R", "R", "R", "R", "R", "R", "U", "U", "U", "C", "U", "R", "CRU"),
    ("Registreering", "", "C", "R", "U", "U", "R", "R", "", "", "U", "", "", "R", "CRU"),
    ("Ootejärjekorra koht", "", "C", "R", "D", "D", "R", "", "", "", "D", "", "", "R", "CDR"),
    ("Osalemine", "", "", "R", "", "", "R", "CU", "", "R", "", "", "", "R", "CRU"),
]

CRUD_SUPPORT_MATRIX = [
    ("Treeninguliik", "R", "R", "R", "", "", "R", "", "", "", "", "R", "", "R", "R"),
    ("Ruum", "R", "", "R", "", "", "R", "", "", "", "", "R", "", "R", "R"),
    ("Varustus", "", "", "", "", "", "", "", "", "", "", "R", "", "", "R"),
    ("Treeneri pädevus", "R", "", "", "", "", "", "", "", "", "", "R", "", "", "R"),
    ("Ruumi varustatus", "", "", "", "", "", "", "", "", "", "", "R", "", "", "R"),
    ("Varustuse nõue", "", "", "", "", "", "", "", "", "", "", "R", "", "", "R"),
    ("Klassifikaator", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R"),
    ("Seisund", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R"),
    ("Roll", "", "", "", "", "", "R", "R", "R", "R", "R", "R", "R", "", "R"),
    ("Riik", "", "", "R", "", "", "", "", "", "", "", "", "", "", "R"),
]


ROUTINES = [
    ("OP1 / fn_planeeri_treeningukord", "Juhataja", "Kasutus kasutusjuhtude poolt: Planeeri treeningukord. Eeltingimused: aktiivne treeninguliik, aktiivne ruum, ruumis olemas treeninguliigi kohustuslik varustus ja TREENER rolliga pädev treener. Järeltingimused: tekib KAVAND treeningukord. Tõrkeolukorrad: vale roll, kattuv aeg, ruumi mahu ületamine, nõutud varustuse puudumine või pädevuse puudumine."),
    ("OP2 / fn_ava_treeningukord", "Juhataja", "Kasutus kasutusjuhtude poolt: Ava registreerimine. Eeltingimused: treeningukord on KAVAND ja tulevikus. Järeltingimused: seisund muutub AVATUD. Tõrkeolukorrad: kirje puudub, seisund pole KAVAND või algus on möödas."),
    ("OP3 / fn_sulge_treeningukord", "Juhataja või määratud treener", "Kasutus kasutusjuhtude poolt: Sulge registreerimine. Eeltingimused: treeningukord on AVATUD ja tegutseja on juhataja või määratud treener. Järeltingimused: seisund muutub SULETUD. Tõrkeolukorrad: vale roll või liiga varane sulgemine treeneri poolt."),
    ("OP4 / fn_lopeta_treeningukord", "Juhataja või määratud treener", "Kasutus kasutusjuhtude poolt: Lõpeta treeningukord. Eeltingimused: treeningukord on SULETUD ja lõpu aeg on möödas. Järeltingimused: seisund muutub TOIMUNUD. Tõrkeolukorrad: vale roll, vale seisund või tulevane treeningukord."),
    ("OP5 / fn_registreeri_klient_treeningukorrale", "Klient", "Kasutus kasutusjuhtude poolt: Esita registreering. Eeltingimused: aktiivne klient ja AVATUD treeningukord tähtaja sees. Järeltingimused: tekib KINNIT või OOTEJRK registreering. Tõrkeolukorrad: topeltaktiivne registreering, möödunud tähtaeg või mitteaktiivne klient."),
    ("OP6 / fn_tyhista_registreering", "Klient või juhataja", "Kasutus kasutusjuhtude poolt: Tühista enda registreering või süsteemne registreeringu tühistamine. Eeltingimused: aktiivne registreering; klient tegutseb enda nimel või tegutseja on juhataja. Järeltingimused: registreering muutub TYH_KL või TYH_SYS; kinnitatud koha vabanemisel edendatakse ootejärjekord. Tõrkeolukorrad: vale omanik, möödunud tähtaeg või lõpetatud treeningukord."),
    ("OP7 / fn_edenda_ootejarjekorrast", "Süsteem", "Kasutus kasutusjuhtude poolt: Ootejärjekorrast edendamine registreeringu tühistamise järel. Eeltingimused: AVATUD treeningukorral on vaba koht ja OOTEJRK rida. Järeltingimused: esimene ootel registreering muutub KINNIT. Tõrkeolukorrad: vaba kohta või ootel rida pole."),
    ("OP8 / fn_marki_osalemine", "Treener või juhataja", "Kasutus kasutusjuhtude poolt: Märgi osalemine. Eeltingimused: kinnitatud registreering, alanud SULETUD või TOIMUNUD treeningukord ning määratud treener või juhataja. Järeltingimused: osalemise rida lisatakse või uuendatakse. Tõrkeolukorrad: vale roll, vale seisund või liiga varane märkimine."),
    ("OP9 / fn_tyhista_treeningukord", "Juhataja", "Kasutus kasutusjuhtude poolt: Tühista treeningukord. Eeltingimused: treeningukord on KAVAND, AVATUD või SULETUD. Järeltingimused: treeningukord muutub TYHIST ning aktiivsed registreeringud TYH_SYS. Tõrkeolukorrad: vale roll, puuduv kirje või juba toimunud treeningukord."),
]


READ_OPERATIONS = [
    ("OP10", "Loe planeerimiseks aktiivsed treeninguliigid, ruumid ja treenerid."),
    ("OP11", "Loe juhatajale treeningukordade haldamise ülevaade."),
    ("OP12", "Loe kliendile avalikud ja vabade kohtadega treeningukorrad."),
    ("OP13", "Loe kliendi enda registreeringud."),
    ("OP14", "Loe treenerile või juhatajale lubatud treeningukorrad."),
    ("OP15", "Loe treeningukorra registreeringud ja osalejad."),
    ("OP16", "Loe treeningukordade täituvuse statistika."),
]


OP_CONTRACTS = [
    {
        "signature": "OP1 / fn_planeeri_treeningukord (p_treeninguliik, p_treener, p_ruum, p_algus, p_lopp, p_registreerimise_tahtaeg, p_tyhistamise_tahtaeg, p_kohtade_piir, p_juhataja)",
        "pre": [
            "Töötaja eksemplar j (millel on e-meil=p_juhataja) on registreeritud ja omab kehtivat JUHATAJA rolli.",
            "Treeninguliik eksemplar tl (millel on treeninguliigi tunnus=p_treeninguliik) on registreeritud ja kasutatav.",
            "Töötaja eksemplar tr (millel on e-meil=p_treener) on registreeritud ja omab kehtivat TREENER rolli.",
            "Ruum eksemplar r (millel on ruumi tunnus=p_ruum) on registreeritud ja aktiivne.",
            "tr pädevus tl-i juhendamiseks on registreeritud ning r vastab tl-i kohustuslikele varustuse nõuetele.",
        ],
        "post": [
            "Treeningukord eksemplar tk on registreeritud.",
            "tk.algus:=p_algus.",
            "tk.lõpp:=p_lopp.",
            "tk.registreerimise_tähtaeg:=p_registreerimise_tahtaeg.",
            "tk.tühistamise_tähtaeg:=p_tyhistamise_tahtaeg.",
            "tk.kohtade_piir:=p_kohtade_piir.",
            "tk.seisund:=KAVAND.",
            "tk ja tl seos on registreeritud.",
            "tk ja tr seos on registreeritud.",
            "tk ja r seos on registreeritud.",
            "tk ja j seos loojana on registreeritud.",
        ],
        "uses": "Planeeri treeningukord.",
    },
    {
        "signature": "OP2 / fn_ava_treeningukord (treeningukorra identifikaator, p_juhataja)",
        "pre": [
            "Treeningukord eksemplar tk (millel on treeningukorra identifikaator) on registreeritud.",
            "Töötaja eksemplar j (millel on e-meil=p_juhataja) on registreeritud ja omab kehtivat JUHATAJA rolli.",
            "tk.seisund=KAVAND.",
        ],
        "post": ["tk.seisund:=AVATUD.", "tk.viimase_muutmise_aeg:=hetke kuupäev ja kellaaeg."],
        "uses": "Ava registreerimine.",
    },
    {
        "signature": "OP3 / fn_sulge_treeningukord (treeningukorra identifikaator, p_sulgeja)",
        "pre": [
            "Treeningukord eksemplar tk (millel on treeningukorra identifikaator) on registreeritud.",
            "Töötaja eksemplar t (millel on e-meil=p_sulgeja) on registreeritud ja on tk-ga seotud juhataja või määratud treener.",
            "tk.seisund=AVATUD.",
        ],
        "post": ["tk.seisund:=SULETUD.", "tk.viimase_muutmise_aeg:=hetke kuupäev ja kellaaeg."],
        "uses": "Sulge registreerimine.",
    },
    {
        "signature": "OP4 / fn_lopeta_treeningukord (treeningukorra identifikaator, p_lopetaja)",
        "pre": [
            "Treeningukord eksemplar tk (millel on treeningukorra identifikaator) on registreeritud.",
            "Töötaja eksemplar t (millel on e-meil=p_lopetaja) on registreeritud ja on tk-ga seotud juhataja või määratud treener.",
            "tk.seisund=SULETUD.",
        ],
        "post": ["tk.seisund:=TOIMUNUD.", "tk.viimase_muutmise_aeg:=hetke kuupäev ja kellaaeg."],
        "uses": "Lõpeta treeningukord.",
    },
    {
        "signature": "OP5 / fn_registreeri_klient_treeningukorrale (treeningukorra identifikaator, p_klient)",
        "pre": [
            "Treeningukord eksemplar tk (millel on treeningukorra identifikaator) on registreeritud.",
            "Klient eksemplar k (millel on e-meil=p_klient) on registreeritud ja aktiivne.",
            "tk.seisund=AVATUD.",
            "k-l puudub tk-ga seotud aktiivne registreering.",
        ],
        "post": [
            "Registreering eksemplar rg on registreeritud.",
            "rg.esitamise_aeg:=hetke kuupäev ja kellaaeg.",
            "Kui tk-l on vaba koht, siis rg.seisund:=KINNIT.",
            "Kui tk-l ei ole vaba kohta, siis rg.seisund:=OOTEJRK ja ootejärjekorra koht eksemplar ojk on registreeritud.",
            "rg ja k seos on registreeritud.",
            "rg ja tk seos on registreeritud.",
        ],
        "uses": "Esita registreering.",
    },
    {
        "signature": "OP6 / fn_tyhista_registreering (registreeringu identifikaator, p_tyhistaja, p_tyh_pohjus)",
        "pre": [
            "Registreering eksemplar rg (millel on registreeringu identifikaator) on registreeritud.",
            "Klient või töötaja eksemplar t (millel on e-meil=p_tyhistaja) on registreeritud ja tal on õigus rg tühistada.",
            "rg.seisund on KINNIT või OOTEJRK.",
        ],
        "post": [
            "rg.seisund:=TYH_KL või TYH_SYS vastavalt tühistaja õigusele.",
            "rg.tühistamise_aeg:=hetke kuupäev ja kellaaeg.",
            "rg.tühistamise_põhjus:=p_tyh_pohjus.",
            "Kui rg-ga on seotud ootejärjekorra koht, siis see seos on kustutatud.",
        ],
        "uses": "Tühista enda registreering; Tühista treeningukord.",
    },
    {
        "signature": "OP7 / fn_edenda_ootejarjekorrast (treeningukorra identifikaator)",
        "pre": [
            "Treeningukord eksemplar tk (millel on treeningukorra identifikaator) on registreeritud.",
            "tk-ga seotud kinnitatud koht vabanes.",
            "tk-ga seotud OOTEJRK seisundis registreering on registreeritud.",
        ],
        "post": [
            "Kõige väiksema järjekorranumbriga ootel registreering rg.seisund:=KINNIT.",
            "rg.edendamise_aeg:=hetke kuupäev ja kellaaeg.",
            "rg-ga seotud ootejärjekorra koht on kustutatud.",
        ],
        "uses": "Edenda ootel registreering; Tühista enda registreering.",
    },
    {
        "signature": "OP8 / fn_marki_osalemine (registreeringu identifikaator, p_markija, p_tulemus, p_markus)",
        "pre": [
            "Registreering eksemplar rg (millel on registreeringu identifikaator) on registreeritud.",
            "Töötaja eksemplar t (millel on e-meil=p_markija) on registreeritud ja on rg treeningukorra juhendaja või juhataja.",
            "rg.seisund=KINNIT.",
        ],
        "post": [
            "Osalemine eksemplar os on registreeritud või uuendatud.",
            "os.tulemus:=p_tulemus.",
            "os.märkimise_aeg:=hetke kuupäev ja kellaaeg.",
            "os.märkus:=p_markus.",
            "os ja rg seos on registreeritud.",
            "os ja t seos märkijana on registreeritud.",
        ],
        "uses": "Märgi osalemine.",
    },
    {
        "signature": "OP9 / fn_tyhista_treeningukord (treeningukorra identifikaator, p_juhataja, p_tyh_pohjus)",
        "pre": [
            "Treeningukord eksemplar tk (millel on treeningukorra identifikaator) on registreeritud.",
            "Töötaja eksemplar j (millel on e-meil=p_juhataja) on registreeritud ja omab kehtivat JUHATAJA rolli.",
            "tk.seisund on KAVAND, AVATUD või SULETUD.",
        ],
        "post": [
            "tk.seisund:=TYHIST.",
            "tk.tühistamise_põhjus:=p_tyh_pohjus.",
            "tk.viimase_muutmise_aeg:=hetke kuupäev ja kellaaeg.",
            "Kõik tk-ga seotud aktiivsed registreeringud rg.seisund:=TYH_SYS.",
            "Kõik muudetud rg.tühistamise_aeg:=hetke kuupäev ja kellaaeg.",
        ],
        "uses": "Tühista treeningukord.",
    },
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
            "Süsteem kuvab aktiivsed treeninguliigid, ruumid ja treenerid koos treeninguliigi nimetuse, ruumi tunnuse, ruumi nimetuse, mahutavuse, treeneri nime, e-posti aadressi ja pädevuse kehtivusega (OP10).",
            "Juhataja valib treeninguliigi, treeneri, ruumi, algus- ja lõpuaja, registreerimise tähtaja, tühistamise tähtaja ning osalejate piiri.",
            "Süsteem kutsub andmebaasioperatsiooni OP1 / fn_planeeri_treeningukord.",
            "Andmebaas kontrollib juhataja rolli, treeneri pädevust, ruumi mahutavust, treeninguliigi kohustuslikke varustuse nõudeid ning treeneri ja ruumi kattuvaid aegu.",
            "Süsteem kuvab loodud treeningukorra juhataja treeningukordade ülevaates koos treeningukorra tunnuse, treeninguliigi nimetuse, alguse, lõpu, ruumi, treeneri, kohtade piiri ja seisundiga (OP11).",
        ],
        "extensions": [
            "Kui treeneril puudub pädevus, siis treeningukorda ei looda.",
            "Kui ruum või treener on samal ajal hõivatud, siis andmebaas katkestab operatsiooni.",
            "Kui osalejate piir ületab ruumi mahutavust, siis andmebaas tagastab vea.",
            "Kui valitud ruumis puudub treeninguliigi kohustuslik varustus või seda on nõutust vähem, siis operatsioon ebaõnnestub ja treeningukorda ei looda.",
        ],
        "operations": "Loeb treeninguliik, ruum, treeneri_padevus, varustus, ruumi_varustuse_omamine ja treeninguliigi_varustuse_noue (OP10, OP11); muudab treeningukord. Rutiin: OP1.",
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
            "Süsteem kuvab treeningukorrad vaate juhataja_treeningukordade_ulevaade alusel koos treeningukorra tunnuse, treeninguliigi nimetuse, alguse, lõpu, ruumi, treeneri, kohtade piiri ja seisundiga (OP11).",
            "Juhataja valib kavandatud treeningukorra ja käivitab registreerimise avamise.",
            "Süsteem kutsub OP2 / fn_ava_treeningukord.",
            "Andmebaas kontrollib juhataja rolli, treeningukorra seisundit ja algusaega.",
            "Süsteem kuvab treeningukorra uue seisundi AVATUD.",
        ],
        "extensions": [
            "Kui treeningukord ei ole KAVAND seisundis, siis seisundimuutust ei tehta.",
            "Kui treeningukorra algusaeg on möödas, siis registreerimist ei avata.",
        ],
        "operations": "Loeb juhataja_treeningukordade_ulevaade (OP11); muudab treeningukord. Rutiin: OP2.",
    },
    {
        "number": "2.1.1.3",
        "name": "Esita registreering",
        "actor": "Klient",
        "interests": [
            "Klient soovib saada koha valitud rühmatreeningul või teada, et ta jäi ootejärjekorda.",
            "Jõusaal soovib vältida ületäituvust ja sama kliendi mitut aktiivset registreeringut samale treeningukorrale.",
        ],
        "trigger": "Klient valib vabade treeningukordade vaatest konkreetse treeningukorra ja soovib osaleda.",
        "preconditions": "Klient on aktiivne; treeningukord on AVATUD; registreerimise tähtaeg ei ole möödas.",
        "postconditions": "Tekib KINNIT registreering või täitunud treeningukorra korral OOTEJRK registreering.",
        "scenario": [
            "Klient avab vabade treeningukordade vaate.",
            "Süsteem kuvab avalikud_treeningukorrad vaate alusel treeningukorrad koos treeningukorra tunnuse, treeninguliigi nimetuse, alguse, lõpu, ruumi, treeneri, vabade kohtade arvu ja ootejärjekorra arvuga (OP12).",
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
        "operations": "Loeb avalikud_treeningukorrad (OP12); muudab registreering. Rutiin: OP5.",
    },
    {
        "number": "2.1.1.4",
        "name": "Vaata enda registreeringuid",
        "actor": "Klient",
        "interests": [
            "Klient soovib näha enda kinnitatud, ootel, tühistatud ja osalemise tulemusega seotud registreeringuid.",
            "Jõusaal soovib vähendada käsitsi päringuid registreeringute seisu kohta.",
        ],
        "trigger": "Klient avab enda registreeringute vaate.",
        "preconditions": "Klient on autenditud ja seotud kliendi rolliga.",
        "postconditions": "Andmeid ei muudeta; klient näeb enda registreeringute hetkeseisu.",
        "scenario": [
            "Klient avab enda registreeringute vaate.",
            "Süsteem loeb kliendi_registreeringud vaadet kliendi e-posti alusel (OP13).",
            "Süsteem kuvab registreeringu tunnuse, registreeringu seisundi, esitamise aja, treeningukorra tunnuse, treeninguliigi nimetuse, treeningukorra aja, ruumi, ootejärjekorra numbri ja osalemise tulemuse (OP13).",
            "Klient saab valida aktiivse registreeringu tühistamise, kui tühistamise tähtaeg lubab.",
        ],
        "extensions": [
            "Kui kliendil registreeringuid ei ole, kuvatakse tühi nimekiri.",
            "Kui registreering ei ole aktiivne või tähtaeg on möödas, ei kuvata tühistamise võimalust.",
        ],
        "operations": "Loeb kliendi_registreeringud (OP13); andmeid ei muuda.",
    },
    {
        "number": "2.1.1.5",
        "name": "Tühista enda registreering",
        "actor": "Klient",
        "interests": [
            "Klient soovib vabastada koha, kui ta ei saa treeningukorrale tulla.",
            "Jõusaal soovib, et vabanenud koht läheks automaatselt esimesele ootel kliendile.",
        ],
        "trigger": "Klient soovib enda aktiivse registreeringu tühistada.",
        "preconditions": "Registreering on KINNIT või OOTEJRK seisundis; klient tegutseb enda registreeringuga ja tühistamise tähtaeg ei ole möödas.",
        "postconditions": "Registreering on TYH_KL seisundis; kinnitatud koha vabanemisel on esimene OOTEJRK registreering edendatud KINNIT seisundisse.",
        "scenario": [
            "Klient avab enda registreeringute vaate.",
            "Süsteem kuvab kliendi_registreeringud vaate alusel kliendi enda registreeringud koos registreeringu tunnuse, treeningukorra tunnuse, treeninguliigi nimetuse, aja, seisundi ja tühistamise tähtajaga (OP13).",
            "Klient valib aktiivse registreeringu ja kinnitab tühistamise.",
            "Süsteem kutsub OP6 / fn_tyhista_registreering.",
            "Kui tühistati kinnitatud registreering, kutsub andmebaas OP7 / fn_edenda_ootejarjekorrast.",
            "Süsteem kuvab tühistatud ja vajadusel edendatud registreeringu tulemuse.",
        ],
        "extensions": [
            "Kui klient proovib tühistada võõrast registreeringut, siis operatsioon ebaõnnestub.",
            "Kui tühistamise tähtaeg on möödas, siis klient ei saa registreeringut tühistada.",
            "Kui ootejärjekorras ei ole klienti, siis edendamist ei toimu.",
        ],
        "operations": "Loeb kliendi_registreeringud (OP13); muudab registreering. Rutiinid: OP6 ja OP7.",
    },
    {
        "number": "2.1.1.6",
        "name": "Märgi osalemine",
        "actor": "Treener või juhataja",
        "interests": [
            "Treener soovib märkida, kes treeningukorral on_osalenud ja kes puudus.",
            "Juhataja soovib kasutada osalemise andmeid aruandluses ja täituvuse hindamisel.",
        ],
        "trigger": "Treeningukord on alanud või toimunud ning treener või juhataja avab osalejate nimekirja.",
        "preconditions": "Treeningukord on SULETUD või TOIMUNUD; registreering on KINNIT; tegutseja on määratud treener või juhataja.",
        "postconditions": "Osalemise kirje on lisatud või uuendatud.",
        "scenario": [
            "Treener või juhataja avab enda treeningukordade töövaate.",
            "Süsteem kuvab treeneri_tunniplaan vaate alusel tegutsejale lubatud treeningukorrad koos treeningukorra tunnuse, treeninguliigi nimetuse, alguse, lõpu, ruumi ja seisundiga (OP14).",
            "Treener või juhataja avab konkreetse treeningukorra osalejate nimekirja.",
            "Süsteem kuvab treeningukorra_osalejad vaate alusel kinnitatud osalejad koos registreeringu tunnuse, kliendi nime, kliendi e-posti aadressi, registreeringu seisundi ja osalemise tulemusega (OP15).",
            "Treener või juhataja märgib on_osalenud/ei osalenud väärtused.",
            "Süsteem kutsub iga muudetud rea kohta OP8 / fn_marki_osalemine.",
            "Andmebaas salvestab või uuendab osalemise tulemuse.",
        ],
        "extensions": [
            "Kui treeningukord on veel liiga varajases seisundis, siis osalemist ei märgita.",
            "Kui registreering ei ole KINNIT, siis andmebaas keeldub osalemise märkimisest.",
            "Kui tegutseja ei ole määratud treener ega juhataja, siis operatsioon ebaõnnestub.",
        ],
        "operations": "Loeb treeneri_tunniplaan ja treeningukorra_osalejad (OP14, OP15); muudab osalemine. Rutiin: OP8.",
    },
    {
        "number": "2.1.1.7",
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
            "Süsteem kuvab treeningukorrad koos treeningukorra tunnuse, treeninguliigi nimetuse, alguse, lõpu, ruumi, treeneri ja seisundiga (OP11).",
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
        "operations": "Loeb juhataja_treeningukordade_ulevaade (OP11); muudab treeningukord ja registreering. Rutiin: OP9.",
    },
    {
        "number": "2.1.1.8",
        "name": "Vaata treeningukordade täituvuse statistikat",
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
            "Süsteem loeb treeningute_taituvuse_statistika vaadet (OP16).",
            "Süsteem kuvab perioodi, treeninguliigi nimetuse, treeningukordade arvu, kohtade koguarvu, kinnitatud registreeringute arvu, ootel registreeringute arvu, osalenute arvu, puudujate arvu ja täituvusprotsendi (OP16).",
            "Juhataja kasutab tulemusi järgmiste treeningukordade planeerimisel.",
        ],
        "extensions": [
            "Kui mõnel treeninguliigil ei ole veel treeningukordi, siis seda ei kuvata täituvuse koondis või kuvatakse nullväärtustega sõltuvalt aruandest.",
        ],
        "operations": "Loeb treeningute_taituvuse_statistika (OP16); andmeid ei muuda.",
    },
]


BUSINESS_RULES = [
    ("Ruum ei tohi üle täituda", "Treeningukorra kohtade piir ei tohi ületada ruumi mahutavust."),
    ("Ruum peab vastama kohustuslikele varustuse nõuetele", "Planeeritav treeningukord peab toimuma ruumis, kus on treeninguliigi jaoks vajalik kohustuslik varustus piisavas koguses."),
    ("Treener peab olema pädev", "Treeningukorda juhendab töötaja, kellel on treeneri roll ja kehtiv pädevus valitud treeninguliigile."),
    ("Treeneril ei tohi olla kattuvaid tunde", "Sama treeneri rollis töötaja ei juhenda samal ajal kahte tühistamata treeningukorda."),
    ("Ruumil ei tohi olla kattuvaid tunde", "Sama ruum ei ole samal ajal kahe tühistamata treeningukorra toimumiskohaks."),
    ("Klient ei saa sama treeningukorda mitu korda aktiivselt broneerida", "Ühel kliendil on sama treeningukorra kohta korraga kuni üks KINNIT või OOTEJRK registreering."),
    ("Registreerimine peab olema avatud ja tähtaja sees", "Registreeringut saab esitada ainult avatud treeningukorrale enne registreerimise tähtaega."),
    ("Kliendi tühistamine peab olema tähtaja sees", "Klient saab tühistada ainult enda aktiivse registreeringu enne tühistamise tähtaega."),
    ("Ootejärjekord peab edendama esimest ootajat", "Kinnitatud koha vabanemisel liigub esimene ootel registreering kinnitatud seisundisse."),
    ("Seisundid muutuvad ainult lubatud suunas", "Registreeringu ja treeningukorra seisundid muutuvad ainult seisundidiagrammides näidatud siirete kaudu."),
    ("Osalemist saab märkida ainult kinnitatud registreeringule", "Osalemise tulemuse saab lisada või muuta ainult kinnitatud registreeringu kohta pärast treeningukorra algust."),
]


TABLES = [
    ("klient", "Kasutajakontoga seotud osaleja.", "PK e_meil, FK kasutajakonto."),
    ("treeninguliigi_seisundi_liik", "Treeninguliigi elutsükli klassifikaator.", "KOOST, AKTIIVNE, MITTEAKT, LOPETATUD."),
    ("treeninguliik", "Rühmatreeningu korduv mall.", "PK treeninguliigi_id, UNIQUE nimetus, FK seisund."),
    ("ruum", "Saal või stuudio.", "PK ruumi_kood, UNIQUE nimetus, CHECK mahutavus > 0."),
    ("varustus", "Treeningu läbiviimiseks vajalik põhiandmete objekt.", "PK varustuse_kood, UNIQUE nimetus, aktiivsuse tunnus."),
    ("ruumi_varustuse_omamine", "Ruumi olemasolev varustus ja kogus.", "PK ruumi_kood + varustuse_kood, FK ruum ja varustus, CHECK kogus > 0."),
    ("treeninguliigi_varustuse_noue", "Treeninguliigi kohustuslik või soovituslik varustuse nõue.", "PK treeninguliigi_id + varustuse_kood, FK treeninguliik ja varustus, CHECK minimaalne_kogus > 0."),
    ("treeneri_padevus", "Treeneri lubatud treeninguliigid.", "PK tootaja_e_meil + treeninguliigi_id, FK tootaja ja treeninguliik."),
    ("treeningukorra_seisundi_liik", "Konkreetse treeningukorra elutsükkel.", "KAVAND, AVATUD, SULETUD, TOIMUNUD, TYHIST."),
    ("treeningukord", "Ajakavas toimuv konkreetne rühmatund.", "FK treeninguliik, treener, ruum, seisund; aja- ja mahupiirangud."),
    ("registreeringu_seisundi_liik", "Registreeringu elutsükkel.", "KINNIT, OOTEJRK, TYH_KL, TYH_SYS."),
    ("registreering", "Kliendi kinnitatud või ootejärjekorra kirje.", "PK registreeringu_id, partial UNIQUE aktiivsele kliendile ja treeningukorrale."),
    ("ootejarjekorra_koht", "Ootejärjekorras oleva registreeringu järjekorrakoht.", "PK/FK registreeringu_id, UNIQUE treeningukorra_id ja ootejarjekorra_nr."),
    ("osalemine", "Kohalolu tulemus.", "PK/FK registreeringu_id, FK markija_e_meil."),
]


VIEWS = [
    ("avalikud_treeningukorrad", "Kliendile nähtav avatud ajakava koos vabade kohtade ja ootejärjekorraga."),
    ("kliendi_registreeringud", "Kliendi enda registreeringud, seisundid, ootejärjekorra number ja osalemise tulemus."),
    ("treeneri_tunniplaan", "Treeneri töölaud tulevaste ja toimunud treeningukordade vaatamiseks."),
    ("treeningukorra_osalejad", "Treeneri ja juhataja osalejate nimekiri koos kohalolu tulemustega."),
    ("juhataja_treeningukordade_ulevaade", "Juhataja haldusvaade kõigi treeningukordade täituvuse ja seisunditega."),
    ("treeningute_taituvuse_statistika", "Koondstatistika treeninguliigi kaupa."),
    ("treeninguliigid_kategooriatega", "Treeninguliikide loend koos kategooriatega."),
    ("ruumide_varustus", "Ruumide varustuse ülevaade juhataja planeerimisvormi ja kontrolli selgitamiseks."),
    ("treeninguliigi_varustuse_nouded", "Treeninguliikide kohustuslikud ja soovituslikud varustuse nõuded."),
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
    ("Andmetalletus", "Põhiandmete, registreeringute, osalemise ja ärireeglite keskne talletuskoht; kontseptuaalne mudel ei sõltu konkreetsest andmebaasisüsteemist."),
]


COMPETENCE_AREAS = [
    ("Juhataja", "Planeerib treeningukordi, avab/sulgeb registreerimist, tühistab kordi ja vaatab aruandeid."),
    ("Töötajate haldur", "Haldab töötajaid ja töötajate rolli omamisi."),
    ("Klassifikaatorite haldur", "Haldab klassifikaatorite lubatud väärtuseid."),
    ("Treener", "Näeb enda tunde ja märgib osalemist."),
    ("Klient", "Vaatab ajakava, registreerub ja tühistab enda registreeringuid."),
]


SUBSYSTEMS = [
    ("Registreeringute funktsionaalne allsüsteem", "Registreeringute register"),
    ("Treeningukordade funktsionaalne allsüsteem", "Treeningukordade register"),
    ("Treeninguliikide funktsionaalne allsüsteem", "Treeninguliikide register"),
    ("Osalemiste funktsionaalne allsüsteem", "Osalemiste register"),
    ("Treenerite funktsionaalne allsüsteem", "Treenerite register"),
    ("Isikute funktsionaalne allsüsteem", "Isikute register"),
    ("Töötajate funktsionaalne allsüsteem", "Töötajate register"),
    ("Klientide funktsionaalne allsüsteem", "Klientide register"),
    ("Klassifikaatorite funktsionaalne allsüsteem", "Klassifikaatorite register"),
]


NFRS = [
    ("modelleerimiskeel", "Mudelid ja selgitavad diagrammid esitatakse EAP mudelis ning Mermaid diagrammidena DOCX-is."),
    ("rakendatavus", "Kontseptuaalne mudel kirjeldab olemeid, seoseid ja elutsükleid andmebaasitehnoloogiast sõltumatult."),
    ("teostuse eraldatus", "Füüsilise teostuse vahendid kirjeldatakse eraldi realisatsiooni peatükis, mitte kontseptuaalse mudeli osana."),
    ("keel", "Dokumentatsioon, kasutajaliides ja andmebaasiobjektide nimed on eesti keeles; andmebaasi identifikaatorid on ASCII-kujul."),
    ("kasutajaliides", "Rollipõhine veebiprototüüp juhatajale, treenerile ja kliendile."),
    ("töökindlus", "Kriitilised ärireeglid kontrollitakse andmete muutmise hetkel, et vigased muudatused ei sõltuks ainult kasutajaliidese kontrollidest."),
    ("turvalisus", "Rakendus kasutab kasutajakonto andmeid ja rollipõhiseid töövooge; tavapärased muutmised käivad andmebaasirutiinide kaudu."),
    ("andmekvaliteet", "Mahutavus, kattuvad ajad, pädevus, topeltregistreering ja seisundimuudatused kontrollitakse üheselt kirjeldatud ärireeglite järgi."),
]


ENTITY_DEFINITIONS = [
    ("Isik", "Isikute register", "Põhiobjekt", "e-meil, isikukood, eesnimi, perenimi, elukoht, seisund", "Tegelik inimene, kellel võib olla kliendi ja/või töötaja roll. Isiku elutsükkel on sõltumatu ühest registreeringust või treeningukorrast."),
    ("Kasutajakonto", "Isikute register", "Toetav objekt", "e-meil, aktiivsus", "Sisselogimist võimaldav konto, mis kuulub isikule."),
    ("Töötaja", "Töötajate register", "Põhiobjekt, Isiku spetsialiseerumine", "töötaja tunnus, töötaja seisund", "Organisatsiooniga seotud isik, kellel on töötaja rolli elutsükkel ja kelle kaudu tekivad juhataja või treeneri tegevusõigused."),
    ("Klient", "Klientide register", "Põhiobjekt, Isiku spetsialiseerumine", "kliendi tunnus, aktiivsus, kliendiks saamise aeg", "Teenuse kasutaja, kelle kliendisuhte elutsükkel võimaldab registreeringuid esitada, vaadata ja tühistada."),
    ("Treener", "Treenerite register", "Põhiobjekt, Töötaja spetsialiseerumine", "treeneri tunnus, rolli kehtivus, pädevuste ulatus", "Töötaja spetsialiseerumine rühmatreeningute kontekstis. Treener juhendab treeningukordi, peab omama pädevust ja märgib osalemist."),
    ("Töötaja rolli omamine", "Töötajate register", "Suhteobjekt", "rolli algus, rolli lõpp", "Seob töötaja rolliga ning võimaldab kirjeldada treeneri või juhataja rolli kehtivust."),
    ("Treeningukord", "Treeningukordade register", "Põhiobjekt", "aeg, kohtade piir, registreerimise tähtaeg, tühistamise tähtaeg, seisund", "Kalendris toimuv konkreetne rühmatreening, millele registreeringud tekivad."),
    ("Registreering", "Registreeringute register", "Keskne põhiobjekt", "esitamise aeg, seisund, tühistamise aeg, edendamise aeg", "Kliendi osalemissoov konkreetsel treeningukorral. Selle elutsükkel on töö keskne elutsükkel."),
    ("Ootejärjekorra koht", "Registreeringute register", "Sõltuv suhteobjekt", "järjekorranumber", "Ainult ootel registreeringuga seotud järjekorrakoht."),
    ("Osalemine", "Osalemiste register", "Sõltuv elutsükliga tulemusobjekt", "tulemus, märkimise aeg, märkus", "Kinnitatud registreeringu põhjal tekkiv kohalolu tulemus. See sõltub registreeringust, kuid märkimine ja muutmine on eraldi ärisündmused."),
    ("Treeninguliik", "Treeninguliikide register", "Põhiandmete põhiobjekt", "nimetus, sisu, tüüpiline kestus, kasutatavus", "Korduv ja hallatav rühmatreeningu kataloogimõiste, mille alusel planeeritakse treeningukordi ning millele kehtivad pädevuse ja varustuse reeglid."),
    ("Ruum", "Treeningukordade register", "Toetav ressursiobjekt", "ruumi tunnus, nimetus, asukoht, mahutavus", "Treeningukorra toimumiskoht, mille mahutavus ja sobivus piiravad planeerimist. Täielik ruumihaldus ei kuulu skoopi."),
    ("Varustus", "Treeningukordade register", "Toetav ressursi- ja põhiandmete objekt", "varustuse tunnus, nimetus, aktiivsus", "Ruumi sobivuse kontrolliks vajalik vahend. Inventari hooldust ja varude elutsüklit ei modelleerita."),
    ("Treeneri pädevus", "Treenerite register", "Sõltuv elutsükliga suhteobjekt", "kehtiv alates, kehtiv kuni", "Seob treeneri treeninguliigiga ning kirjeldab selle pädevuse kehtivust ajas."),
    ("Ruumi varustatus", "Treeningukordade register", "Suhteobjekt", "kogus, märkus", "Seob ruumi selles olemas oleva varustusega."),
    ("Varustuse nõue", "Treeningukordade register", "Suhteobjekt", "minimaalne kogus, kohustuslikkus, märkus", "Seob treeninguliigi vajaliku varustusega."),
    ("Klassifikaator", "Klassifikaatorite register", "Põhiobjekt", "kood, nimetus, tähendus, aktiivsus", "Kontrollitud väärtuste üldine olemitüüp, mille kaudu kirjeldatakse seisundeid, rolle, riike ja teisi lubatud väärtuste hulki."),
    ("Seisund", "Klassifikaatorite register", "Klassifikaatori liik", "kood, nimetus, tähendus, aktiivsus", "Klassifikaatori väärtus, mis kirjeldab isiku, töötaja, treeningukorra või registreeringu hetkeseisu. Näited: KAVAND, AVATUD, KINNIT."),
    ("Roll", "Klassifikaatorite register", "Klassifikaatori liik", "kood, nimetus, vastutus, aktiivsus", "Klassifikaatori väärtus, mis kirjeldab töötaja tegutsemisõigust. Näited: JUHATAJA, TREENER."),
    ("Riik", "Klassifikaatorite register", "Klassifikaatori liik", "kood, nimetus, aktiivsus", "Klassifikaatori väärtus, mis toetab isiku andmete kirjeldamist. Näited: Eesti, Läti, Soome."),
]


CONCEPTUAL_ATTRIBUTE_DEFINITIONS = [
    ("Isik", "e-meil", "Isiku e-posti aadress, mida kasutatakse süsteemis isiku tuvastamiseks. {Isiku tõstutundetu unikaalne identifikaator. @Kohustuslik. Peab sisaldama märki \"@\". @Pole_tühi.} Näiteväärtus: klient@jousaal.ee"),
    ("Isik", "isikukood", "Isiku Eesti isikukood. {Koosneb täpselt 11 numbrimärgist. Kui väärtus registreeritakse, siis @Pole_tühi.} Näiteväärtus: 39504040004"),
    ("Isik", "eesnimi", "Isiku eesnimi. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Mari"),
    ("Isik", "perenimi", "Isiku perekonnanimi. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Tamm"),
    ("Isik", "elukoht", "Isiku elukoha aadress kliendihalduse jaoks. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 255 märki pikk.} Näiteväärtus: Tallinn, Akadeemia tee 5"),
    ("Isik", "seisund", "Isiku kasutusseisund süsteemis. {@Kohustuslik. Väärtus peab olema registreeritud seisundi klassifikaatori väärtus.} Näiteväärtus: Aktiivne"),
    ("Kasutajakonto", "e-meil", "Kasutajakontoga seotud isiku e-posti aadress. {@Kohustuslik. Peab sisaldama märki \"@\". @Pole_tühi.} Näiteväärtus: klient@jousaal.ee"),
    ("Kasutajakonto", "aktiivsus", "Tunnus, mis näitab, kas kontoga saab süsteemi sisse logida. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE"),
    ("Töötaja", "töötaja tunnus", "Töötajat organisatsioonis eristav tunnus. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: T-104"),
    ("Töötaja", "seisund", "Töötaja kasutusseisund süsteemis. {@Kohustuslik. Väärtus peab olema registreeritud seisundi klassifikaatori väärtus.} Näiteväärtus: Aktiivne"),
    ("Klient", "kliendi tunnus", "Klienti organisatsioonis eristav tunnus. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: K-2048"),
    ("Klient", "aktiivsus", "Tunnus, mis näitab, kas klient saab registreeringuid esitada. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE"),
    ("Klient", "kliendiks saamise aeg", "Kuupäev ja kellaaeg, millal isik registreeriti kliendiks. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59.} Näiteväärtus: 2026-03-10 09:15"),
    ("Treener", "treeneri tunnus", "Treenerit organisatsioonis eristav tunnus. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: TR-12"),
    ("Treener", "rolli kehtivus", "Ajavahemik, millal töötaja tegutseb treeneri rollis. {@Kohustuslik. Algus ja lõpp peavad olema vahemikus 2000-01-01 kuni 2100-12-31; lõpp ei tohi olla algusest varasem.} Näiteväärtus: 2026-01-01 kuni 2026-12-31"),
    ("Treener", "pädevuste ulatus", "Treeneri pädevuste kirjeldus juhatajale treeningukordade planeerimiseks. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Jõutreeningud algajatele ja edasijõudnutele"),
    ("Töötaja rolli omamine", "rolli algus", "Kuupäev, millest alates töötaja roll kehtib. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 kuni 2100-12-31.} Näiteväärtus: 2026-01-01"),
    ("Töötaja rolli omamine", "rolli lõpp", "Kuupäev, millest alates töötaja roll enam ei kehti. {Kui väärtus registreeritakse, peab see olema vahemikus 2000-01-01 kuni 2100-12-31 ja mitte varasem kui rolli algus.} Näiteväärtus: 2026-12-31"),
    ("Treeningukord", "algus", "Treeningukorra alguse kuupäev ja kellaaeg. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59.} Näiteväärtus: 2026-05-12 18:00"),
    ("Treeningukord", "lõpp", "Treeningukorra lõpu kuupäev ja kellaaeg. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59 ja hilisem kui algus.} Näiteväärtus: 2026-05-12 19:00"),
    ("Treeningukord", "registreerimise tähtaeg", "Viimane kuupäev ja kellaaeg, milleni klient saab treeningukorrale registreeruda. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59 ja mitte hilisem kui algus.} Näiteväärtus: 2026-05-12 17:00"),
    ("Treeningukord", "tühistamise tähtaeg", "Viimane kuupäev ja kellaaeg, milleni klient saab registreeringu ise tühistada. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59 ja mitte hilisem kui algus.} Näiteväärtus: 2026-05-12 16:00"),
    ("Treeningukord", "kohtade piir", "Treeningukorrale lubatud klientide maksimaalne arv inimestes. {@Kohustuslik. Täisarv. Väärtus peab olema suurem kui 0.} Näiteväärtus: 12"),
    ("Treeningukord", "seisund", "Treeningukorra elutsükli seisund. {@Kohustuslik. Väärtus peab olema registreeritud seisundi klassifikaatori väärtus.} Näiteväärtus: Registreerimiseks avatud"),
    ("Registreering", "esitamise aeg", "Kuupäev ja kellaaeg, millal klient esitas registreeringu. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59.} Näiteväärtus: 2026-05-10 13:25"),
    ("Registreering", "seisund", "Registreeringu elutsükli seisund. {@Kohustuslik. Väärtus peab olema registreeritud seisundi klassifikaatori väärtus.} Näiteväärtus: Kinnitatud"),
    ("Registreering", "tühistamise aeg", "Kuupäev ja kellaaeg, millal registreering tühistati. {Kui väärtus registreeritakse, peab see olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59.} Näiteväärtus: 2026-05-11 10:00"),
    ("Registreering", "edendamise aeg", "Kuupäev ja kellaaeg, millal ootel registreering kinnitatud registreeringuks edendati. {Kui väärtus registreeritakse, peab see olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59.} Näiteväärtus: 2026-05-11 10:01"),
    ("Registreering", "tühistamise põhjus", "Registreeringu tühistamise põhjendus kliendile, treenerile ja juhatajale. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Klient tühistas registreeringu enne tähtaega."),
    ("Ootejärjekorra koht", "järjekorranumber", "Registreeringu koht treeningukorra ootejärjekorras. {@Kohustuslik. Täisarv. Väärtus peab olema suurem kui 0.} Näiteväärtus: 3"),
    ("Osalemine", "tulemus", "Treeningukorrale registreeritud kliendi osalemise tulemus. {@Kohustuslik. Lubatud väärtused on \"osales\" ja \"ei osalenud\".} Näiteväärtus: osales"),
    ("Osalemine", "märkimise aeg", "Kuupäev ja kellaaeg, millal treener või juhataja märkis osalemise tulemuse. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 00:00 kuni 2100-12-31 23:59.} Näiteväärtus: 2026-05-12 19:05"),
    ("Osalemine", "märkus", "Treeneri või juhataja sisemine märkus osalemise kohta. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Klient saabus 10 minutit hiljem."),
    ("Treeninguliik", "nimetus", "Treeninguliigi nimetus, mida kasutatakse treeningukorra kirjeldamisel. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Jõutreening algajatele"),
    ("Treeninguliik", "sisu", "Treeninguliigi sisukirjeldus klientidele ja juhatajatele. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 1000 märki pikk.} Näiteväärtus: Üldkehaline jõutreening algajatele."),
    ("Treeninguliik", "tüüpiline kestus", "Treeninguliigi tavapärane kestus minutites. {@Kohustuslik. Täisarv. Väärtus peab olema suurem kui 0.} Näiteväärtus: 60"),
    ("Treeninguliik", "kasutatavus", "Tunnus, mis näitab, kas treeninguliiki saab uutel treeningukordadel kasutada. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE"),
    ("Ruum", "ruumi tunnus", "Ruumi organisatsioonis eristav tunnus. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: SAAL-1"),
    ("Ruum", "nimetus", "Ruumi nimetus, mida kasutatakse treeningukorra planeerimisel. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Peasaal"),
    ("Ruum", "asukoht", "Ruumi asukoha kirjeldus klientidele, treeneritele ja juhatajatele. {@Kohustuslik. @Pole_tühi. Võib olla kuni 255 märki pikk.} Näiteväärtus: 1. korrus"),
    ("Ruum", "mahutavus", "Ruumi maksimaalne mahutavus inimestes. {@Kohustuslik. Täisarv. Väärtus peab olema suurem kui 0.} Näiteväärtus: 20"),
    ("Varustus", "varustuse tunnus", "Varustust organisatsioonis eristav tunnus. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: MAT-01"),
    ("Varustus", "nimetus", "Varustuse nimetus treeningukordade planeerimiseks. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Joogamatt"),
    ("Varustus", "aktiivsus", "Tunnus, mis näitab, kas varustust saab treeningukordade planeerimisel kasutada. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE"),
    ("Treeneri pädevus", "kehtiv alates", "Kuupäev, millest alates treeneri pädevus kehtib. {@Kohustuslik. Väärtus peab olema vahemikus 2000-01-01 kuni 2100-12-31.} Näiteväärtus: 2026-01-01"),
    ("Treeneri pädevus", "kehtiv kuni", "Kuupäev, milleni treeneri pädevus kehtib. {Kui väärtus registreeritakse, peab see olema vahemikus 2000-01-01 kuni 2100-12-31 ja mitte varasem kui kehtiv alates.} Näiteväärtus: 2026-12-31"),
    ("Ruumi varustatus", "kogus", "Ruumis olemasoleva varustuse kogus tükkides. {@Kohustuslik. Täisarv. Väärtus ei tohi olla negatiivne.} Näiteväärtus: 15"),
    ("Ruumi varustatus", "märkus", "Juhatajale mõeldud märkus ruumi varustatuse kohta. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Osa matte asub kõrvalruumis."),
    ("Varustuse nõue", "minimaalne kogus", "Treeninguliigi läbiviimiseks vajalik minimaalne varustuse kogus tükkides. {@Kohustuslik. Täisarv. Väärtus ei tohi olla negatiivne.} Näiteväärtus: 10"),
    ("Varustuse nõue", "kohustuslikkus", "Tunnus, mis näitab, kas varustus on treeninguliigi jaoks kohustuslik. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE"),
    ("Varustuse nõue", "märkus", "Juhatajale ja treenerile mõeldud märkus varustuse nõude kohta. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Algajate rühmas võib kasutada poole vähem raskusi."),
    ("Klassifikaator", "kood", "Klassifikaatori väärtust eristav kood. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: AKTIIVNE"),
    ("Klassifikaator", "nimetus", "Klassifikaatori väärtuse nimetus kasutajale kuvamiseks. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Aktiivne"),
    ("Klassifikaator", "tähendus", "Klassifikaatori väärtuse selgitus süsteemi haldajale. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Väärtus näitab, et objekt on kasutatav."),
    ("Klassifikaator", "aktiivsus", "Tunnus, mis näitab, kas klassifikaatori väärtust saab uutes kirjetes kasutada. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE"),
    ("Seisund", "kood", "Seisundi klassifikaatori väärtust eristav kood. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: AVATUD"),
    ("Seisund", "nimetus", "Seisundi nimetus kasutajale kuvamiseks. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Avatud"),
    ("Seisund", "tähendus", "Seisundi tähenduse selgitus haldajale. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Klient saab treeningukorrale registreeruda."),
    ("Seisund", "aktiivsus", "Tunnus, mis näitab, kas seisundit saab uutes kirjetes kasutada. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE"),
    ("Roll", "kood", "Rolli klassifikaatori väärtust eristav kood. {@Kohustuslik. @Pole_tühi. Võib olla kuni 30 märki pikk.} Näiteväärtus: TREENER"),
    ("Roll", "nimetus", "Rolli nimetus kasutajale kuvamiseks. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Treener"),
    ("Roll", "vastutus", "Rolli vastutuse kirjeldus töötajate haldurile ja juhatajale. {Kui väärtus registreeritakse, siis @Pole_tühi. Võib olla kuni 500 märki pikk.} Näiteväärtus: Märgib treeningukorra osalemist."),
    ("Roll", "aktiivsus", "Tunnus, mis näitab, kas rolli saab töötajale määrata. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE"),
    ("Riik", "kood", "Riigi klassifikaatori väärtust eristav kood. {@Kohustuslik. @Pole_tühi. Võib olla kuni 10 märki pikk.} Näiteväärtus: EE"),
    ("Riik", "nimetus", "Riigi nimetus kasutajale kuvamiseks. {@Kohustuslik. @Pole_tühi. Võib olla kuni 100 märki pikk.} Näiteväärtus: Eesti"),
    ("Riik", "aktiivsus", "Tunnus, mis näitab, kas riiki saab isiku andmete juures kasutada. {@Kohustuslik. Lubatud väärtused on TRUE ja FALSE.} Näiteväärtus: TRUE"),
]


ATTRIBUTE_DEFINITIONS = [
    ('riik', 'riigi_kood', 'Riigi klassifikaatori lühikood. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK, mittetühi domeen.', 'EE'),
    ('riik', 'nimetus', 'Riigi nimetus. Andmetüüp: VARCHAR(100). Nullitavus: kohustuslik. Piirangud: mittetühi väärtus.', 'Eesti'),
    ('riik', 'on_aktiivne', 'Tunnus, kas riiki saab kasutada uute isikute juures. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('isiku_seisundi_liik', 'isiku_seisundi_liigi_kood', 'Isiku seisundi klassifikaatori kood. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK.', 'AKTIIVNE'),
    ('isiku_seisundi_liik', 'nimetus', 'Isiku seisundi kasutajale loetav nimetus. Andmetüüp: VARCHAR(100). Nullitavus: kohustuslik. Piirangud: mittetühi väärtus.', 'Aktiivne'),
    ('isiku_seisundi_liik', 'on_aktiivne', 'Tunnus, kas seisundit saab kasutada. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('tootaja_seisundi_liik', 'tootaja_seisundi_liigi_kood', 'Töötaja seisundi klassifikaatori kood. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK.', 'AKTIIVNE'),
    ('tootaja_seisundi_liik', 'nimetus', 'Töötaja seisundi nimetus. Andmetüüp: VARCHAR(100). Nullitavus: kohustuslik. Piirangud: mittetühi väärtus.', 'Aktiivne'),
    ('tootaja_seisundi_liik', 'on_aktiivne', 'Tunnus, kas töötaja seisundit saab kasutada. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('tootaja_roll', 'tootaja_rolli_kood', 'Töötaja rolli lühikood. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK.', 'TREENER, JUHATAJA'),
    ('tootaja_roll', 'nimetus', 'Rolli nimetus. Andmetüüp: VARCHAR(100). Nullitavus: kohustuslik. Piirangud: mittetühi väärtus.', 'Treener'),
    ('tootaja_roll', 'on_aktiivne', 'Tunnus, kas rolli saab töötajale määrata. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('tootaja_roll', 'kirjeldus', 'Rolli sisuline kirjeldus. Andmetüüp: TEXT. Nullitavus: kohustuslik. Piirangud: mittetühi väärtus.', 'Treener märgib osalemist.'),
    ('treeninguliigi_seisundi_liik', 'treeninguliigi_seisundi_kood', 'Treeninguliigi elutsükli seisundi kood. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK.', 'KOOST, AKTIIVNE, MITTEAKT, LOPETATUD'),
    ('treeninguliigi_seisundi_liik', 'nimetus', 'Treeninguliigi seisundi nimetus. Andmetüüp: VARCHAR(100). Nullitavus: kohustuslik. Piirangud: mittetühi väärtus.', 'Aktiivne'),
    ('treeninguliigi_seisundi_liik', 'on_aktiivne', 'Tunnus, kas seisund on kasutatav. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('treeningukorra_seisundi_liik', 'treeningukorra_seisundi_kood', 'Treeningukorra elutsükli seisundi kood. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK.', 'KAVAND, AVATUD, SULETUD, TOIMUNUD, TYHIST'),
    ('treeningukorra_seisundi_liik', 'nimetus', 'Treeningukorra seisundi nimetus. Andmetüüp: VARCHAR(100). Nullitavus: kohustuslik. Piirangud: mittetühi väärtus.', 'Avatud'),
    ('treeningukorra_seisundi_liik', 'on_aktiivne', 'Tunnus, kas seisund on kasutatav. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('treeningukorra_seisundi_liik', 'kirjeldus', 'Treeningukorra seisundi tähendus. Andmetüüp: TEXT. Nullitavus: kohustuslik. Piirangud: mittetühi väärtus.', 'Klient saab registreeruda.'),
    ('registreeringu_seisundi_liik', 'registreeringu_seisundi_kood', 'Registreeringu seisundi kood. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK.', 'KINNIT, OOTEJRK, TYH_KL, TYH_SYS'),
    ('registreeringu_seisundi_liik', 'nimetus', 'Registreeringu seisundi nimetus. Andmetüüp: VARCHAR(100). Nullitavus: kohustuslik. Piirangud: mittetühi väärtus.', 'Kinnitatud'),
    ('registreeringu_seisundi_liik', 'on_aktiivne', 'Tunnus, kas seisund on kasutatav. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('registreeringu_seisundi_liik', 'kirjeldus', 'Registreeringu seisundi tähendus. Andmetüüp: TEXT. Nullitavus: kohustuslik. Piirangud: mittetühi väärtus.', 'Kliendil on kinnitatud koht.'),
    ('treeningu_kategooria_tyyp', 'treeningu_kategooria_tyybi_kood', 'Treeningukategooria tüübi kood. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK.', 'INTENS'),
    ('treeningu_kategooria_tyyp', 'nimetus', 'Kategooria tüübi nimetus. Andmetüüp: VARCHAR(100). Nullitavus: kohustuslik. Piirangud: mittetühi väärtus.', 'Intensiivsus'),
    ('treeningu_kategooria_tyyp', 'on_aktiivne', 'Tunnus, kas kategooria tüüpi saab kasutada. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('treeningu_kategooria', 'treeningu_kategooria_kood', 'Treeningukategooria kood. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK.', 'JOUD'),
    ('treeningu_kategooria', 'treeningu_kategooria_tyybi_kood', 'Kategooria tüübi viide. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: FK treeningu_kategooria_tyyp.', 'INTENS'),
    ('treeningu_kategooria', 'nimetus', 'Treeningukategooria nimetus. Andmetüüp: VARCHAR(100). Nullitavus: kohustuslik. Piirangud: mittetühi väärtus.', 'Jõutreening'),
    ('treeningu_kategooria', 'on_aktiivne', 'Tunnus, kas kategooriat saab treeninguliigile määrata. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('isik', 'e_meil', 'Isiku e-posti aadress ja peamine identifikaator. Andmetüüp: e_meil_aadress. Nullitavus: kohustuslik. Piirangud: PK, domeen nõuab @ märki.', 'klient@jousaal.ee'),
    ('isik', 'isikukood', 'Isiku riiklik või organisatsiooniline isikukood. Andmetüüp: VARCHAR(50). Nullitavus: valikuline. Piirangud: unikaalne, kui väärtus on olemas.', '50101010001'),
    ('isik', 'riigi_kood', 'Isiku riigi viide. Andmetüüp: kood_10. Nullitavus: valikuline. Piirangud: FK riik, ON UPDATE CASCADE.', 'EE'),
    ('isik', 'isiku_seisundi_liigi_kood', 'Isiku kasutatavuse seisund. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: FK isiku_seisundi_liik.', 'AKTIIVNE'),
    ('isik', 'synni_kp', 'Isiku sünnikuupäev. Andmetüüp: DATE. Nullitavus: valikuline. Piirangud: ei tohi olla tulevikus.', '1990-05-20'),
    ('isik', 'registreerimise_aeg', 'Isiku andmete loomise ajatempel. Andmetüüp: TIMESTAMP(0) WITH TIME ZONE. Nullitavus: kohustuslik. Piirangud: vaikeväärtus CURRENT_TIMESTAMP.', '2026-05-26 10:00'),
    ('isik', 'viimase_muutmise_aeg', 'Isiku viimase muutmise ajatempel. Andmetüüp: TIMESTAMP(0) WITH TIME ZONE. Nullitavus: kohustuslik. Piirangud: trigger uuendab UPDATE korral.', '2026-05-26 10:05'),
    ('isik', 'eesnimi', 'Isiku eesnimi või ainus nimekomponent. Andmetüüp: VARCHAR(100). Nullitavus: valikuline. Piirangud: vähemalt üks nimekomponent peab olema olemas, antud väärtus ei tohi olla tühi.', 'Mari'),
    ('isik', 'perenimi', 'Isiku perekonnanimi. Andmetüüp: VARCHAR(100). Nullitavus: valikuline. Piirangud: vähemalt üks nimekomponent peab olema olemas, antud väärtus ei tohi olla tühi.', 'Tamm'),
    ('isik', 'elukoht', 'Isiku elukoha vabatekstiline kirjeldus. Andmetüüp: VARCHAR(255). Nullitavus: valikuline. Piirangud: antud väärtus ei tohi olla tühi.', 'Tallinn'),
    ('kasutajakonto', 'e_meil', 'Konto e-posti aadress ja seos isikuga. Andmetüüp: e_meil_aadress. Nullitavus: kohustuslik. Piirangud: PK, FK isik ON DELETE/UPDATE CASCADE.', 'klient@jousaal.ee'),
    ('kasutajakonto', 'parool', 'Parooli räsi. Andmetüüp: VARCHAR(255). Nullitavus: kohustuslik. Piirangud: mittetühi; selget parooli ei salvestata.', 'pbkdf2:sha256:...'),
    ('kasutajakonto', 'on_aktiivne', 'Tunnus, kas kontoga saab sisse logida. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('klient', 'e_meil', 'Kliendi konto e-posti aadress. Andmetüüp: e_meil_aadress. Nullitavus: kohustuslik. Piirangud: PK, FK kasutajakonto ON DELETE/UPDATE CASCADE.', 'klient@jousaal.ee'),
    ('klient', 'registreerimise_aeg', 'Kliendiks registreerimise aeg. Andmetüüp: TIMESTAMP(0) WITH TIME ZONE. Nullitavus: kohustuslik. Piirangud: vaikeväärtus CURRENT_TIMESTAMP.', '2026-05-20 09:00'),
    ('klient', 'on_aktiivne', 'Tunnus, kas klient saab registreeruda treeningukordadele. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('tootaja', 'e_meil', 'Töötaja konto e-posti aadress. Andmetüüp: e_meil_aadress. Nullitavus: kohustuslik. Piirangud: PK, FK kasutajakonto ON DELETE/UPDATE CASCADE.', 'treener@jousaal.ee'),
    ('tootaja', 'tootaja_seisundi_liigi_kood', 'Töötaja seisund. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: FK tootaja_seisundi_liik.', 'AKTIIVNE'),
    ('tootaja_rolli_omamine', 'tootaja_e_meil', 'Rolli omava töötaja e-posti aadress. Andmetüüp: e_meil_aadress. Nullitavus: kohustuslik. Piirangud: PK osa, FK tootaja ON DELETE/UPDATE CASCADE.', 'treener@jousaal.ee'),
    ('tootaja_rolli_omamine', 'tootaja_rolli_kood', 'Töötajale määratud roll. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK osa, FK tootaja_roll.', 'TREENER'),
    ('tootaja_rolli_omamine', 'alguse_aeg', 'Rolli kehtivuse algus. Andmetüüp: TIMESTAMP(0) WITH TIME ZONE. Nullitavus: kohustuslik. Piirangud: PK osa.', '2026-01-01 00:00'),
    ('tootaja_rolli_omamine', 'kehtivuse_lopu_aeg', 'Rolli kehtivuse lõpp. Andmetüüp: TIMESTAMP(0) WITH TIME ZONE. Nullitavus: valikuline. Piirangud: lõpp peab olema pärast algust; aktiivsele rollile osaline unikaalne indeks.', '2026-12-31 23:59'),
    ('treeninguliik', 'treeninguliigi_id', 'Treeninguliigi sisemine identifikaator. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: PK, sequence vaikeväärtus, positiivne väärtus.', '1000'),
    ('treeninguliik', 'nimetus', 'Treeninguliigi nimi. Andmetüüp: VARCHAR(100). Nullitavus: kohustuslik. Piirangud: UNIQUE, mittetühi.', 'Jooga algajatele'),
    ('treeninguliik', 'kirjeldus', 'Treeninguliigi sisu kirjeldus. Andmetüüp: TEXT. Nullitavus: valikuline. Piirangud: antud väärtus ei tohi olla tühi.', 'Rahulik joogatund algajatele.'),
    ('treeninguliik', 'kestus_minutites', 'Tüüpiline kestus minutites. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: CHECK 15 kuni 240.', '60'),
    ('treeninguliik', 'vajalik_varustus', 'Kliendile nähtav varustuse lühikirjeldus. Andmetüüp: VARCHAR(255). Nullitavus: valikuline. Piirangud: antud väärtus ei tohi olla tühi.', 'Matid'),
    ('treeninguliik', 'treeninguliigi_seisundi_kood', 'Treeninguliigi seisund. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: FK treeninguliigi_seisundi_liik, vaikeväärtus KOOST.', 'AKTIIVNE'),
    ('treeninguliik', 'registreerija_e_meil', 'Treeninguliigi loonud töötaja. Andmetüüp: e_meil_aadress. Nullitavus: kohustuslik. Piirangud: FK tootaja.', 'juhataja@jousaal.ee'),
    ('treeninguliik', 'viimase_muutja_e_meil', 'Treeninguliigi viimati muutnud töötaja. Andmetüüp: e_meil_aadress. Nullitavus: kohustuslik. Piirangud: FK tootaja.', 'juhataja@jousaal.ee'),
    ('treeninguliik', 'registreerimise_aeg', 'Treeninguliigi loomise ajatempel. Andmetüüp: TIMESTAMP(0) WITH TIME ZONE. Nullitavus: kohustuslik. Piirangud: vaikeväärtus CURRENT_TIMESTAMP.', '2026-05-20 09:00'),
    ('treeninguliik', 'viimase_muutmise_aeg', 'Treeninguliigi viimase muutmise ajatempel. Andmetüüp: TIMESTAMP(0) WITH TIME ZONE. Nullitavus: kohustuslik. Piirangud: trigger uuendab UPDATE korral.', '2026-05-20 09:05'),
    ('treeninguliigi_kategooria_omamine', 'treeninguliigi_id', 'Kategooriat omava treeninguliigi viide. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: PK osa, FK treeninguliik.', '1000'),
    ('treeninguliigi_kategooria_omamine', 'treeningu_kategooria_kood', 'Treeninguliigile määratud kategooria. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK osa, FK treeningu_kategooria.', 'JOUD'),
    ('varustus', 'varustuse_kood', 'Varustuse lühikood. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK.', 'MATID'),
    ('varustus', 'nimetus', 'Varustuse nimetus. Andmetüüp: VARCHAR(100). Nullitavus: kohustuslik. Piirangud: UNIQUE, mittetühi.', 'Treeningmatid'),
    ('varustus', 'kirjeldus', 'Varustuse kirjeldus. Andmetüüp: TEXT. Nullitavus: valikuline. Piirangud: antud väärtus ei tohi olla tühi.', 'Joogatunnis kasutatav matt.'),
    ('varustus', 'on_aktiivne', 'Tunnus, kas varustust saab nõuetes ja ruumides kasutada. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('treeninguliigi_varustuse_noue', 'treeninguliigi_id', 'Treeninguliik, millele nõue kehtib. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: PK osa, FK treeninguliik.', '1000'),
    ('treeninguliigi_varustuse_noue', 'varustuse_kood', 'Nõutud varustuse viide. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK osa, FK varustus.', 'MATID'),
    ('treeninguliigi_varustuse_noue', 'minimaalne_kogus', 'Treeninguliigile vajalik minimaalne kogus. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: CHECK > 0.', '6'),
    ('treeninguliigi_varustuse_noue', 'on_kohustuslik', 'Tunnus, kas nõude rikkumine keelab planeerimise. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('treeninguliigi_varustuse_noue', 'markus', 'Nõude täpsustav märkus. Andmetüüp: TEXT. Nullitavus: valikuline. Piirangud: antud väärtus ei tohi olla tühi.', 'Matid peavad olema terved.'),
    ('ruum', 'ruumi_kood', 'Ruumi lühikood. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK.', 'SAAL_A'),
    ('ruum', 'nimetus', 'Ruumi nimetus. Andmetüüp: VARCHAR(100). Nullitavus: kohustuslik. Piirangud: UNIQUE, mittetühi.', 'Saal A'),
    ('ruum', 'asukoht', 'Ruumi asukoha kirjeldus. Andmetüüp: VARCHAR(255). Nullitavus: valikuline. Piirangud: antud väärtus ei tohi olla tühi.', '2. korrus'),
    ('ruum', 'mahutavus', 'Ruumi maksimaalne osalejate arv. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: CHECK > 0.', '12'),
    ('ruum', 'on_aktiivne', 'Tunnus, kas ruumi saab treeningukorrale määrata. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: vaikeväärtus TRUE.', 'TRUE/FALSE'),
    ('ruumi_varustuse_omamine', 'ruumi_kood', 'Ruum, kus varustus asub. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK osa, FK ruum ON DELETE/UPDATE CASCADE.', 'SAAL_A'),
    ('ruumi_varustuse_omamine', 'varustuse_kood', 'Ruumis oleva varustuse viide. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: PK osa, FK varustus ON DELETE/UPDATE CASCADE.', 'MATID'),
    ('ruumi_varustuse_omamine', 'kogus', 'Ruumis oleva varustuse kogus. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: CHECK > 0.', '12'),
    ('ruumi_varustuse_omamine', 'markus', 'Ruumi varustuse täpsustav märkus. Andmetüüp: TEXT. Nullitavus: valikuline. Piirangud: antud väärtus ei tohi olla tühi.', 'Kapis ukse kõrval.'),
    ('treeneri_padevus', 'tootaja_e_meil', 'Pädeva treeneri e-posti aadress. Andmetüüp: e_meil_aadress. Nullitavus: kohustuslik. Piirangud: PK osa, FK tootaja ON DELETE/UPDATE CASCADE; trigger nõuab TREENER rolli.', 'treener@jousaal.ee'),
    ('treeneri_padevus', 'treeninguliigi_id', 'Treeninguliik, mida treener võib juhendada. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: PK osa, FK treeninguliik.', '1000'),
    ('treeneri_padevus', 'alates', 'Pädevuse alguskuupäev. Andmetüüp: DATE. Nullitavus: kohustuslik. Piirangud: CHECK kuni puudub või kuni >= alates.', '2026-01-01'),
    ('treeneri_padevus', 'kuni', 'Pädevuse lõppkuupäev. Andmetüüp: DATE. Nullitavus: valikuline. Piirangud: kui väärtus on antud, ei tohi see olla enne algust.', '2026-12-31'),
    ('treeningukord', 'treeningukorra_id', 'Kalendris toimuva treeningukorra identifikaator. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: PK, sequence vaikeväärtus, positiivne väärtus.', '5001'),
    ('treeningukord', 'treeninguliigi_id', 'Treeninguliik, mille alusel kord toimub. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: FK treeninguliik.', '1000'),
    ('treeningukord', 'treener_e_meil', 'Treeningukorda juhendav treener. Andmetüüp: e_meil_aadress. Nullitavus: kohustuslik. Piirangud: FK tootaja; trigger kontrollib rolli, pädevust ja kattuvusi.', 'treener@jousaal.ee'),
    ('treeningukord', 'ruumi_kood', 'Ruum, kus kord toimub. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: FK ruum; trigger kontrollib mahutavust, varustust ja ruumi kattuvusi.', 'SAAL_A'),
    ('treeningukord', 'alguse_aeg', 'Treeningukorra alguse aeg. Andmetüüp: ajakava_ajahetk. Nullitavus: kohustuslik. Piirangud: peab olema enne lõppu.', '2026-06-01 18:00'),
    ('treeningukord', 'lopu_aeg', 'Treeningukorra lõpu aeg. Andmetüüp: ajakava_ajahetk. Nullitavus: kohustuslik. Piirangud: peab olema pärast algust.', '2026-06-01 19:00'),
    ('treeningukord', 'registreerimise_lopp', 'Registreerimise lõpptähtaeg. Andmetüüp: ajakava_ajahetk. Nullitavus: kohustuslik. Piirangud: peab olema enne treeningukorra algust.', '2026-06-01 17:00'),
    ('treeningukord', 'tyhistamise_lopp', 'Kliendi tühistamise lõpptähtaeg. Andmetüüp: ajakava_ajahetk. Nullitavus: kohustuslik. Piirangud: peab olema hiljemalt treeningukorra alguseks.', '2026-06-01 16:00'),
    ('treeningukord', 'maksimaalne_osalejate_arv', 'Selle korra osalejate piirarv. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: CHECK > 0; trigger ei luba ületada ruumi mahutavust.', '10'),
    ('treeningukord', 'treeningukorra_seisundi_kood', 'Treeningukorra seisund. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: FK treeningukorra_seisundi_liik; trigger lubab ainult määratud siirdeid.', 'KAVAND/AVATUD/SULETUD/TOIMUNUD/TYHIST'),
    ('treeningukord', 'looja_e_meil', 'Treeningukorra loonud juhataja. Andmetüüp: e_meil_aadress. Nullitavus: kohustuslik. Piirangud: FK tootaja.', 'juhataja@jousaal.ee'),
    ('treeningukord', 'viimase_muutja_e_meil', 'Treeningukorra viimati muutnud töötaja. Andmetüüp: e_meil_aadress. Nullitavus: kohustuslik. Piirangud: FK tootaja.', 'juhataja@jousaal.ee'),
    ('treeningukord', 'loomise_aeg', 'Treeningukorra loomise ajatempel. Andmetüüp: TIMESTAMP(0) WITH TIME ZONE. Nullitavus: kohustuslik. Piirangud: vaikeväärtus CURRENT_TIMESTAMP.', '2026-05-26 10:00'),
    ('treeningukord', 'viimase_muutmise_aeg', 'Treeningukorra viimase muutmise ajatempel. Andmetüüp: TIMESTAMP(0) WITH TIME ZONE. Nullitavus: kohustuslik. Piirangud: trigger uuendab UPDATE korral.', '2026-05-26 10:05'),
    ('treeningukord', 'tyhistamise_pohjus', 'Treeningukorra tühistamise põhjus. Andmetüüp: TEXT. Nullitavus: valikuline. Piirangud: TYHIST seisundis peab põhjus olema sisuline; antud väärtus ei tohi olla tühi.', 'Treener haigestus.'),
    ('registreering', 'registreeringu_id', 'Registreeringu identifikaator. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: PK, sequence vaikeväärtus, positiivne väärtus.', '9001'),
    ('registreering', 'treeningukorra_id', 'Treeningukord, millele klient registreerub. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: FK treeningukord.', '5001'),
    ('registreering', 'klient_e_meil', 'Registreeruva kliendi e-posti aadress. Andmetüüp: e_meil_aadress. Nullitavus: kohustuslik. Piirangud: FK klient; osaline UNIQUE keelab mitu aktiivset registreeringut samale korrale.', 'klient@jousaal.ee'),
    ('registreering', 'registreeringu_seisundi_kood', 'Registreeringu seisund. Andmetüüp: kood_10. Nullitavus: kohustuslik. Piirangud: FK registreeringu_seisundi_liik; trigger lubab ainult määratud siirdeid.', 'KINNIT/OOTEJRK/TYH_KL/TYH_SYS'),
    ('registreering', 'registreerimise_aeg', 'Registreeringu loomise aeg. Andmetüüp: TIMESTAMP(0) WITH TIME ZONE. Nullitavus: kohustuslik. Piirangud: vaikeväärtus CURRENT_TIMESTAMP.', '2026-05-26 11:00'),
    ('registreering', 'tyhistamise_aeg', 'Registreeringu tühistamise aeg. Andmetüüp: TIMESTAMP(0) WITH TIME ZONE. Nullitavus: valikuline. Piirangud: täidetakse tühistamise korral.', '2026-05-27 09:00'),
    ('registreering', 'edendamise_aeg', 'Ootejärjekorrast kinnitatuks edendamise aeg. Andmetüüp: TIMESTAMP(0) WITH TIME ZONE. Nullitavus: valikuline. Piirangud: täidetakse OOTEJRK -> KINNIT siirdel.', '2026-05-27 09:05'),
    ('registreering', 'tyhistamise_pohjus', 'Registreeringu tühistamise põhjus. Andmetüüp: TEXT. Nullitavus: valikuline. Piirangud: antud väärtus ei tohi olla tühi.', 'Klient haigestus.'),
    ('ootejarjekorra_koht', 'registreeringu_id', 'Ootejärjekorras oleva registreeringu viide. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: PK, FK registreering ON DELETE CASCADE.', '9002'),
    ('ootejarjekorra_koht', 'treeningukorra_id', 'Treeningukord, mille ootejärjekorras koht asub. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: FK treeningukord; UNIQUE koos ootejarjekorra_nr.', '5001'),
    ('ootejarjekorra_koht', 'ootejarjekorra_nr', 'Kliendi järjekorranumber sama treeningukorra ootejärjekorras. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: CHECK > 0, treeningukorra piires unikaalne.', '1'),
    ('osalemine', 'registreeringu_id', 'Registreering, mille kohta osalemist märgitakse. Andmetüüp: INTEGER. Nullitavus: kohustuslik. Piirangud: PK, FK registreering ON DELETE CASCADE; trigger nõuab KINNIT registreeringut.', '9001'),
    ('osalemine', 'on_osalenud', 'Tunnus, kas klient osales treeningukorral. Andmetüüp: BOOLEAN. Nullitavus: kohustuslik. Piirangud: väärtus TRUE või FALSE.', 'TRUE/FALSE'),
    ('osalemine', 'markija_e_meil', 'Osalemise märkinud treener või juhataja. Andmetüüp: e_meil_aadress. Nullitavus: kohustuslik. Piirangud: FK tootaja; funktsioon kontrollib rolli.', 'treener@jousaal.ee'),
    ('osalemine', 'markimise_aeg', 'Osalemise märkimise aeg. Andmetüüp: TIMESTAMP(0) WITH TIME ZONE. Nullitavus: kohustuslik. Piirangud: vaikeväärtus CURRENT_TIMESTAMP; ei tohi olla enne treeningukorra algust.', '2026-06-01 19:05'),
    ('osalemine', 'markus', 'Osalemise kohta käiv märkus. Andmetüüp: TEXT. Nullitavus: valikuline. Piirangud: antud väärtus ei tohi olla tühi.', 'Osales kogu treeningus.'),
]


POSTGRESQL_REQUIREMENTS = [
    ("Domeenid", "SQL loob korduvkasutatavad domeenid kood_10, e_meil_aadress ja ajakava_ajahetk."),
    ("Tabelid", "SQL loob üle seitsme tabeli, sh klient, treeninguliik, ruum, varustus, treeningukord, registreering ja osalemine."),
    ("Vaated", "SQL loob vähemalt neli vaadet; projektis on üheksa rakenduse, põhiandmete ja aruandluse vaadet."),
    ("Triggerid", "SQL loob triggerid rolli, seisundimuutuste, invariandi ja osalemise kontrolliks."),
    ("Rutiinid", "SQL loob vähemalt neli rakendusest kutsutavat funktsiooni; projektis on neid üle üheksa."),
    ("Indeksid", "SQL lisab välisvõtmete veergude indeksid ja osalise unikaalse indeksi aktiivsele registreeringule."),
    ("Testandmed", "SQL lisab testandmed kõigisse põhitabelitesse ja klassifikaatoritesse."),
    ("Rollid ja õigused", "SQL loob rakenduse ja vaatleja rollid ning annab õigused DO-plokkides, mis taluvad piiratud õigustega keskkonda."),
]


STATE_TRANSITIONS_SESSION = [
    ("CREATE", "KAVAND", "Juhataja", "Planeeri treeningukord (OP1)", "On sobiv treeninguliik, ruum ja treeneri rollis pädev töötaja.", "Tekib kavandatud treeningukord.", "Treeningukord, Töötaja, Treeninguliik, Ruum"),
    ("KAVAND", "AVATUD", "Juhataja", "Ava registreerimine (OP2)", "Treeningukord on tulevikus ja kavandatud.", "Klient saab esitada registreeringu.", "Treeningukord"),
    ("AVATUD", "SULETUD", "Juhataja, treener või aeg", "Sulge registreerimine (OP3)", "Registreerimine on avatud; treeneri korral on tähtaeg möödas.", "Uusi registreeringuid enam ei lisata.", "Treeningukord"),
    ("SULETUD", "TOIMUNUD", "Treener, juhataja või aeg", "Lõpeta treeningukord (OP4)", "Treeningukorra lõppaeg on möödas.", "Treeningukord märgitakse toimunuks.", "Treeningukord, Osalemine"),
    ("KAVAND/AVATUD/SULETUD", "TYHIST", "Juhataja", "Tühista treeningukord (OP9)", "Treeningukord ei ole juba toimunud.", "Treeningukord ja aktiivsed registreeringud on tühistatud.", "Treeningukord, Registreering"),
]


STATE_TRANSITIONS_REGISTRATION = [
    ("CREATE", "KINNIT", "Klient", "Esita registreering (OP5)", "Klient on aktiivne, treeningukord on avatud, tähtaeg kehtib ja vaba koht on olemas.", "Tekib kinnitatud registreering.", "Klient, Treeningukord, Registreering"),
    ("CREATE", "OOTEJRK", "Klient", "Esita registreering (OP5)", "Klient on aktiivne, treeningukord on avatud, tähtaeg kehtib ja kohad on täis.", "Tekib ootel registreering ja ootejärjekorra koht.", "Klient, Treeningukord, Registreering, Ootejärjekorra koht"),
    ("OOTEJRK", "KINNIT", "Süsteem", "Edenda ootel registreering (OP7)", "Kinnitatud koht vabanes ja sama treeningukorra ootejärjekorras on registreering.", "Esimene ootel registreering muutub kinnitatuks.", "Registreering, Ootejärjekorra koht, Treeningukord"),
    ("KINNIT/OOTEJRK", "TYH_KL", "Klient", "Tühista enda registreering (OP6)", "Klient tegutseb enda aktiivse registreeringuga ja tühistamise tähtaeg lubab.", "Registreering on kliendi poolt tühistatud; kinnitatud koha vabanemisel käivitub edendamine.", "Registreering, Ootejärjekorra koht"),
    ("KINNIT/OOTEJRK", "TYH_SYS", "Juhataja või süsteem", "Tühista treeningukord / süsteemne tühistamine (OP9)", "Treeningukord tühistatakse või juhataja tühistab aktiivse registreeringu.", "Registreering on süsteemselt tühistatud.", "Registreering, Treeningukord, Ootejärjekorra koht"),
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
        "1.3 Registreeringute registri eskiismudelid",
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
    max_width_in = 3.4 if filename == "10_attendance_activity.png" else 6.6
    max_height_in = 8.2
    with Image.open(path) as image:
        aspect = image.width / image.height
    width_in = min(max_width_in, max_height_in * aspect)
    doc.add_picture(str(path), width=Inches(width_in))
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


def add_operation_contract(doc: Document, contract: dict[str, object]) -> None:
    p = doc.add_paragraph()
    p.add_run(str(contract["signature"])).bold = True
    doc.add_paragraph("Eeltingimused:")
    add_bullets(doc, list(contract["pre"]))
    doc.add_paragraph("Järeltingimused:")
    add_bullets(doc, list(contract["post"]))
    add_labeled_paragraph(doc, "Kasutus kasutusjuhtude poolt", str(contract["uses"]))


def add_report_content(doc: Document) -> None:
    state = {"table": 0, "figure": 0}

    add_toc(doc)

    doc.add_heading("Sissejuhatus", level=1)
    add_paragraphs(doc, [
        f"Projekt käsitleb süsteemi „{SYSTEM_NAME}” funktsionaalset allsüsteemi „{TITLE}”. "
        "Allsüsteemi eesmärk on hallata rühmatreeningute tegelikku tööprotsessi: juhataja planeerib konkreetsed treeningukorrad, "
        "avab registreerimise, klient registreerub või satub ootejärjekorda, süsteem edendab vabanenud kohale esimese ootel kliendi "
        "ning treener märgib pärast tundi osalemise.",
        "Käesolev projekt käsitleb jõusaali infosüsteemi ühte kitsast registreeringukeskset rühmatreeningute allsüsteemi. Projekti skoobis on "
        "konkreetsete treeningukordade, kliendi registreeringute, ootejärjekorra ja osalemise tulemuse käsitlemine. Hinnakirjad, "
        "kampaaniad, õnnetused, sissepääsud ja hooldustööd kuuluvad jõusaali terviksüsteemi teistesse allsüsteemidesse ning "
        "neid käesolevas töös ei modelleerita. Selline piiritlus võimaldab keskenduda valitud allsüsteemi andmemudelile, "
        "ärireeglitele, andmebaasioperatsioonidele ja kasutusjuhtudele.",
        "Keskne elutsükli objekt on registreering: klient esitab registreeringu, registreering kinnitatakse või paigutatakse ootejärjekorda, "
        "seda saab tähtaja piires tühistada, ootel registreeringut saab koha vabanemisel edendada ning kinnitatud registreeringu põhjal tekib osalemise tulemus. "
        "Treeningukord, treeninguliik ja treener on samuti sisulised põhiobjektid, kuid töö ei käsitle kõiki võimalikke jõusaali ega personalihalduse valdkondi.",
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
        "Talletada registreeringu elutsükliks vajalikud mõisted: isik, töötaja, klient, treener, treeninguliik, treeningukord, registreering, ootejärjekorra koht, osalemine ja klassifikaator.",
        "Eristada põhiobjekte, suhteobjekte, toetavaid põhiandmeid ja klassifikaatoreid.",
        "Kirjeldada ärireeglid nii, et kontseptuaalne mudel ei sõltuks konkreetsest andmebaasitehnoloogiast.",
        "Pakkuda prototüübis erinevaid töövooge juhatajale, treeneri rollis töötajale ja kliendile.",
    ])
    doc.add_heading("1.1.3 Lausendid", level=3)
    add_bullets(doc, STRATEGIC_STATEMENTS)
    doc.add_heading("1.1.3.1 Skoobi piiritlus", level=4)
    add_table(doc, state, "Skoobi piirid jõusaali terviksüsteemis", ["Valdkond", "Otsus", "Põhjendus"], [
        ("Rühmatreeningud ja treeningukorrad", "Skoobis", "Valitud funktsionaalse allsüsteemi keskne tööprotsess."),
        ("Isikud, töötajad, kliendid, treenerid, registreeringud ja osalemised", "Skoobis", "Need objektid on vajalikud registreeringu esitamiseks, rollide tuvastamiseks, treeneri sobivuse kontrolliks ja kohalolu märkimiseks."),
        ("Treeninguliigid", "Skoobis põhiandmete põhiobjektina", "Treeninguliik ei ole pelk väärtusloend, vaid hallatav kataloogimõiste, millel on sisu, kestus, kasutatavus, varustuse nõuded ja pädevuse seosed."),
        ("Seisundid, rollid ja riigid", "Skoobis klassifikaatoritena", "Need annavad kontrollitud lubatud väärtused ja õiguste aluse, kuid ei ole iseseisvad äriprotsessi põhiobjektid."),
        ("Sissepääsud, hinnakirjad, kampaaniad, õnnetused ja hooldustööd", "Väljaspool skoopi", "Need on jõusaali terviksüsteemi teised võimalikud registrid, kuid ei ole rühmatreeningute registreerimise ja osalemise töövoo jaoks vajalikud."),
    ])
    doc.add_heading("1.1.4 Põhiobjektid", level=3)
    add_table(doc, state, "Terviksüsteemi põhiobjektid", ["Objekt", "Selgitus"], CORE_OBJECTS)
    add_table(doc, state, "Toetavad objektid ja suhteobjektid", ["Objekt", "Liigitus", "Selgitus"], SUPPORTING_CONCEPTS)
    add_table(doc, state, "Klassifikaatorid", ["Mõiste", "Liigitus", "Selgitus"], CLASSIFIERS)
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
        "Joonisel on fookuses töövoogude ja talletatavate mõistete piir. Tehnilised realisatsioonivahendid, nagu konkreetsed tabelid, indeksid, funktsioonid ja triggerid, on kirjeldatud hilisemas füüsilise teostuse peatükis.",
    ])

    doc.add_heading("1.2 Rühmatreeningute ajakava, registreerimise ja osalemise funktsionaalse allsüsteemi eskiismudelid", level=2)
    doc.add_heading("1.2.1 Eesmärgid", level=3)
    add_bullets(doc, [
        "Juhataja saab planeerida konkreetseid treeningukordi koos treeneri rollis töötaja, ruumi ja mahupiiranguga.",
        "Klient saab vaadata vabu treeningukordi, esitada registreeringu ja näha, kas registreering on kinnitatud või ootejärjekorras.",
        "Klient saab vaadata enda registreeringuid ning tühistada enda aktiivse registreeringu tähtaja piires.",
        "Treener saab töötaja spetsialiseerumisena näha enda tunde, vaadata treeningukorra registreeringuid ja märkida osalemist.",
    ])
    doc.add_heading("1.2.2 Seosed pädevusalade ja registritega", level=3)
    add_table(doc, state, "Allsüsteemi seosed pädevusalade ja registritega", ["Pädevusala", "Register/vaade", "Seos"], [
        ("Juhataja", "Treeningukordade register; Registreeringute register; Treeninguliikide register; Töötajate register; Klassifikaatorite register", "Loob ja muudab treeningukordi, vaatab statistikat."),
        ("Treener", "Treenerite register; Treeningukordade register; Osalemiste register; Registreeringute register", "Loeb enda tunniplaani, kasutab pädevuse seoseid ja märgib osalemist."),
        ("Klient", "Treeningukordade register; Registreeringute register; Klientide register", "Loeb avatud ajakava ning loob või tühistab registreeringuid."),
        ("Töötajate haldur", "Töötajate register; Isikute register; Klassifikaatorite register", "Haldab töötajaid ja töötaja rolli omamisi."),
        ("Klassifikaatorite haldur", "Klassifikaatorite register", "Haldab süsteemis kasutatavaid klassifikaatori väärtuseid."),
    ])
    doc.add_heading("1.2.3 Allsüsteemi funktsionaalsed nõuded", level=3)
    add_figure(doc, state, *DIAGRAMS[1])
    add_table(doc, state, "Olulisemad kasutusjuhud", ["Kasutusjuht", "Tegutsejad", "Kirjeldus"], USE_CASES)
    doc.add_heading("1.2.4 Allsüsteemi mittefunktsionaalsed nõuded", level=3)
    add_table(doc, state, "Mittefunktsionaalsed nõuded", ["Tüüp", "Nõue"], NFRS)
    doc.add_heading("1.2.5 Allsüsteemi kahe elementaarse äriprotsessi tegevusdiagrammid", level=3)
    add_figure(doc, state, *DIAGRAMS[3])
    add_figure(doc, state, *DIAGRAMS[9])
    add_figure(doc, state, *DIAGRAMS[6])
    add_paragraphs(doc, [
        "Registreerimise töövoog on äriliselt oluline, sest see seob mitu objekti ja mitu reeglit: klient, avatud treeningukord, "
        "tähtaeg, mahutavus, aktiivne registreering ja ootejärjekord. Ootejärjekorra edendamine on eraldi oluline ärisündmus, mis vastab registreeringu seisundisiirdele OOTEJRK -> KINNIT.",
    ])

    doc.add_heading("1.3 Registreeringute registri eskiismudelid", level=2)
    doc.add_heading("1.3.1 Eesmärgid", level=3)
    add_paragraphs(doc, [
        "Keskne register on Registreeringute register. Selle eesmärk on talletada kliendi osalemissoov, selle seisund, võimalik ootejärjekorra koht, tühistamine ja koha vabanemisel edendamine. Treeningukordade, treeninguliikide, treenerite, isikute, töötajate, klientide, osalemiste ja klassifikaatorite registrid toetavad seda keskset elutsüklit ilma kogu jõusaali ERP-ks laienemata.",
    ])
    doc.add_heading("1.3.2 Registrit kasutavad pädevusalad", level=3)
    add_table(doc, state, "Registrit kasutavad pädevusalad", ["Pädevusala", "Kasutus"], COMPETENCE_AREAS)
    doc.add_heading("1.3.3 Registrit teenindavad funktsionaalsed allsüsteemid", level=3)
    add_bullets(doc, [
        "Registreeringute funktsionaalne allsüsteem teenindab keskset põhiregistrit.",
        "Treeningukordade funktsionaalne allsüsteem annab registreeringule konkreetse toimumiskorra.",
        "Treeninguliikide funktsionaalne allsüsteem hoiab hallatavaid rühmatreeningu kataloogimõisteid, mille põhjal treeningukordi planeeritakse.",
        "Treenerite funktsionaalne allsüsteem hoiab treeneri rolli ja pädevuse infot ainult selles ulatuses, mis on vajalik rühmatreeningute planeerimiseks.",
        "Osalemiste funktsionaalne allsüsteem märgib kinnitatud registreeringu tulemuse.",
        "Isikute, töötajate, klientide ja klassifikaatorite funktsionaalsed allsüsteemid toetavad identiteedi, rollide ja lubatud väärtuste kasutamist.",
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
        "Isikute register annab kliendi ja töötaja identiteedi.",
        "Töötajate register määrab juhataja ja treeneri rollide omamise.",
        "Klassifikaatorite register määrab seisundite, rollide ja riikide lubatud väärtused.",
        "Varustuse põhiandmed seovad treeninguliigi nõuded ruumis olemas oleva varustusega.",
    ])
    doc.add_heading("1.3.6 Ärireeglid", level=3)
    add_table(doc, state, "Registri ärireeglid", ["Reegel", "Kontseptuaalne kontroll"], BUSINESS_RULES)
    doc.add_heading("1.3.7 Registri kontseptuaalne eskiismudel", level=3)
    add_figure(doc, state, *DIAGRAMS[2])
    add_table(doc, state, "Põhiobjektid", ["Objekt", "Selgitus"], CORE_OBJECTS)
    add_table(doc, state, "Toetavad objektid ja suhteobjektid", ["Objekt", "Liigitus", "Selgitus"], SUPPORTING_CONCEPTS)
    add_table(doc, state, "Klassifikaatorid", ["Mõiste", "Liigitus", "Selgitus"], CLASSIFIERS)
    add_paragraphs(doc, [
        "Registreering on keskne põhiobjekt, sest sellel on iseseisev elutsükkel ja selle seisundisiirded on töö olulisemate kasutusjuhtude alus. "
        "Treeningukord ja treeninguliik ei ole registreeringu atribuudid: treeningukord elab ajakava elutsüklis ning treeninguliik on hallatav kataloogimõiste. "
        "Treener on samaaegselt kasutusjuhtude tegutseja ja töötaja spetsialiseerumisena käsitletav põhiobjekt. "
        "Osalemine sõltub registreeringust, kuid see on elutsükliga tulemusobjekt, mitte juhuslik abiveerg. Ootejärjekorra koht jääb sõltuvaks suhteobjektiks.",
    ])

    doc.add_heading("2 Detailanalüüs", level=1)
    doc.add_heading("2.1 Rühmatreeningute ajakava, registreerimise ja osalemise funktsionaalse allsüsteemi detailanalüüs", level=2)
    doc.add_heading("2.1.1 Allsüsteemi täpsustunud funktsionaalsed nõuded", level=3)
    add_paragraphs(doc, [
        "Laiendatud kasutusjuhud eristavad lugemistoiminguid ja andmeid muutvaid ärilisi toiminguid tekstiliselt. Teostuse peatükis on näidatud, millised PostgreSQL rutiinid neid toiminguid realiseerivad.",
    ])
    add_table(doc, state, "Täpsustatud kasutusjuhud ja andmebaasioperatsioonid", ["Kasutusjuht", "Lugemisoperatsioonid", "Muutmisoperatsioonid"], [
        ("Planeeri treeningukord", "OP10, OP11", "OP1 / fn_planeeri_treeningukord"),
        ("Ava/sulge/lõpeta/tühista treeningukord", "OP11", "OP2 / fn_ava_treeningukord; OP3 / fn_sulge_treeningukord; OP4 / fn_lopeta_treeningukord; OP9 / fn_tyhista_treeningukord"),
        ("Vaata vabu treeningukordi", "OP12", ""),
        ("Esita registreering", "OP12", "OP5 / fn_registreeri_klient_treeningukorrale"),
        ("Vaata enda registreeringuid", "OP13", ""),
        ("Tühista enda registreering", "OP13", "OP6 / fn_tyhista_registreering; OP7 / fn_edenda_ootejarjekorrast"),
        ("Vaata treeningukorra registreeringuid", "OP15", ""),
        ("Märgi osalemine", "OP14, OP15", "OP8 / fn_marki_osalemine"),
        ("Vaata treeningukordade täituvuse statistikat", "OP16", ""),
    ])
    add_table(doc, state, "Lugemisoperatsioonide viited", ["OP", "Eesmärk"], READ_OPERATIONS)
    add_paragraphs(doc, [
        "Järgnevalt on samad kasutusjuhud esitatud laiendatud formaadis. Kirjeldused seovad tegutseja eesmärgi, eel- ja järeltingimused, tüüpilise sündmuste järjestuse, alternatiivid ning andmebaasioperatsioonid.",
    ])
    for use_case in EXTENDED_USE_CASES:
        add_extended_use_case(doc, use_case)

    doc.add_heading("2.2 Rühmatreeningute funktsionaalse allsüsteemi vajatavate registrite detailanalüüs", level=2)
    doc.add_heading("2.2.1 Kontseptuaalne andmemudel", level=3)
    doc.add_heading("2.2.1.1 Olemi-suhte diagrammid", level=4)
    add_paragraphs(doc, [
        "Kontseptuaalne mudel on jagatud registrite kaupa, kuid ülevaatejoonis hoiab tervikpildi koos. Detailanalüüsis on eraldi skeemid isikute registrile, treeningukordade registrile, registreeringute registrile, osalemiste registrile ning klassifikaatorite registrile. "
        "Joonised ei kirjelda füüsilisi tabeleid, indekseid, triggereid ega SQL-andmetüüpe.",
    ])
    for idx in [10, 11, 12, 13, 14]:
        add_figure(doc, state, *DIAGRAMS[idx])
    doc.add_page_break()
    doc.add_heading("2.2.1.2 Olemitüüpide definitsioonid", level=4)
    add_table(doc, state, "Olemitüüpide definitsioonid", ["Olemitüüp", "Register", "Liigitus", "Diagrammil näidatud atribuudid", "Definitsioon"], ENTITY_DEFINITIONS)
    doc.add_heading("2.2.1.3 Atribuutide definitsioonid", level=4)
    add_paragraphs(doc, [
        "Kontseptuaalsed atribuudid kirjeldavad diagrammidel nähtavaid ärilisi tunnuseid. SQL-andmetüübid, välisvõtmed, indeksid ja triggerid on füüsilise disaini osa ning neid siin ei kasutata.",
    ])
    add_table(doc, state, "Kontseptuaalsete atribuutide definitsioonid", ["Olemitüüp", "Atribuut", "Definitsioon"], CONCEPTUAL_ATTRIBUTE_DEFINITIONS)
    doc.add_heading("2.2.2 Andmebaasioperatsioonide lepingud", level=3)
    for contract in OP_CONTRACTS:
        add_operation_contract(doc, contract)
    add_paragraphs(doc, [
        "Operatsioonilepingud on realiseeritud PostgreSQL funktsioonidena. Rakendus võib enne vormi saatmist teha kasutajakogemust parandavaid kontrolle, "
        "kuid lõplik otsus jääb andmebaasile. Vea korral tagastab PostgreSQL erindi, mille Flask kuvab kasutajale eestikeelse teatena.",
    ])
    doc.add_heading("2.2.3 Registri põhiobjekti seisundidiagramm", level=3)
    add_figure(doc, state, *DIAGRAMS[4])
    add_table(doc, state, "Treeningukorra lubatud seisundimuudatused", ["Algseisund", "Lõppseisund", "Tegutseja või käivitaja", "Kasutusjuht", "Eeltingimus", "Järeltingimus", "Mõjutatud olemid"], STATE_TRANSITIONS_SESSION)
    add_figure(doc, state, *DIAGRAMS[5])
    add_table(doc, state, "Registreeringu lubatud seisundimuudatused", ["Algseisund", "Lõppseisund", "Tegutseja või käivitaja", "Kasutusjuht", "Eeltingimus", "Järeltingimus", "Mõjutatud olemid"], STATE_TRANSITIONS_REGISTRATION)

    doc.add_page_break()
    doc.add_heading("2.3 CRUD maatriks", level=2)
    add_table(
        doc,
        state,
        "CRUD-maatriks põhiobjektide ja kesksete olemitüüpide lõikes",
        CRUD_HEADERS,
        CRUD_MAIN_MATRIX,
    )
    add_table(
        doc,
        state,
        "CRUD-maatriks suhteobjektide, ressursiobjektide ja klassifikaatorite lõikes",
        CRUD_HEADERS,
        CRUD_SUPPORT_MATRIX,
    )
    add_paragraphs(doc, [
        "Maatriksis on kõik kontseptuaalsetel skeemidel näidatud olemid. Treeninguliik, treener, treeningukord, registreering ja osalemine on nähtavad seal, kus kasutusjuht neid päriselt loeb või muudab. Tühistamine on käsitletud seisundimuutusena, mitte füüsilise kustutamisena; ootejärjekorra koht võib tühistamisel või edendamisel kaduda, sest see sõltub registreeringu seisundist.",
    ])

    doc.add_heading("3 Füüsiline disain", level=1)
    doc.add_heading("3.1 Rühmatreeningute funktsionaalse allsüsteemi vajatavate registrite füüsiline disain", level=2)
    add_figure(doc, state, *DIAGRAMS[7])
    add_paragraphs(doc, [
        "Paketi süsteem on esitatud EAP mudelis paketidiagrammina „Rühmatreeningute pädevusalad ja registrid”. DOCX-is toetavad sama jaotust süsteemi kontekst, õiguste ja andmebaasirutiinide diagramm ning rakenduse ja andmebaasi arhitektuuri diagramm.",
    ])
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
    add_paragraphs(doc, ["Andmebaas luuakse PostgreSQLis. Esitatav skript eeldab hindamiseks eraldatud olemasolevat andmebaasi, loob public skeemi uuesti ning lisab sinna vajalikud objektid."])
    doc.add_heading("4.2 Skeemid", level=2)
    add_paragraphs(doc, ["Käesolevas prototüübis kasutatakse public skeemi. Rakenduse ja vaatleja rollidele antakse õigused sellele skeemile."])
    doc.add_heading("4.3 Domeenid", level=2)
    add_paragraphs(doc, ["SQL loob korduvkasutatavad domeenid kood_10, e_meil_aadress ja ajakava_ajahetk. Domeenid kirjeldavad klassifikaatorikoode, e-posti aadressi salvestust ning ajakava ajatemplite vahemikku. Isiku nimeosad on tabelis piiritletud lühikesed tekstiveerud koos mittetühjuse kontrollidega."])
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
    add_paragraphs(doc, ["Validaatori live SQL režiim kutsub registreerimise, tühistamise, ootejärjekorra edendamise ja treeningukorra planeerimise funktsioone. Varustuse sobivust kontrollitakse on_ruum_sobiv_treeninguliigile abifunktsiooni kaudu. SQL skript sisaldab ka demoandmeid, mille põhjal saab rutiine käsitsi välja kutsuda."])
    doc.add_heading("4.10 Indeksid", level=2)
    doc.add_heading("4.10.1 Välisvõtmete veergudele lisatavad indeksid", level=3)
    add_paragraphs(doc, ["SQL lisab indeksid välisvõtmete veergudele, sh treeningukord.treeninguliigi_id, treeningukord.treener_e_meil, treeningukord.ruumi_kood, registreering.treeningukorra_id, registreering.klient_e_meil ning varustuse seostabelite varustuse_kood veerud."])
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
    add_paragraphs(doc, ["Päringuplaani kontrolliks sobib näiteks EXPLAIN SELECT treeningukorra_id, treeninguliigi_nimetus, vabu_kohti FROM avalikud_treeningukorrad WHERE vabu_kohti > 0. Vaade kasutab treeningukorra ja registreeringu indekseid ning koondab kinnitatud/ootejärjekorra loendusi."])
    doc.add_heading("4.16 Rollid ja kasutajad", level=2)
    add_paragraphs(doc, ["SQL proovib luua rollid jousaali_rakendus ja jousaali_vaatleja. Kui kasutajal puudub CREATE ROLE õigus, annab skript NOTICE teate ega katkesta põhiskeemi loomist."])
    doc.add_heading("4.17 Üleliigsete õiguste äravõtmine", level=2)
    add_paragraphs(doc, ["Skript proovib eemaldada PUBLIC rollilt public skeemi CREATE õiguse. Kui käivitajal puudub selleks õigus, väljastatakse NOTICE ning põhiskeemi loomist ei katkestata. Rakenduse roll ei saa tavapärastes õigustes põhitabelitesse otse INSERT, UPDATE või DELETE käske teha; andmeid muutvad töövood käivad PostgreSQL funktsioonide kaudu."])
    doc.add_heading("4.18 Õiguste jagamine", level=2)
    add_paragraphs(doc, ["Rakenduse roll saab skeemi kasutusõiguse, tabelite lugemisõiguse, järjestuste kasutusõiguse ja funktsioonide käivitamise õiguse. Vaatleja roll saab lugemisõiguse."])
    doc.add_heading("4.19 Andmebaasiobjektide kustutamine", level=2)
    add_paragraphs(doc, ["Kustutamislaused tuleb käivitada vastupidises sõltuvusjärjekorras: õigused, vaated, triggerid, funktsioonid, tabelid, domeenid, rollid. Esitatav loomisskript alustab public skeemi taasloomisega, mistõttu seda tuleb käivitada ainult hindamiseks eraldatud andmebaasis. Täiendav kustutamise näidisplokk on skripti lõpus kommentaaridena."])

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
        "Projekt ei käsitle enam treeningut kui töövihiku laadset kirjelduskaarti ega kogu jõusaali infosüsteemi. Keskne elutsükli objekt on registreering: "
        "registreering luuakse, kinnitatakse või paigutatakse ootejärjekorda, tühistatakse kliendi või süsteemi poolt ning edendatakse koha vabanemisel. "
        "Treeningukord, treeninguliik, isik, töötaja, klient ja treener on vajalikud põhiobjektid, kuid treener ei ole isikust ja töötajast eraldiseisev uus persooniobjekt. Andmebaas kontrollib mahutavust, kattuvaid aegu, treeneri pädevust, "
        "kohustuslikku varustust, registreerimise tähtaegu, seisundimuutusi ja ootejärjekorra edendamist.",
        "Lisaks mahutavusele ja pädevusele kontrollib andmebaas ka seda, et treeningukorra ruumis oleks treeninguliigi jaoks nõutav varustus. See ei muuda projekti inventarihalduseks, vaid lisab ajakava planeerimisele sisulise ruumi sobivuse reegli.",
        "Vaba teema nõue on täidetud valitud allsüsteemi sügavuse kaudu: töös on eraldi kasutajarollid, mitu seotud põhiobjekti, seisundimudelid, ootejärjekorra transaktsiooniline edendamine, ruumi ja treeneri kattuvuste kontroll, pädevuse kontroll, mahutavuse kontroll ning rollipõhised vaated. Seetõttu ei ole vaja modelleerida kõiki jõusaali võimalikke ärivaldkondi.",
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
