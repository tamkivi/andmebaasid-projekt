#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re
from typing import Iterable

from docx import Document
from docx.enum.section import WD_SECTION_START
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Inches, Pt, RGBColor
from PIL import Image, ImageDraw, ImageFont

from sql_ddl import SQL_DDL

ROOT = Path(__file__).resolve().parents[1]
DST = ROOT / "Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx"
DIAGRAM_DIR = ROOT / "work" / "generated_diagrams"


AUTHORS = "Tristan Aik Sild, Gustav Tamkivi"
AUTHOR_EMAIL = "gustavpaul@tamkivi.com"
SYSTEM_NAME = "Jõusaali infosüsteem"
SUBSYSTEM_NAME = "Treeningute funktsionaalne allsüsteem"
REGISTER_NAME = "Treeningute register"


ACTORS = [
    ("Treener", "Sisemine pädevusala", "Registreerib, muudab ja aktiveerib treeninguid."),
    ("Juhataja", "Sisemine pädevusala", "Jälgib treeningute portfelli ning lõpetab treeninguid."),
    ("Klient", "Väline pädevusala", "Soovib leida sobiva aktiivse treeningu ja sellel osaleda."),
    ("Uudistaja", "Väline pädevusala", "Soovib vaadata avalikult nähtavat treeningute infot."),
    ("Klassifikaatorite haldur", "Sisemine pädevusala", "Haldab klassifikaatoreid, sh treeningu seisundeid ja kategooriaid."),
    ("Töötajate haldur", "Sisemine pädevusala", "Haldab töötajate ja rollide põhiandmeid."),
    ("Maksekeskus", "Väline pädevusala", "Vahendab treeninguga seotud maksete kinnitusi."),
]


MAIN_OBJECTS = [
    ("Isik", "Jõusaali kliendi, töötaja või süsteemi kasutaja üldandmed."),
    ("Töötaja", "Jõusaali heaks töötav isik ja tema rollid."),
    ("Treening", "Jõusaalis pakutav treeninguteenus."),
    ("Broneering", "Kliendi kavatsus osaleda konkreetsel treeningul."),
    ("Makse", "Treeningu või broneeringuga seotud tasumise sündmus."),
    ("Klassifikaator", "Ühiselt hallatavad seisundid, tüübid ja kategooriad."),
]


SUBSYSTEMS_REGISTERS = [
    ("Isikute funktsionaalne allsüsteem", "Isikute register", "Isik"),
    ("Töötajate funktsionaalne allsüsteem", "Töötajate register", "Töötaja"),
    ("Treeningute funktsionaalne allsüsteem", "Treeningute register", "Treening"),
    ("Broneeringute funktsionaalne allsüsteem", "Broneeringute register", "Broneering"),
    ("Maksete funktsionaalne allsüsteem", "Maksete register", "Makse"),
    ("Klassifikaatorite funktsionaalne allsüsteem", "Klassifikaatorite register", "Klassifikaator"),
]


STATEMENTS = [
    "Treening on jõusaalis pakutav teenus.",
    "Treener registreerib treeningu.",
    "Juhataja lõpetab treeningu.",
    "Klient broneerib treeningul osalemise.",
    "Maksekeskus kinnitab makse.",
    "Klassifikaatorite haldur haldab klassifikaatoreid.",
    "Töötajate haldur haldab töötajaid.",
    "Treeningul on üks seisund.",
    "Treening kuulub nulli või mitmesse treeningu kategooriasse.",
]


PROCESSES = [
    ("Treeningu registreerimine", "Treener saab teabe uue treeningu kohta.", "Treening on ootel seisundis registreeritud."),
    ("Treeningu muutmine", "Treeningu andmetes ilmneb viga või muutus.", "Treeningu andmed on ajakohased."),
    ("Treeningu aktiveerimine", "Treening on valmis klientidele nähtavaks tegemiseks.", "Treening on aktiivne."),
    ("Treeningu ajutiselt kasutusest eemaldamine", "Treeninguga ilmneb ajutine probleem.", "Treening on mitteaktiivne."),
    ("Treeningu lõpetamine", "Treeningut ei pakuta enam või probleem on püsiv.", "Treening on lõppenud."),
    ("Treeningute vaatamine", "Klient või uudistaja soovib treeningute infot.", "Kasutaja näeb lubatud treeninguandmeid."),
    ("Treeningule broneerimine", "Klient soovib treeningul osaleda.", "Broneering ja vajaduse korral makse on registreeritud."),
]


HIGH_LEVEL_USE_CASES = [
    ("Tuvasta kasutaja", "Treener, Juhataja, Klassifikaatorite haldur, Töötajate haldur", "Kasutaja esitab süsteemile enda tuvastamiseks vajalikud andmed ning süsteem seob kasutaja tema pädevusalaga."),
    ("Registreeri treening", "Treener", "Treener registreerib uue treeningu põhiandmed ja seob treeningu sobivate kategooriatega."),
    ("Muuda treeningut", "Treener", "Treener muudab ootel või mitteaktiivse treeningu põhiandmeid ja kategooriaseoseid."),
    ("Unusta treening", "Treener", "Treener eemaldab ootel treeningu edasisest kasutusest, kui treeningut ei ole vaja pakkuda."),
    ("Aktiveeri treening", "Treener", "Treener muudab ootel või mitteaktiivse treeningu aktiivseks, kui treening kuulub vähemalt ühte kategooriasse."),
    ("Muuda treening mitteaktiivseks", "Treener", "Treener eemaldab aktiivse treeningu ajutiselt kasutusest, kui treeninguga on ilmnenud ajutine probleem."),
    ("Lõpeta treening", "Juhataja", "Juhataja lõpetab aktiivse või mitteaktiivse treeningu, kui treeningut enam ei pakuta."),
    ("Vaata aktiivseid treeninguid", "Klient, Uudistaja", "Klient või uudistaja vaatab aktiivsete treeningute avalikke andmeid."),
    ("Vaata kõiki treeninguid", "Juhataja", "Juhataja vaatab kõigi treeningute tööalaseid andmeid ja seisundeid."),
    ("Vaata kõiki ootel või mitteaktiivseid treeninguid", "Treener", "Treener vaatab ootel ja mitteaktiivseid treeninguid, et valida muutmiseks või aktiveerimiseks sobiv treening."),
    ("Vaata treeningute koondaruannet", "Juhataja", "Juhataja vaatab treeningute arvu seisundite ja kategooriate kaupa."),
]


