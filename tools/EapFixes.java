import com.healthmarketscience.jackcess.Cursor;
import com.healthmarketscience.jackcess.CursorBuilder;
import com.healthmarketscience.jackcess.Database;
import com.healthmarketscience.jackcess.DatabaseBuilder;
import com.healthmarketscience.jackcess.Row;
import com.healthmarketscience.jackcess.Table;

import java.io.File;
import java.nio.channels.FileChannel;
import java.nio.file.StandardOpenOption;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

public class EapFixes {
    private static final int PKG_PADEVUSALAD = 4;
    private static final int PKG_DISAIN_REGISTRID = 7;
    private static final int PKG_ISIKUTE_REGISTER = 10;
    private static final int PKG_TOOTAJATE_REGISTER = 14;
    private static final int PKG_AKTIVEERI_STSENAARIUMID = 17;

    private final Database db;

    private EapFixes(Database db) {
        this.db = db;
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            throw new IllegalArgumentException("Usage: EapFixes <file.eap>");
        }
        File file = new File(args[0]);
        try (
            FileChannel channel = FileChannel.open(file.toPath(), StandardOpenOption.READ, StandardOpenOption.WRITE);
            Database db = new DatabaseBuilder(file).setChannel(channel).setReadOnly(false).open()
        ) {
            EapFixes fixes = new EapFixes(db);
            fixes.apply();
        }
    }

    private void apply() throws Exception {
        renameModelItems();
        fixStateTransitions();
        populateActivationScenario();
        addCompetencyDiagram();
        addRegisterDiagrams();
        populateDesignRegisterPackage();
        addUseCaseExtendsAndScenarioText();
        addAttributeNotesAndConstraints();
    }

    private static String guid() {
        return "{" + UUID.randomUUID().toString().toUpperCase() + "}";
    }

    private static String s(Object value) {
        return value == null ? "" : value.toString();
    }

    private static String z() {
        return " ";
    }

    private Row findRow(Table table, String column, Object value) throws Exception {
        Cursor cursor = CursorBuilder.createCursor(table);
        for (Row row : cursor) {
            Object actual = row.get(column);
            if (value == null ? actual == null : value.equals(actual)) {
                return row;
            }
        }
        return null;
    }

    private int maxLong(Table table, String column) throws Exception {
        int max = 0;
        for (Row row : table) {
            Object value = row.get(column);
            if (value instanceof Number) {
                max = Math.max(max, ((Number) value).intValue());
            }
        }
        return max;
    }

    private Map<String, Object> copy(Row row) {
        return new LinkedHashMap<>(row);
    }

    private void updateById(String tableName, String idColumn, int id, Map<String, Object> values) throws Exception {
        Table table = db.getTable(tableName);
        Row row = findRow(table, idColumn, id);
        if (row == null) {
            throw new IllegalStateException("Missing " + tableName + "." + idColumn + "=" + id);
        }
        row.putAll(values);
        table.updateRow(row);
    }

    private void renamePackage(int packageId, String name) throws Exception {
        updateById("t_package", "Package_ID", packageId, Map.of("Name", name, "ModifiedDate", new Date()));
        Table objects = db.getTable("t_object");
        Cursor cursor = CursorBuilder.createCursor(objects);
        for (Row row : cursor) {
            if ("Package".equals(row.get("Object_Type")) && String.valueOf(packageId).equals(s(row.get("PDATA1")))) {
                row.put("Name", name);
                row.put("ModifiedDate", new Date());
                objects.updateRow(row);
                return;
            }
        }
    }

    private void renameModelItems() throws Exception {
        renamePackage(9, "Treeningute funktsionaalne allsüsteem");
        renamePackage(12, "Treeningute elutsüklid");
        renamePackage(15, "Treeningute register");

        updateById("t_object", "Object_ID", 16, Map.of("Name", "Treener", "ModifiedDate", new Date()));
        updateById("t_object", "Object_ID", 44, Map.of("Name", "Treeningu_seisundi_liik", "ModifiedDate", new Date()));
        updateById("t_object", "Object_ID", 48, Map.of("Name", "Treeningu_kategooria", "ModifiedDate", new Date()));
        updateById("t_object", "Object_ID", 54, Map.of("Name", "Treeningu_kategooria_omamine", "ModifiedDate", new Date()));
        updateById("t_object", "Object_ID", 64, Map.of("Name", "Treeningu_kategooria_tüüp", "ModifiedDate", new Date()));

        updateById("t_diagram", "Diagram_ID", 2, Map.of("Name", "Treeningute funktsionaalne allsüsteem", "ModifiedDate", new Date()));
        updateById("t_diagram", "Diagram_ID", 3, Map.of("Name", "Treeningu lõpetamise tegevusdiagramm", "ModifiedDate", new Date()));
        updateById("t_diagram", "Diagram_ID", 4, Map.of("Name", "Treeningute register", "ModifiedDate", new Date()));
        updateById("t_diagram", "Diagram_ID", 6, Map.of("Name", "Treeningu seisundidiagramm", "ModifiedDate", new Date()));
        updateById("t_diagram", "Diagram_ID", 8, Map.of("Name", "Treeningute FASiga seotud pädevusalad ja registrid", "ModifiedDate", new Date()));

        updateById("t_connector", "Connector_ID", 43, Map.of(
            "Name", "Treener tahab registreerida uue treeningu, sest organisatsiooni jõuab teave uue treeningu kohta, millega kliendid saavad hakata tulevikus tehinguid tegema.",
            "PDATA3", "OP1, OP7, OP8"
        ));
        updateById("t_connector", "Connector_ID", 50, Map.of(
            "Name", "Treener tahab treeningu unustada, sest organisatsiooni jõuab teave, et treening sellisel kujul ei realiseeru ning seda ei saa hakata klientidele tehinguteks pakkuma",
            "PDATA3", "OP2"
        ));
        updateById("t_connector", "Connector_ID", 51, Map.of(
            "Name", "Treener tahab muuta treeningu andmeid, sest ilmneb, et nende registreerimisel on tehtud viga või treeningu atribuutide väärtuste ja seoste hulgas on toimunud muudatus",
            "PDATA3", "OP6, OP7, OP8"
        ));
        updateById("t_connector", "Connector_ID", 52, Map.of(
            "Name", "Treener tahab muuta treeningu andmeid, sest ilmneb, et nende registreerimisel on tehtud viga või treeningu atribuutide väärtuste ja seoste hulgas on toimunud muudatus",
            "PDATA3", "OP6, OP7, OP8"
        ));
    }

    private void fixStateTransitions() throws Exception {
        updateById("t_connector", "Connector_ID", 49, Map.of(
            "Name", "Treener tahab treeningu aktiveerida, sest treeningu ooteperiood või treeninguga seotud ajutised probleemid on lahenenud",
            "PDATA2", "Treening kuulub vähemalt ühte Treeningu_kategooriasse",
            "PDATA3", "OP3"
        ));
        updateById("t_connector", "Connector_ID", 45, Map.of(
            "Name", "Treener tahab treeningu uuesti aktiveerida, sest treeninguga seotud ajutised probleemid on lahenenud",
            "PDATA2", "Treening kuulub vähemalt ühte Treeningu_kategooriasse",
            "PDATA3", "OP3"
        ));
        updateById("t_connector", "Connector_ID", 44, Map.of(
            "Name", "Treener tahab treeningu ajutiselt kasutusest eemaldada, sest treeninguga on ilmnenud ajutise iseloomuga probleemid",
            "PDATA2", z(),
            "PDATA3", "OP4"
        ));
        updateById("t_connector", "Connector_ID", 46, Map.of(
            "Name", "Juhataja tahab treeningu lõpetada, sest treeninguga on ilmnenud püsiva iseloomuga probleemid või treeningut enam ei pakuta",
            "PDATA2", z(),
            "PDATA3", "OP5"
        ));
        updateById("t_connector", "Connector_ID", 47, Map.of(
            "Name", "Juhataja tahab mitteaktiivse treeningu lõpetada, sest treeninguga on ilmnenud püsiva iseloomuga probleemid või treeningut enam ei pakuta",
            "PDATA2", z(),
            "PDATA3", "OP5"
        ));
    }

    private int addObjectFromTemplate(int templateObjectId, int packageId, String type, int nType, String name, String note) throws Exception {
        Table table = db.getTable("t_object");
        table.setAllowAutoNumberInsert(true);
        Row template = findRow(table, "Object_ID", templateObjectId);
        Map<String, Object> row = copy(template);
        int id = maxLong(table, "Object_ID") + 1;
        row.put("Object_ID", id);
        row.put("Object_Type", type);
        row.put("Package_ID", packageId);
        row.put("Name", name);
        row.put("Note", note == null || note.isEmpty() ? z() : note);
        row.put("ea_guid", guid());
        row.put("NType", nType);
        row.put("Stereotype", z());
        row.put("PDATA1", z());
        row.put("PDATA2", z());
        row.put("PDATA3", z());
        row.put("PDATA4", z());
        row.put("PDATA5", z());
        row.put("Classifier", 0);
        row.put("Classifier_guid", z());
        row.put("ParentID", 0);
        row.put("CreatedDate", new Date());
        row.put("ModifiedDate", new Date());
        row.put("TPos", 0);
        table.addRowFromMap(row);
        return id;
    }

    private int addDiagramFromTemplate(int templateDiagramId, int packageId, String type, String name) throws Exception {
        Table table = db.getTable("t_diagram");
        table.setAllowAutoNumberInsert(true);
        Row template = findRow(table, "Diagram_ID", templateDiagramId);
        Map<String, Object> row = copy(template);
        int id = maxLong(table, "Diagram_ID") + 1;
        row.put("Diagram_ID", id);
        row.put("Package_ID", packageId);
        row.put("ParentID", 0);
        row.put("Diagram_Type", type);
        row.put("Name", name);
        row.put("ea_guid", guid());
        row.put("CreatedDate", new Date());
        row.put("ModifiedDate", new Date());
        row.put("TPos", 0);
        table.addRowFromMap(row);
        return id;
    }

    private void addDiagramObject(int diagramId, int objectId, int left, int top, int right, int bottom, int sequence) throws Exception {
        Table table = db.getTable("t_diagramobjects");
        table.setAllowAutoNumberInsert(true);
        Row template = table.iterator().next();
        Map<String, Object> row = copy(template);
        row.put("Diagram_ID", diagramId);
        row.put("Object_ID", objectId);
        row.put("RectLeft", left);
        row.put("RectTop", top);
        row.put("RectRight", right);
        row.put("RectBottom", bottom);
        row.put("Sequence", sequence);
        row.put("ObjectStyle", z());
        row.put("Instance_ID", maxLong(table, "Instance_ID") + 1);
        table.addRowFromMap(row);
    }

    private int addConnectorFromTemplate(int templateConnectorId, String type, String stereotype, int sourceId, int targetId, String name, String guard, String operation) throws Exception {
        Table table = db.getTable("t_connector");
        table.setAllowAutoNumberInsert(true);
        Row template = findRow(table, "Connector_ID", templateConnectorId);
        Map<String, Object> row = copy(template);
        int id = maxLong(table, "Connector_ID") + 1;
        String connectorGuid = guid();
        row.put("Connector_ID", id);
        row.put("Connector_Type", type);
        row.put("Stereotype", stereotype == null || stereotype.isBlank() ? z() : stereotype);
        row.put("Start_Object_ID", sourceId);
        row.put("End_Object_ID", targetId);
        row.put("Name", name == null || name.isEmpty() ? z() : name);
        row.put("PDATA2", guard == null || guard.isEmpty() ? z() : guard);
        row.put("PDATA3", operation == null || operation.isEmpty() ? z() : operation);
        row.put("ea_guid", connectorGuid);
        row.put("DiagramID", 0);
        row.put("SourceRole", z());
        row.put("DestRole", z());
        row.put("PDATA1", z());
        row.put("PDATA4", z());
        row.put("PDATA5", "SX=0;SY=0;EX=0;EY=0;");
        table.addRowFromMap(row);
        if (stereotype != null && !stereotype.isBlank()) {
            addStereotypeXref("connector", connectorGuid, stereotype);
        }
        return id;
    }

    private void addStereotypeXref(String type, String clientGuid, String stereotype) throws Exception {
        Table table = db.getTable("t_xref");
        Row template = table.iterator().next();
        Map<String, Object> row = copy(template);
        row.put("XrefID", guid());
        row.put("Name", "Stereotypes");
        row.put("Type", type + " property");
        row.put("Visibility", "Public");
        row.put("Namespace", z());
        row.put("Requirement", z());
        row.put("Constraint", z());
        row.put("Behavior", z());
        row.put("Partition", "0");
        row.put("Description", "@STEREO;Name=" + stereotype + ";@ENDSTEREO;");
        row.put("Client", clientGuid);
        row.put("Supplier", "<none>");
        row.put("Link", z());
        table.addRowFromMap(row);
    }

    private void populateActivationScenario() throws Exception {
        if (packageHasObjects(PKG_AKTIVEERI_STSENAARIUMID)) {
            return;
        }
        int partition = addObjectFromTemplate(30, PKG_AKTIVEERI_STSENAARIUMID, "ActivityPartition", 0, "Treener", "");
        int start = addObjectFromTemplate(32, PKG_AKTIVEERI_STSENAARIUMID, "StateNode", 100, "Algus", "");
        int view = addObjectFromTemplate(31, PKG_AKTIVEERI_STSENAARIUMID, "Action", 0, "Vaata kõiki ootel või mitteaktiivseid treeninguid", "");
        int hasItems = addObjectFromTemplate(33, PKG_AKTIVEERI_STSENAARIUMID, "Decision", 0, "Kas nimekirjas on eksemplare?", "");
        int select = addObjectFromTemplate(38, PKG_AKTIVEERI_STSENAARIUMID, "Action", 0, "Vali treening", "");
        int hasCategory = addObjectFromTemplate(33, PKG_AKTIVEERI_STSENAARIUMID, "Decision", 0, "Kas treening kuulub kategooriasse?", "");
        int activate = addObjectFromTemplate(40, PKG_AKTIVEERI_STSENAARIUMID, "Action", 0, "Aktiveeri valitud treening", "");
        int again = addObjectFromTemplate(41, PKG_AKTIVEERI_STSENAARIUMID, "Decision", 0, "Kas soovib jätkata?", "");
        int end = addObjectFromTemplate(37, PKG_AKTIVEERI_STSENAARIUMID, "StateNode", 101, "Lõpp", "");

        int diagram = addDiagramFromTemplate(3, PKG_AKTIVEERI_STSENAARIUMID, "Activity", "Treeningu aktiveerimise tegevusdiagramm");
        addDiagramObject(diagram, partition, 70, -50, 670, -760, 10);
        addDiagramObject(diagram, start, 120, -105, 140, -125, 9);
        addDiagramObject(diagram, view, 210, -90, 390, -145, 8);
        addDiagramObject(diagram, hasItems, 310, -215, 340, -250, 7);
        addDiagramObject(diagram, select, 285, -330, 385, -365, 6);
        addDiagramObject(diagram, hasCategory, 310, -440, 340, -475, 5);
        addDiagramObject(diagram, activate, 280, -545, 400, -590, 4);
        addDiagramObject(diagram, again, 505, -625, 535, -660, 3);
        addDiagramObject(diagram, end, 130, -615, 150, -635, 2);

        addConnectorFromTemplate(15, "ControlFlow", "", start, view, "", "", "");
        addConnectorFromTemplate(15, "ControlFlow", "", view, hasItems, "", "", "");
        addConnectorFromTemplate(17, "ControlFlow", "", hasItems, select, "", "Jah", "");
        addConnectorFromTemplate(17, "ControlFlow", "", hasItems, end, "", "Ei", "");
        addConnectorFromTemplate(15, "ControlFlow", "", select, hasCategory, "", "", "");
        addConnectorFromTemplate(17, "ControlFlow", "", hasCategory, activate, "", "Jah", "");
        addConnectorFromTemplate(17, "ControlFlow", "", hasCategory, again, "", "Ei", "");
        addConnectorFromTemplate(15, "ControlFlow", "", activate, again, "", "", "");
        addConnectorFromTemplate(17, "ControlFlow", "", again, view, "", "Jah", "");
        addConnectorFromTemplate(17, "ControlFlow", "", again, end, "", "Ei", "");
    }

    private boolean packageHasObjects(int packageId) throws Exception {
        for (Row row : db.getTable("t_object")) {
            Object value = row.get("Package_ID");
            if (value instanceof Number && ((Number) value).intValue() == packageId && !"Package".equals(row.get("Object_Type"))) {
                return true;
            }
        }
        return false;
    }

    private void addCompetencyDiagram() throws Exception {
        if (diagramExists(PKG_PADEVUSALAD, "Pädevusalad")) {
            return;
        }
        int diagram = addDiagramFromTemplate(2, PKG_PADEVUSALAD, "Use Case", "Pädevusalad");
        addDiagramObject(diagram, 16, 80, -80, 125, -170, 4);
        addDiagramObject(diagram, 17, 230, -80, 275, -170, 3);
        addDiagramObject(diagram, 62, 380, -80, 425, -170, 2);
        addDiagramObject(diagram, 18, 530, -80, 575, -170, 1);
    }

    private boolean diagramExists(int packageId, String name) throws Exception {
        for (Row row : db.getTable("t_diagram")) {
            if (name.equals(row.get("Name")) && row.get("Package_ID") instanceof Number && ((Number) row.get("Package_ID")).intValue() == packageId) {
                return true;
            }
        }
        return false;
    }

    private void addRegisterDiagrams() throws Exception {
        if (!diagramExists(PKG_ISIKUTE_REGISTER, "Isikute register")) {
            int diagram = addDiagramFromTemplate(4, PKG_ISIKUTE_REGISTER, "Logical", "Isikute register");
            addDiagramObject(diagram, 50, 230, -120, 410, -260, 4);
            addDiagramObject(diagram, 43, 35, -70, 145, -145, 3);
            addDiagramObject(diagram, 46, 500, -125, 620, -200, 2);
            addDiagramObject(diagram, 68, 235, -320, 395, -390, 1);
        }
        if (!diagramExists(PKG_TOOTAJATE_REGISTER, "Töötajate register")) {
            int diagram = addDiagramFromTemplate(4, PKG_TOOTAJATE_REGISTER, "Logical", "Töötajate register");
            addDiagramObject(diagram, 50, 45, -80, 225, -220, 6);
            addDiagramObject(diagram, 51, 285, -95, 400, -175, 5);
            addDiagramObject(diagram, 45, 500, -55, 630, -130, 4);
            addDiagramObject(diagram, 67, 280, -310, 455, -390, 3);
            addDiagramObject(diagram, 47, 55, -330, 190, -405, 2);
        }
    }

    private void populateDesignRegisterPackage() throws Exception {
        if (packageHasObjects(PKG_DISAIN_REGISTRID)) {
            return;
        }
        String[] tableNames = {
            "riik", "isiku_seisundi_liik", "isik", "kasutajakonto", "tootaja_seisundi_liik",
            "tootaja", "tootaja_roll", "tootaja_rolli_omamine", "treeningu_seisundi_liik",
            "treeningu_kategooria_tyyp", "treeningu_kategooria", "treening", "treeningu_kategooria_omamine"
        };
        String[] notes = {
            "PostgreSQL tabel. PK: riigi_kood. Veerud: riigi_kood, nimetus, on_aktiivne.",
            "PostgreSQL tabel. PK: kood. Veerud: kood, nimetus, on_aktiivne.",
            "PostgreSQL tabel. PK: isikukood + riigi_kood. Veerud: isikukood, riigi_kood, isiku_seisundi_liik_kood, synni_kp, reg_aeg, viimase_muutm_aeg, eesnimi, perenimi, elukoht, e_meil.",
            "PostgreSQL tabel. PK/FK: e_meil. Veerud: e_meil, parool, on_aktiivne.",
            "PostgreSQL tabel. PK: kood. Veerud: kood, nimetus, on_aktiivne.",
            "PostgreSQL tabel. PK/FK: e_meil. Veerud: e_meil, tootaja_seisundi_liik_kood.",
            "PostgreSQL tabel. PK: kood. Veerud: kood, nimetus, on_aktiivne, kirjeldus.",
            "PostgreSQL tabel. PK: tootaja_e_meil + tootaja_roll_kood + alguse_aeg. Veerud: tootaja_e_meil, tootaja_roll_kood, alguse_aeg, lopu_aeg.",
            "PostgreSQL tabel. PK: kood. Veerud: kood, nimetus, on_aktiivne.",
            "PostgreSQL tabel. PK: kood. Veerud: kood, nimetus, on_aktiivne.",
            "PostgreSQL tabel. PK: kood. Veerud: kood, treeningu_kategooria_tyyp_kood, nimetus, on_aktiivne.",
            "PostgreSQL tabel. PK: treeningu_kood. Veerud: treeningu_kood, treeningu_seisundi_liik_kood, registreerija_e_meil, viimase_muutja_e_meil, reg_aeg, viimase_muutm_aeg, nimetus, kirjeldus, kestus_minutites, maksimaalne_osalejate_arv, vajalik_varustus, hind.",
            "PostgreSQL tabel. PK: treeningu_kood + treeningu_kategooria_kood. Veerud: treeningu_kood, treeningu_kategooria_kood."
        };
        int[] ids = new int[tableNames.length];
        for (int i = 0; i < tableNames.length; i++) {
            ids[i] = addObjectFromTemplate(53, PKG_DISAIN_REGISTRID, "Class", 0, tableNames[i], notes[i]);
            updateById("t_object", "Object_ID", ids[i], Map.of("Stereotype", "table"));
            Row row = findRow(db.getTable("t_object"), "Object_ID", ids[i]);
            addStereotypeXref("element", s(row.get("ea_guid")), "table");
        }
        int diagram = addDiagramFromTemplate(4, PKG_DISAIN_REGISTRID, "Logical", "Treeningute registrite füüsiline disain");
        int[][] pos = {
            {20, -50, 160, -115}, {190, -50, 360, -115}, {395, -50, 580, -150}, {620, -50, 790, -115},
            {20, -215, 210, -280}, {245, -215, 390, -280}, {430, -215, 570, -280}, {610, -215, 820, -295},
            {20, -380, 220, -445}, {255, -380, 475, -445}, {510, -380, 700, -445}, {740, -380, 940, -485},
            {430, -560, 710, -625}
        };
        for (int i = 0; i < ids.length; i++) {
            addDiagramObject(diagram, ids[i], pos[i][0], pos[i][1], pos[i][2], pos[i][3], ids.length - i);
        }
    }

    private void addAttributeNotesAndConstraints() throws Exception {
        Table attributes = db.getTable("t_attribute");
        Map<Integer, String> notesById = new LinkedHashMap<>();
        notesById.put(1, "Klassifikaatori väärtust esitav kood. Kohustuslik ja klassifikaatori tüübi piires unikaalne.");
        notesById.put(2, "Klassifikaatori väärtuse ametlik eestikeelne nimetus. Kohustuslik ja mittetühi.");
        notesById.put(21, "Näitab, kas klassifikaatori väärtust saab kasutada uute andmete liigitamisel.");
        notesById.put(7, "Riigi poolt väljastatud isiku identifikaator. Koos riigi identifikaatoriga isiku loomulik identifikaator.");
        notesById.put(8, "Isiku eesnimi. Vähemalt üks kahest atribuudist eesnimi või perenimi peab olema registreeritud.");
        notesById.put(9, "Isiku perenimi. Vähemalt üks kahest atribuudist eesnimi või perenimi peab olema registreeritud.");
        notesById.put(10, "Isiku sünnikuupäev sünnikoha kohaliku aja järgi.");
        notesById.put(11, "Isiku alalise elukoha aadress.");
        notesById.put(13, "Isiku e-posti aadress, mida kasutatakse kasutaja tuvastamisel kasutajanimena.");
        notesById.put(14, "Isiku registreerimise kuupäev ja kellaaeg.");
        notesById.put(19, "Isiku andmete viimase muutmise kuupäev ja kellaaeg.");
        notesById.put(12, "Parooli ja soola põhjal leitud räsiväärtus.");
        notesById.put(18, "Näitab, kas konto parooli on võimalik süsteemi sisenemiseks kasutada.");
        notesById.put(15, "Rollist tulenevate õiguste ja kohustuste vabatekstiline kirjeldus.");
        notesById.put(16, "Kuupäev ja kellaaeg, millest alates töötaja kannab rolli.");
        notesById.put(17, "Kuupäev ja kellaaeg, milleni töötaja kannab rolli.");
        notesById.put(4, "Treeningute arvuline kood, mille sisestab inimkasutaja. Treeningu loomulik identifikaator.");
        notesById.put(6, "Treeningu registreerimise kuupäev ja kellaaeg.");
        notesById.put(20, "Treeningu andmete viimase muutmise kuupäev ja kellaaeg.");

        Cursor cursor = CursorBuilder.createCursor(attributes);
        for (Row row : cursor) {
            int id = ((Number) row.get("ID")).intValue();
            if (notesById.containsKey(id)) {
                row.put("Notes", notesById.get(id));
            }
            if (id == 4 || id == 7) {
                row.put("LowerBound", "1");
                row.put("UpperBound", "1");
            }
            attributes.updateRow(row);
        }

        Table constraints = db.getTable("t_attributeconstraints");
        if (constraints.iterator().hasNext()) {
            return;
        }
        addAttrConstraint(42, 1, "kood", "Mandatory", "Kood on kohustuslik.");
        addAttrConstraint(42, 1, "kood", "Unique", "Kood on klassifikaatori tüübi piires unikaalne.");
        addAttrConstraint(42, 2, "nimetus", "Mandatory", "Nimetus on kohustuslik ja ei tohi olla tühi string.");
        addAttrConstraint(42, 21, "on_aktiivne", "Mandatory", "Väärtus on kohustuslik.");
        addAttrConstraint(50, 7, "isikukood", "Mandatory", "Isikukood on kohustuslik.");
        addAttrConstraint(50, 7, "isikukood", "Format", "Lubatud on tähed, numbrid, tühikud, sidekriipsud, plussmärgid, võrdusmärgid ja kaldkriipsud.");
        addAttrConstraint(50, 7, "isikukood", "Unique", "Koos isikukoodi riigiga isiku unikaalne identifikaator.");
        addAttrConstraint(50, 10, "sünni_kp", "Range", "Väärtus peab olema vahemikus 01.01.1900 kuni 31.12.2100.");
        addAttrConstraint(50, 13, "e_meil", "Mandatory", "E-posti aadress on kohustuslik.");
        addAttrConstraint(50, 13, "e_meil", "Length", "Võib olla kuni 254 märki pikk ja peab sisaldama @ märki.");
        addAttrConstraint(50, 13, "e_meil", "Unique", "Tõstutundetu unikaalne identifikaator.");
        addAttrConstraint(50, 19, "viimase_muutm_aeg", "Range", "Viimase muutmise aeg peab olema registreerimise ajast suurem või sellega võrdne.");
        addAttrConstraint(68, 12, "parool", "Mandatory", "Parooli räsiväärtus on kohustuslik ja ei tohi olla tühi string.");
        addAttrConstraint(68, 18, "on_aktiivne", "Mandatory", "Väärtus on kohustuslik.");
        addAttrConstraint(47, 15, "kirjeldus", "Not empty", "Kui kirjeldus registreeritakse, siis ei tohi see olla tühi string.");
        addAttrConstraint(67, 16, "alguse_aeg", "Mandatory", "Rolli omamise alguse aeg on kohustuslik.");
        addAttrConstraint(67, 17, "lõpu_aeg", "Range", "Kui lõpu aeg registreeritakse, siis peab see olema alguse ajast suurem.");
        addAttrConstraint(53, 4, "treeningu_kood", "Mandatory", "Treeningu kood on kohustuslik.");
        addAttrConstraint(53, 4, "treeningu_kood", "Unique", "Treeningu kood on treeningu unikaalne identifikaator.");
        addAttrConstraint(53, 4, "treeningu_kood", "Range", "Väärtus peab olema positiivne täisarv.");
        addAttrConstraint(53, 6, "reg_aeg", "Mandatory", "Registreerimise aeg on kohustuslik.");
        addAttrConstraint(53, 20, "viimase_muutm_aeg", "Range", "Viimase muutmise aeg peab olema registreerimise ajast suurem või sellega võrdne.");
    }

    private void addUseCaseExtendsAndScenarioText() throws Exception {
        addUseCaseConnectorIfMissing(63, 23, "extend");
        addUseCaseConnectorIfMissing(22, 28, "extend");
        addActivationScenarioRows();
    }

    private void addUseCaseConnectorIfMissing(int sourceId, int targetId, String stereotype) throws Exception {
        for (Row row : db.getTable("t_connector")) {
            if ("UseCase".equals(row.get("Connector_Type"))
                && row.get("Start_Object_ID") instanceof Number
                && row.get("End_Object_ID") instanceof Number
                && ((Number) row.get("Start_Object_ID")).intValue() == sourceId
                && ((Number) row.get("End_Object_ID")).intValue() == targetId) {
                return;
            }
        }
        addConnectorFromTemplate(12, "UseCase", stereotype, sourceId, targetId, z(), z(), z());
    }

    private void addActivationScenarioRows() throws Exception {
        Table scenarios = db.getTable("t_objectscenarios");
        for (Row row : scenarios) {
            if (row.get("Object_ID") instanceof Number && ((Number) row.get("Object_ID")).intValue() == 25) {
                return;
            }
        }
        addScenario(25, "Tüüpiline sündmuste järjestus", "Basic Path",
            "1. Treener soovib aktiveerida treeningu.\n"
                + "2. Käivitub kasutusjuht \"Vaata kõiki ootel või mitteaktiivseid treeninguid\".\n"
                + "3. Treener valib nimekirjast treeningu ja annab korralduse see aktiivseks muuta.\n"
                + "4. Süsteem kontrollib, et treening kuulub vähemalt ühte Treeningu_kategooriasse.\n"
                + "5. Süsteem salvestab seisundimuudatuse operatsiooniga OP3.");
        addScenario(25, "Alternatiivid", "Alternate",
            "3a. Kui nimekirjas ei ole ühtegi ootel või mitteaktiivset treeningut, siis ei saa Treener jätkata.\n"
                + "4a. Kui treening ei kuulu ühtegi Treeningu_kategooriasse, siis aktiveerimine ebaõnnestub.");
    }

    private void addScenario(int objectId, String scenario, String type, String notes) throws Exception {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("Object_ID", objectId);
        row.put("Scenario", scenario);
        row.put("ScenarioType", type);
        row.put("EValue", 0.0d);
        row.put("Notes", notes);
        row.put("XMLContent", z());
        row.put("ea_guid", guid());
        db.getTable("t_objectscenarios").addRowFromMap(row);
    }

    private void addAttrConstraint(int objectId, int attrId, String attrName, String type, String notes) throws Exception {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("Object_ID", objectId);
        row.put("Constraint", type + "_" + attrName);
        row.put("AttName", attrName);
        row.put("Type", type);
        row.put("Notes", notes);
        row.put("ID", attrId);
        db.getTable("t_attributeconstraints").addRowFromMap(row);
    }
}
