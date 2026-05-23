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
    ("03_core_er.png", "Põhiandmemudel: treeninguliik, treeningukord, registreering, osalemine ja seotud objektid."),
    ("04_registration_activity.png", "Registreerimise tegevusvoog koos kontrollide, mahutavuse ja ootejärjekorraga."),
    ("05_session_state.png", "Treeningukorra seisundimudel ja lubatud üleminekud."),
    ("06_registration_state.png", "Registreeringu seisundimudel ja ootejärjekorrast edendamine."),
    ("07_waitlist_sequence.png", "Ootejärjekorra edendamise järjestus pärast kinnitatud registreeringu tühistamist."),
    ("08_permission_flow.png", "Õiguste ja andmebaasirutiinide seos juhataja, treeneri ja kliendi vaates."),
    ("09_app_db_architecture.png", "Rakenduse ja andmebaasi arhitektuur: vaated lugemiseks, funktsioonid kirjutamiseks."),
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
    ("Treeneri pädevus", "Seos, mis määrab, millist treeninguliiki treener tohib juhendada."),
    ("Klient", "Kasutajakontoga seotud osaleja, kes saab registreeruda avatud treeningukorrale."),
    ("Registreering", "Kliendi koht või ootejärjekorra kirje treeningukorral. Aktiivne seisund on kas KINNIT või OOTEJRK."),
    ("Osalemine", "Kinnitatud registreeringu kohalolu tulemus, mille märgib määratud treener või juhataja."),
]


USE_CASES = [
    ("Planeeri treeningukord", "Juhataja", "Juhataja valib aktiivse treeninguliigi, pädeva treeneri, ruumi, aja ja mahupiirangu. Andmebaas kontrollib pädevust, ruumi mahtu ja kattuvaid aegu."),
    ("Ava registreerimine", "Juhataja", "Kavandatud tulevane treeningukord muudetakse seisundisse AVATUD, et kliendid saaksid registreeruda."),
    ("Registreeru treeningukorrale", "Klient", "Klient valib avatud treeningukorra. Kui koht on olemas, tekib KINNIT registreering; kui koht puudub, tekib OOTEJRK rida."),
    ("Tühista registreering", "Klient, juhataja", "Klient saab enne tähtaega enda aktiivse registreeringu tühistada. Kui vabaneb kinnitatud koht, edendab andmebaas esimese ootel kliendi."),
    ("Tühista treeningukord", "Juhataja", "Juhataja saab kavandatud, avatud või suletud treeningukorra tühistada. Kõik aktiivsed registreeringud lähevad seisundisse TYH_SYS."),
    ("Märgi osalemine", "Treener, juhataja", "Määratud treener või juhataja märgib kinnitatud registreeringutele osales/ei osalenud tulemuse."),
    ("Vaata statistikat", "Juhataja", "Juhataja näeb täituvust, kinnitatud osalejate arvu, ootejärjekorda ja toimunud treeningukordade koondit."),
]


ROUTINES = [
    ("fn_planeeri_treeningukord", "Juhataja", "Loob KAVAND treeningukorra. Kontrollib juhataja rolli, aktiivset treeninguliiki, treeneri rolli ja pädevust, ruumi aktiivsust, ajavahemikku, mahutavust ning treeneri/ruumi kattuvusi."),
    ("fn_ava_treeningukord", "Juhataja", "Muudab tulevase KAVAND treeningukorra seisundisse AVATUD. Ebaõnnestub, kui kirje puudub, pole kavandatud või algus on möödas."),
    ("fn_sulge_treeningukord", "Juhataja või määratud treener", "Muudab AVATUD treeningukorra seisundisse SULETUD. Treener peab ootama registreerimise tähtaja möödumist; juhataja saab sulgeda vajadusel varem."),
    ("fn_lopeta_treeningukord", "Juhataja või määratud treener", "Muudab lõppenud SULETUD treeningukorra seisundisse TOIMUNUD. Ei luba tulevast treeningukorda lõpetada."),
    ("fn_registreeri_klient_treeningukorrale", "Klient", "Loob registreeringu. Kontrollib aktiivset klienti, AVATUD seisundit, tähtaega ja topeltaktiivse registreeringu puudumist. Tagastab seisundi ja teate."),
    ("fn_tyhista_registreering", "Klient või juhataja", "Tühistab aktiivse registreeringu. Klient saab tühistada ainult enda registreeringu enne tähtaega. Kinnitatud koha vabanemisel kutsub edendamise funktsiooni."),
    ("fn_edenda_ootejarjekorrast", "Süsteem", "Lukustab treeningukorra ja esimese OOTEJRK rea ning muudab selle seisundisse KINNIT, kui vaba koht on olemas."),
    ("fn_marki_osalemine", "Treener või juhataja", "Lisab või uuendab osalemise tulemuse kinnitatud registreeringule. Kontrollid on osalemise triggeris."),
    ("fn_tyhista_treeningukord", "Juhataja", "Muudab treeningukorra TYHIST seisundisse ja tühistab kõik aktiivsed registreeringud seisundisse TYH_SYS."),
]