OPERATIONS = [
    ("OP1", "Tuvasta kasutaja", ["Kasutajakonto on registreeritud."], ["Süsteem tuvastab kasutaja e-posti aadressi ja parooli alusel ning leiab kasutaja pädevusalad."]),
    ("OP2", "Leia treeningu kategooriate valik", ["Treener on autenditud ja autoriseeritud."], ["Süsteem tagastab aktiivsed treeningu kategooriad ning nende tüübid."]),
    ("OP3", "Registreeri treening", ["Treener on autenditud ja autoriseeritud.", "Valitud treeningu kategooriad on registreeritud."], ["Treening on registreeritud ootel seisundis.", "Treeningu registreerija ja viimane muutja on registreeritud.", "Treeningu kategooriaseosed on registreeritud."]),
    ("OP4", "Leia ootel treeningud", ["Treener on autenditud ja autoriseeritud."], ["Süsteem tagastab ootel treeningute nimekirja."]),
    ("OP5", "Leia ootel või mitteaktiivsed treeningud", ["Treener on autenditud ja autoriseeritud."], ["Süsteem tagastab ootel ja mitteaktiivsete treeningute nimekirja."]),
    ("OP6", "Unusta treening", ["Treening on ootel seisundis registreeritud."], ["Treeningu seisundiks saab unustatud.", "Viimase muutmise aeg ja muutja on registreeritud."]),
    ("OP7", "Leia muudetava treeningu detailandmed", ["Treening on ootel või mitteaktiivses seisundis registreeritud."], ["Süsteem tagastab treeningu põhiandmed ja kategooriaseosed."]),
    ("OP8", "Muuda treeningut", ["Treening on ootel või mitteaktiivses seisundis registreeritud."], ["Treeningu põhiandmed on muudetud.", "Treeningu kategooriaseosed vastavad sisendile.", "Viimase muutmise aeg ja muutja on registreeritud."]),
    ("OP9", "Lisa treeningu kategooria seos", ["Treening ja treeningu kategooria on registreeritud."], ["Treeningu ja kategooria seos on registreeritud."]),
    ("OP10", "Eemalda treeningu kategooria seos", ["Treeningu ja kategooria seos on registreeritud."], ["Treeningu ja kategooria seos on kustutatud."]),
    ("OP11", "Aktiveeri treening", ["Treening on ootel või mitteaktiivses seisundis.", "Treening kuulub vähemalt ühte treeningu kategooriasse."], ["Treeningu seisundiks saab aktiivne.", "Viimase muutmise aeg ja muutja on registreeritud."]),
    ("OP12", "Leia aktiivsed treeningud", ["Kasutaja kasutab avalikku või tööalast vaadet."], ["Süsteem tagastab aktiivsete treeningute lubatud andmed."]),
    ("OP13", "Muuda treening mitteaktiivseks", ["Treening on aktiivses seisundis."], ["Treeningu seisundiks saab mitteaktiivne.", "Viimase muutmise aeg ja muutja on registreeritud."]),
    ("OP14", "Leia kõik treeningud", ["Juhataja on autenditud ja autoriseeritud."], ["Süsteem tagastab kõigi treeningute tööalased andmed."]),
    ("OP15", "Lõpeta treening", ["Treening on aktiivses või mitteaktiivses seisundis."], ["Treeningu seisundiks saab lõppenud.", "Viimase muutmise aeg ja muutja on registreeritud."]),
    ("OP16", "Leia treeningute koondaruanne", ["Juhataja on autenditud ja autoriseeritud."], ["Süsteem tagastab treeningute arvu seisundite ja kategooriate kaupa."]),
]


