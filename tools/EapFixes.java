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
    private static final int PHYSICAL_PACKAGE = 7;
    private static final int PHYSICAL_DIAGRAM = 13;

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
        removeStaleWorkbookObjects();
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

    private static String duid() {
        return UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase();
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

    private boolean containsAny(String value, Set<String> fragments) {
        if (value == null || value.isBlank()) {
            return false;
        }
        for (String fragment : fragments) {
            if (value.contains(fragment)) {
                return true;
            }
        }
        return false;
    }

    private void removeStaleWorkbookObjects() throws Exception {
        Set<String> staleObjectNames = Set.of(
            "Muuda treening mitteaktiivseks",
            "Unusta treening",
            "Vali treening",
            "Lõpeta valitud treening",
            "Aktiveeri valitud treening",
            "Kas treening kuulub kategooriasse?"
        );
        Table objects = db.getTable("t_object");
        Set<Integer> staleObjectIds = new HashSet<>();
        for (Row row : objects) {
            Object id = row.get("Object_ID");
            Object name = row.get("Name");
            if (id instanceof Number && name instanceof String && staleObjectNames.contains(name)) {
                staleObjectIds.add(((Number) id).intValue());
            }
        }
        for (int objectId : staleObjectIds) {
            deleteObjectAndDependencies(objectId);
        }

        Set<String> staleConnectorFragments = Set.of(
            "treeningu unustada",
            "treening sellisel kujul ei realiseeru",
            "treening kuulub kategooriasse"
        );
        Table connectors = db.getTable("t_connector");
        if (connectors == null) {
            return;
        }
        Set<Integer> staleConnectorIds = new HashSet<>();
        Cursor cursor = CursorBuilder.createCursor(connectors);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            boolean stale = false;
            for (Column column : connectors.getColumns()) {
                Object value = row.get(column.getName());
                if (value instanceof String && containsAny((String) value, staleConnectorFragments)) {
                    stale = true;
                    break;
                }
            }
            if (stale) {
                Object connectorId = row.get("Connector_ID");
                if (connectorId instanceof Number) {
                    staleConnectorIds.add(((Number) connectorId).intValue());
                }
                cursor.deleteCurrentRow();
            }
        }
        deleteConnectorDependencies(staleConnectorIds);
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
        replacements.put("treeningu_kood", "treeningukorra_id");
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
            {"treeninguliigi_id", "integer", "PK"},
            {"nimetus", "varchar(200)", "UNIQUE, NOT NULL"},
            {"kestus_minutites", "integer", "NOT NULL"},
            {"treeninguliigi_seisundi_kood", "varchar(10)", "FK treeninguliigi_seisundi_liik.treeninguliigi_seisundi_kood"}
        });
        ensureClassWithColumns("Treeningukord", "Kalendris toimuv rühmatreening koos ruumi, treeneri, aja ja mahupiiranguga.", new String[][] {
            {"treeningukorra_id", "integer", "PK"},
            {"treeninguliigi_id", "integer", "FK treeninguliik.treeninguliigi_id"},
            {"treener_e_meil", "varchar(254)", "FK tootaja.e_meil"},
            {"ruumi_kood", "varchar(10)", "FK ruum.ruumi_kood"},
            {"alguse_aeg", "timestamp", "NOT NULL"},
            {"lopu_aeg", "timestamp", "NOT NULL"},
            {"maksimaalne_osalejate_arv", "integer", "CHECK > 0"},
            {"treeningukorra_seisundi_kood", "varchar(10)", "FK treeningukorra_seisundi_liik.treeningukorra_seisundi_kood"}
        });
        ensureClassWithColumns("Registreering", "Kliendi kinnitatud või ootejärjekorras registreering treeningukorrale.", new String[][] {
            {"registreeringu_id", "integer", "PK"},
            {"treeningukorra_id", "integer", "FK treeningukord.treeningukorra_id"},
            {"klient_e_meil", "varchar(254)", "FK klient.e_meil"},
            {"registreeringu_seisundi_kood", "varchar(10)", "FK registreeringu_seisundi_liik.registreeringu_seisundi_kood"}
        });
        ensureClassWithColumns("OotejarjekorraKoht", "Ootejärjekorras oleva registreeringu kohustuslik järjekorrakoht.", new String[][] {
            {"registreeringu_id", "integer", "PK, FK registreering.registreeringu_id"},
            {"treeningukorra_id", "integer", "FK treeningukord.treeningukorra_id"},
            {"ootejarjekorra_nr", "integer", "UNIQUE per treeningukord, NOT NULL"}
        });
        ensureClassWithColumns("Osalemine", "Kinnitatud registreeringu osalemise tulemus.", new String[][] {
            {"registreeringu_id", "integer", "PK, FK registreering.registreeringu_id"},
            {"on_osalenud", "boolean", "NOT NULL"},
            {"markija_e_meil", "varchar(254)", "FK tootaja.e_meil"}
        });
        ensureClassWithColumns("Ruum", "Jõusaali saal või stuudio, mille mahutavus piirab treeningukorra osalejate arvu.", new String[][] {
            {"ruumi_kood", "varchar(10)", "PK"},
            {"nimetus", "varchar(200)", "UNIQUE, NOT NULL"},
            {"mahutavus", "integer", "CHECK > 0"}
        });
        ensureClassWithColumns("Varustus", "Toetav põhiandmete objekt, mille abil kontrollitakse ruumi sobivust treeninguliigile.", new String[][] {
            {"varustuse_kood", "varchar(10)", "PK"},
            {"nimetus", "varchar(100)", "UNIQUE, NOT NULL"},
            {"on_aktiivne", "boolean", "NOT NULL"}
        });
        ensureClassWithColumns("Ruumi_varustuse_omamine", "Seos ruumi ja olemasoleva varustuse koguse vahel.", new String[][] {
            {"ruumi_kood", "varchar(10)", "PK, FK ruum.ruumi_kood"},
            {"varustuse_kood", "varchar(10)", "PK, FK varustus.varustuse_kood"},
            {"kogus", "integer", "CHECK > 0"}
        });
        ensureClassWithColumns("Treeninguliigi_varustuse_noue", "Treeninguliigi kohustuslik või soovituslik varustuse nõue.", new String[][] {
            {"treeninguliigi_id", "integer", "PK, FK treeninguliik.treeninguliigi_id"},
            {"varustuse_kood", "varchar(10)", "PK, FK varustus.varustuse_kood"},
            {"minimaalne_kogus", "integer", "CHECK > 0"},
            {"on_kohustuslik", "boolean", "NOT NULL"}
        });
        ensureClassWithColumns("Klient", "Kasutajakontoga seotud osaleja.", new String[][] {
            {"e_meil", "varchar(254)", "PK, FK kasutajakonto.e_meil"},
            {"on_aktiivne", "boolean", "NOT NULL"}
        });
        ensureClassWithColumns("Treeneri_padevus", "Seos, mis määrab, millist treeninguliiki treener võib juhendada.", new String[][] {
            {"tootaja_e_meil", "varchar(254)", "PK, FK tootaja.e_meil"},
            {"treeninguliigi_id", "integer", "PK, FK treeninguliik.treeninguliigi_id"},
            {"alates", "date", "NOT NULL"},
            {"kuni", "date", "NOT NULL, DEFAULT infinity"}
        });
    }

    private void ensurePhysicalTables() throws Exception {
        Map<String, Integer> ids = new LinkedHashMap<>();
        ids.put("klient", ensurePhysicalTable("klient", "Kliendi osalejatabel. PK/FK: e_meil.", new String[][] {
            {"e_meil", "e_meil_aadress", "PK, FK kasutajakonto.e_meil"},
            {"registreerimise_aeg", "ajakava_ajahetk", "NOT NULL"},
            {"on_aktiivne", "boolean", "NOT NULL"}
        }));
        ids.put("treeninguliigi_seisundi_liik", ensurePhysicalTable("treeninguliigi_seisundi_liik", "Treeninguliigi seisundite klassifikaator.", new String[][] {
            {"treeninguliigi_seisundi_kood", "kood_10", "PK"},
            {"nimetus", "varchar(200)", "NOT NULL"},
            {"on_aktiivne", "boolean", "NOT NULL"}
        }));
        ids.put("treeninguliik", ensurePhysicalTable("treeninguliik", "Rühmatreeningu korduv mall. PK: treeninguliigi_id.", new String[][] {
            {"treeninguliigi_id", "integer", "PK"},
            {"nimetus", "varchar(200)", "UNIQUE, NOT NULL"},
            {"kirjeldus", "text", "nullable"},
            {"kestus_minutites", "integer", "NOT NULL"},
            {"vajalik_varustus", "text", "nullable"},
            {"treeninguliigi_seisundi_kood", "kood_10", "FK treeninguliigi_seisundi_liik.treeninguliigi_seisundi_kood"},
            {"registreerija_e_meil", "e_meil_aadress", "FK tootaja.e_meil, nullable"},
            {"viimase_muutja_e_meil", "e_meil_aadress", "FK tootaja.e_meil, nullable"},
            {"registreerimise_aeg", "ajakava_ajahetk", "NOT NULL"},
            {"viimase_muutmise_aeg", "ajakava_ajahetk", "NOT NULL"}
        }));
        ids.put("treeninguliigi_kategooria_omamine", ensurePhysicalTable("treeninguliigi_kategooria_omamine", "Treeninguliigi ja kategooria seos. PK: treeninguliigi_id + treeningu_kategooria_kood.", new String[][] {
            {"treeninguliigi_id", "integer", "PK, FK treeninguliik.treeninguliigi_id"},
            {"treeningu_kategooria_kood", "kood_10", "PK, FK treeningu_kategooria.treeningu_kategooria_kood"}
        }));
        ids.put("varustus", ensurePhysicalTable("varustus", "Rühmatreeningu läbiviimiseks vajalik varustus. PK: varustuse_kood.", new String[][] {
            {"varustuse_kood", "kood_10", "PK"},
            {"nimetus", "varchar(100)", "UNIQUE, NOT NULL"},
            {"kirjeldus", "text", "nullable"},
            {"on_aktiivne", "boolean", "NOT NULL"}
        }));
        ids.put("treeninguliigi_varustuse_noue", ensurePhysicalTable("treeninguliigi_varustuse_noue", "Treeninguliigi varustuse nõue. PK: treeninguliigi_id + varustuse_kood.", new String[][] {
            {"treeninguliigi_id", "integer", "PK, FK treeninguliik.treeninguliigi_id"},
            {"varustuse_kood", "kood_10", "PK, FK varustus.varustuse_kood"},
            {"minimaalne_kogus", "integer", "NOT NULL, CHECK > 0"},
            {"on_kohustuslik", "boolean", "NOT NULL"},
            {"markus", "text", "nullable"}
        }));
        ids.put("ruum", ensurePhysicalTable("ruum", "Jõusaali ruum või stuudio. PK: ruumi_kood.", new String[][] {
            {"ruumi_kood", "kood_10", "PK"},
            {"nimetus", "varchar(200)", "UNIQUE, NOT NULL"},
            {"asukoht", "varchar(300)", "nullable"},
            {"mahutavus", "integer", "NOT NULL, CHECK > 0"},
            {"on_aktiivne", "boolean", "NOT NULL"}
        }));
        ids.put("ruumi_varustuse_omamine", ensurePhysicalTable("ruumi_varustuse_omamine", "Ruumi olemasolev varustus ja kogus. PK: ruumi_kood + varustuse_kood.", new String[][] {
            {"ruumi_kood", "kood_10", "PK, FK ruum.ruumi_kood"},
            {"varustuse_kood", "kood_10", "PK, FK varustus.varustuse_kood"},
            {"kogus", "integer", "NOT NULL, CHECK > 0"},
            {"markus", "text", "nullable"}
        }));
        ids.put("treeneri_padevus", ensurePhysicalTable("treeneri_padevus", "Treeneri lubatud treeninguliigid. PK: tootaja_e_meil + treeninguliigi_id.", new String[][] {
            {"tootaja_e_meil", "e_meil_aadress", "PK, FK tootaja.e_meil"},
            {"treeninguliigi_id", "integer", "PK, FK treeninguliik.treeninguliigi_id"},
            {"alates", "date", "NOT NULL"},
            {"kuni", "date", "NOT NULL, DEFAULT infinity"}
        }));
        ids.put("treeningukorra_seisundi_liik", ensurePhysicalTable("treeningukorra_seisundi_liik", "Treeningukorra seisundite klassifikaator.", new String[][] {
            {"treeningukorra_seisundi_kood", "kood_10", "PK"},
            {"nimetus", "varchar(200)", "NOT NULL"},
            {"on_aktiivne", "boolean", "NOT NULL"},
            {"kirjeldus", "text", "nullable"}
        }));
        ids.put("treeningukord", ensurePhysicalTable("treeningukord", "Ajakavas toimuv konkreetne rühmatreening. PK: treeningukorra_id.", new String[][] {
            {"treeningukorra_id", "integer", "PK"},
            {"treeninguliigi_id", "integer", "FK treeninguliik.treeninguliigi_id"},
            {"treener_e_meil", "e_meil_aadress", "FK tootaja.e_meil"},
            {"ruumi_kood", "kood_10", "FK ruum.ruumi_kood"},
            {"alguse_aeg", "ajakava_ajahetk", "NOT NULL"},
            {"lopu_aeg", "ajakava_ajahetk", "NOT NULL"},
            {"registreerimise_lopp", "ajakava_ajahetk", "NOT NULL"},
            {"tyhistamise_lopp", "ajakava_ajahetk", "NOT NULL"},
            {"maksimaalne_osalejate_arv", "integer", "NOT NULL, CHECK > 0"},
            {"treeningukorra_seisundi_kood", "kood_10", "FK treeningukorra_seisundi_liik.treeningukorra_seisundi_kood"},
            {"looja_e_meil", "e_meil_aadress", "FK tootaja.e_meil, nullable"},
            {"viimase_muutja_e_meil", "e_meil_aadress", "FK tootaja.e_meil, nullable"},
            {"loomise_aeg", "ajakava_ajahetk", "NOT NULL"},
            {"viimase_muutmise_aeg", "ajakava_ajahetk", "NOT NULL"},
            {"tyhistamise_pohjus", "text", "nullable"}
        }));
        ids.put("registreeringu_seisundi_liik", ensurePhysicalTable("registreeringu_seisundi_liik", "Registreeringu seisundite klassifikaator.", new String[][] {
            {"registreeringu_seisundi_kood", "kood_10", "PK"},
            {"nimetus", "varchar(200)", "NOT NULL"},
            {"on_aktiivne", "boolean", "NOT NULL"},
            {"kirjeldus", "text", "nullable"}
        }));
        ids.put("registreering", ensurePhysicalTable("registreering", "Kliendi kinnitatud või ootejärjekorra registreering. PK: registreeringu_id.", new String[][] {
            {"registreeringu_id", "integer", "PK"},
            {"treeningukorra_id", "integer", "FK treeningukord.treeningukorra_id"},
            {"klient_e_meil", "e_meil_aadress", "FK klient.e_meil"},
            {"registreeringu_seisundi_kood", "kood_10", "FK registreeringu_seisundi_liik.registreeringu_seisundi_kood"},
            {"registreerimise_aeg", "ajakava_ajahetk", "NOT NULL"},
            {"tyhistamise_aeg", "ajakava_ajahetk", "nullable"},
            {"edendamise_aeg", "ajakava_ajahetk", "nullable"},
            {"tyhistamise_pohjus", "text", "nullable"}
        }));
        ids.put("ootejarjekorra_koht", ensurePhysicalTable("ootejarjekorra_koht", "Ootejärjekorras oleva registreeringu järjekorrakoht. PK/FK: registreeringu_id.", new String[][] {
            {"registreeringu_id", "integer", "PK, FK registreering.registreeringu_id"},
            {"treeningukorra_id", "integer", "FK treeningukord.treeningukorra_id"},
            {"ootejarjekorra_nr", "integer", "NOT NULL"}
        }));
        ids.put("osalemine", ensurePhysicalTable("osalemine", "Kohalolu tulemus kinnitatud registreeringule. PK/FK: registreeringu_id.", new String[][] {
            {"registreeringu_id", "integer", "PK, FK registreering.registreeringu_id"},
            {"on_osalenud", "boolean", "NOT NULL"},
            {"markija_e_meil", "e_meil_aadress", "FK tootaja.e_meil"},
            {"markimise_aeg", "ajakava_ajahetk", "NOT NULL"},
            {"markus", "text", "nullable"}
        }));

        ensurePhysicalDiagramObjects(ids);
        ensurePhysicalForeignKeys(ids);
    }

    private int ensurePhysicalTable(String name, String note, String[][] columns) throws Exception {
        int id = ensureObject("Class", PHYSICAL_PACKAGE, TEMPLATE_CLASS, name, note);
        updateById("t_object", "Object_ID", id, Map.of(
            "Package_ID", PHYSICAL_PACKAGE,
            "Stereotype", "table",
            "Note", note
        ));
        for (String[] column : columns) {
            addAttributeIfMissing(id, column[0], column[1], column[2]);
        }
        return id;
    }

    private int physicalObjectId(String name, Map<String, Integer> newIds) throws Exception {
        if (newIds.containsKey(name)) {
            return newIds.get(name);
        }
        return findObjectId("Class", name);
    }

    private void ensurePhysicalForeignKeys(Map<String, Integer> ids) throws Exception {
        addConnectorIfMissing(ids.get("klient"), physicalObjectId("kasutajakonto", ids), "fk_klient_kasutajakonto", "e_meil -> kasutajakonto.e_meil");
        addConnectorIfMissing(ids.get("treeninguliik"), ids.get("treeninguliigi_seisundi_liik"), "fk_treeninguliik_treeninguliigi_seisundi_liik", "treeninguliigi_seisundi_kood -> treeninguliigi_seisundi_liik.treeninguliigi_seisundi_kood");
        addConnectorIfMissing(ids.get("treeninguliik"), physicalObjectId("tootaja", ids), "fk_treeninguliik_registreerija", "registreerija_e_meil -> tootaja.e_meil");
        addConnectorIfMissing(ids.get("treeninguliik"), physicalObjectId("tootaja", ids), "fk_treeninguliik_muutja", "viimase_muutja_e_meil -> tootaja.e_meil");
        addConnectorIfMissing(ids.get("treeninguliigi_kategooria_omamine"), ids.get("treeninguliik"), "fk_treeninguliigi_kategooria_liik", "treeninguliigi_id -> treeninguliik.treeninguliigi_id");
        addConnectorIfMissing(ids.get("treeninguliigi_kategooria_omamine"), physicalObjectId("treeningu_kategooria", ids), "fk_treeninguliigi_kategooria_omamine_treeningu_kategooria", "treeningu_kategooria_kood -> treeningu_kategooria.treeningu_kategooria_kood");
        addConnectorIfMissing(ids.get("treeninguliigi_varustuse_noue"), ids.get("treeninguliik"), "fk_treeninguliigi_varustuse_noue_treeninguliik", "treeninguliigi_id -> treeninguliik.treeninguliigi_id");
        addConnectorIfMissing(ids.get("treeninguliigi_varustuse_noue"), ids.get("varustus"), "fk_treeninguliigi_varustuse_noue_varustus", "varustuse_kood -> varustus.varustuse_kood");
        addConnectorIfMissing(ids.get("ruumi_varustuse_omamine"), ids.get("ruum"), "fk_ruumi_varustuse_omamine_ruum", "ruumi_kood -> ruum.ruumi_kood");
        addConnectorIfMissing(ids.get("ruumi_varustuse_omamine"), ids.get("varustus"), "fk_ruumi_varustuse_omamine_varustus", "varustuse_kood -> varustus.varustuse_kood");
        addConnectorIfMissing(ids.get("treeneri_padevus"), physicalObjectId("tootaja", ids), "fk_treeneri_padevus_tootaja", "tootaja_e_meil -> tootaja.e_meil");
        addConnectorIfMissing(ids.get("treeneri_padevus"), ids.get("treeninguliik"), "fk_treeneri_padevus_treeninguliik", "treeninguliigi_id -> treeninguliik.treeninguliigi_id");
        addConnectorIfMissing(ids.get("treeningukord"), ids.get("treeninguliik"), "fk_treeningukord_treeninguliik", "treeninguliigi_id -> treeninguliik.treeninguliigi_id");
        addConnectorIfMissing(ids.get("treeningukord"), physicalObjectId("tootaja", ids), "fk_treeningukord_treener", "treener_e_meil -> tootaja.e_meil");
        addConnectorIfMissing(ids.get("treeningukord"), ids.get("ruum"), "fk_treeningukord_ruum", "ruumi_kood -> ruum.ruumi_kood");
        addConnectorIfMissing(ids.get("treeningukord"), ids.get("treeningukorra_seisundi_liik"), "fk_treeningukord_treeningukorra_seisundi_liik", "treeningukorra_seisundi_kood -> treeningukorra_seisundi_liik.treeningukorra_seisundi_kood");
        addConnectorIfMissing(ids.get("treeningukord"), physicalObjectId("tootaja", ids), "fk_treeningukord_looja", "looja_e_meil -> tootaja.e_meil");
        addConnectorIfMissing(ids.get("treeningukord"), physicalObjectId("tootaja", ids), "fk_treeningukord_muutja", "viimase_muutja_e_meil -> tootaja.e_meil");
        addConnectorIfMissing(ids.get("registreering"), ids.get("treeningukord"), "fk_registreering_kord", "treeningukorra_id -> treeningukord.treeningukorra_id");
        addConnectorIfMissing(ids.get("registreering"), ids.get("klient"), "fk_registreering_klient", "klient_e_meil -> klient.e_meil");
        addConnectorIfMissing(ids.get("registreering"), ids.get("registreeringu_seisundi_liik"), "fk_registreering_registreeringu_seisundi_liik", "registreeringu_seisundi_kood -> registreeringu_seisundi_liik.registreeringu_seisundi_kood");
        addConnectorIfMissing(ids.get("ootejarjekorra_koht"), ids.get("registreering"), "fk_ootejarjekorra_koht_registreering", "registreeringu_id -> registreering.registreeringu_id");
        addConnectorIfMissing(ids.get("ootejarjekorra_koht"), ids.get("treeningukord"), "fk_ootejarjekorra_koht_treeningukord", "treeningukorra_id -> treeningukord.treeningukorra_id");
        addConnectorIfMissing(ids.get("osalemine"), ids.get("registreering"), "fk_osalemine_registreering", "registreeringu_id -> registreering.registreeringu_id");
        addConnectorIfMissing(ids.get("osalemine"), physicalObjectId("tootaja", ids), "fk_osalemine_markija", "markija_e_meil -> tootaja.e_meil");
    }

    private boolean connectorExists(int startObjectId, int endObjectId, String name) throws Exception {
        for (Row row : db.getTable("t_connector")) {
            if (name.equals(row.get("Name"))
                && row.get("Start_Object_ID") instanceof Number
                && ((Number) row.get("Start_Object_ID")).intValue() == startObjectId
                && row.get("End_Object_ID") instanceof Number
                && ((Number) row.get("End_Object_ID")).intValue() == endObjectId) {
                return true;
            }
        }
        return false;
    }

    private int addConnectorIfMissing(int startObjectId, int endObjectId, String name, String note) throws Exception {
        if (startObjectId == 0 || endObjectId == 0 || connectorExists(startObjectId, endObjectId, name)) {
            return 0;
        }
        Table table = db.getTable("t_connector");
        table.setAllowAutoNumberInsert(true);
        Row template = table.iterator().next();
        Map<String, Object> row = copy(template);
        int id = maxLong(table, "Connector_ID") + 1;
        row.put("Connector_ID", id);
        row.put("Name", name);
        row.put("Direction", "Source -> Destination");
        row.put("Notes", note);
        row.put("Connector_Type", "Association");
        row.put("SourceCard", "0..*");
        row.put("DestCard", "1");
        row.put("SourceRole", note);
        row.put("DestRole", name);
        row.put("Start_Object_ID", startObjectId);
        row.put("End_Object_ID", endObjectId);
        row.put("Stereotype", "FK");
        row.put("PDATA1", z());
        row.put("PDATA2", z());
        row.put("PDATA3", z());
        row.put("PDATA4", z());
        row.put("PDATA5", "SX=0;SY=0;EX=0;EY=0;");
        row.put("DiagramID", PHYSICAL_DIAGRAM);
        row.put("ea_guid", guid());
        table.addRowFromMap(row);
        addDiagramLinkIfMissing(id);
        return id;
    }

    private boolean diagramObjectExists(int diagramId, int objectId) throws Exception {
        for (Row row : db.getTable("t_diagramobjects")) {
            if (row.get("Diagram_ID") instanceof Number
                && ((Number) row.get("Diagram_ID")).intValue() == diagramId
                && row.get("Object_ID") instanceof Number
                && ((Number) row.get("Object_ID")).intValue() == objectId) {
                return true;
            }
        }
        return false;
    }

    private void ensurePhysicalDiagramObjects(Map<String, Integer> ids) throws Exception {
        int[][] layout = new int[][] {
            {physicalObjectId("kasutajakonto", ids), 620, -50, 790, -115},
            {physicalObjectId("tootaja", ids), 245, -215, 390, -280},
            {ids.get("klient"), 855, -50, 1015, -115},
            {ids.get("treeninguliigi_seisundi_liik"), 20, -380, 250, -445},
            {ids.get("treeninguliik"), 295, -380, 470, -470},
            {physicalObjectId("treeningu_kategooria", ids), 295, -250, 490, -315},
            {ids.get("treeninguliigi_kategooria_omamine"), 520, -245, 775, -315},
            {ids.get("ruum"), 510, -300, 670, -365},
            {ids.get("varustus"), 750, -300, 930, -365},
            {ids.get("ruumi_varustuse_omamine"), 705, -385, 965, -455},
            {ids.get("treeninguliigi_varustuse_noue"), 745, -465, 1035, -540},
            {ids.get("treeneri_padevus"), 510, -440, 720, -525},
            {ids.get("treeningukorra_seisundi_liik"), 20, -560, 260, -625},
            {ids.get("treeningukord"), 300, -585, 520, -720},
            {ids.get("registreeringu_seisundi_liik"), 570, -585, 830, -650},
            {ids.get("registreering"), 860, -500, 1060, -620},
            {ids.get("osalemine"), 860, -700, 1040, -790}
        };
        for (int[] item : layout) {
            addDiagramObjectIfMissing(PHYSICAL_DIAGRAM, item[0], item[1], item[2], item[3], item[4]);
        }
    }

    private void addDiagramObjectIfMissing(int diagramId, int objectId, int left, int top, int right, int bottom) throws Exception {
        if (objectId == 0 || diagramObjectExists(diagramId, objectId)) {
            return;
        }
        Table table = db.getTable("t_diagramobjects");
        table.setAllowAutoNumberInsert(true);
        Row template = table.iterator().next();
        Map<String, Object> row = copy(template);
        row.put("Diagram_ID", diagramId);
        row.put("Object_ID", objectId);
        row.put("RectTop", top);
        row.put("RectLeft", left);
        row.put("RectRight", right);
        row.put("RectBottom", bottom);
        row.put("Sequence", maxLong(table, "Sequence") + 1);
        row.put("ObjectStyle", "DUID=" + duid() + ";");
        row.put("Instance_ID", maxLong(table, "Instance_ID") + 1);
        table.addRowFromMap(row);
    }

    private boolean diagramLinkExists(int connectorId) throws Exception {
        Table table = db.getTable("t_diagramlinks");
        if (table == null) {
            return true;
        }
        for (Row row : table) {
            if (row.get("ConnectorID") instanceof Number
                && ((Number) row.get("ConnectorID")).intValue() == connectorId
                && row.get("DiagramID") instanceof Number
                && ((Number) row.get("DiagramID")).intValue() == PHYSICAL_DIAGRAM) {
                return true;
            }
        }
        return false;
    }

    private void addDiagramLinkIfMissing(int connectorId) throws Exception {
        if (diagramLinkExists(connectorId)) {
            return;
        }
        Table table = db.getTable("t_diagramlinks");
        table.setAllowAutoNumberInsert(true);
        Row template = table.iterator().next();
        Map<String, Object> row = copy(template);
        row.put("DiagramID", PHYSICAL_DIAGRAM);
        row.put("ConnectorID", connectorId);
        row.put("Geometry", "SX=0;SY=0;EX=0;EY=0;EDGE=2;$LLB=;LLT=;LMT=;LMB=;LRT=;LRB=;IRHS=;ILHS=;");
        row.put("Style", "Mode=3;Color=-1;LWidth=0;");
        row.put("Hidden", 0);
        row.put("Path", z());
        row.put("Instance_ID", maxLong(table, "Instance_ID") + 1);
        table.addRowFromMap(row);
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
