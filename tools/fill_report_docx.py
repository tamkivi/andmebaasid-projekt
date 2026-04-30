#!/usr/bin/env python3
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import shutil
import tempfile
import xml.etree.ElementTree as ET
import re


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "work" / "AB_projekt_taidetav.docx"
DST = ROOT / "work" / "AB_projekt_taidetav_filled.docx"


def replace_all(text: str, replacements: list[tuple[str, str]]) -> str:
    for old, new in replacements:
        text = text.replace(old, new)
    return text


NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
ET.register_namespace("w", NS["w"])


def paragraph_text(paragraph: ET.Element) -> str:
    return "".join(node.text or "" for node in paragraph.findall(".//w:t", NS))


def set_paragraph_text(paragraph: ET.Element, new_text: str) -> None:
    text_nodes = paragraph.findall(".//w:t", NS)
    if not text_nodes:
        return
    text_nodes[0].text = new_text
    for node in text_nodes[1:]:
        node.text = ""


def main() -> None:
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        with ZipFile(SRC) as zf:
            zf.extractall(tmp)

        replacements = [
            ("[Autorite nimed]", "Tristan Aik Sild, Gustav Tamkivi"),
            ("Y infosüsteemi", "Jõusaali infosüsteemi"),
            ("Y infosüsteemist", "jõusaali infosüsteemist"),
            ("Y peab olema organisatsiooni valdkonna nimetus", "Jõusaal peab olema organisatsiooni valdkonna nimetus"),

            ("X_kategooria_omamine", "treeningu_kategooria_omamine"),
            ("X_kategooria_tüübiga", "treeningu_kategooria_tüübiga"),
            ("X_kategooria_tüüp", "treeningu_kategooria_tüüp"),
            ("X_kategooria_kood", "treeningu_kategooria_kood"),
            ("X_kategooria_", "treeningu_kategooria_"),
            ("X_kategooria", "treeningu_kategooria"),
            ("X_seisundi_liik", "treeningu_seisundi_liik"),
            ("X_kood_uus", "treeningu_kood_uus"),
            ("X_kood_vana", "treeningu_kood_vana"),
            ("X_kood", "treeningu_kood"),

            ("X funktsionaalse allsüsteemi", "treeningute funktsionaalse allsüsteemi"),
            ("X funktsionaalne allsüsteem", "treeningute funktsionaalne allsüsteem"),
            ("X funktsionaalses allsüsteemis", "treeningute funktsionaalses allsüsteemis"),
            ("X registri", "treeningute registri"),
            ("X register", "treeningute register"),
            ("X registrit", "treeningute registrit"),
            ("X registrites", "treeningute registrites"),
            ("X elutsüklid", "treeningute elutsüklid"),

            ("X haldur", "treener"),
            ("X halduri", "treeneri"),
            ("X haldurid", "treenerid"),
            ("Registreeri X", "Registreeri treening"),
            ("Unusta X", "Unusta treening"),
            ("Muuda X mitteaktiivseks", "Muuda treening mitteaktiivseks"),
            ("Muuda X mittaktiivseks", "Muuda treening mitteaktiivseks"),
            ("Muuda X", "Muuda treeningut"),
            ("Aktiveeri X", "Aktiveeri treening"),
            ("Lõpeta X", "Lõpeta treening"),
            ("Vaata aktiivseid X", "Vaata aktiivseid treeninguid"),
            ("Vaata kõiki X", "Vaata kõiki treeninguid"),
            ("Vaata kõiki ootel või mitteaktiivseid X", "Vaata kõiki ootel või mitteaktiivseid treeninguid"),
            ("Vaata X koondaruannet", "Vaata treeningute koondaruannet"),

            ("uue X kohta", "uue treeningu kohta"),
            ("X registreerimine", "treeningu registreerimine"),
            ("X unustamine", "treeningu unustamine"),
            ("X aktiveerimine", "treeningu aktiveerimine"),
            ("X ajutiselt kasutusest eemaldamine", "treeningu ajutiselt kasutusest eemaldamine"),
            ("X lõplikult kasutusest eemaldamine", "treeningu lõplikult kasutusest eemaldamine"),
            ("X kasutamine", "treeningu kasutamine"),
            ("X andmed", "treeningu andmed"),
            ("X andmeid", "treeningu andmeid"),
            ("X detailandmed", "treeningu detailandmed"),
            ("X nimekirja", "treeningute nimekirja"),
            ("X nimekiri", "treeningute nimekiri"),
            ("X arvu", "treeningute arvu"),
            ("X hetkeseisund", "treeningu hetkeseisund"),
            ("X registreerimise", "treeningu registreerimise"),
            ("X viimase", "treeningu viimase"),
            ("X seotud", "treeninguga seotud"),
            ("X puhul", "treeningu puhul"),
            ("X kohta", "treeningu kohta"),
            ("X põhjal", "treeningute registri põhjal"),
            ("X põhiandmed", "treeningu põhiandmed"),
            ("X klassifitseerimist", "treeningute klassifitseerimist"),
            ("X rühmitamist", "treeningute rühmitamist"),
            ("üks ja sama X", "üks ja sama treening"),
            ("Igal X", "Igal treeningul"),
            ("Iga X", "Iga treening"),
            ("iga X", "iga treeningu"),
            ("kõigi X", "kõigi treeningute"),
            ("kõikide X", "kõikide treeningute"),
            ("aktiivsete X", "aktiivsete treeningute"),
            ("aktiivsed X", "aktiivsed treeningud"),
            ("ootel X", "ootel treeningute"),
            ("X.", "treening."),
            ("X,", "treening,"),
            ("X ", "treening "),
            ("X", "Treening"),
        ]

        fill_replacements = [
            (
                "Pakkuda kõigile töötajatele meeldivat töökeskkonda<täienda>",
                "Pakkuda kõigile töötajatele meeldivat töökeskkondaSuurendada klientide järjepidevat treeningutes osalemist ja toetada treenerite töö paremat planeerimist.",
            ),
            (
                "Tagada ülevaade treeningutest, mille pakkumine ja läbiviimine on jõusaali üks põhitegevusi<täienda>",
                "Tagada ülevaade treeningutest, mille pakkumine ja läbiviimine on jõusaali üks põhitegevusiVõimaldada avaldada klientidele ja uudistajatele ajakohast infot jõusaali treeningute kohta.",
            ),
            (
                "Tagada ülevaade treening, millega tehingute (transaktsioonide) tegemine on üks organisatsiooni põhieesmärk",
                "Tagada ülevaade treeningutest, mille pakkumine ja läbiviimine on jõusaali üks põhitegevusi",
            ),
            (
                "treener registreerib treeninguu",
                "treener registreerib treeningu",
            ),
            (
                "treener registreerib Treening",
                "treener registreerib treeningu",
            ),
            (
                "treening iseloomustab null või rohkem treeningu_kategooriat",
                "Treeningut iseloomustab null või rohkem treeningu kategooriat",
            ),
            (
                "treening iseloomustab null või rohkem treening kategooriat",
                "Treeningut iseloomustab null või rohkem treeningu kategooriat",
            ),
            (
                "treeningu_kategooria on klassifikaator",
                "treeningu kategooria on klassifikaator",
            ),
            (
                "treening kategooria on klassifikaator",
                "treeningu kategooria on klassifikaator",
            ),
            (
                "Uudistajale pakuvad huvi treeningu andmed",
                "Uudistajale pakuvad huvi avalikult nähtavad treeningute andmed",
            ),
            (
                "Uudistajale pakuvad huvi avalikult nähtavad treeningute andmed<täienda>",
                "Uudistajale pakuvad huvi avalikult nähtavad treeningute andmedKlient registreerub treeningule.",
            ),
            (
                "EelarveTreening<täienda>",
                "EelarveTreeningTreeningule registreerumine",
            ),
            (
                "treeningu lõplikult kasutusest eemaldamine (lõpetamine)<täienda><täienda>",
                "treeningu lõplikult kasutusest eemaldamine (lõpetamine)Klient soovib treeningul osaledaTreeningule registreerumine",
            ),
            (
                "Uudistaja<täienda>",
                "UudistajaAdministraator",
            ),
            (
                "Igale töötajale on ettenähtud oma arvuti. <täienda või kustuta>",
                "Igale töötajale on ettenähtud oma arvuti. Treenerid ja administraatorid kasutavad infosüsteemi tööarvutist või tahvelarvutist jõusaali ruumides.",
            ),
            (
                "Klassifikaatorite haldur<täienda>",
                "Klassifikaatorite haldurAdministraator",
            ),
            (
                "Uudistaja<täienda või kustuta>",
                "Uudistaja",
            ),
            (
                "treeningute register<täienda><täienda>",
                "treeningute registerBroneeringute funktsionaalne allsüsteemBroneeringute register",
            ),
            (
                "Registrit kasutavad pädevusaladJuhataja treenerKlientUudistaja<täienda>",
                "Registrit kasutavad pädevusaladJuhataja treenerKlientUudistajaAdministraator",
            ),
            (
                "Võimaldab rühmitada treening klassifitseerimiseks kasutatavaid kategooriaid ühise nime alla. Kategooria tüüp kirjeldab, mis liiki klassifikatsiooniga on tegemist. treeningu_kategooria_tüüp näide on <abc>, sest iga treeningu on seotud null või rohkema <abc>-ga ning iga <abc> on seotud null või rohkema Treening-ga.",
                "Võimaldab rühmitada treeningute klassifitseerimiseks kasutatavaid kategooriaid ühise nime alla. Kategooria tüüp kirjeldab, mis liiki klassifikatsiooniga on tegemist. treeningu_kategooria_tüüp näide on treeningu liik, sest iga treening on seotud null või rohkema treeningu liigiga ning iga treeningu liik on seotud null või rohkema treeninguga.",
            ),
            (
                "Näiteks treeningu_kategooria_tüüp <abc> alla kuuluvate kategooriate näited on <täienda>",
                "Näiteks treeningu_kategooria_tüüp treeningu liik alla kuuluvate kategooriate näited on eratrenn, grupitrenn ja füsioteraapia.",
            ),
            (
                "Näitab treening kuulumist kategooriatesse.",
                "Näitab treeningu kuulumist kategooriatesse.",
            ),
            (
                "mitme treening kategooriaga",
                "mitme treeningu kategooriaga",
            ),
            (
                "üldisele treening elutsüklile",
                "üldisele treeningu elutsüklile",
            ),
            (
                "Selleks, et saaks registreerida andmeid <täienda> registrites, peavad olema registreeritud treeningu andmed ja seega peab olema realiseeritud treeningute register.",
                "Selleks, et saaks registreerida andmeid broneeringute ja treeningupäevikute registrites, peavad olema registreeritud treeningu andmed ja seega peab olema realiseeritud treeningute register.",
            ),
            ("uue treening.", "uue treeningu."),
            ("sealt treening ja", "sealt treeningu ja"),
            ("treening lõpetamise", "treeningu lõpetamise"),
            ("treening aktiveerimise", "treeningu aktiveerimise"),
            ("treening kood", "treeningu kood"),
            ("treening registreerinud", "treeningu registreerinud"),
            ("Iga treening seisundi", "Iga treeningu seisundi"),
            ("selles seisundis olevate treening arv", "selles seisundis olevate treeningute arv"),
            ("Töötajate registriga on treeninguga seotud", "Töötajate registriga on treening seotud"),
            ("Klassifikaatorite registriga on treeninguga seotud", "Klassifikaatorite registriga on treening seotud"),
            ("rohkema treening kategooriaga", "rohkema treeningu kategooriaga"),
            ("treening kategooriasse", "treeningu kategooriasse"),
            ("treening andmete", "treeningu andmete"),
            ("treening saab aktiveerida", "Treeningu saab aktiveerida"),
            ("seoses treening on", "seoses treeninguga on"),
            ("treening ei ole vaja", "treeningut ei ole vaja"),
            ("Võimaldada treening elektrooniliselt registreerida", "Võimaldada treeningut elektrooniliselt registreerida"),
            ("Säilitada informatsiooni treeningu kohta sellises mahus", "Säilitada informatsiooni treeningute kohta sellises mahus"),
            ("treening algseisundit", "treeningu algseisundit"),
            ("treening seisundi", "treeningu seisundi"),
            ("treening seisund", "treeningu seisund"),
            ("treening registreerija", "treeningu registreerija"),
            ("treening kuulub", "treening kuulub"),
            ("treening mõnest", "treeningu mõnest"),
            ("treening atribuutide", "treeningu atribuutide"),
            ("treening uude", "treeningu uude"),
            ("treening kategooriast", "treeningu kategooriast"),
            ("treening elutsüklis", "treeningu elutsüklis"),
            ("selle treening saab", "selle treeninguga saab"),
            ("aktiivseid treening,", "aktiivseid treeninguid,"),
            ("aktiivseid treening.", "aktiivseid treeninguid."),
            ("treening ooteperiood", "treeningu ooteperiood"),
            ("treening seoses", "treeninguga seoses"),
            ("aktiveerida treening.", "aktiveerida treeningu."),
            ("valib nimekirjast treening ja", "valib nimekirjast treeningu ja"),
            ("ühtegi ootel või mitteaktiivset treening", "ühtegi ootel või mitteaktiivset treeningut"),
            ("ühtegi aktiivset treening", "ühtegi aktiivset treeningut"),
            ("ühtegi treening,", "ühtegi treeningut,"),
            ("ühtegi treening ", "ühtegi treeningut "),
            ("seoses selle treening on", "seoses selle treeninguga on"),
            ("Subjekt valib treening,", "Subjekt valib treeningu,"),
            ("Juhataja valib nimekirjast treening ja", "Juhataja valib nimekirjast treeningu ja"),
            ("Juhataja avaldab soovi treening lõpetada", "Juhataja avaldab soovi treening lõpetada"),
            ("treening ja sellega", "treeningu ja sellega"),
            ("treening kohta", "treeningu kohta"),
            ("treeningu kasutava kliendi", "treeningut kasutava kliendi"),
            ("kõigist treening ", "kõigist treeningutest "),
            ("näha treening, millest", "näha treeningut, millest"),
            ("kõikide organisatsioonile teadaolevate treeningu andmed", "kõikide organisatsioonile teadaolevate treeningute andmed"),
            ("Süsteem salvestab treeningu andmed (OP1) ning ükshaaval kõikide kategooriasse kuulumiste andmed (OP7) <täienda või kustuta>", "Süsteem salvestab treeningu andmed (OP1) ning ükshaaval kõikide kategooriasse kuulumiste andmed (OP7)."),
            ("<täienda või kustuta>", ""),
            ("Süsteem kuvab ootel treeningute nimekirja, kus on kood, <täienda> (OP3.1)", "Süsteem kuvab ootel treeningute nimekirja, kus on kood, nimetus, kestus minutites, treeningu tase ja maksimaalne osalejate arv (OP3.1)"),
            ("Süsteem kuvab aktiivsete treeningute nimekirja, kus on kood, <täienda> (OP6.1)", "Süsteem kuvab aktiivsete treeningute nimekirja, kus on kood, nimetus, kestus minutites, treeningu tase ja maksimaalne osalejate arv (OP6.1)"),
            ("Süsteem kuvab ootel või mitteaktiivses seisundis treeningute nimekirja, kus on kood, hetkeseisundi nimetus, <täienda> (OP7.1)", "Süsteem kuvab ootel või mitteaktiivses seisundis treeningute nimekirja, kus on kood, hetkeseisundi nimetus, nimetus, kestus minutites, treeningu tase ja maksimaalne osalejate arv (OP7.1)"),
            ("Süsteem kuvab kõigi treeningute nimekirja, kus on kood, hetkeseisundi nimetus, <täienda> (OP8.1)", "Süsteem kuvab kõigi treeningute nimekirja, kus on kood, hetkeseisundi nimetus, nimetus, kestus minutites, treeningu tase, maksimaalne osalejate arv ja hind (OP8.1)"),
            ("Süsteem kuvab aktiivsete või mitteaktiivsete treeningute nimekirja, kus on kood, hetkeseisundi nimetus, <täienda> (OP9.1)", "Süsteem kuvab aktiivsete või mitteaktiivsete treeningute nimekirja, kus on kood, hetkeseisundi nimetus, nimetus, kestus minutites, treeningu tase ja maksimaalne osalejate arv (OP9.1)"),
            ("Iga treeningu kohta esitatakse kood, <täienda> (OP11.2).", "Iga treeningu kohta esitatakse kood, nimetus, kirjeldus, kestus minutites, treeningu tase, vajalik varustus ja hind (OP11.2)."),
            ("treeningu põhiandmed (treeningu_kood, <täienda>, registreerimise aeg", "treeningu põhiandmed (treeningu_kood, nimetus, kirjeldus, kestus_minutites, maksimaalne_osalejate_arv, treeningu_tase, vajalik_varustus, hind, registreerimise aeg"),
            ("treeningu põhiandmed (treeningu_kood, <täienda>)", "treeningu põhiandmed (treeningu_kood, nimetus, kirjeldus, kestus_minutites, maksimaalne_osalejate_arv, treeningu_tase, vajalik_varustus, hind)"),
            ("Näiteks treeningu_kategooria_tüüp treeningu liik alla kuuluvate kategooriate näited on eratrenn, grupitrenn ja füsioteraapia.", "Näiteks treeningu_kategooria_tüüp treeningu liik alla kuuluvate kategooriate näited on eratrenn, grupitrenn ja füsioteraapia. Teised kategooria tüübid on treeningu tase, intensiivsus, eesmärk, sihtrühm ja varustus. Nende alla kuuluvate kategooriate näited on algaja, kesktase, edasijõudnud, madal intensiivsus, keskmine intensiivsus, kõrge intensiivsus, jõud, vastupidavus, liikuvus, kaalulangetus, täiskasvanud, seeniorid, oma keharaskus, hantlid ja treeningmatt."),
            ("Treeningu saab aktiveerida vaid siis, kui see on seotud vähemalt ühe treening kategooriaga", "Treeningu saab aktiveerida vaid siis, kui see on seotud vähemalt ühe treeningu kategooriaga"),
            ("Selles peatükis esitatakse mudel, mis kirjeldab treeningute funktsionaalse allsüsteemi toimimiseks vajalike registrite tehnilist lahendust <täienda> andmebaasisüsteemis.", "Selles peatükis esitatakse mudel, mis kirjeldab treeningute funktsionaalse allsüsteemi toimimiseks vajalike registrite tehnilist lahendust PostgreSQL andmebaasisüsteemis."),
            ("<täienda> esitatakse diagrammid, mis kirjeldavad andmebaasis loodavate tabelite struktuuri ning nendes defineeritavaid kitsendusi.", "Järgnevalt esitatakse diagrammid, mis kirjeldavad andmebaasis loodavate tabelite struktuuri ning nendes defineeritavaid kitsendusi."),
            ("Selles peatükis esitatakse andmebaasi PostgreSQLis (<täienda>) realiseerimiseks mõeldud laused.", "Selles peatükis esitatakse andmebaasi PostgreSQLis realiseerimiseks mõeldud laused."),
            ("treening kategooriatesse", "treeningu kategooriatesse"),
            ("treening registreeris", "treeningu registreeris"),
            ("Eelarvete register<täienda><täienda>", "Eelarvete registerTreeningutele registreerumise funktsionaalne allsüsteemTreeningutele registreerumise register"),
            ("Seisundiklassifikaator, mis võimaldab fikseerida iga treeningu puhul selle hetkeseisundi vastavalt üldisele treeningu elutsüklile. Võimalike väärtuste näited on ootel ja aktiivne.<täienda>Klassifikaatorite register<täienda> Võimalike väärtuste näited on<täienda><täienda><täienda><täienda>", "Seisundiklassifikaator, mis võimaldab fikseerida iga treeningu puhul selle hetkeseisundi vastavalt üldisele treeningu elutsüklile. Võimalike väärtuste näited on ootel, aktiivne, mitteaktiivne ja lõpetatud.Treeningule_registreerumineTreeningutele registreerumise registerNäitab kliendi soovi osaleda konkreetsel aktiivsel treeningul. Võimalike väärtuste näited on kliendi registreerumine grupitreeningule või eratrenni ajale.Registreeringu_seisundi_liikKlassifikaatorite registerSeisundiklassifikaator, mis võimaldab fikseerida treeningule registreerumise hetkeseisundi. Võimalike väärtuste näited on ootel, kinnitatud, tühistatud ja toimunud."),
            ("Treening<täienda>", "Treeningnimetus\nTreeningu nimetus, mida kuvatakse töötajatele, klientidele ja uudistajatele.\n\n{1. @Kohustuslik. 2. Nimetus ei tohi olla tühi string. 3. Nimetus peab olema treeningute hulgas unikaalne.}\nJõutreening algajatele\nTreeningkirjeldus\nTreeningu sisu lühikirjeldus kliendile ja töötajale.\n\n{1. @Kohustuslik. 2. Kirjeldus ei tohi olla tühi string.}\nAlgajatele mõeldud juhendatud jõutreening, kus õpitakse põhilisi harjutusi.\nTreeningkestus_minutites\nTreeningu planeeritud kestus minutites.\n\n{1. @Kohustuslik. 2. Väärtus peab olema positiivne täisarv. 3. Väärtus peab olema vahemikus 15 kuni 240.}\n60\nTreeningmaksimaalne_osalejate_arv\nTreeningul osaleda võivate klientide maksimaalne arv.\n\n{1. @Kohustuslik. 2. Väärtus peab olema positiivne täisarv.}\n12\nTreeningvajalik_varustus\nTreeningul osalemiseks vajalik varustus või märge, et erivarustust ei ole vaja.\n\n{1. @Kohustuslik. 2. Väärtus ei tohi olla tühi string.}\nTreeningmatt ja hantlid\nTreeninghind\nTreeningul osalemise hind eurodes.\n\n{1. @Kohustuslik. 2. Väärtus ei tohi olla negatiivne.}\n15.00"),
            ("OP1 Registreeri treening(\np_treeningu_kood, \n<täienda>\np_e_meil, \n<täienda>\n)", "OP1 Registreeri treening(\np_treeningu_kood,\np_nimetus,\np_kirjeldus,\np_kestus_minutites,\np_maksimaalne_osalejate_arv,\np_vajalik_varustus,\np_hind,\np_e_meil\n)"),
            ("treeningu_seisundi_liik eksemplar osl (millel on kood=1 (\"Ootel\") ja on_aktiivne=TRUE) on registreeritud\n<täienda>", "treeningu_seisundi_liik eksemplar osl (millel on kood=1 (\"Ootel\") ja on_aktiivne=TRUE) on registreeritud\nEi leidu teist treening eksemplari, millel on sama treeningu_kood või sama nimetus"),
            ("o.viimase_muutm_aeg:= hetke kuupäev + kellaaeg\n<täienda>", "o.viimase_muutm_aeg:= hetke kuupäev + kellaaeg\no.nimetus:= p_nimetus\no.kirjeldus:= p_kirjeldus\no.kestus_minutites:= p_kestus_minutites\no.maksimaalne_osalejate_arv:= p_maksimaalne_osalejate_arv\no.vajalik_varustus:= p_vajalik_varustus\no.hind:= p_hind"),
            ("o ja t (viimase muutja rollis) seos on registreeritud\n<täienda>", "o ja t (viimase muutja rollis) seos on registreeritud"),
            ("OP4 Muuda treening mitteaktiivseks (\n<täienda>\n)\nEeltingimused:\n<täienda>\nJäreltingimused:\n--Kustuta seoseid\n<täienda>\n--Loo seoseid\n<täienda>\n--Väärtusta atribuute\n<täienda>", "OP4 Muuda treening mitteaktiivseks (\np_treeningu_kood,\np_e_meil\n)\nEeltingimused:\nTöötaja eksemplar t (millel on e_meil=p_e_meil) on registreeritud\ntreening eksemplar o (millel on treeningu_kood=p_treeningu_kood) on registreeritud\no on seotud treeningu_seisundi_liik eksemplariga osl_vana (millel on kood=2 (\"Aktiivne\"))\ntreeningu_seisundi_liik eksemplar osl_uus (millel on kood=3 (\"Mitteaktiivne\") ja on_aktiivne=TRUE) on registreeritud\nJäreltingimused:\n--Kustuta seoseid\no ja osl_vana seos on kustutatud\no olemasolev seos viimase muutjaga on kustutatud\n--Loo seoseid\no ja osl_uus seos on registreeritud\no ja t (viimase muutja rollis) seos on registreeritud\n--Väärtusta atribuute\no.viimase_muutm_aeg:= hetke kuupäev + kellaaeg"),
            ("OP6 Muuda treeningut (\np_treeningu_kood_vana, \np_treeningu_kood_uus, \np_e_meil,\n<täienda>\n)", "OP6 Muuda treeningut (\np_treeningu_kood_vana,\np_treeningu_kood_uus,\np_nimetus,\np_kirjeldus,\np_kestus_minutites,\np_maksimaalne_osalejate_arv,\np_vajalik_varustus,\np_hind,\np_e_meil\n)"),
            ("o on seotud treeningu_seisundi_liik eksemplariga osl ((millel on kood=1 (\"Ootel\")) või (millel on kood=3 (\"Mitteaktiivne\")))\n<täienda>", "o on seotud treeningu_seisundi_liik eksemplariga osl ((millel on kood=1 (\"Ootel\")) või (millel on kood=3 (\"Mitteaktiivne\")))\nEi leidu teist treening eksemplari, millel on treeningu_kood=p_treeningu_kood_uus või nimetus=p_nimetus"),
            ("o.treeningu_kood:= p_treeningu_kood_uus\n<täienda>", "o.treeningu_kood:= p_treeningu_kood_uus\no.nimetus:= p_nimetus\no.kirjeldus:= p_kirjeldus\no.kestus_minutites:= p_kestus_minutites\no.maksimaalne_osalejate_arv:= p_maksimaalne_osalejate_arv\no.vajalik_varustus:= p_vajalik_varustus\no.hind:= p_hind\no.viimase_muutm_aeg:= hetke kuupäev + kellaaeg"),
            ("p_treening kategooria_kood", "p_treeningu_kategooria_kood"),
            ("OP8 Eemalda treening kategooriast", "OP8 Eemalda treeningu kategooriast"),
            ("TreeningCRURURRRURRCRU<täienda>", "TreeningCRURURRRURRCRUTreeningule_registreerumineCRRRR"),
        ]
        all_replacements = replacements + fill_replacements

        doc_xml = tmp / "word" / "document.xml"
        tree = ET.parse(doc_xml)
        root = tree.getroot()
        paragraphs = root.findall(".//w:p", NS)
        previous = ""
        previous_previous = ""
        for paragraph in paragraphs:
            current = paragraph_text(paragraph)
            if not current:
                continue
            # Leave Word's generated field/TOC paragraphs structurally intact.
            if "HYPERLINK" in current or "PAGEREF" in current or "TOC \\" in current:
                continue
            changed = replace_all(current, all_replacements)
            if changed in {"<täienda>", "<täienda või kustuta>"}:
                context_fill = {
                    "Pakkuda kõigile töötajatele meeldivat töökeskkonda": "Suurendada klientide järjepidevat treeningutes osalemist ja toetada treenerite töö paremat planeerimist.",
                    "Tagada ülevaade treeningutest, mille pakkumine ja läbiviimine on jõusaali üks põhitegevusi": "Võimaldada avaldada klientidele ja uudistajatele ajakohast infot jõusaali treeningute kohta.",
                    "Uudistajale pakuvad huvi avalikult nähtavad treeningute andmed": "Klient registreerub treeningule.",
                    "treeningu lõplikult kasutusest eemaldamine (lõpetamine)": "Klient soovib treeningul osaleda",
                    "Klient soovib treeningul osaleda": "Treeningule registreerumine",
                    "Uudistaja": "Administraator",
                    "Klassifikaatorite haldur": "Administraator",
                    "treeningute register": "broneeringute funktsionaalne allsüsteem",
                    "broneeringute funktsionaalne allsüsteem": "broneeringute register",
                    "Eelarvete register": "Treeningutele registreerumise funktsionaalne allsüsteem",
                    "Treeningutele registreerumise funktsionaalne allsüsteem": "Treeningutele registreerumise register",
                    "Seisundiklassifikaator, mis võimaldab fikseerida iga treeningu puhul selle hetkeseisundi vastavalt üldisele treeningu elutsüklile. Võimalike väärtuste näited on ootel ja aktiivne.": "Treeningule_registreerumine",
                    "Treeningule_registreerumine": "Treeningutele registreerumise register",
                    "Treeningutele registreerumise register": "Näitab kliendi soovi osaleda konkreetsel aktiivsel treeningul. Võimalike väärtuste näited on kliendi registreerumine grupitreeningule või eratrenni ajale.",
                    "Näitab kliendi soovi osaleda konkreetsel aktiivsel treeningul. Võimalike väärtuste näited on kliendi registreerumine grupitreeningule või eratrenni ajale.": "Registreeringu_seisundi_liik",
                    "Registreeringu_seisundi_liik": "Klassifikaatorite register",
                    "Klassifikaatorite register": "Seisundiklassifikaator, mis võimaldab fikseerida treeningule registreerumise hetkeseisundi. Võimalike väärtuste näited on ootel, kinnitatud, tühistatud ja toimunud.",
                    "p_treeningu_kood,": "p_nimetus,\np_kirjeldus,\np_kestus_minutites,\np_maksimaalne_osalejate_arv,\np_vajalik_varustus,\np_hind,",
                    "p_e_meil,": "",
                    "treeningu_seisundi_liik eksemplar osl (millel on kood=1 (\"Ootel\") ja on_aktiivne=TRUE) on registreeritud": "Ei leidu teist treening eksemplari, millel on sama treeningu_kood või sama nimetus",
                    "o.viimase_muutm_aeg:= hetke kuupäev + kellaaeg": "o.nimetus:= p_nimetus\no.kirjeldus:= p_kirjeldus\no.kestus_minutites:= p_kestus_minutites\no.maksimaalne_osalejate_arv:= p_maksimaalne_osalejate_arv\no.vajalik_varustus:= p_vajalik_varustus\no.hind:= p_hind",
                    "--Kustuta seoseid": "o olemasolev seos viimase muutjaga on kustutatud",
                    "--Loo seoseid": "o ja t (viimase muutja rollis) seos on registreeritud",
                    "--Väärtusta atribuute": "o.viimase_muutm_aeg:= hetke kuupäev + kellaaeg",
                    "p_e_meil,": "",
                    "p_treeningu_kood_uus,": "p_nimetus,\np_kirjeldus,\np_kestus_minutites,\np_maksimaalne_osalejate_arv,\np_vajalik_varustus,\np_hind,",
                    "o on seotud treeningu_seisundi_liik eksemplariga osl ((millel on kood=1 (\"Ootel\")) või (millel on kood=3 (\"Mitteaktiivne\")))": "Ei leidu teist treening eksemplari, millel on treeningu_kood=p_treeningu_kood_uus või nimetus=p_nimetus",
                    "o.treeningu_kood:= p_treeningu_kood_uus": "o.nimetus:= p_nimetus\no.kirjeldus:= p_kirjeldus\no.kestus_minutites:= p_kestus_minutites\no.maksimaalne_osalejate_arv:= p_maksimaalne_osalejate_arv\no.vajalik_varustus:= p_vajalik_varustus\no.hind:= p_hind\no.viimase_muutm_aeg:= hetke kuupäev + kellaaeg",
                }
                if previous == "Treening" and previous_previous == "Eelarve":
                    changed = "Treeningule registreerumine"
                elif previous == "treeningute register" and previous_previous == "Treening":
                    changed = "Jõusaali poolt klientidele pakutav juhendatud või iseseisev treeninguvõimalus, mille kohta säilitatakse kood, nimetus, kirjeldus, kestus, kategooriad ja hetkeseisund."
                elif previous == "treeningute register" and previous_previous != "treeningute funktsionaalne allsüsteem":
                    changed = current
                elif previous in context_fill:
                    changed = context_fill[previous]
                if previous == "Treening" and previous_previous.startswith("22.04.2015"):
                    changed = "nimetus\nTreeningu nimetus, mida kuvatakse töötajatele, klientidele ja uudistajatele.\n\n{1. @Kohustuslik. 2. Nimetus ei tohi olla tühi string. 3. Nimetus peab olema treeningute hulgas unikaalne.}\nJõutreening algajatele\nTreening\nkirjeldus\nTreeningu sisu lühikirjeldus kliendile ja töötajale.\n\n{1. @Kohustuslik. 2. Kirjeldus ei tohi olla tühi string.}\nAlgajatele mõeldud juhendatud jõutreening, kus õpitakse põhilisi harjutusi.\nTreening\nkestus_minutites\nTreeningu planeeritud kestus minutites.\n\n{1. @Kohustuslik. 2. Väärtus peab olema positiivne täisarv. 3. Väärtus peab olema vahemikus 15 kuni 240.}\n60\nTreening\nmaksimaalne_osalejate_arv\nTreeningul osaleda võivate klientide maksimaalne arv.\n\n{1. @Kohustuslik. 2. Väärtus peab olema positiivne täisarv.}\n12\nTreening\nvajalik_varustus\nTreeningul osalemiseks vajalik varustus või märge, et erivarustust ei ole vaja.\n\n{1. @Kohustuslik. 2. Väärtus ei tohi olla tühi string.}\nTreeningmatt ja hantlid\nTreening\nhind\nTreeningul osalemise hind eurodes.\n\n{1. @Kohustuslik. 2. Väärtus ei tohi olla negatiivne.}\n15.00"
                if previous.startswith("Töötajad töötavad neile spetsiaalselt ettenähtud ruumides."):
                    changed = "Treenerid ja administraatorid kasutavad infosüsteemi tööarvutist või tahvelarvutist jõusaali ruumides."
                if previous == "Uudistaja" and previous_previous == "Klient":
                    changed = ""
            if changed != current:
                set_paragraph_text(paragraph, changed)
            previous_previous = previous
            previous = changed

        remaining_fills = [
            "Treeningutele registreerumise funktsionaalne allsüsteem",
            "Treeningutele registreerumise register",
            "Joonisel esitatakse treeningu aktiveerimise protsess alates treeneri soovist muuta treening aktiivseks kuni seisundimuudatuse salvestamiseni.",
            "Treeningutele registreerumise register",
            "Näitab kliendi soovi osaleda konkreetsel aktiivsel treeningul.",
            "Registreeringu_seisundi_liik",
            "Klassifikaatorite register",
            "Seisundiklassifikaator, mis võimaldab fikseerida treeningule registreerumise hetkeseisundi. Võimalike väärtuste näited on ootel, kinnitatud, tühistatud ja toimunud.",
            "p_nimetus,\np_kirjeldus,\np_kestus_minutites,\np_maksimaalne_osalejate_arv,\np_vajalik_varustus,\np_hind,",
            "",
            "o ja t (viimase muutja rollis) seos on registreeritud",
            "p_treeningu_kood,\np_e_meil",
            "Töötaja eksemplar t (millel on e_meil=p_e_meil) on registreeritud\ntreening eksemplar o (millel on treeningu_kood=p_treeningu_kood) on registreeritud\no on seotud treeningu_seisundi_liik eksemplariga osl_vana (millel on kood=2 (\"Aktiivne\"))\ntreeningu_seisundi_liik eksemplar osl_uus (millel on kood=3 (\"Mitteaktiivne\") ja on_aktiivne=TRUE) on registreeritud",
            "p_nimetus,\np_kirjeldus,\np_kestus_minutites,\np_maksimaalne_osalejate_arv,\np_vajalik_varustus,\np_hind,",
            "o olemasolev seos viimase muutjaga on kustutatud",
            "o ja t (viimase muutja rollis) seos on registreeritud",
            "o.viimase_muutm_aeg:= hetke kuupäev + kellaaeg",
            "Treeningule_registreerumineCRRRR",
        ]
        fill_index = 0
        for paragraph in paragraphs:
            current = paragraph_text(paragraph)
            if "<täienda" in current:
                if fill_index < len(remaining_fills):
                    set_paragraph_text(paragraph, current.replace("<täienda>", remaining_fills[fill_index]).replace("<täienda või kustuta>", remaining_fills[fill_index]))
                    fill_index += 1
                else:
                    set_paragraph_text(paragraph, current.replace("<täienda>", "").replace("<täienda või kustuta>", ""))

        final_replacements = [
            ("Treeningutele registreerumise register Võimalike väärtuste näited onTreeningutele registreerumise register", "Treeningutele registreerumise register"),
            ("Treeningutele registreerumise register\nTreeningutele registreerumise register", "Treeningutele registreerumise register\nNäitab kliendi soovi osaleda konkreetsel aktiivsel treeningul."),
            ("Treeningutele registreerumise register\n\nTreeningutele registreerumise register", "Treeningutele registreerumise register\n\nNäitab kliendi soovi osaleda konkreetsel aktiivsel treeningul."),
            ("Registreeringu_seisundi_liik\nKlassifikaatorite register\nSeisundiklassifikaator, mis võimaldab fikseerida treeningule registreerumise hetkeseisundi. Võimalike väärtuste näited on ootel, kinnitatud, tühistatud ja toimunud.", "Registreeringu_seisundi_liik\nKlassifikaatorite register\nSeisundiklassifikaator, mis võimaldab fikseerida treeningule registreerumise hetkeseisundi. Võimalike väärtuste näited on ootel, kinnitatud, tühistatud ja toimunud."),
            ("OP1 Registreeri treening(\np_treeningu_kood, \nRegistreeringu_seisundi_liik\np_e_meil, \nKlassifikaatorite register\n)", "OP1 Registreeri treening(\np_treeningu_kood,\np_nimetus,\np_kirjeldus,\np_kestus_minutites,\np_maksimaalne_osalejate_arv,\np_vajalik_varustus,\np_hind,\np_e_meil\n)"),
            ("o ja t (viimase muutja rollis) seos on registreeritud\nSeisundiklassifikaator, mis võimaldab fikseerida treeningule registreerumise hetkeseisundi. Võimalike väärtuste näited on ootel, kinnitatud, tühistatud ja toimunud.", "o ja t (viimase muutja rollis) seos on registreeritud"),
            ("OP4 Muuda treening mitteaktiivseks (\np_nimetus,\np_kirjeldus,\np_kestus_minutites,\np_maksimaalne_osalejate_arv,\np_vajalik_varustus,\np_hind,\n)\nEeltingimused:\n\nJäreltingimused:", "OP4 Muuda treening mitteaktiivseks (\np_treeningu_kood,\np_e_meil\n)\nEeltingimused:\nTöötaja eksemplar t (millel on e_meil=p_e_meil) on registreeritud\ntreening eksemplar o (millel on treeningu_kood=p_treeningu_kood) on registreeritud\no on seotud treeningu_seisundi_liik eksemplariga osl_vana (millel on kood=2 (\"Aktiivne\"))\ntreeningu_seisundi_liik eksemplar osl_uus (millel on kood=3 (\"Mitteaktiivne\") ja on_aktiivne=TRUE) on registreeritud\nJäreltingimused:"),
            ("--Kustuta seoseid\no olemasolev seos viimase muutjaga on kustutatud\n--Loo seoseid\no ja t (viimase muutja rollis) seos on registreeritud\n--Väärtusta atribuute\no.viimase_muutm_aeg:= hetke kuupäev + kellaaeg\nKasutus kasutusjuhtude poolt: Muuda treening mitteaktiivseks", "--Kustuta seoseid\no ja osl_vana seos on kustutatud\no olemasolev seos viimase muutjaga on kustutatud\n--Loo seoseid\no ja osl_uus seos on registreeritud\no ja t (viimase muutja rollis) seos on registreeritud\n--Väärtusta atribuute\no.viimase_muutm_aeg:= hetke kuupäev + kellaaeg\nKasutus kasutusjuhtude poolt: Muuda treening mitteaktiivseks"),
            ("OP6 Muuda treeningut (\np_treeningu_kood_vana, \np_treeningu_kood_uus, \np_e_meil,\n\n)", "OP6 Muuda treeningut (\np_treeningu_kood_vana,\np_treeningu_kood_uus,\np_nimetus,\np_kirjeldus,\np_kestus_minutites,\np_maksimaalne_osalejate_arv,\np_vajalik_varustus,\np_hind,\np_e_meil\n)"),
        ]
        whole = ET.tostring(root, encoding="unicode")
        for old, new in final_replacements:
            whole = whole.replace(old, new)
        root = ET.fromstring(whole)
        tree = ET.ElementTree(root)
        paragraphs = root.findall(".//w:p", NS)
        nonempty = []
        for paragraph in paragraphs:
            current = paragraph_text(paragraph)
            if current:
                nonempty.append((paragraph, current))

        for idx, (paragraph, current) in enumerate(nonempty):
            if current == "Üliõpilane:":
                set_paragraph_text(paragraph, "Üliõpilased: Tristan Aik Sild, Gustav Tamkivi")
            if current == "Õpperühm:":
                set_paragraph_text(paragraph, "Õpperühm: IAIB23")
            if current == "Matrikli nr:":
                set_paragraph_text(paragraph, "Matrikli nr: , 253787IAIB")
            if current == "e-posti aadress:":
                set_paragraph_text(paragraph, "e-posti aadressid: gustav@taltech.ee, trists@taltech.ee")
            if current == "Treeningutele registreerumise funktsionaalne allsüsteem" and idx > 0 and "Aktiveeri treening" in nonempty[idx - 1][1]:
                set_paragraph_text(paragraph, "Joonisel esitatakse treeningu aktiveerimise protsess alates treeneri soovist muuta treening aktiivseks kuni seisundimuudatuse salvestamiseni.")
            if current == "treeningu_seisundi_liik" and idx + 8 < len(nonempty):
                sequence = [
                    "treeningu_seisundi_liik",
                    "Klassifikaatorite register",
                    "Seisundiklassifikaator, mis võimaldab fikseerida iga treeningu puhul selle hetkeseisundi vastavalt üldisele treeningu elutsüklile. Võimalike väärtuste näited on ootel, aktiivne, mitteaktiivne ja lõpetatud.",
                    "Treeningule_registreerumine",
                    "Treeningutele registreerumise register",
                    "Näitab kliendi soovi osaleda konkreetsel aktiivsel treeningul.",
                    "Registreeringu_seisundi_liik",
                    "Klassifikaatorite register",
                    "Seisundiklassifikaator, mis võimaldab fikseerida treeningule registreerumise hetkeseisundi. Võimalike väärtuste näited on ootel, kinnitatud, tühistatud ja toimunud.",
                ]
                for offset, value in enumerate(sequence):
                    set_paragraph_text(nonempty[idx + offset][0], value)
            if current == "OP1 Registreeri treening(" and idx + 5 < len(nonempty):
                set_paragraph_text(nonempty[idx + 1][0], "p_treeningu_kood,\np_nimetus,\np_kirjeldus,\np_kestus_minutites,\np_maksimaalne_osalejate_arv,\np_vajalik_varustus,\np_hind,\np_e_meil")
                set_paragraph_text(nonempty[idx + 2][0], "")
                set_paragraph_text(nonempty[idx + 3][0], "")
                set_paragraph_text(nonempty[idx + 4][0], ")")
            if current.startswith("Seisundiklassifikaator, mis võimaldab fikseerida treeningule registreerumise hetkeseisundi") and idx > 0 and nonempty[idx - 1][1] == "o ja t (viimase muutja rollis) seos on registreeritud":
                set_paragraph_text(paragraph, "")
            if current == "OP4 Muuda treening mitteaktiivseks (" and idx + 11 < len(nonempty):
                sequence = [
                    "OP4 Muuda treening mitteaktiivseks (",
                    "p_treeningu_kood,\np_e_meil",
                    ")",
                    "Eeltingimused:",
                    "Töötaja eksemplar t (millel on e_meil=p_e_meil) on registreeritud\ntreening eksemplar o (millel on treeningu_kood=p_treeningu_kood) on registreeritud\no on seotud treeningu_seisundi_liik eksemplariga osl_vana (millel on kood=2 (\"Aktiivne\"))\ntreeningu_seisundi_liik eksemplar osl_uus (millel on kood=3 (\"Mitteaktiivne\") ja on_aktiivne=TRUE) on registreeritud",
                    "Järeltingimused:",
                    "--Kustuta seoseid",
                    "o ja osl_vana seos on kustutatud\no olemasolev seos viimase muutjaga on kustutatud",
                    "--Loo seoseid",
                    "o ja osl_uus seos on registreeritud\no ja t (viimase muutja rollis) seos on registreeritud",
                    "--Väärtusta atribuute",
                    "o.viimase_muutm_aeg:= hetke kuupäev + kellaaeg",
                ]
                for offset, value in enumerate(sequence):
                    set_paragraph_text(nonempty[idx + offset][0], value)
            if current == "OP6 Muuda treeningut (" and idx + 5 < len(nonempty):
                set_paragraph_text(nonempty[idx + 1][0], "p_treeningu_kood_vana,\np_treeningu_kood_uus,\np_nimetus,\np_kirjeldus,\np_kestus_minutites,\np_maksimaalne_osalejate_arv,\np_vajalik_varustus,\np_hind,\np_e_meil")
                set_paragraph_text(nonempty[idx + 2][0], ")")
                set_paragraph_text(nonempty[idx + 3][0], "Eeltingimused:")
                set_paragraph_text(nonempty[idx + 4][0], "Töötaja eksemplar t (millel on e_meil=p_e_meil) on registreeritud")

        nonempty = []
        for paragraph in paragraphs:
            current = paragraph_text(paragraph)
            if current:
                nonempty.append((paragraph, current))
        for idx, (paragraph, current) in enumerate(nonempty):
            if current == ")" and idx > 0 and nonempty[idx - 1][1] == ")":
                set_paragraph_text(paragraph, "")

        body = root.find("w:body", NS)
        if body is not None:
            for child in list(body):
                if child.tag != f"{{{NS['w']}}}p":
                    continue
                text = paragraph_text(child)
                if "HYPERLINK" not in text:
                    continue
                if (
                    "Sissejuhatus (Andmebaasid II)" in text
                    or re.search(r'"\s+[45](?:\.\d+)*', text)
                    or "Realisatsioon PostgreSQLis" in text
                    or "Realisatsioon Oracles" in text
                ):
                    body.remove(child)
                    continue
                cleaned = replace_all(text, all_replacements)
                cleaned = cleaned.replace("6\tTehisintellekti kasutus", "4\tTehisintellekti kasutus")
                cleaned = cleaned.replace("7\tKasutatud materjalid", "5\tKasutatud materjalid")
                cleaned = cleaned.replace("6Tehisintellekti kasutus", "4\tTehisintellekti kasutus")
                cleaned = cleaned.replace("7Kasutatud materjalid", "5\tKasutatud materjalid")
                if cleaned != text:
                    set_paragraph_text(child, cleaned)

            # Keep booking as a related whole-system process/register, but do not
            # present it as an extra detailed entity in the selected X register.
            deleting_booking_detail = False
            for child in list(body):
                if child.tag != f"{{{NS['w']}}}p":
                    continue
                text = paragraph_text(child)
                if text == "Treeningule_registreerumine":
                    deleting_booking_detail = True
                if deleting_booking_detail and text == "Atribuutide definitsioonid":
                    deleting_booking_detail = False
                if deleting_booking_detail:
                    body.remove(child)

            for child in list(body):
                if child.tag != f"{{{NS['w']}}}p":
                    continue
                text = paragraph_text(child)
                if "Treeningule_registreerumineCRRRR" in text:
                    set_paragraph_text(child, text.replace("Treeningule_registreerumineCRRRR", ""))

            for child in list(body):
                if child.tag != f"{{{NS['w']}}}p":
                    continue
                text = paragraph_text(child)
                if text == "Tehisintellekti kasutus on lubatud ja soositud, kuid lõpptulemuse õigsuse eest vastutavad töö autorid.":
                    set_paragraph_text(
                        child,
                        "Töö koostamisel kasutati OpenAI ChatGPT/Codex abi töövihiku täitmise mustandite koostamiseks, juhendmaterjalide põhjal kontrollnimekirja tegemiseks, sõnastuse ühtlustamiseks ja dokumendi tehniliseks genereerimiseks. Autorid kontrollisid ja suunasid tehisintellekti pakutud sisu ning vastutavad lõpptulemuse õigsuse eest.",
                    )

            # Remove workbook instruction/comment tail that follows the actual
            # references in the converted template, and cite the extra guides used.
            trimming_tail = False
            for child in list(body):
                if child.tag != f"{{{NS['w']}}}p":
                    continue
                text = paragraph_text(child)
                if text.startswith("Stackoverflow. What is the maximum length of a valid email address?"):
                    set_paragraph_text(
                        child,
                        text
                        + "\nIseseisva töö ülesande püstitus ITI0206 2026. [WWW] https://maurus.ttu.ee/390 (01.05.2026)"
                        + "\nProjekti juhend ITI0206 2026. [WWW] https://maurus.ttu.ee/390 (01.05.2026)"
                        + "\nProjekti mustripõhine juhend ITI0206. [WWW] https://maurus.ttu.ee/390 (01.05.2026)"
                        + "\nProjekti tüüpvigade materjal ITI0206 2026. [WWW] https://maurus.ttu.ee/390 (01.05.2026)"
                        + "\nNäidisprojekt ITI0206 vastuvõtuajad. [WWW] https://maurus.ttu.ee/390 (01.05.2026)",
                    )
                    trimming_tail = True
                    continue
                if trimming_tail:
                    body.remove(child)

        # The 2026 ITI0206 guide explicitly says these sections may be deleted for
        # Andmebaasid I; they are continued in Andmebaasid II.
        def delete_section(start_title: str, end_title: str) -> None:
            body = root.find("w:body", NS)
            if body is None:
                return
            children = list(body)
            deleting = False
            for child in children:
                if child.tag != f"{{{NS['w']}}}p":
                    continue
                text = paragraph_text(child)
                if text == start_title:
                    deleting = True
                if deleting and text == end_title:
                    deleting = False
                if deleting:
                    body.remove(child)

        delete_section("Sissejuhatus (Andmebaasid II)", "Strateegiline analüüs")
        delete_section("Realisatsioon PostgreSQLis", "Realisatsioon Oracles")
        delete_section("Realisatsioon Oracles", "Tehisintellekti kasutus")

        tree.write(doc_xml, encoding="utf-8", xml_declaration=True)

        shutil.copyfile(SRC, DST)
        with ZipFile(DST, "w", compression=ZIP_DEFLATED) as out:
            for path in sorted(tmp.rglob("*")):
                if path.is_file():
                    out.write(path, path.relative_to(tmp).as_posix())


if __name__ == "__main__":
    main()