EXTENDED_USE_CASES = [
    {
        "name": "Tuvasta kasutaja",
        "actor": "Treener",
        "stakeholders": [
            ("Treener", "Soovib pääseda enda tööülesannete täitmiseks lubatud kasutusjuhtudeni."),
            ("Juhataja", "Soovib, et süsteemi tööalaseid funktsioone kasutaksid ainult õigustatud kasutajad."),
        ],
        "trigger": "Kasutaja soovib alustada tööalase süsteemifunktsiooni kasutamist.",
        "pre": ["Kasutajakonto on registreeritud ja aktiivne."],
        "post": ["Kasutaja on autenditud ja tema pädevusalad on tuvastatud."],
        "steps": [
            ("Kasutaja avaldab soovi süsteemi siseneda.", ""),
            ("Süsteem kuvab tuvastamiseks vajaliku vormi.", ""),
            ("Kasutaja sisestab e-posti aadressi ja parooli.", ""),
            ("Süsteem tuvastab kasutaja ning leiab tema pädevusalad.", "OP1"),
        ],
        "extensions": [
            "4a. Kui kasutajakontot ei leita või parool ei vasta kontole, siis kasutajat ei autendita.",
            "4b. Kui kasutajakonto ei ole aktiivne, siis kasutajat ei autendita.",
        ],
    },
    {
        "name": "Registreeri treening",
        "actor": "Treener",
        "stakeholders": [
            ("Treener", "Soovib uue treeningu andmed kiiresti ja korrektselt registreerida."),
            ("Juhataja", "Soovib, et treeningute portfell oleks ajakohane."),
            ("Klient", "Soovib hiljem näha terviklikku infot aktiivsete treeningute kohta."),
        ],
        "trigger": "Treener saab teabe uue jõusaalis pakutava treeningu kohta.",
        "pre": ["Treener on autenditud ja autoriseeritud.", "Treeningu seisundi ja kategooria klassifikaatorid on registreeritud."],
        "post": ["Treening on registreeritud ootel seisundis.", "Treening on seotud valitud treeningu kategooriatega."],
        "steps": [
            ("Treener avaldab soovi registreerida uus treening.", ""),
            ("Süsteem kuvab treeningu sisestamiseks vajaliku vormi ning aktiivsed treeningu kategooriad.", "OP2"),
            ("Treener sisestab treeningu nimetuse, kirjelduse, kestuse, maksimaalse osalejate arvu, vajaliku varustuse, hinna ja kategooriad.", ""),
            ("Süsteem kontrollib sisestatud andmeid.", ""),
            ("Süsteem salvestab treeningu andmed ja kategooriaseosed.", "OP3"),
            ("Süsteem kuvab registreeritud treeningu detailandmed.", "OP7"),
        ],
        "extensions": [
            "4a. Kui kohustuslik väärtus puudub või ei vasta piirangule, siis salvestamine ebaõnnestub.",
            "5a. Kui sama nimetusega treening on juba registreeritud, siis salvestamine ebaõnnestub.",
        ],
    },
    {
        "name": "Muuda treeningut",
        "actor": "Treener",
        "stakeholders": [
            ("Treener", "Soovib parandada treeningu andmeid või ajakohastada kategooriaseoseid."),
            ("Juhataja", "Soovib, et treeningute register sisaldaks korrektseid tööandmeid."),
            ("Klient", "Soovib, et aktiivseks muutuvad treeningud oleksid sisuliselt õiged."),
        ],
        "trigger": "Treener märkab ootel või mitteaktiivse treeningu andmetes muutmise vajadust.",
        "pre": ["Treener on autenditud ja autoriseeritud.", "Treening on ootel või mitteaktiivses seisundis."],
        "post": ["Treeningu põhiandmed ja kategooriaseosed on ajakohased."],
        "steps": [
            ("Treener avaldab soovi muuta treeningu andmeid.", ""),
            ("Süsteem kuvab ootel ja mitteaktiivsed treeningud.", "OP5"),
            ("Treener valib muudetava treeningu.", ""),
            ("Süsteem kuvab valitud treeningu detailandmed ja kategooriaseosed.", "OP7"),
            ("Treener muudab treeningu põhiandmeid ning lisab või eemaldab kategooriaseoseid.", ""),
            ("Süsteem salvestab treeningu põhiandmete muudatused.", "OP8"),
            ("Süsteem salvestab lisatud kategooriaseosed.", "OP9"),
            ("Süsteem kustutab eemaldatud kategooriaseosed.", "OP10"),
        ],
        "extensions": [
            "2a. Kui süsteemis ei ole ühtegi ootel või mitteaktiivset treeningut, siis ei saa Treener jätkata.",
            "6a. Kui muudetud andmed ei vasta piirangutele, siis muudatuste salvestamine ebaõnnestub.",
        ],
    },
    {
        "name": "Unusta treening",
        "actor": "Treener",
        "stakeholders": [
            ("Treener", "Soovib eemaldada ootel treeningu edasisest töövoost."),
            ("Juhataja", "Soovib, et treeningute portfell ei sisaldaks realiseerumata ettepanekuid."),
        ],
        "trigger": "Treener saab teabe, et ootel treeningut ei hakata pakkuma.",
        "pre": ["Treener on autenditud ja autoriseeritud.", "Treening on ootel seisundis."],
        "post": ["Treening on unustatud seisundis."],
        "steps": [
            ("Treener avaldab soovi unustada treening.", ""),
            ("Süsteem kuvab ootel treeningud.", "OP4"),
            ("Treener valib unustatava treeningu.", ""),
            ("Süsteem salvestab treeningu seisundimuudatuse.", "OP6"),
            ("Süsteem eemaldab unustatud treeningu ootel treeningute nimekirjast.", "OP4"),
        ],
        "extensions": [
            "2a. Kui süsteemis ei ole ühtegi ootel treeningut, siis ei saa Treener treeningut unustada.",
        ],
    },
    {
        "name": "Aktiveeri treening",
        "actor": "Treener",
        "stakeholders": [
            ("Treener", "Soovib valmis treeningu klientidele nähtavaks teha."),
            ("Klient", "Soovib näha ainult pakutavaid ja osalemiseks sobivaid treeninguid."),
            ("Juhataja", "Soovib, et avalikus vaates oleks ainult kontrollitud treeningud."),
        ],
        "trigger": "Treener otsustab, et ootel või mitteaktiivne treening on valmis aktiivseks muutmiseks.",
        "pre": ["Treener on autenditud ja autoriseeritud.", "Treening on ootel või mitteaktiivses seisundis."],
        "post": ["Treening on aktiivses seisundis."],
        "steps": [
            ("Treener avaldab soovi aktiveerida treening.", ""),
            ("Süsteem kuvab ootel ja mitteaktiivsed treeningud.", "OP5"),
            ("Treener valib nimekirjast treeningu.", ""),
            ("Süsteem kontrollib, et treening kuulub vähemalt ühte treeningu kategooriasse.", "OP7"),
            ("Süsteem salvestab treeningu seisundimuudatuse.", "OP11"),
            ("Süsteem kuvab muudetud treeningu detailandmed.", "OP7"),
        ],
        "extensions": [
            "3a. Kui nimekirjas ei ole ühtegi ootel või mitteaktiivset treeningut, siis ei saa Treener jätkata.",
            "4a. Kui treening ei kuulu ühtegi treeningu kategooriasse, siis aktiveerimine ebaõnnestub.",
        ],
    },
    {
        "name": "Muuda treening mitteaktiivseks",
        "actor": "Treener",
        "stakeholders": [
            ("Treener", "Soovib ajutise probleemiga treeningu klientidele nähtavast pakkumisest eemaldada."),
            ("Klient", "Soovib näha ainult tegelikult pakutavaid aktiivseid treeninguid."),
            ("Juhataja", "Soovib, et treeningute avalik pakkumine oleks kontrollitud."),
        ],
        "trigger": "Treener saab teabe aktiivse treeningu ajutisest probleemist.",
        "pre": ["Treener on autenditud ja autoriseeritud.", "Treening on aktiivses seisundis."],
        "post": ["Treening on mitteaktiivses seisundis."],
        "steps": [
            ("Treener avaldab soovi muuta treening mitteaktiivseks.", ""),
            ("Süsteem kuvab aktiivsed treeningud.", "OP12"),
            ("Treener valib mitteaktiivseks muudetava treeningu.", ""),
            ("Süsteem salvestab treeningu seisundimuudatuse.", "OP13"),
            ("Süsteem eemaldab treeningu aktiivsete treeningute avalikust nimekirjast.", "OP12"),
        ],
        "extensions": [
            "2a. Kui süsteemis ei ole ühtegi aktiivset treeningut, siis ei saa Treener treeningut mitteaktiivseks muuta.",
        ],
    },
    {
        "name": "Lõpeta treening",
        "actor": "Juhataja",
        "stakeholders": [
            ("Juhataja", "Soovib eemaldada püsivalt treeningu, mida jõusaal enam ei paku."),
            ("Treener", "Soovib, et treeningute nimekiri ei sisaldaks kasutusest väljas teenuseid."),
            ("Klient", "Soovib näha ainult tegelikult pakutavaid aktiivseid treeninguid."),
        ],
        "trigger": "Juhataja saab teabe, et treeningut enam ei pakuta või selle probleem on püsiv.",
        "pre": ["Juhataja on autenditud ja autoriseeritud.", "Treening on aktiivses või mitteaktiivses seisundis."],
        "post": ["Treening on lõppenud seisundis."],
        "steps": [
            ("Juhataja avaldab soovi lõpetada treening.", ""),
            ("Süsteem kuvab kõik treeningud koos seisunditega.", "OP14"),
            ("Juhataja valib lõpetatava treeningu.", ""),
            ("Süsteem salvestab treeningu seisundimuudatuse.", "OP15"),
            ("Süsteem kuvab lõpetatud treeningu detailandmed.", "OP14"),
        ],
        "extensions": [
            "2a. Kui süsteemis ei ole ühtegi aktiivset ega mitteaktiivset treeningut, siis ei saa Juhataja treeningut lõpetada.",
        ],
    },
    {
        "name": "Vaata aktiivseid treeninguid",
        "actor": "Klient",
        "stakeholders": [
            ("Klient", "Soovib leida sobiva aktiivse treeningu."),
            ("Uudistaja", "Soovib näha jõusaali avalikku treeninguvalikut."),
            ("Juhataja", "Soovib, et avalikult nähtav treeninguinfo oleks ajakohane."),
        ],
        "trigger": "Klient või uudistaja soovib vaadata pakutavaid treeninguid.",
        "pre": ["Aktiivsete treeningute avalik vaade on kasutatav."],
        "post": ["Aktiivsete treeningute lubatud andmed on kasutajale kuvatud."],
        "steps": [
            ("Klient või uudistaja avaldab soovi vaadata aktiivseid treeninguid.", ""),
            ("Süsteem kuvab aktiivsete treeningute nimekirja.", "OP12"),
            ("Klient või uudistaja valib treeningu, mille andmeid ta soovib täpsemalt vaadata.", ""),
            ("Süsteem kuvab valitud aktiivse treeningu lubatud detailandmed.", "OP12"),
        ],
        "extensions": [
            "2a. Kui aktiivseid treeninguid ei ole, siis kuvab süsteem tühja nimekirja.",
        ],
    },
    {
        "name": "Vaata treeningute koondaruannet",
        "actor": "Juhataja",
        "stakeholders": [
            ("Juhataja", "Soovib saada ülevaadet treeningute jaotusest seisundite ning kategooriate kaupa."),
            ("Treener", "Soovib, et juhtimisotsused põhineksid ajakohastel andmetel."),
        ],
        "trigger": "Juhataja soovib hinnata treeningute portfelli hetkeseisu.",
        "pre": ["Juhataja on autenditud ja autoriseeritud."],
        "post": ["Koondaruanne on Juhatajale kuvatud."],
        "steps": [
            ("Juhataja avaldab soovi vaadata treeningute koondaruannet.", ""),
            ("Süsteem kuvab treeningute arvu seisundite ja kategooriate kaupa.", "OP16"),
        ],
        "extensions": [
            "2a. Kui aruande aluseks olevaid treeninguid ei ole, siis kuvab süsteem nullväärtustega koondvaate.",
        ],
    },
]