BUSINESS_RULES = [
    ("Ruum ei tohi üle täituda", "Trigger fn_kontrolli_treeningukorra_invariandid kontrollib, et maksimaalne_osalejate_arv <= ruum.mahutavus."),
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

    for name, size in [("Heading 1", 15), ("Heading 2", 12.5), ("Heading 3", 11)]:
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
        "Süsteemi üldvaade",
        "Kasutusjuhud ja äriprotsessid",
        "Põhiobjektid ja eskiismudel",
        "Seisundimudelid",
        "Operatsioonilepingud",
        "Ärireeglid ja andmebaasis realiseerimine",
        "Andmemudel ja füüsiline disain",
        "Rakenduse prototüüp",
        "Kontroll ja valideerimine",
        "Kaitsmise selgitus",
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
    doc.add_picture(str(path), width=Inches(6.6))
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


def add_paragraphs(doc: Document, texts: list[str]) -> None:
    for text in texts:
        doc.add_paragraph(text)


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
        "Need teemad on teadlikult välja jäetud, et hoida fookus andmebaasi poolt kontrollitaval ajakava, registreerimise ja osalemise protsessil.",
    ])

    doc.add_heading("Süsteemi üldvaade", level=1)
    add_figure(doc, state, *DIAGRAMS[0])
    add_table(doc, state, "Tegutsejad ja nende rollid", ["Tegutseja", "Tüüp", "Vastutus"], ACTORS)
    add_paragraphs(doc, [
        "Rakendus on Flaski prototüüp, mis kasutab PostgreSQL andmebaasi. Lugemiseks kasutatakse rollipõhiseid vaateid ning "
        "tavapärased kirjutavad töövood kutsuvad andmebaasi funktsioone. Andmebaasi triggerid, osalised indeksid ja kontrollid "
        "keelavad vigased seisundimuudatused, kattuvad ajad ja mahutavuse rikkumised ka siis, kui keegi prooviks rakendusest mööda minna.",
    ])

    doc.add_heading("Kasutusjuhud ja äriprotsessid", level=1)
    add_figure(doc, state, *DIAGRAMS[1])
    add_table(doc, state, "Olulisemad kasutusjuhud", ["Kasutusjuht", "Tegutseja", "Sisu"], USE_CASES)
    add_figure(doc, state, *DIAGRAMS[3])
    add_figure(doc, state, *DIAGRAMS[6])
    add_paragraphs(doc, [
        "Registreerimise töövoog on äriliselt oluline, sest see seob mitu objekti ja mitu reeglit: klient, avatud treeningukord, "
        "tähtaeg, mahutavus, aktiivne registreering ja ootejärjekord. Ootejärjekorra edendamine toimub ühes andmebaasi transaktsioonis, "
        "kus treeningukord ja edendatav registreering lukustatakse.",
    ])

    doc.add_heading("Põhiobjektid ja eskiismudel", level=1)
    add_figure(doc, state, *DIAGRAMS[2])
    add_table(doc, state, "Põhiobjektid", ["Objekt", "Selgitus"], CORE_OBJECTS)
    add_paragraphs(doc, [
        "Põhiobjektide arv ja omavahelised seosed näitavad, et lahendus ei ole enam ühe treeningukaardi CRUD. Treeninguliik on mall, "
        "treeningukord on konkreetne sündmus, registreering on kliendi osalemissoov või ootejärjekorra koht ning osalemine on pärast "
        "tundi märgitav tulemus. Ruum ja treeneri pädevus annavad protsessile piirangud, mida andmebaas saab sisuliselt kontrollida.",
    ])

    doc.add_heading("Seisundimudelid", level=1)
    add_figure(doc, state, *DIAGRAMS[4])
    add_table(doc, state, "Treeningukorra lubatud seisundimuudatused", ["Algseisund", "Lõppseisund", "Sündmus ja tegutseja"], STATE_TRANSITIONS_SESSION)
    add_figure(doc, state, *DIAGRAMS[5])
    add_table(doc, state, "Registreeringu lubatud seisundimuudatused", ["Algseisund", "Lõppseisund", "Sündmus ja tegutseja"], STATE_TRANSITIONS_REGISTRATION)

    doc.add_heading("Operatsioonilepingud", level=1)
    add_table(doc, state, "Andmebaasirutiinide lepingud", ["Rutiin", "Tegutseja", "Eeltingimused, järeltingimused ja vead"], ROUTINES)
    add_paragraphs(doc, [
        "Operatsioonilepingud on realiseeritud PostgreSQL funktsioonidena. Rakendus võib enne vormi saatmist teha kasutajakogemust parandavaid kontrolle, "
        "kuid lõplik otsus jääb andmebaasile. Vea korral tagastab PostgreSQL erindi, mille Flask kuvab kasutajale eestikeelse teatena.",
    ])

    doc.add_heading("Ärireeglid ja nende realiseerimine andmebaasis", level=1)
    add_table(doc, state, "Ärireeglite realiseerimine", ["Reegel", "Andmebaasi mehhanism"], BUSINESS_RULES)
    add_figure(doc, state, *DIAGRAMS[7])

    doc.add_heading("Andmemudel ja füüsiline disain", level=1)
    add_table(doc, state, "Olulisemad tabelid ja piirangud", ["Tabel", "Eesmärk", "Võtmed ja piirangud"], TABLES)
    add_table(doc, state, "Rakenduse ja aruandluse vaated", ["Vaade", "Kasutus"], VIEWS)
    add_figure(doc, state, *DIAGRAMS[8])
    add_paragraphs(doc, [
        "Füüsiline mudel kasutab eraldi klassifikaatoreid treeninguliigi, treeningukorra ja registreeringu seisunditele. "
        "Aktiivse registreeringu topelttegemise keelab osaline unikaalne indeks. Ruumi ja treeneri kattuvused on triggeripõhised, "
        "sest see ei eelda PostgreSQL laienduste paigaldamist. Ootejärjekorra edendamine toimub funktsioonis, mis lukustab korraga "
        "vajalikud read ja väldib sama koha mitmekordset jagamist.",
    ])

    doc.add_heading("Rakenduse prototüüp", level=1)
    add_paragraphs(doc, [
        "Flaski prototüübis on kolm nähtavat töövoogu. Juhataja saab näha ja planeerida treeningukordi, avada või sulgeda registreerimist, "
        "tühistada treeningukorra ning vaadata täituvuse statistikat. Treener näeb enda treeningukordi, avab osalejate nimekirja ja märgib "
        "osalemist. Klient näeb avatud ajakava, registreerub treeningukorrale, näeb kas ta on kinnitatud või ootejärjekorras ning saab enda "
        "registreeringu enne tähtaega tühistada.",
        "Tavapärased kirjutavad marsruudid ei tee otse INSERT/UPDATE/DELETE käske tabelitesse treeningukord, registreering ja osalemine. "
        "Need kutsuvad funktsioone fn_planeeri_treeningukord, fn_ava_treeningukord, fn_sulge_treeningukord, fn_lopeta_treeningukord, "
        "fn_registreeri_klient_treeningukorrale, fn_tyhista_registreering, fn_tyhista_treeningukord ja fn_marki_osalemine.",
    ])

    doc.add_heading("Kontroll ja valideerimine", level=1)
    add_bullets(doc, [
        "Staatiline validaator kontrollib nõutud tabeleid, funktsioone, vaateid, triggereid, osalist unikaalset indeksit ja Mermaid diagramme.",
        "DOCX kontroll otsib uue projekti võtmetermineid: rühmatreeningute ajakava, treeningukord, registreering, ootejärjekord, osalemine, ruum ja treeneri pädevus.",
        "Rakenduse kontroll otsib, et kirjutavad marsruudid kutsuvad andmebaasi funktsioone ja et rakenduse ZIP ei sisalda venv, .env, __pycache__, .class või .jar faile.",
        "Validaator toetab valikulisi live SQL teste keskkonnamuutujaga RUN_LIVE_SQL_TESTS=1, et tõestada kattuvuste, mahutavuse, topeltregistreeringu, ootejärjekorra ja seisundite käitumist tegelikus PostgreSQL andmebaasis.",
    ])

    doc.add_heading("Kaitsmise selgitus", level=1)
    add_paragraphs(doc, [
        "Projekt ei käsitle enam treeningut kui töövihiku laadset kirjelduskaarti. Põhiobjekt on konkreetne treeningukord koos ruumi, "
        "treeneri, registreeringute, ootejärjekorra ja osalemisega. Andmebaas kontrollib mahutavust, kattuvaid aegu, treeneri pädevust, "
        "registreerimise tähtaegu, seisundimuutusi ja ootejärjekorra edendamist.",
        "Vaba teema tugevus tuleb sellest, et protsessil on mitu osalist, mitu töökohta ja mitu üksteisest sõltuvat ärireeglit. "
        "Juhataja, treener ja klient näevad erinevaid vaateid ja saavad teha erinevaid toiminguid, kuid sisulised reeglid paiknevad andmebaasis.",
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
