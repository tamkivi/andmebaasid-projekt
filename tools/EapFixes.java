import com.healthmarketscience.jackcess.Cursor;
import com.healthmarketscience.jackcess.CursorBuilder;
import com.healthmarketscience.jackcess.Column;
import com.healthmarketscience.jackcess.Database;
import com.healthmarketscience.jackcess.DatabaseBuilder;
import com.healthmarketscience.jackcess.Row;
import com.healthmarketscience.jackcess.Table;

import java.io.File;
import java.nio.channels.FileChannel;
import java.nio.file.StandardOpenOption;
import java.util.Date;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

public class EapFixes {
    private static final int PKG_ANALYSIS_SUBSYSTEM = 9;
    private static final int PKG_STATE_MODELS = 12;
    private static final int PKG_REGISTER = 15;
    private static final int TEMPLATE_ACTOR = 16;
    private static final int TEMPLATE_USE_CASE = 23;
    private static final int TEMPLATE_CLASS = 53;

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
            new EapFixes(db).apply();
        }
    }

    private void apply() throws Exception {
        renamePackagesAndDiagrams();
        replaceOldProjectText();
        neutralizeTemplateClass();
        removeStaleTreeningPhysicalClass();
        ensureActors();
        ensureUseCases();
        ensureCoreClasses();
        ensurePhysicalTables();
        removeOldPaymentLanguage();
    }

    private static String guid() {
        return "{" + UUID.randomUUID().toString().toUpperCase() + "}";
    }

    private static String z() {
        return " ";
    }

    private static String s(Object value) {
        return value == null ? "" : value.toString();
    }

    private Map<String, Object> copy(Row row) {
        return new LinkedHashMap<>(row);
    }

    private String findColumn(Table table, String wanted) {
        for (Column column : table.getColumns()) {
            if (column.getName().equalsIgnoreCase(wanted)) {
                return column.getName();
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

    private Row findRow(Table table, String column, Object value) throws Exception {
        Cursor cursor = CursorBuilder.createCursor(table);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            Object actual = row.get(column);
            if (value == null ? actual == null : value.equals(actual)) {
                return row;
            }
        }
        return null;
    }

    private void updateById(String tableName, String idColumn, int id, Map<String, Object> values) throws Exception {
        Table table = db.getTable(tableName);
        Cursor cursor = CursorBuilder.createCursor(table);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            Object actual = row.get(idColumn);
            if (actual instanceof Number && ((Number) actual).intValue() == id) {
                row.putAll(values);
                row.put("ModifiedDate", new Date());
                cursor.updateCurrentRowFromMap(row);
                return;
            }
        }
    }

    private int findObjectId(String type, String name) throws Exception {
        for (Row row : db.getTable("t_object")) {
            if (type.equals(row.get("Object_Type")) && name.equals(row.get("Name")) && row.get("Object_ID") instanceof Number) {
                return ((Number) row.get("Object_ID")).intValue();
            }
        }
        return 0;
    }

    private void deleteRowsByNumber(String tableName, String columnName, int value) throws Exception {
        Table table = db.getTable(tableName);
        if (table == null || findColumn(table, columnName) == null) {
            return;
        }
        Cursor cursor = CursorBuilder.createCursor(table);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            Object actual = row.get(columnName);
            if (actual instanceof Number && ((Number) actual).intValue() == value) {
                cursor.deleteCurrentRow();
            }
        }
    }

    private void deleteConnectorDependencies(Set<Integer> connectorIds) throws Exception {
        if (connectorIds.isEmpty()) {
            return;
        }
        Table diagramLinks = db.getTable("t_diagramlinks");
        if (diagramLinks != null && findColumn(diagramLinks, "ConnectorID") != null) {
            Cursor cursor = CursorBuilder.createCursor(diagramLinks);
            Row row;
            while ((row = cursor.getNextRow()) != null) {
                Object actual = row.get("ConnectorID");
                if (actual instanceof Number && connectorIds.contains(((Number) actual).intValue())) {
                    cursor.deleteCurrentRow();
                }
            }
        }
    }

    private void deleteConnectorsForObject(int objectId) throws Exception {
        Table connectors = db.getTable("t_connector");
        if (connectors == null) {
            return;
        }
        Set<Integer> connectorIds = new HashSet<>();
        Cursor cursor = CursorBuilder.createCursor(connectors);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            Object start = row.get("Start_Object_ID");
            Object end = row.get("End_Object_ID");
            boolean referencesObject =
                (start instanceof Number && ((Number) start).intValue() == objectId)
                || (end instanceof Number && ((Number) end).intValue() == objectId);
            if (referencesObject) {
                Object connectorId = row.get("Connector_ID");
                if (connectorId instanceof Number) {
                    connectorIds.add(((Number) connectorId).intValue());
                }
                cursor.deleteCurrentRow();
            }
        }
        deleteConnectorDependencies(connectorIds);
    }

    private void deleteObjectAndDependencies(int objectId) throws Exception {
        for (String tableName : new String[] {
            "t_attribute", "t_attributeconstraints", "t_diagramobjects", "t_method",
            "t_objectconstraint", "t_objecteffort", "t_objectfiles", "t_objectmetrics",
            "t_objectproblems", "t_objectproperties", "t_objectrequires", "t_objectresource",
            "t_objectrisks", "t_objectscenarios", "t_objecttests", "t_objecttrx", "t_operation"
        }) {
            deleteRowsByNumber(tableName, "Object_ID", objectId);
        }
        deleteConnectorsForObject(objectId);
        deleteRowsByNumber("t_object", "Object_ID", objectId);
    }

    private void neutralizeTemplateClass() throws Exception {
        updateById("t_object", "Object_ID", TEMPLATE_CLASS, Map.of(
            "Name", "Mallklass",
            "Note", "Tehniline lähteklass, mida EAP post-protsessor kasutab uute objektide kopeerimisel. Ei ole osa esitatavast domeenimudelist.",
            "Package_ID", 0
        ));
        deleteRowsByNumber("t_attribute", "Object_ID", TEMPLATE_CLASS);
        deleteRowsByNumber("t_diagramobjects", "Object_ID", TEMPLATE_CLASS);
        deleteConnectorsForObject(TEMPLATE_CLASS);
    }

    private void removeStaleTreeningPhysicalClass() throws Exception {
        Table objects = db.getTable("t_object");
        Set<Integer> staleObjectIds = new HashSet<>();
        for (Row row : objects) {
            Object id = row.get("Object_ID");
            if (id instanceof Number
                && "Class".equals(row.get("Object_Type"))
                && "treening".equals(row.get("Name"))) {
                staleObjectIds.add(((Number) id).intValue());
            }
        }
        for (int objectId : staleObjectIds) {
            deleteObjectAndDependencies(objectId);
        }
    }

    private int ensureObject(String type, int packageId, int templateId, String name, String note) throws Exception {
        int existing = findObjectId(type, name);
        if (existing != 0) {
            updateById("t_object", "Object_ID", existing, Map.of("Name", name, "Note", note));
            return existing;
        }

        Table table = db.getTable("t_object");
        table.setAllowAutoNumberInsert(true);
        Row template = findRow(table, "Object_ID", templateId);
        Map<String, Object> row = copy(template);
        int id = maxLong(table, "Object_ID") + 1;
        row.put("Object_ID", id);
        row.put("Object_Type", type);
        row.put("Package_ID", packageId);
        row.put("Name", name);
        row.put("Alias", z());
        row.put("Note", note == null || note.isBlank() ? z() : note);
        row.put("ea_guid", guid());
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

    private void renamePackagesAndDiagrams() throws Exception {
        updateById("t_package", "Package_ID", PKG_ANALYSIS_SUBSYSTEM, Map.of(
            "Name", "Rühmatreeningute ajakava, registreerimise ja osalemise funktsionaalne allsüsteem"
        ));
        updateById("t_package", "Package_ID", PKG_STATE_MODELS, Map.of(
            "Name", "Treeningukorra ja registreeringu elutsüklid"
        ));
        updateById("t_package", "Package_ID", PKG_REGISTER, Map.of(
            "Name", "Rühmatreeningute ajakava ja registreeringute register"
        ));

        updateById("t_diagram", "Diagram_ID", 2, Map.of("Name", "Rühmatreeningute funktsionaalne allsüsteem"));
        updateById("t_diagram", "Diagram_ID", 3, Map.of("Name", "Registreerimise ja ootejärjekorra tegevusvoog"));
        updateById("t_diagram", "Diagram_ID", 4, Map.of("Name", "Rühmatreeningute registri füüsiline mudel"));
        updateById("t_diagram", "Diagram_ID", 6, Map.of("Name", "Treeningukorra seisundimudel"));
        updateById("t_diagram", "Diagram_ID", 8, Map.of("Name", "Rühmatreeningute pädevusalad ja registrid"));
    }

    private void replaceOldProjectText() throws Exception {
        Map<String, String> replacements = new LinkedHashMap<>();
        replacements.put("Treeningute funktsionaalne allsüsteem", "Rühmatreeningute ajakava, registreerimise ja osalemise funktsionaalne allsüsteem");
        replacements.put("treeningute funktsionaalne allsüsteem", "rühmatreeningute ajakava, registreerimise ja osalemise funktsionaalne allsüsteem");
        replacements.put("Treeningute register", "Rühmatreeningute ajakava ja registreeringute register");
        replacements.put("treeningute register", "rühmatreeningute ajakava ja registreeringute register");
        replacements.put("Treeningu_seisundi_liik", "Treeningukorra_seisundi_liik");
        replacements.put("treeningu_seisundi_liik", "treeningukorra_seisundi_liik");
        replacements.put("Treeningu_kategooria_omamine", "Treeninguliigi_kategooria_omamine");
        replacements.put("treeningu_kategooria_omamine", "treeninguliigi_kategooria_omamine");
        replacements.put("treeningu_kood", "treeningukorra_kood");
        replacements.put("Registreeri treening", "Planeeri treeningukord");
        replacements.put("Aktiveeri treening", "Ava registreerimine");
        replacements.put("Lõpeta treening", "Lõpeta treeningukord");
        replacements.put("Vaata aktiivseid treeninguid", "Vaata avatud rühmatreeningute ajakava");
        replacements.put("Vaata treeningute koondaruannet", "Vaata täituvuse statistikat");

        for (String tableName : new String[] {"t_package", "t_object", "t_diagram", "t_attribute", "t_operation", "t_connector"}) {
            Table table = db.getTable(tableName);
            if (table == null) {
                continue;
            }
            Cursor cursor = CursorBuilder.createCursor(table);
            Row row;
            while ((row = cursor.getNextRow()) != null) {
                boolean changed = false;
                for (Column column : table.getColumns()) {
                    Object value = row.get(column.getName());
                    if (!(value instanceof String)) {
                        continue;
                    }
                    String current = (String) value;
                    String updated = current;
                    for (Map.Entry<String, String> entry : replacements.entrySet()) {
                        updated = updated.replace(entry.getKey(), entry.getValue());
                    }
                    if (!updated.equals(current)) {
                        row.put(column.getName(), updated);
                        changed = true;
                    }
                }
                if (changed) {
                    if (findColumn(table, "ModifiedDate") != null) {
                        row.put("ModifiedDate", new Date());
                    }
                    cursor.updateCurrentRowFromMap(row);
                }
            }
        }
    }

    private void ensureActors() throws Exception {
        ensureObject("Actor", 4, TEMPLATE_ACTOR, "Juhataja", "Sisemine kasutaja, kes planeerib, avab, sulgeb ja tühistab treeningukordi ning vaatab statistikat.");
        ensureObject("Actor", 4, TEMPLATE_ACTOR, "Treener", "Sisemine kasutaja, kes näeb enda treeningukordi ja märgib osalemist.");
        ensureObject("Actor", 4, TEMPLATE_ACTOR, "Klient", "Väline kasutaja, kes registreerub treeningukorrale ja tühistab enda registreeringu.");
        ensureObject("Actor", 4, TEMPLATE_ACTOR, "Süsteem", "Automaatne osapool, mis edendab ootejärjekorda ja jõustab andmebaasi ärireegleid.");
    }

    private void ensureUseCases() throws Exception {
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Planeeri treeningukord", "Juhataja loob konkreetse treeningukorra koos treeneri, ruumi, aja ja mahupiiranguga.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Ava registreerimine", "Juhataja muudab kavandatud treeningukorra klientidele registreerimiseks avatuks.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Registreeru treeningukorrale", "Klient saab kinnitatud registreeringu või ootejärjekorra koha.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Tühista registreering", "Klient tühistab enda aktiivse registreeringu ja süsteem edendab vajadusel ootejärjekorda.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Märgi osalemine", "Treener või juhataja märgib kinnitatud registreeringule osalemise tulemuse.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Vaata täituvuse statistikat", "Juhataja vaatab treeningukordade täituvust ja ootejärjekorda.");
    }

    private void ensureCoreClasses() throws Exception {
        ensureClassWithColumns("Treeninguliik", "Korduv rühmatreeningu mall, mille alusel planeeritakse konkreetsed treeningukorrad.", new String[][] {
            {"treeninguliigi_kood", "integer", "PK"},
            {"nimetus", "varchar(200)", "UNIQUE, NOT NULL"},
            {"kestus_minutites", "integer", "NOT NULL"},
            {"seisundi_kood", "varchar(10)", "FK treeninguliigi_seisundi_liik.kood"}
        });
        ensureClassWithColumns("Treeningukord", "Kalendris toimuv rühmatreening koos ruumi, treeneri, aja ja mahupiiranguga.", new String[][] {
            {"treeningukorra_kood", "integer", "PK"},
            {"treeninguliigi_kood", "integer", "FK treeninguliik.treeninguliigi_kood"},
            {"treener_e_meil", "varchar(254)", "FK tootaja.e_meil"},
            {"ruumi_kood", "varchar(10)", "FK ruum.ruumi_kood"},
            {"alguse_aeg", "timestamp", "NOT NULL"},
            {"lopu_aeg", "timestamp", "NOT NULL"},
            {"maksimaalne_osalejate_arv", "integer", "CHECK > 0"},
            {"seisundi_kood", "varchar(10)", "FK treeningukorra_seisundi_liik.kood"}
        });
        ensureClassWithColumns("Registreering", "Kliendi kinnitatud või ootejärjekorras registreering treeningukorrale.", new String[][] {
            {"registreeringu_kood", "integer", "PK"},
            {"treeningukorra_kood", "integer", "FK treeningukord.treeningukorra_kood"},
            {"klient_e_meil", "varchar(254)", "FK klient.e_meil"},
            {"seisundi_kood", "varchar(10)", "FK registreeringu_seisundi_liik.kood"},
            {"ootejarjekorra_nr", "integer", "ootejärjekorra positsioon"}
        });
        ensureClassWithColumns("Osalemine", "Kinnitatud registreeringu osalemise tulemus.", new String[][] {
            {"registreeringu_kood", "integer", "PK, FK registreering.registreeringu_kood"},
            {"osales", "boolean", "NOT NULL"},
            {"markija_e_meil", "varchar(254)", "FK tootaja.e_meil"}
        });
        ensureClassWithColumns("Ruum", "Jõusaali saal või stuudio, mille mahutavus piirab treeningukorra osalejate arvu.", new String[][] {
            {"ruumi_kood", "varchar(10)", "PK"},
            {"nimetus", "varchar(200)", "UNIQUE, NOT NULL"},
            {"mahutavus", "integer", "CHECK > 0"}
        });
        ensureClassWithColumns("Klient", "Kasutajakontoga seotud osaleja.", new String[][] {
            {"e_meil", "varchar(254)", "PK, FK kasutajakonto.e_meil"},
            {"on_aktiivne", "boolean", "NOT NULL"}
        });
        ensureClassWithColumns("Treeneri_padevus", "Seos, mis määrab, millist treeninguliiki treener võib juhendada.", new String[][] {
            {"tootaja_e_meil", "varchar(254)", "PK, FK tootaja.e_meil"},
            {"treeninguliigi_kood", "integer", "PK, FK treeninguliik.treeninguliigi_kood"},
            {"alates", "date", "NOT NULL"},
            {"kuni", "date", "nullable"}
        });
    }

    private void ensurePhysicalTables() throws Exception {
        for (String tableName : new String[] {
            "klient", "treeninguliigi_seisundi_liik", "treeninguliik", "ruum",
            "treeneri_padevus", "treeningukorra_seisundi_liik", "treeningukord",
            "registreeringu_seisundi_liik", "registreering", "osalemine"
        }) {
            ensureObject("Class", 7, TEMPLATE_CLASS, tableName, "PostgreSQL füüsiline tabel uues rühmatreeningute protsessimudelis.");
        }
    }

    private void ensureClassWithColumns(String name, String note, String[][] columns) throws Exception {
        int id = ensureObject("Class", PKG_REGISTER, TEMPLATE_CLASS, name, note);
        for (String[] column : columns) {
            addAttributeIfMissing(id, column[0], column[1], column[2]);
        }
    }

    private boolean attributeExists(int objectId, String name) throws Exception {
        for (Row row : db.getTable("t_attribute")) {
            if (row.get("Object_ID") instanceof Number
                && ((Number) row.get("Object_ID")).intValue() == objectId
                && name.equals(row.get("Name"))) {
                return true;
            }
        }
        return false;
    }

    private int maxAttributePos(int objectId) throws Exception {
        int max = 0;
        for (Row row : db.getTable("t_attribute")) {
            if (row.get("Object_ID") instanceof Number
                && ((Number) row.get("Object_ID")).intValue() == objectId
                && row.get("Pos") instanceof Number) {
                max = Math.max(max, ((Number) row.get("Pos")).intValue());
            }
        }
        return max;
    }

    private void addAttributeIfMissing(int objectId, String name, String type, String note) throws Exception {
        if (attributeExists(objectId, name)) {
            return;
        }
        Table table = db.getTable("t_attribute");
        table.setAllowAutoNumberInsert(true);
        Row template = table.iterator().next();
        Map<String, Object> row = copy(template);
        row.put("ID", maxLong(table, "ID") + 1);
        row.put("Object_ID", objectId);
        row.put("Name", name);
        row.put("Scope", "Private");
        row.put("Stereotype", z());
        row.put("LowerBound", note.contains("nullable") ? "0" : "1");
        row.put("UpperBound", "1");
        row.put("Notes", note);
        row.put("Type", type);
        row.put("Pos", maxAttributePos(objectId) + 1);
        row.put("ea_guid", guid());
        table.addRowFromMap(row);
    }

    private void removeOldPaymentLanguage() throws Exception {
        for (String tableName : new String[] {"t_object", "t_attribute", "t_connector"}) {
            Table table = db.getTable(tableName);
            Cursor cursor = CursorBuilder.createCursor(table);
            Row row;
            while ((row = cursor.getNextRow()) != null) {
                boolean changed = false;
                for (Column column : table.getColumns()) {
                    Object value = row.get(column.getName());
                    if (!(value instanceof String)) {
                        continue;
                    }
                    String updated = ((String) value)
                        .replace("Treeningu hind eurodes koos käibemaksuga, maksimaalselt kaks kohta pärast koma.", "Makseid ja hindu selles allsüsteemis ei modelleerita.")
                        .replace("Treeningu hind eurodes. Kohustuslik null või positiivne rahasumma.", "Makseid ja hindu selles allsüsteemis ei modelleerita.")
                        .replace("hind_ei_kuulu_skoopi", "makseid_ei_modelleerita");
                    if (!updated.equals(value)) {
                        row.put(column.getName(), updated);
                        changed = true;
                    }
                }
                if (changed) {
                    cursor.updateCurrentRowFromMap(row);
                }
            }
        }
    }
}