ENTITIES = [
    ("Treening", "Treeningute registri põhiobjekt.", "treeningu_kood"),
    ("Treeningu_seisundi_liik", "Klassifikaator, mis kirjeldab treeningu elutsükli seisundit.", "kood"),
    ("Treeningu_kategooria", "Klassifikaator, millega treeninguid rühmitatakse.", "kood"),
    ("Treeningu_kategooria_tüüp", "Klassifikaatorite tüüpe kirjeldav klassifikaator.", "kood"),
    ("Treeningu_kategooria_omamine", "Seos treeningu ja treeningu kategooria vahel.", "treeningu_kood + treeningu_kategooria_kood"),
    ("Isik", "Isikute registri põhiobjekt.", "isikukood + riigi_kood"),
    ("Töötaja", "Töötajate registri põhiobjekt.", "e_meil"),
    ("Kasutajakonto", "Autentimiseks kasutatav konto.", "e_meil"),
]


ATTRIBUTES = [
    ("Treening", "treeningu_kood", "Treeningu arvuline kood.", "Kohustuslik. Positiivne täisarv. Unikaalne."),
    ("Treening", "nimetus", "Treeningu ametlik nimetus.", "Kohustuslik. Mittetühi. Unikaalne."),
    ("Treening", "kirjeldus", "Treeningu sisu kirjeldus.", "Kohustuslik. Mittetühi."),
    ("Treening", "kestus_minutites", "Treeningu kestus minutites.", "Kohustuslik. Vahemikus 15 kuni 240."),
    ("Treening", "maksimaalne_osalejate_arv", "Treeningule lubatud osalejate arv.", "Kohustuslik. Positiivne täisarv."),
    ("Treening", "vajalik_varustus", "Treeningul vajalik varustus.", "Kohustuslik. Mittetühi."),
    ("Treening", "hind", "Treeningu hind eurodes.", "Kohustuslik. Null või positiivne arv."),
    ("Treening", "reg_aeg", "Treeningu registreerimise aeg.", "Kohustuslik. Küsitakse süsteemi kellalt."),
    ("Treening", "viimase_muutm_aeg", "Treeningu viimase muutmise aeg.", "Kohustuslik. Ei tohi olla varasem kui registreerimise aeg."),
    ("Isik", "synni_kp", "Isiku sünnikuupäev.", "Kohustuslik. Vahemikus 01.01.1900 kuni 31.12.2100."),
    ("Isik", "e_meil", "Isiku e-posti aadress.", "Kohustuslik. Sisaldab @ märki. Unikaalne."),
]


BUSINESS_RULES = [
    "Treeningu nimetus peab olema treeningute registris unikaalne.",
    "Treeningu saab aktiivseks muuta ainult siis, kui treening kuulub vähemalt ühte treeningu kategooriasse.",
    "Aktiivne treening peab olema seotud aktiivse treeningu seisundi liigiga.",
    "Treeningu kestus peab olema 15 kuni 240 minutit.",
    "Treeningu maksimaalne osalejate arv peab olema positiivne täisarv.",
    "Treeningu hind peab olema null või positiivne rahasumma.",
    "Treeningu viimase muutmise aeg ei tohi olla varasem kui treeningu registreerimise aeg.",
]


NFR = [
    ("Kasutajaliides", "Süsteemi kasutajaliides peab olema eestikeelne ning kasutama kogu treeningute funktsionaalses allsüsteemis samu mõisteid."),
    ("Kasutajaliides", "Vormides peab kohustuslikke välju eristama enne andmete salvestamist."),
    ("Turvalisus", "Treeneri ja juhataja kasutusjuhud peavad olema kasutatavad ainult autenditud ja autoriseeritud kasutajatele."),
    ("Turvalisus", "Paroole ei tohi salvestada avatekstina."),
    ("Turvalisus", "Treeningu muutmise ja seisundimuutmise operatsioonide juures tuleb säilitada viimase muutja e-posti aadress ning muutmise aeg."),
    ("Töökindlus", "Treeningute registri varukoopia tuleb teha vähemalt üks kord ööpäevas."),
    ("Jõudlus", "Aktiivsete treeningute nimekirja päring peab tavalise koormuse korral vastama kuni kahe sekundiga."),
]


@dataclass
class CaptionCounter:
    figures: int = 0
    tables: int = 0


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "",
        "/Library/Fonts/Arial.ttf",
    ]
    for path in candidates:
        if path and Path(path).exists():
            try:
                return ImageFont.truetype(path, size=size)
            except OSError:
                pass
    return ImageFont.load_default()


def draw_centered(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], text: str, fill: str, fnt: ImageFont.ImageFont) -> None:
    lines = wrap_text(draw, text, fnt, max_width=box[2] - box[0] - 18)
    heights = [draw.textbbox((0, 0), line, font=fnt)[3] for line in lines]
    total = sum(heights) + max(0, len(lines) - 1) * 4
    y = box[1] + ((box[3] - box[1]) - total) // 2
    for line, height in zip(lines, heights):
        width = draw.textbbox((0, 0), line, font=fnt)[2]
        draw.text((box[0] + ((box[2] - box[0]) - width) // 2, y), line, fill=fill, font=fnt)
        y += height + 4


def wrap_text(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.ImageFont, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        if draw.textbbox((0, 0), candidate, font=fnt)[2] <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines or [text]


def draw_box(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], text: str, fill: str = "#eef4ff", outline: str = "#1f4e79") -> None:
    draw.rounded_rectangle(box, radius=10, fill=fill, outline=outline, width=2)
    draw_centered(draw, box, text, "#1b1b1b", font(22))


def draw_arrow(draw: ImageDraw.ImageDraw, start: tuple[int, int], end: tuple[int, int], fill: str = "#555555") -> None:
    draw.line([start, end], fill=fill, width=3)
    ex, ey = end
    sx, sy = start
    if abs(ex - sx) >= abs(ey - sy):
        direction = 1 if ex > sx else -1
        points = [(ex, ey), (ex - 14 * direction, ey - 8), (ex - 14 * direction, ey + 8)]
    else:
        direction = 1 if ey > sy else -1
        points = [(ex, ey), (ex - 8, ey - 14 * direction), (ex + 8, ey - 14 * direction)]
    draw.polygon(points, fill=fill)


def make_diagrams() -> list[tuple[Path, str]]:
    DIAGRAM_DIR.mkdir(parents=True, exist_ok=True)
    diagrams: list[tuple[Path, str]] = []

    specs = [
        ("01_architecture.png", "Jõusaali infosüsteemi põhiobjektid ja registrid", ["Isik", "Töötaja", "Treening", "Broneering", "Makse", "Klassifikaator"], "ring"),
        ("02_use_cases.png", "Treeningute funktsionaalse allsüsteemi kasutusjuhud", ["Treener", "Registreeri", "Muuda", "Aktiveeri", "Juhataja", "Lõpeta", "Aruanne", "Klient", "Vaata aktiivseid"], "usecase"),
        ("03_activity_register.png", "Treeningu registreerimise tegevusvoog", ["Algus", "Sisesta andmed", "Kontrolli", "Salvesta", "Kuva detailandmed", "Lõpp"], "flow"),
        ("04_activity_activate.png", "Treeningu aktiveerimise tegevusvoog", ["Algus", "Vali treening", "Kontrolli kategooriat", "Muuda aktiivseks", "Lõpp"], "flow"),
        ("05_conceptual.png", "Treeningute registri kontseptuaalne eskiismudel", ["Treening", "Treeningu_seisundi_liik", "Treeningu_kategooria", "Treeningu_kategooria_tüüp", "Töötaja"], "model"),
        ("06_state.png", "Treeningu seisundidiagramm", ["Ootel", "Aktiivne", "Mitteaktiivne", "Lõppenud", "Unustatud"], "state"),
        ("07_physical.png", "Treeningute registri füüsiline andmemudel", ["treening", "treeningu_seisundi_liik", "treeningu_kategooria", "treeningu_kategooria_omamine", "kasutajakonto"], "model"),
    ]

    for filename, title, items, kind in specs:
        path = DIAGRAM_DIR / filename
        img = Image.new("RGB", (1400, 850), "#ffffff")
        draw = ImageDraw.Draw(img)
        draw.text((50, 38), title, fill="#203040", font=font(34, bold=True))
        if kind == "ring":
            coords = [(120, 170), (500, 170), (880, 170), (120, 470), (500, 470), (880, 470)]
            for (x, y), item in zip(coords, items):
                draw_box(draw, (x, y, x + 300, y + 120), item)
            draw_arrow(draw, (420, 230), (500, 230))
            draw_arrow(draw, (800, 230), (880, 230))
            draw_arrow(draw, (270, 290), (270, 470))
            draw_arrow(draw, (650, 290), (650, 470))
            draw_arrow(draw, (1030, 290), (1030, 470))
        elif kind == "usecase":
            actor_boxes = [(80, 170, 290, 260), (80, 430, 290, 520), (80, 610, 290, 700)]
            usecase_boxes = [(440, 145, 710, 235), (760, 145, 1030, 235), (1080, 145, 1320, 235), (440, 410, 710, 500), (760, 410, 1030, 500), (440, 605, 710, 695)]
            for box, item in zip(actor_boxes, ["Treener", "Juhataja", "Klient ja Uudistaja"]):
                draw_box(draw, box, item, "#fff3df", "#9a5b00")
            for box, item in zip(usecase_boxes, ["Registreeri treening", "Muuda treeningut", "Aktiveeri treening", "Lõpeta treening", "Vaata aruannet", "Vaata aktiivseid"]):
                draw.ellipse(box, fill="#eef4ff", outline="#1f4e79", width=3)
                draw_centered(draw, box, item, "#1b1b1b", font(20))
            for end in [(440, 190), (760, 190), (1080, 190)]:
                draw_arrow(draw, (290, 215), end)
            for end in [(440, 455), (760, 455)]:
                draw_arrow(draw, (290, 475), end)
            draw_arrow(draw, (290, 655), (440, 650))
        elif kind == "state":
            coords = [(105, 330), (390, 190), (390, 480), (735, 330), (1035, 330)]
            for (x, y), item in zip(coords, items):
                draw_box(draw, (x, y, x + 230, y + 105), item, "#f2f7ed", "#3d6b2f")
            draw_arrow(draw, (335, 382), (390, 245))
            draw_arrow(draw, (335, 382), (390, 535))
            draw_arrow(draw, (620, 245), (735, 382))
            draw_arrow(draw, (620, 535), (735, 382))
            draw_arrow(draw, (965, 382), (1035, 382))
        elif kind == "flow":
            x = 70
            box_width = 170
            step_width = 220
            boxes = []
            for item in items:
                boxes.append((x, 320, x + box_width, 430, item))
                x += step_width
            for left, top, right, bottom, item in boxes:
                draw_box(draw, (left, top, right, bottom), item, "#f8fbff", "#1f4e79")
            for first, second in zip(boxes, boxes[1:]):
                draw_arrow(draw, (first[2], 375), (second[0], 375))
        else:
            coords = [(90, 160), (495, 160), (900, 160), (290, 470), (710, 470)]
            for (x, y), item in zip(coords, items):
                draw_box(draw, (x, y, x + 310, y + 120), item)
            draw_arrow(draw, (400, 220), (495, 220))
            draw_arrow(draw, (805, 220), (900, 220))
            draw_arrow(draw, (245, 280), (445, 470))
            draw_arrow(draw, (650, 280), (865, 470))
        img.save(path)
        diagrams.append((path, title))
    return diagrams


def set_cell_shading(cell, fill: str) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), fill)
    tc_pr.append(shd)


def set_repeat_table_header(row) -> None:
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def style_table(table) -> None:
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    header = table.rows[0]
    set_repeat_table_header(header)
    for cell in header.cells:
        set_cell_shading(cell, "D9EAF7")
        for p in cell.paragraphs:
            for run in p.runs:
                run.bold = True
    for row in table.rows:
        for cell in row.cells:
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.TOP


def add_table(doc: Document, caption: str, headers: list[str], rows: list[Iterable[str]], counter: CaptionCounter):
    counter.tables += 1
    p = doc.add_paragraph(f"Tabel {counter.tables}. {caption}", style="Caption")
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    table = doc.add_table(rows=1, cols=len(headers))
    style_table(table)
    for i, header in enumerate(headers):
        table.rows[0].cells[i].text = header
    for row_data in rows:
        row = table.add_row()
        for i, value in enumerate(row_data):
            row.cells[i].text = str(value)
    doc.add_paragraph()
    return table


def add_figure(doc: Document, image_path: Path, caption: str, counter: CaptionCounter) -> None:
    counter.figures += 1
    paragraph = doc.add_paragraph()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = paragraph.add_run()
    run.add_picture(str(image_path), width=Inches(6.6))
    cp = doc.add_paragraph(f"Joonis {counter.figures}. {caption}", style="Caption")
    cp.alignment = WD_ALIGN_PARAGRAPH.CENTER


def bullet_list(doc: Document, items: Iterable[str]) -> None:
    for item in items:
        doc.add_paragraph(item, style="List Bullet")


def number_list(doc: Document, items: Iterable[str]) -> None:
    for item in items:
        doc.add_paragraph(item, style="List Number")


def add_heading(doc: Document, text: str, level: int) -> None:
    doc.add_heading(text, level=level)


def setup_document() -> Document:
    doc = Document()
    section = doc.sections[0]
    section.start_type = WD_SECTION_START.NEW_PAGE
    section.page_width = Cm(21)
    section.page_height = Cm(29.7)
    section.left_margin = Cm(2.5)
    section.right_margin = Cm(2.0)
    section.top_margin = Cm(2.0)
    section.bottom_margin = Cm(2.0)

    styles = doc.styles
    styles["Normal"].font.name = "Arial"
    styles["Normal"]._element.rPr.rFonts.set(qn("w:eastAsia"), "Arial")
    styles["Normal"].font.size = Pt(10.5)
    for style_name, size in [("Title", 20), ("Heading 1", 16), ("Heading 2", 13), ("Heading 3", 11)]:
        style = styles[style_name]
        style.font.name = "Arial"
        style._element.rPr.rFonts.set(qn("w:eastAsia"), "Arial")
        style.font.size = Pt(size)
        style.font.color.rgb = RGBColor(31, 78, 121)
    styles["Caption"].font.name = "Arial"
    styles["Caption"].font.size = Pt(9)
    styles["Caption"].font.italic = True
    return doc


def add_title_page(doc: Document) -> None:
    for _ in range(4):
        doc.add_paragraph()
    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = title.add_run(f"{SYSTEM_NAME}\n{SUBSYSTEM_NAME.lower()}")
    run.bold = True
    run.font.size = Pt(20)
    run.font.color.rgb = RGBColor(31, 78, 121)
    doc.add_paragraph()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.add_run("Süsteemianalüüsi ja andmebaasi disaini projekt").bold = True
    doc.add_paragraph()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.add_run(f"Autorid: {AUTHORS}\nE-post: {AUTHOR_EMAIL}\nTallinn 2026")
    doc.add_page_break()


def add_contents(doc: Document, counter: CaptionCounter) -> None:
    add_heading(doc, "Sisukord", 1)
    doc.add_paragraph("Sisukord on esitatud dokumendi struktuurse ülevaatena. Leheküljenumbreid ei hoita käsitsi, et vältida aegunud viiteid pärast dokumendi taastootmist.")
    rows = [
        ("1", "Sissejuhatus"),
        ("2", "Süsteemi üldvaade"),
        ("3", "Mittefunktsionaalsed nõuded"),
        ("4", "Kasutusjuhud"),
        ("5", "Treeningute registri eskiismudel"),
        ("6", "Operatsioonilepingud"),
        ("7", "Andmemudel ja füüsiline disain"),
        ("8", "Reprodutseerimine ja kontroll"),
    ]
    add_table(doc, "Dokumendi peatükkide ülevaade", ["Peatükk", "Pealkiri"], rows, counter)
    doc.add_page_break()


def add_overview(doc: Document, counter: CaptionCounter, diagrams: list[tuple[Path, str]]) -> None:
    add_heading(doc, "1 Sissejuhatus", 1)
    doc.add_paragraph("Dokument kirjeldab jõusaali infosüsteemi treeningute funktsionaalset allsüsteemi ning selle allsüsteemi toetavat treeningute registrit.")
    add_heading(doc, "1.1 Organisatsiooni kirjeldus", 2)
    doc.add_paragraph("Jõusaal pakub klientidele rühmatreeninguid, personaaltreeninguid ja muid treeninguteenuseid. Organisatsiooni igapäevane töö sõltub sellest, et treeningute info oleks täpne, kontrollitud ja klientidele õigel ajal kättesaadav.")
    add_heading(doc, "1.2 Organisatsiooni eesmärgid", 2)
    bullet_list(doc, [
        "Pakkuda klientidele kvaliteetseid ja ajakohase kavaga treeninguteenuseid.",
        "Suurendada klientide järjepidevat treeningutes osalemist.",
        "Toetada treenerite töö planeerimist ja treeningute portfelli juhtimist.",
        "Võimaldada juhtkonnal hinnata treeningute valikut ja selle muutumist.",
    ])

    add_heading(doc, "2 Süsteemi üldvaade", 1)
    doc.add_paragraph("Süsteemi üldvaade seob organisatsiooni eesmärgid põhiobjektide, pädevusalade, registrite ja põhiprotsessidega.")
    add_figure(doc, diagrams[0][0], diagrams[0][1], counter)

    add_heading(doc, "2.1 Infosüsteemi eesmärgid", 2)
    bullet_list(doc, [
        "Võimaldada treeningut elektrooniliselt registreerida, muuta ja seisundite kaudu juhtida.",
        "Säilitada treeningute kohta andmeid mahus, mis toetab treeningute pakkumist, broneerimist ja aruandlust.",
        "Tagada aktiivsete treeningute ajakohane avalik kuvamine klientidele ja uudistajatele.",
        "Võimaldada treeningute andmete kasutamist broneeringute ja maksete protsessides.",
        "Võimaldada juhtkonnal vaadata treeningute koondaruannet seisundite ja kategooriate kaupa.",
    ])

    add_heading(doc, "2.2 Põhiobjektid", 2)
    add_table(doc, "Põhiobjektid", ["Põhiobjekt", "Selgitus"], MAIN_OBJECTS, counter)

    add_heading(doc, "2.3 Tegutsejad ja pädevusalad", 2)
    add_table(doc, "Tegutsejad ja pädevusalad", ["Tegutseja", "Pädevusala liik", "Huvi"], ACTORS, counter)

    add_heading(doc, "2.4 Funktsionaalsed allsüsteemid ja registrid", 2)
    add_table(doc, "Funktsionaalsete allsüsteemide ja registrite vastavus", ["Funktsionaalne allsüsteem", "Register", "Põhiobjekt"], SUBSYSTEMS_REGISTERS, counter)

    add_heading(doc, "2.5 Põhiprotsessid ja käivitavad sündmused", 2)
    add_table(doc, "Põhiprotsessid", ["Põhiprotsess", "Käivitav sündmus", "Tulemus"], PROCESSES, counter)

    add_heading(doc, "2.6 Lausendid", 2)
    number_list(doc, STATEMENTS)


def add_nfr(doc: Document, counter: CaptionCounter) -> None:
    add_heading(doc, "3 Mittefunktsionaalsed nõuded", 1)
    doc.add_paragraph("Mittefunktsionaalsed nõuded kirjeldavad süsteemi kvaliteediomadusi ja tehnilisi piiranguid, mitte eraldiseisvaid ärifunktsioone.")
    add_table(doc, "Mittefunktsionaalsed nõuded", ["Alajaotus", "Nõue"], NFR, counter)


def add_use_cases(doc: Document, counter: CaptionCounter, diagrams: list[tuple[Path, str]]) -> None:
    add_heading(doc, "4 Kasutusjuhud", 1)
    doc.add_paragraph("Kasutusjuhud kirjeldavad treeningute funktsionaalse allsüsteemi kasutajale nähtavat käitumist ja süsteemi vastuseid.")
    add_figure(doc, diagrams[1][0], diagrams[1][1], counter)

    add_heading(doc, "4.1 Kõrgtaseme kasutusjuhud", 2)
    add_table(doc, "Kõrgtaseme kasutusjuhud", ["Kasutusjuht", "Tegutsejad", "Kirjeldus"], HIGH_LEVEL_USE_CASES, counter)

    add_heading(doc, "4.2 Laiendatud kasutusjuhud", 2)
    for uc in EXTENDED_USE_CASES:
        add_heading(doc, f"4.2 {uc['name']}", 3)
        add_table(doc, f"Laiendatud kasutusjuht: {uc['name']}", ["Väli", "Sisu"], [
            ("Kasutusjuht", uc["name"]),
            ("Primaarne tegutseja", uc["actor"]),
            ("Käivitav sündmus", uc["trigger"]),
            ("Eeltingimused", "\n".join(uc["pre"])),
            ("Järeltingimused", "\n".join(uc["post"])),
        ], counter)
        add_table(doc, f"Osapooled ja nende huvid: {uc['name']}", ["Osapool", "Huvi"], uc["stakeholders"], counter)
        add_table(doc, f"Stsenaarium: {uc['name']}", ["Samm", "Tegevus", "Operatsioon"], [(i + 1, step, op) for i, (step, op) in enumerate(uc["steps"])], counter)
        add_table(doc, f"Laiendused: {uc['name']}", ["Laiendus"], [(item,) for item in uc["extensions"]], counter)

    add_figure(doc, diagrams[2][0], diagrams[2][1], counter)
    add_figure(doc, diagrams[3][0], diagrams[3][1], counter)


def add_register_model(doc: Document, counter: CaptionCounter, diagrams: list[tuple[Path, str]]) -> None:
    add_heading(doc, "5 Treeningute registri eskiismudel", 1)
    doc.add_paragraph("Treeningute register on treeningute funktsionaalse allsüsteemi põhiregister. Register kasutab töötajate, isikute ja klassifikaatorite registrites olevaid andmeid.")
    add_heading(doc, "5.1 Registri seosed", 2)
    add_table(doc, "Treeningute registri eskiismudeli seosed", ["Nimekiri", "Väärtused"], [
        ("Registrit kasutavad pädevusalad", "Treener; Juhataja; Klient; Uudistaja"),
        ("Registrit teenindavad funktsionaalsed allsüsteemid", "Treeningute funktsionaalne allsüsteem"),
        ("Selle registriga seotud registrid", "Isikute register; Töötajate register; Broneeringute register; Maksete register; Klassifikaatorite register"),
    ], counter)
    add_heading(doc, "5.2 Ärireeglid", 2)
    number_list(doc, BUSINESS_RULES)
    add_heading(doc, "5.3 Kontseptuaalne eskiismudel", 2)
    add_figure(doc, diagrams[4][0], diagrams[4][1], counter)


def add_operations(doc: Document, counter: CaptionCounter) -> None:
    add_heading(doc, "6 Operatsioonilepingud", 1)
    doc.add_paragraph("Operatsioonilepingud on koostatud lepingprojekteerimise põhimõttel ning nende tähised vastavad kasutusjuhtudes kasutatud viidetele.")
    for op_id, name, pre, post in OPERATIONS:
        add_heading(doc, f"{op_id} {name}", 2)
        add_table(doc, f"Andmebaasioperatsiooni leping: {op_id}", ["Osa", "Sisu"], [
            ("Operatsioon", f"{op_id} {name}"),
            ("Eeltingimused", "\n".join(pre)),
            ("Järeltingimused", "\n".join(post)),
            ("Kasutus kasutusjuhtude poolt", ", ".join(sorted({uc["name"] for uc in EXTENDED_USE_CASES if any(op_id == op for _, op in uc["steps"])})) or "Tööalane abipäring"),
        ], counter)


def add_data_design(doc: Document, counter: CaptionCounter, diagrams: list[tuple[Path, str]]) -> None:
    add_heading(doc, "7 Andmemudel ja füüsiline disain", 1)
    doc.add_paragraph("Andmemudel kirjeldab treeningute registri loogilisi olemitüüpe ning PostgreSQL füüsilist realisatsiooni.")
    add_heading(doc, "7.1 Olemid ja atribuudid", 2)
    add_table(doc, "Olemitüübid", ["Olemitüüp", "Definitsioon", "Identifikaator"], ENTITIES, counter)
    add_table(doc, "Atribuutide definitsioonid", ["Olemitüüp", "Atribuut", "Definitsioon", "Piirangud"], ATTRIBUTES, counter)
    add_heading(doc, "7.2 Seisundimudel", 2)
    add_figure(doc, diagrams[5][0], diagrams[5][1], counter)
    add_heading(doc, "7.3 Füüsiline mudel", 2)
    add_figure(doc, diagrams[6][0], diagrams[6][1], counter)
    add_heading(doc, "7.4 SQL DDL", 2)
    doc.add_paragraph("Järgmine DDL on PostgreSQL jaoks koostatud ning seda kasutatakse projekti kontrollis.")
    for line in SQL_DDL.strip().splitlines():
        display_line = line.replace("REFERENCES", "references")
        p = doc.add_paragraph()
        run = p.add_run(display_line)
        run.font.name = "Courier New"
        run._element.rPr.rFonts.set(qn("w:eastAsia"), "Courier New")
        run.font.size = Pt(8)


def add_reproducibility(doc: Document, counter: CaptionCounter) -> None:
    add_heading(doc, "8 Reprodutseerimine ja kontroll", 1)
    doc.add_paragraph("Projekt on taastoodetav jälgitavatest lähtefailidest. Lõppartefaktid genereeritakse skriptiga, mis loob DOCX dokumendi, teisendab EAP malli ja rakendab EAP parandused.")
    add_table(doc, "Taastootmise sisendid ja väljundid", ["Fail või kataloog", "Roll"], [
        ("instruction_guides/", "Kursuse juhendid, näidisprojekt ja tüüpvigade dokument."),
        ("preset_files/EA_mall_AB_projekt_Eeltaidetud_2026.eap", "EAP lähtebaas, millest lõplik mudel teisendatakse."),
        ("tools/fill_report_docx.py", "Struktureeritud DOCX dokumendi generaator."),
        ("tools/EapConvert.java", "EAP malli teisendaja kirjutatavasse Access 2000 vormingusse."),
        ("tools/EapRename.java ja tools/EapFixes.java", "EAP mudeli nime- ja sisuparandused."),
        ("tools/sql_ddl.py", "PostgreSQL DDL lähtefail."),
        ("tools/validate_project.py", "Automaatne kontrollskript."),
        ("build_all.sh või build_all.bat", "Lõppartefaktide taastootmine puhtast kloonist."),
    ], counter)


def validate_text_sanity(doc: Document) -> None:
    text = "\n".join(p.text for p in doc.paragraphs)
    forbidden = ["HYPERLINK", "PAGEREF", "MERGEFORMAT", "<täienda", "<Siia", "<abc>"]
    found = [item for item in forbidden if item in text]
    if found:
        raise ValueError(f"Generated DOCX contains forbidden visible text: {found}")
    if re.search(r"\bOP\d+(?:\.\d+)?\b", text):
        refs = set(re.findall(r"\bOP\d+(?:\.\d+)?\b", text))
        defs = {op_id for op_id, *_ in OPERATIONS}
        dangling = sorted(refs - defs)
        if dangling:
            raise ValueError(f"Dangling operation references: {dangling}")


def main() -> None:
    diagrams = make_diagrams()
    counter = CaptionCounter()
    doc = setup_document()
    add_title_page(doc)
    add_contents(doc, counter)
    add_overview(doc, counter, diagrams)
    add_nfr(doc, counter)
    add_use_cases(doc, counter, diagrams)
    add_register_model(doc, counter, diagrams)
    add_operations(doc, counter)
    add_data_design(doc, counter, diagrams)
    add_reproducibility(doc, counter)
    validate_text_sanity(doc)
    doc.save(DST)
    print(f"Wrote {DST}")
    print(f"Embedded figures: {counter.figures}")
    print(f"Word tables: {counter.tables}")


if __name__ == "__main__":
    main()
