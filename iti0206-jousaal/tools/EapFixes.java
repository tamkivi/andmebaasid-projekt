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
    private static final int PKG_ANALYSIS_REGISTERS = 6;
    private static final int PKG_STATE_MODELS = 12;
    private static final int PKG_REGISTER = 15;
    private static final int TEMPLATE_ACTOR = 16;
    private static final int TEMPLATE_USE_CASE = 23;
    private static final int TEMPLATE_STATE_INITIAL = 55;
    private static final int TEMPLATE_STATE = 56;
    private static final int TEMPLATE_STATE_FINAL = 58;
    private static final int TEMPLATE_CLASS = 53;
    private static final int PHYSICAL_PACKAGE = 7;
    private static final int USE_CASE_DIAGRAM = 2;
    private static final int TRAINING_STATE_DIAGRAM = 6;
    private static final int PHYSICAL_DIAGRAM = 13;

    private final Database db;
    private final Map<String, Integer> packageIdsByName = new LinkedHashMap<>();

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
        replaceOldProjectText();
        renamePackagesAndDiagrams();
        neutralizeTemplateClass();
        removeStaleTreeningPhysicalClass();
        removeStaleWorkbookObjects();
        ensureCurrentStateModels();
        ensureRegisterPackages();
        ensureActors();
        ensureUseCases();
        ensureUseCaseDiagramParity();
        ensureCoreClasses();
        removeClassifierGeneralizations();
        ensurePhysicalTables();
        removeOldPaymentLanguage();
        removeNonSubmittedTemplateObjects();
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

    private int findPackageId(String name) throws Exception {
        for (Row row : db.getTable("t_package")) {
            if (name.equals(row.get("Name")) && row.get("Package_ID") instanceof Number) {
                return ((Number) row.get("Package_ID")).intValue();
            }
        }
        return 0;
    }

    private int packageId(String name) throws Exception {
        Integer existing = packageIdsByName.get(name);
        if (existing != null) {
            return existing;
        }
        int id = findPackageId(name);
        if (id == 0) {
            throw new IllegalStateException("Missing EAP package: " + name);
        }
        packageIdsByName.put(name, id);
        return id;
    }

    private void updateById(String tableName, String idColumn, int id, Map<String, Object> values) throws Exception {
        Table table = db.getTable(tableName);
        Cursor cursor = CursorBuilder.createCursor(table);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            Object actual = row.get(idColumn);
            boolean matches = actual instanceof Number && ((Number) actual).intValue() == id;
            if (!matches && actual != null) {
                matches = String.valueOf(id).equals(actual.toString());
            }
            if (matches) {
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

    private void removeNonSubmittedTemplateObjects() throws Exception {
        deleteObjectAndDependencies(TEMPLATE_CLASS);
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
            "Uudistaja",
            "Muuda treening mitteaktiivseks",
            "Unusta treening",
            "Vali treening",
            "Vali treeningukord",
            "Otsi treeningukorda",
            "Muuda treeningukorra andmeid",
            "Muuda treeningut",
            "Lõpeta valitud treening",
            "Lõpeta valitud treeningukord",
            "Aktiveeri valitud treening",
            "Vaata avatud rühmatreeningute ajakava",
            "Vaata kõiki treeninguid",
            "Vaata kõiki treeninguid, mida saab lõpetada",
            "Vaata kõiki ootel või mitteaktiivseid treeninguid",
            "Vaata treeningukordi, mida saab lõpetada",
            "Vaata kavandatud või suletud treeningukordi",
            "Vaata tunniplaani",
            "Sulge enda treeningukorra registreerimine",
            "Rakenda registreerimise tähtaja tingimus",
            "Vaata täituvuse statistikat",
            "Tuvasta kasutaja",
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

    private int findDiagramId(String name) throws Exception {
        for (Row row : db.getTable("t_diagram")) {
            if (name.equals(row.get("Name")) && row.get("Diagram_ID") instanceof Number) {
                return ((Number) row.get("Diagram_ID")).intValue();
            }
        }
        return 0;
    }

    private int ensureStateDiagram(int preferredId, String name) throws Exception {
        int existingId = findDiagramId(name);
        if (existingId != 0) {
            updateById("t_diagram", "Diagram_ID", existingId, Map.of(
                "Name", name,
                "Package_ID", PKG_STATE_MODELS,
                "Diagram_Type", "Statechart"
            ));
            return existingId;
        }

        Table table = db.getTable("t_diagram");
        if (preferredId != 0 && findRow(table, "Diagram_ID", preferredId) != null) {
            updateById("t_diagram", "Diagram_ID", preferredId, Map.of(
                "Name", name,
                "Package_ID", PKG_STATE_MODELS,
                "Diagram_Type", "Statechart"
            ));
            return preferredId;
        }

        table.setAllowAutoNumberInsert(true);
        Row template = findRow(table, "Diagram_ID", TRAINING_STATE_DIAGRAM);
        Map<String, Object> row = copy(template);
        int id = maxLong(table, "Diagram_ID") + 1;
        row.put("Diagram_ID", id);
        row.put("Name", name);
        row.put("Package_ID", PKG_STATE_MODELS);
        row.put("Diagram_Type", "Statechart");
        row.put("ea_guid", guid());
        row.put("CreatedDate", new Date());
        row.put("ModifiedDate", new Date());
        table.addRowFromMap(row);
        return id;
    }

    private Map<String, Object> connectorTemplate(String preferredType) throws Exception {
        Table table = db.getTable("t_connector");
        for (Row row : table) {
            if (preferredType.equals(row.get("Connector_Type"))) {
                return copy(row);
            }
        }
        return copy(table.iterator().next());
    }

    private void removeStateFlowsForPackage(int packageId) throws Exception {
        Set<Integer> lifecycleObjectIds = new HashSet<>();
        for (Row row : db.getTable("t_object")) {
            Object id = row.get("Object_ID");
            Object rowPackageId = row.get("Package_ID");
            Object type = row.get("Object_Type");
            boolean isLifecycleObject = "State".equals(type) || "StateNode".equals(type);
            if (id instanceof Number
                && rowPackageId instanceof Number
                && ((Number) rowPackageId).intValue() == packageId
                && isLifecycleObject) {
                lifecycleObjectIds.add(((Number) id).intValue());
            }
        }
        if (lifecycleObjectIds.isEmpty()) {
            return;
        }

        Set<Integer> connectorIds = new HashSet<>();
        Table connectors = db.getTable("t_connector");
        Cursor cursor = CursorBuilder.createCursor(connectors);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            Object connectorId = row.get("Connector_ID");
            Object start = row.get("Start_Object_ID");
            Object end = row.get("End_Object_ID");
            boolean stateFlowInPackage =
                "StateFlow".equals(row.get("Connector_Type"))
                && connectorId instanceof Number
                && start instanceof Number
                && end instanceof Number
                && (lifecycleObjectIds.contains(((Number) start).intValue())
                    || lifecycleObjectIds.contains(((Number) end).intValue()));
            if (stateFlowInPackage) {
                connectorIds.add(((Number) connectorId).intValue());
                cursor.deleteCurrentRow();
            }
        }
        deleteConnectorDependencies(connectorIds);
    }

    private void removeStaleStateObjects() throws Exception {
        Set<String> staleStateNames = Set.of("Alg", "Ootel", "Aktiivne", "Mitteaktiivne", "Lõpetatud", "Unustatud");
        Set<Integer> staleObjectIds = new HashSet<>();
        for (Row row : db.getTable("t_object")) {
            Object id = row.get("Object_ID");
            Object name = row.get("Name");
            Object type = row.get("Object_Type");
            Object packageId = row.get("Package_ID");
            boolean isLifecycleObject = "State".equals(type) || "StateNode".equals(type);
            if (id instanceof Number
                && packageId instanceof Number
                && ((Number) packageId).intValue() == PKG_STATE_MODELS
                && isLifecycleObject
                && name instanceof String
                && staleStateNames.contains(name)) {
                staleObjectIds.add(((Number) id).intValue());
            }
        }
        for (int objectId : staleObjectIds) {
            deleteObjectAndDependencies(objectId);
        }
    }

    private void clearDiagramContents(int diagramId) throws Exception {
        deleteRowsByNumber("t_diagramobjects", "Diagram_ID", diagramId);
        deleteRowsByNumber("t_diagramlinks", "DiagramID", diagramId);
    }

    private int ensureState(String name, String note) throws Exception {
        return ensureObject("State", PKG_STATE_MODELS, TEMPLATE_STATE, name, note);
    }

    private int ensureInitialNode(String name, String note) throws Exception {
        return ensureObject("StateNode", PKG_STATE_MODELS, TEMPLATE_STATE_INITIAL, name, note);
    }

    private int ensureFinalNode(String name, String note) throws Exception {
        return ensureObject("StateNode", PKG_STATE_MODELS, TEMPLATE_STATE_FINAL, name, note);
    }

    private int addStateFlowIfMissing(
        int startObjectId,
        int endObjectId,
        String name,
        int diagramId,
        Map<String, Object> template
    ) throws Exception {
        if (startObjectId == 0 || endObjectId == 0 || connectorBetweenExists(startObjectId, endObjectId, "StateFlow")) {
            return 0;
        }
        Table table = db.getTable("t_connector");
        table.setAllowAutoNumberInsert(true);
        Map<String, Object> row = new LinkedHashMap<>(template);
        int id = maxLong(table, "Connector_ID") + 1;
        row.put("Connector_ID", id);
        row.put("Name", name);
        row.put("Direction", "Source -> Destination");
        row.put("Notes", name);
        row.put("Connector_Type", "StateFlow");
        row.put("SourceCard", z());
        row.put("DestCard", z());
        row.put("SourceRole", z());
        row.put("DestRole", z());
        row.put("Start_Object_ID", startObjectId);
        row.put("End_Object_ID", endObjectId);
        row.put("Stereotype", z());
        row.put("PDATA1", z());
        row.put("PDATA2", z());
        row.put("PDATA3", z());
        row.put("PDATA4", z());
        row.put("PDATA5", "SX=0;SY=0;EX=0;EY=0;");
        row.put("DiagramID", diagramId);
        row.put("ea_guid", guid());
        table.addRowFromMap(row);
        addDiagramLinkIfMissing(diagramId, id);
        return id;
    }

    private void ensureCurrentStateModels() throws Exception {
        int trainingDiagramId = ensureStateDiagram(TRAINING_STATE_DIAGRAM, "Treeningukorra seisundimudel");
        int registrationDiagramId = ensureStateDiagram(0, "Registreeringu seisundimudel");
        Map<String, Object> stateFlowTemplate = connectorTemplate("StateFlow");

        Map<String, Integer> states = new LinkedHashMap<>();
        states.put("sessionStart", ensureInitialNode("Algus: treeningukord", "Treeningukorra elutsükli algussõlm."));
        states.put("KAVAND", ensureState("KAVAND", "Treeningukord on planeeritud, kuid registreerimine pole avatud."));
        states.put("AVATUD", ensureState("AVATUD", "Treeningukord on klientidele registreerimiseks avatud."));
        states.put("SULETUD", ensureState("SULETUD", "Registreerimine on lõppenud, kuid treeningukord pole veel toimunuks märgitud."));
        states.put("TOIMUNUD", ensureState("TOIMUNUD", "Treeningukord on pärast lõppu toimunuks märgitud."));
        states.put("TYHIST", ensureState("TYHIST", "Treeningukord on juhataja otsusega tühistatud."));
        states.put("sessionDoneEnd", ensureFinalNode("Lõpp: toimunud treeningukord", "Treeningukorra toimunud lõpptulemus."));
        states.put("sessionCancelledEnd", ensureFinalNode("Lõpp: tühistatud treeningukord", "Treeningukorra tühistatud lõpptulemus."));
        states.put("registrationStart", ensureInitialNode("Algus: registreering", "Registreeringu elutsükli algussõlm."));
        states.put("KINNIT", ensureState("KINNIT", "Registreering on kinnitatud osalejakohaga."));
        states.put("OOTEJRK", ensureState("OOTEJRK", "Registreering on ootejärjekorras ja ootab vaba kohta."));
        states.put("TYH_KL", ensureState("TYH_KL", "Klient tühistas aktiivse registreeringu tähtaja piires."));
        states.put("TYH_SYS", ensureState("TYH_SYS", "Registreering tühistati süsteemselt treeningukorra tühistamise tõttu."));
        states.put("registrationClientCancelledEnd", ensureFinalNode("Lõpp: klient tühistas registreeringu", "Registreeringu kliendipoolse tühistamise lõpptulemus."));
        states.put("registrationSystemCancelledEnd", ensureFinalNode("Lõpp: süsteemselt tühistatud registreering", "Registreeringu süsteemse tühistamise lõpptulemus."));

        removeStateFlowsForPackage(PKG_STATE_MODELS);
        clearDiagramContents(trainingDiagramId);
        clearDiagramContents(registrationDiagramId);
        removeStaleStateObjects();

        addDiagramObjectIfMissing(trainingDiagramId, states.get("sessionStart"), 20, -170, 105, -225);
        addDiagramObjectIfMissing(trainingDiagramId, states.get("KAVAND"), 150, -150, 310, -215);
        addDiagramObjectIfMissing(trainingDiagramId, states.get("AVATUD"), 360, -150, 520, -215);
        addDiagramObjectIfMissing(trainingDiagramId, states.get("SULETUD"), 570, -150, 730, -215);
        addDiagramObjectIfMissing(trainingDiagramId, states.get("TOIMUNUD"), 780, -80, 950, -145);
        addDiagramObjectIfMissing(trainingDiagramId, states.get("TYHIST"), 780, -240, 950, -305);
        addDiagramObjectIfMissing(trainingDiagramId, states.get("sessionDoneEnd"), 1000, -80, 1205, -145);
        addDiagramObjectIfMissing(trainingDiagramId, states.get("sessionCancelledEnd"), 1000, -240, 1205, -305);

        addStateFlowIfMissing(states.get("sessionStart"), states.get("KAVAND"), "Juhataja planeerib / OP1 fn_planeeri_treeningukord", trainingDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("KAVAND"), states.get("AVATUD"), "Juhataja avab / OP2 fn_ava_treeningukord", trainingDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("AVATUD"), states.get("SULETUD"), "Juhataja või treener sulgeb / OP3 fn_sulge_treeningukord", trainingDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("SULETUD"), states.get("TOIMUNUD"), "Treener või juhataja lõpetab / OP4 fn_lopeta_treeningukord", trainingDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("KAVAND"), states.get("TYHIST"), "Juhataja tühistab / OP9 fn_tyhista_treeningukord", trainingDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("AVATUD"), states.get("TYHIST"), "Juhataja tühistab / OP9 fn_tyhista_treeningukord", trainingDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("SULETUD"), states.get("TYHIST"), "Juhataja tühistab / OP9 fn_tyhista_treeningukord", trainingDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("TOIMUNUD"), states.get("sessionDoneEnd"), "Toimunud treeningukorra lõpp", trainingDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("TYHIST"), states.get("sessionCancelledEnd"), "Tühistatud treeningukorra lõpp", trainingDiagramId, stateFlowTemplate);

        addDiagramObjectIfMissing(registrationDiagramId, states.get("registrationStart"), 20, -170, 105, -225);
        addDiagramObjectIfMissing(registrationDiagramId, states.get("KINNIT"), 160, -100, 320, -165);
        addDiagramObjectIfMissing(registrationDiagramId, states.get("OOTEJRK"), 160, -245, 320, -310);
        addDiagramObjectIfMissing(registrationDiagramId, states.get("TYH_KL"), 500, -100, 660, -165);
        addDiagramObjectIfMissing(registrationDiagramId, states.get("TYH_SYS"), 500, -245, 660, -310);
        addDiagramObjectIfMissing(registrationDiagramId, states.get("registrationClientCancelledEnd"), 735, -100, 1010, -165);
        addDiagramObjectIfMissing(registrationDiagramId, states.get("registrationSystemCancelledEnd"), 735, -245, 1010, -310);

        addStateFlowIfMissing(states.get("registrationStart"), states.get("KINNIT"), "Klient esitab registreeringu, vaba koht / OP5 fn_registreeri_klient_treeningukorrale", registrationDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("registrationStart"), states.get("OOTEJRK"), "Klient esitab registreeringu, kohad täis / OP5 fn_registreeri_klient_treeningukorrale", registrationDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("OOTEJRK"), states.get("KINNIT"), "Süsteem edendab pärast koha vabanemist / OP7 fn_edenda_ootejarjekorrast", registrationDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("KINNIT"), states.get("TYH_KL"), "Klient tühistab enne tähtaega / OP6 fn_tyhista_registreering", registrationDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("OOTEJRK"), states.get("TYH_KL"), "Klient tühistab enne tähtaega / OP6 fn_tyhista_registreering", registrationDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("KINNIT"), states.get("TYH_SYS"), "Treeningukord tühistatakse / OP9 fn_tyhista_treeningukord", registrationDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("OOTEJRK"), states.get("TYH_SYS"), "Treeningukord tühistatakse / OP9 fn_tyhista_treeningukord", registrationDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("TYH_KL"), states.get("registrationClientCancelledEnd"), "Kliendi tühistuse lõpp", registrationDiagramId, stateFlowTemplate);
        addStateFlowIfMissing(states.get("TYH_SYS"), states.get("registrationSystemCancelledEnd"), "Süsteemse tühistuse lõpp", registrationDiagramId, stateFlowTemplate);
    }

    private int ensureObject(String type, int packageId, int templateId, String name, String note) throws Exception {
        String safeNote = note == null || note.isBlank() ? z() : note;
        int existing = findObjectId(type, name);
        if (existing != 0) {
            updateById("t_object", "Object_ID", existing, Map.of(
                "Name", name,
                "Note", safeNote,
                "Package_ID", packageId
            ));
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
        row.put("Note", safeNote);
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

    private Row findPackageObject(int packageId) throws Exception {
        for (Row row : db.getTable("t_object")) {
            Object pdata1 = row.get("PDATA1");
            if ("Package".equals(row.get("Object_Type")) && String.valueOf(packageId).equals(s(pdata1))) {
                return row;
            }
        }
        return null;
    }

    private Row findFirstPackageObject() throws Exception {
        for (Row row : db.getTable("t_object")) {
            if ("Package".equals(row.get("Object_Type"))) {
                return row;
            }
        }
        return null;
    }

    private void ensurePackageObject(int packageId, String name, int parentId, String packageGuid, String note) throws Exception {
        Row existing = findPackageObject(packageId);
        if (existing != null && existing.get("Object_ID") instanceof Number) {
            updateById("t_object", "Object_ID", ((Number) existing.get("Object_ID")).intValue(), Map.of(
                "Name", name,
                "Note", note,
                "Package_ID", parentId,
                "PDATA1", String.valueOf(packageId),
                "ea_guid", packageGuid
            ));
            return;
        }

        Table table = db.getTable("t_object");
        table.setAllowAutoNumberInsert(true);
        Row template = findFirstPackageObject();
        Map<String, Object> row = copy(template);
        int objectId = maxLong(table, "Object_ID") + 1;
        row.put("Object_ID", objectId);
        row.put("Object_Type", "Package");
        row.put("Name", name);
        row.put("Note", note);
        row.put("Package_ID", parentId);
        row.put("PDATA1", String.valueOf(packageId));
        row.put("ea_guid", packageGuid);
        row.put("CreatedDate", new Date());
        row.put("ModifiedDate", new Date());
        row.put("TPos", packageId);
        table.addRowFromMap(row);
    }

    private int ensurePackage(String name, int parentId, String note) throws Exception {
        Table table = db.getTable("t_package");
        int existingId = findPackageId(name);
        if (existingId != 0) {
            updateById("t_package", "Package_ID", existingId, Map.of(
                "Name", name,
                "Parent_ID", parentId,
                "Notes", note
            ));
            String packageGuid = s(findRow(table, "Package_ID", existingId).get("ea_guid"));
            ensurePackageObject(existingId, name, parentId, packageGuid, note);
            packageIdsByName.put(name, existingId);
            return existingId;
        }

        table.setAllowAutoNumberInsert(true);
        Row template = findRow(table, "Package_ID", PKG_REGISTER);
        Map<String, Object> row = copy(template);
        int id = maxLong(table, "Package_ID") + 1;
        String packageGuid = guid();
        row.put("Package_ID", id);
        row.put("Name", name);
        row.put("Parent_ID", parentId);
        row.put("Notes", note);
        row.put("ea_guid", packageGuid);
        row.put("CreatedDate", new Date());
        row.put("ModifiedDate", new Date());
        row.put("TPos", id);
        table.addRowFromMap(row);
        ensurePackageObject(id, name, parentId, packageGuid, note);
        packageIdsByName.put(name, id);
        return id;
    }

    private void renamePackagesAndDiagrams() throws Exception {
        updateById("t_package", "Package_ID", PKG_ANALYSIS_SUBSYSTEM, Map.of(
            "Name", "Registreeringukeskne rühmatreeningute funktsionaalne allsüsteem"
        ));
        updateById("t_package", "Package_ID", PKG_STATE_MODELS, Map.of(
            "Name", "Treeningukorra ja registreeringu elutsüklid"
        ));
        updateById("t_package", "Package_ID", PKG_REGISTER, Map.of(
            "Name", "Registreeringute register"
        ));

        updateById("t_diagram", "Diagram_ID", 2, Map.of("Name", "Registreeringukeskne rühmatreeningute funktsionaalne allsüsteem"));
        updateById("t_diagram", "Diagram_ID", 3, Map.of("Name", "Registreerimise ja ootejärjekorra tegevusvoog"));
        updateById("t_diagram", "Diagram_ID", 4, Map.of("Name", "Registreeringute ja treeningukordade füüsiline mudel"));
        updateById("t_diagram", "Diagram_ID", 6, Map.of("Name", "Treeningukorra seisundimudel"));
        updateById("t_diagram", "Diagram_ID", 7, Map.of("Name", "Registreeringute registri kontseptuaalne eskiismudel"));
        updateById("t_diagram", "Diagram_ID", 8, Map.of("Name", "Registreeringukeskse allsüsteemi pädevusalad ja registrid"));
        updateById("t_diagram", "Diagram_ID", 9, Map.of("Name", "Ava registreerimise tegevusdiagramm"));
        updateById("t_diagram", "Diagram_ID", 13, Map.of("Name", "Rühmatreeningute registrite füüsiline disain"));
    }

    private void ensureRegisterPackages() throws Exception {
        ensurePackage("Registreeringute register", PKG_ANALYSIS_REGISTERS, "Registreeringute ja ootejärjekorra põhiandmete register.");
        ensurePackage("Treeningukordade register", PKG_ANALYSIS_REGISTERS, "Treeningukordade, ruumide ja varustuse seoste register.");
        ensurePackage("Treeninguliikide register", PKG_ANALYSIS_REGISTERS, "Treeninguliikide põhiandmete register.");
        ensurePackage("Osalemiste register", PKG_ANALYSIS_REGISTERS, "Osalemise tulemuste register.");
        ensurePackage("Treenerite register", PKG_ANALYSIS_REGISTERS, "Treenerite ja pädevuste register.");
        ensurePackage("Isikute register", PKG_ANALYSIS_REGISTERS, "Isikute ja kasutajakontode register.");
        ensurePackage("Töötajate register", PKG_ANALYSIS_REGISTERS, "Töötajate ja töötaja rollide register.");
        ensurePackage("Klientide register", PKG_ANALYSIS_REGISTERS, "Klientide register.");
        ensurePackage("Klassifikaatorite register", PKG_ANALYSIS_REGISTERS, "Seisundite, rollide ja riikide klassifikaatorite register.");
    }

    private void replaceOldProjectText() throws Exception {
        Map<String, String> replacements = new LinkedHashMap<>();
        replacements.put("Treeningute funktsionaalne allsüsteem", "registreeringukeskne rühmatreeningute funktsionaalne allsüsteem");
        replacements.put("treeningute funktsionaalne allsüsteem", "registreeringukeskne rühmatreeningute funktsionaalne allsüsteem");
        replacements.put("Registreeringukeskne rühmaregistreeringukeskne rühmatreeningute funktsionaalne allsüsteem", "Registreeringukeskne rühmatreeningute funktsionaalne allsüsteem");
        replacements.put("registreeringukeskne rühmaregistreeringukeskne rühmatreeningute funktsionaalne allsüsteem", "registreeringukeskne rühmatreeningute funktsionaalne allsüsteem");
        replacements.put("Treeningute register", "Registreeringute register");
        replacements.put("treeningute register", "registreeringute register");
        replacements.put("Treeningute elutsüklid", "Treeningukorra ja registreeringu elutsüklid");
        replacements.put("treeningute elutsüklid", "treeningukorra ja registreeringu elutsüklid");
        replacements.put("Treeningu_seisundi_liik", "Treeningukorra_seisundi_liik");
        replacements.put("treeningu_seisundi_liik", "treeningukorra_seisundi_liik");
        replacements.put("Treeningu_kategooria_omamine", "Treeninguliigi_kategooria_omamine");
        replacements.put("treeningu_kategooria_omamine", "treeninguliigi_kategooria_omamine");
        replacements.put("treeningu_kood", "treeningukorra_id");
        replacements.put("Registreeri treening", "Planeeri treeningukord");
        replacements.put("Registreeru treeningukorrale", "Esita registreering");
        replacements.put("Tühista registreering", "Tühista enda registreering");
        replacements.put("Aktiveeri treening", "Ava registreerimine");
        replacements.put("Lõpeta treening", "Lõpeta treeningukord");
        replacements.put("Vaata aktiivseid treeninguid", "Vaata avatud rühmatreeningute ajakava");
        replacements.put("Vaata treeningute koondaruannet", "Vaata treeningukordade täituvuse statistikat");
        replacements.put("Vaata täituvuse statistikat", "Vaata treeningukordade täituvuse statistikat");

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
        removeStaleActors();
        ensureObject("Actor", 4, TEMPLATE_ACTOR, "Juhataja", "Sisemine kasutaja, kes planeerib, avab, sulgeb ja tühistab treeningukordi ning vaatab statistikat.");
        ensureObject("Actor", 4, TEMPLATE_ACTOR, "Töötajate haldur", "Sisemine kasutaja, kes haldab töötajate andmeid ja töötajatega seotud rolli omamisi.");
        ensureObject("Actor", 4, TEMPLATE_ACTOR, "Klassifikaatorite haldur", "Sisemine kasutaja, kes haldab süsteemis kasutatavaid klassifikaatori väärtuseid.");
        ensureObject("Actor", 4, TEMPLATE_ACTOR, "Treener", "Töötaja rolliga seotud tegutseja, kelle kaudu treener näeb enda treeningukordi, kasutab pädevusi ja märgib osalemist.");
        ensureObject("Actor", 4, TEMPLATE_ACTOR, "Klient", "Väline kasutaja, kes vaatab vabu treeningukordi, esitab registreeringu, vaatab enda registreeringuid ja tühistab enda registreeringu.");
        ensureObject("Actor", 4, TEMPLATE_ACTOR, "Süsteem", "Automaatne osapool, mis edendab ootejärjekorda ja jõustab andmebaasi ärireegleid.");
    }

    private void removeStaleActors() throws Exception {
        Set<String> staleActorNames = Set.of("Aeg");
        Table objects = db.getTable("t_object");
        Set<Integer> staleObjectIds = new HashSet<>();
        for (Row row : objects) {
            Object id = row.get("Object_ID");
            Object name = row.get("Name");
            Object type = row.get("Object_Type");
            if (id instanceof Number && "Actor".equals(type) && name instanceof String && staleActorNames.contains(name)) {
                staleObjectIds.add(((Number) id).intValue());
            }
        }
        for (int objectId : staleObjectIds) {
            deleteObjectAndDependencies(objectId);
        }
    }

    private void ensureUseCases() throws Exception {
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Planeeri treeningukord", "Juhataja loob konkreetse treeningukorra koos treeneri, ruumi, aja ja mahupiiranguga.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Ava registreerimine", "Juhataja muudab kavandatud treeningukorra klientidele registreerimiseks avatuks.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Vaata vabu treeningukordi", "Klient näeb treeningukordi, millele saab registreeruda.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Esita registreering", "Klient saab kinnitatud registreeringu või ootejärjekorra koha.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Vaata enda registreeringuid", "Klient näeb enda kinnitatud, ootel ja tühistatud registreeringuid.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Tühista enda registreering", "Klient tühistab enda aktiivse registreeringu ja süsteem edendab vajadusel ootejärjekorda.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Edenda ootel registreering", "Süsteem muudab esimese ootel registreeringu kinnitatuks, kui koht vabaneb.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Vaata treeningukorra registreeringuid", "Treeneri rollis töötaja või juhataja näeb konkreetse treeningukorra registreeringuid.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Sulge registreerimine", "Juhataja, treeneri rollis töötaja või tähtaja tingimus lõpetab registreerimise.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Lõpeta treeningukord", "Treeneri rollis töötaja või juhataja märgib pärast lõppu treeningukorra toimunuks.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Tühista treeningukord", "Juhataja tühistab treeningukorra ja aktiivsed registreeringud süsteemselt.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Märgi osalemine", "Treener või juhataja märgib kinnitatud registreeringule osalemise tulemuse.");
        ensureObject("UseCase", PKG_ANALYSIS_SUBSYSTEM, TEMPLATE_USE_CASE, "Vaata treeningukordade täituvuse statistikat", "Juhataja vaatab treeningukordade täituvust ja ootejärjekorda.");
    }

    private void ensureUseCaseDiagramParity() throws Exception {
        removeActorUseCaseAssociations();

        addDiagramObjectByName(USE_CASE_DIAGRAM, "Actor", "Juhataja", 120, -70, 270, -135);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "Actor", "Treener", 470, -70, 620, -135);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "Actor", "Klient", 820, -70, 970, -135);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "Actor", "Süsteem", 120, -470, 270, -535);

        addDiagramObjectByName(USE_CASE_DIAGRAM, "UseCase", "Planeeri treeningukord", 80, -180, 260, -235);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "UseCase", "Ava registreerimine", 285, -180, 465, -235);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "UseCase", "Sulge registreerimine", 490, -180, 670, -235);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "UseCase", "Lõpeta treeningukord", 695, -180, 875, -235);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "UseCase", "Tühista treeningukord", 900, -180, 1080, -235);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "UseCase", "Vaata treeningukordade täituvuse statistikat", 80, -285, 320, -350);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "UseCase", "Vaata treeningukorra registreeringuid", 345, -285, 585, -350);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "UseCase", "Märgi osalemine", 610, -285, 790, -340);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "UseCase", "Vaata vabu treeningukordi", 815, -285, 1035, -340);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "UseCase", "Esita registreering", 80, -405, 260, -460);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "UseCase", "Vaata enda registreeringuid", 285, -405, 505, -460);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "UseCase", "Tühista enda registreering", 530, -405, 750, -460);
        addDiagramObjectByName(USE_CASE_DIAGRAM, "UseCase", "Edenda ootel registreering", 775, -405, 995, -460);

        addActorUseCaseAssociation("Juhataja", "Planeeri treeningukord");
        addActorUseCaseAssociation("Juhataja", "Ava registreerimine");
        addActorUseCaseAssociation("Juhataja", "Sulge registreerimine");
        addActorUseCaseAssociation("Juhataja", "Lõpeta treeningukord");
        addActorUseCaseAssociation("Juhataja", "Tühista treeningukord");
        addActorUseCaseAssociation("Juhataja", "Vaata treeningukorra registreeringuid");
        addActorUseCaseAssociation("Juhataja", "Märgi osalemine");
        addActorUseCaseAssociation("Juhataja", "Vaata treeningukordade täituvuse statistikat");

        addActorUseCaseAssociation("Treener", "Vaata treeningukorra registreeringuid");
        addActorUseCaseAssociation("Treener", "Märgi osalemine");
        addActorUseCaseAssociation("Treener", "Sulge registreerimine");
        addActorUseCaseAssociation("Treener", "Lõpeta treeningukord");

        addActorUseCaseAssociation("Klient", "Vaata vabu treeningukordi");
        addActorUseCaseAssociation("Klient", "Esita registreering");
        addActorUseCaseAssociation("Klient", "Vaata enda registreeringuid");
        addActorUseCaseAssociation("Klient", "Tühista enda registreering");

        addActorUseCaseAssociation("Süsteem", "Edenda ootel registreering");
    }

    private void addDiagramObjectByName(int diagramId, String type, String name, int left, int top, int right, int bottom) throws Exception {
        addDiagramObjectIfMissing(diagramId, findObjectId(type, name), left, top, right, bottom);
    }

    private void removeActorUseCaseAssociations() throws Exception {
        Table connectors = db.getTable("t_connector");
        if (connectors == null) {
            return;
        }
        Map<Integer, String> typesById = new LinkedHashMap<>();
        for (Row row : db.getTable("t_object")) {
            Object id = row.get("Object_ID");
            Object type = row.get("Object_Type");
            if (id instanceof Number && type instanceof String) {
                typesById.put(((Number) id).intValue(), (String) type);
            }
        }
        Set<Integer> connectorIds = new HashSet<>();
        Cursor cursor = CursorBuilder.createCursor(connectors);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            Object start = row.get("Start_Object_ID");
            Object end = row.get("End_Object_ID");
            Object connectorId = row.get("Connector_ID");
            if (!(start instanceof Number) || !(end instanceof Number) || !(connectorId instanceof Number)) {
                continue;
            }
            String startType = typesById.get(((Number) start).intValue());
            String endType = typesById.get(((Number) end).intValue());
            boolean actorToUseCase = "Actor".equals(startType) && "UseCase".equals(endType);
            boolean useCaseToActor = "UseCase".equals(startType) && "Actor".equals(endType);
            if (actorToUseCase || useCaseToActor) {
                connectorIds.add(((Number) connectorId).intValue());
                cursor.deleteCurrentRow();
            }
        }
        deleteConnectorDependencies(connectorIds);
    }

    private boolean connectorBetweenExists(int startObjectId, int endObjectId, String connectorType) throws Exception {
        for (Row row : db.getTable("t_connector")) {
            if (connectorType.equals(row.get("Connector_Type"))
                && row.get("Start_Object_ID") instanceof Number
                && ((Number) row.get("Start_Object_ID")).intValue() == startObjectId
                && row.get("End_Object_ID") instanceof Number
                && ((Number) row.get("End_Object_ID")).intValue() == endObjectId) {
                return true;
            }
        }
        return false;
    }

    private void addActorUseCaseAssociation(String actorName, String useCaseName) throws Exception {
        int actorId = findObjectId("Actor", actorName);
        int useCaseId = findObjectId("UseCase", useCaseName);
        if (actorId == 0 || useCaseId == 0 || connectorBetweenExists(actorId, useCaseId, "Association")) {
            return;
        }
        Table table = db.getTable("t_connector");
        table.setAllowAutoNumberInsert(true);
        Row template = table.iterator().next();
        Map<String, Object> row = copy(template);
        int id = maxLong(table, "Connector_ID") + 1;
        row.put("Connector_ID", id);
        row.put("Name", z());
        row.put("Direction", "Unspecified");
        row.put("Notes", z());
        row.put("Connector_Type", "Association");
        row.put("SourceCard", z());
        row.put("DestCard", z());
        row.put("SourceRole", z());
        row.put("DestRole", z());
        row.put("Start_Object_ID", actorId);
        row.put("End_Object_ID", useCaseId);
        row.put("Stereotype", z());
        row.put("PDATA1", z());
        row.put("PDATA2", z());
        row.put("PDATA3", z());
        row.put("PDATA4", z());
        row.put("PDATA5", "SX=0;SY=0;EX=0;EY=0;");
        row.put("DiagramID", USE_CASE_DIAGRAM);
        row.put("ea_guid", guid());
        table.addRowFromMap(row);
        addDiagramLinkIfMissing(USE_CASE_DIAGRAM, id);
    }

    private void removeStaleConceptualClasses() throws Exception {
        Set<String> staleClassNames = Set.of(
            "Juhataja",
            "Töötaja_rolli_omamine",
            "OotejarjekorraKoht",
            "Ruumi_varustuse_omamine",
            "Treeninguliigi_varustuse_noue",
            "Treeneri_padevus",
            "Treeningukorra_seisundi_liik",
            "Töötaja_seisundi_liik",
            "Isiku_seisundi_liik",
            "Töötaja_roll",
            "Treeningu_kategooria",
            "Treeningu_kategooria_tüüp",
            "Treeninguliigi_kategooria_omamine"
        );
        Table objects = db.getTable("t_object");
        Set<Integer> staleObjectIds = new HashSet<>();
        for (Row row : objects) {
            Object id = row.get("Object_ID");
            Object name = row.get("Name");
            Object type = row.get("Object_Type");
            Object packageId = row.get("Package_ID");
            boolean isPhysical = packageId instanceof Number && ((Number) packageId).intValue() == PHYSICAL_PACKAGE;
            if (id instanceof Number && "Class".equals(type) && name instanceof String && staleClassNames.contains(name) && !isPhysical) {
                staleObjectIds.add(((Number) id).intValue());
            }
        }
        for (int objectId : staleObjectIds) {
            deleteObjectAndDependencies(objectId);
        }
    }

    private void ensureCoreClasses() throws Exception {
        removeStaleConceptualClasses();

        ensureClassWithColumns("Isikute register", "Isik", "Põhiobjekt: tegelik inimene, kellel võib olla kliendi ja/või töötaja roll.", new String[][] {
            {"e_meil", "tunnus", "Isiku e-posti tunnus."},
            {"isikukood", "tunnus", "Isiku lisatunnus."},
            {"nimi", "nimetus", "Isiku nimi."},
            {"isiku_seisund", "seisund", "Isiku kasutatavuse seisund."}
        });
        ensureClassWithColumns("Isikute register", "Kasutajakonto", "Sisselogimist võimaldav konto, mis kuulub isikule.", new String[][] {
            {"e_meil", "tunnus", "Kasutajakontoga seotud isiku e-posti tunnus."},
            {"aktiivsus", "tunnus", "Kas kontoga saab süsteemi sisse logida."}
        });
        ensureClassWithColumns("Töötajate register", "Töötaja", "Põhiobjekt organisatsiooniga seotud isikuna. Töötaja kaudu tekivad juhataja ja treeneri tegevusõigused.", new String[][] {
            {"tootaja_tunnus", "tunnus", "Töötaja tunnus."},
            {"tootaja_seisund", "seisund", "Töötaja kasutatavuse seisund."}
        });
        ensureClassWithColumns("Töötajate register", "Töötaja rolli omamine", "Seob töötaja rolliga ning võimaldab kirjeldada treeneri või juhataja rolli kehtivust.", new String[][] {
            {"rolli_algus", "aeg", "Rolli kehtivuse algus."},
            {"rolli_lopp", "aeg", "Rolli kehtivuse lõpp."}
        });
        ensureClassWithColumns("Treenerite register", "Treener", "Põhiobjekt töötaja rolli ja pädevuste kaudu rühmatreeningute kontekstis. Treener juhendab treeningukordi ja omab pädevusi.", new String[][] {
            {"treeneri_tunnus", "tunnus", "Treeneri äriline tunnus."},
            {"rolli_kehtivus", "aeg", "Treeneri rolli kehtivus."},
            {"padevuste_ulatus", "kirjeldus", "Treeneri pädevuste äriline ulatus."}
        });
        ensureClassWithColumns("Treenerite register", "Treeneri pädevus", "Sõltuv elutsükliga suhteobjekt, mis määrab, millist treeninguliiki treener võib juhendada ja millal see pädevus kehtib.", new String[][] {
            {"kehtiv_alates", "aeg", "Pädevuse algus."},
            {"kehtiv_kuni", "aeg", "Pädevuse lõpp."}
        });
        ensureClassWithColumns("Treeninguliikide register", "Treeninguliik", "Põhiandmete põhiobjekt: hallatav rühmatreeningu kataloogimõiste, mille alusel planeeritakse konkreetsed treeningukorrad.", new String[][] {
            {"nimetus", "nimetus", "Treeninguliigi nimetus."},
            {"sisu", "kirjeldus", "Treeninguliigi kirjeldus."},
            {"tyypiline_kestus", "aeg", "Tavaline kestus."},
            {"kasutatavus", "seisund", "Kas treeninguliiki saab kasutada."}
        });
        ensureClassWithColumns("Treeningukordade register", "Treeningukord", "Põhiobjekt: kalendris toimuv rühmatreening, millele registreeringud tekivad.", new String[][] {
            {"treeningukorra_tunnus", "tunnus", "Treeningukorra äriline tunnus."},
            {"algus_ja_lopp", "aeg", "Toimumise ajavahemik."},
            {"registreerimise_tahtaeg", "aeg", "Hetk, milleni saab registreeringuid esitada."},
            {"tyhistamise_tahtaeg", "aeg", "Hetk, milleni klient saab enda registreeringu tühistada."},
            {"kohtade_piir", "arv", "Suurim lubatud kinnitatud osalejate arv."},
            {"treeningukorra_seisund", "seisund", "Treeningukorra hetkeseisund."}
        });
        ensureClassWithColumns("Registreeringute register", "Registreering", "Keskne põhiobjekt: kliendi osalemissoov konkreetsele treeningukorrale.", new String[][] {
            {"registreeringu_tunnus", "tunnus", "Registreeringu äriline tunnus."},
            {"esitamise_aeg", "aeg", "Registreeringu loomise aeg."},
            {"registreeringu_seisund", "seisund", "Registreeringu hetkeseisund."},
            {"tyhistamise_aeg", "aeg", "Tühistamise aeg, kui registreering tühistati."},
            {"edendamise_aeg", "aeg", "Aeg, mil ootel registreering kinnitati."}
        });
        ensureClassWithColumns("Registreeringute register", "Ootejärjekorra koht", "Ootejärjekorras oleva registreeringu kohustuslik järjekorrakoht.", new String[][] {
            {"jarjekorranumber", "arv", "Ootel registreeringu järjekord sama treeningukorra sees."}
        });
        ensureClassWithColumns("Osalemiste register", "Osalemine", "Sõltuv elutsükliga tulemusobjekt: kinnitatud registreeringu osalemise või puudumise tulemus.", new String[][] {
            {"tulemus", "tunnus", "Kas klient osales või puudus."},
            {"markimise_aeg", "aeg", "Osalemise märkimise aeg."},
            {"markus", "kirjeldus", "Täpsustav märkus."}
        });
        ensureClassWithColumns("Treeningukordade register", "Ruum", "Jõusaali saal või stuudio, mille mahutavus piirab treeningukorra osalejate arvu.", new String[][] {
            {"ruumi_tunnus", "tunnus", "Ruumi tunnus."},
            {"nimetus", "nimetus", "Ruumi nimetus."},
            {"asukoht", "kirjeldus", "Ruumi asukoht."},
            {"mahutavus", "arv", "Ruumi maksimaalne osalejate arv."}
        });
        ensureClassWithColumns("Treeningukordade register", "Varustus", "Toetav põhiandmete objekt, mille abil kontrollitakse ruumi sobivust treeninguliigile.", new String[][] {
            {"varustuse_tunnus", "tunnus", "Varustuse tunnus."},
            {"nimetus", "nimetus", "Varustuse nimetus."},
            {"aktiivsus", "tunnus", "Kas varustust saab kasutada."}
        });
        ensureClassWithColumns("Treeningukordade register", "Ruumi varustatus", "Seos ruumi ja olemasoleva varustuse koguse vahel.", new String[][] {
            {"kogus", "arv", "Ruumis olemas oleva varustuse kogus."}
        });
        ensureClassWithColumns("Treeningukordade register", "Varustuse nõue", "Treeninguliigi kohustuslik või soovituslik varustuse nõue.", new String[][] {
            {"minimaalne_kogus", "arv", "Vajalik minimaalne kogus."},
            {"kohustuslikkus", "tunnus", "Kas nõue on kohustuslik."}
        });
        ensureClassWithColumns("Klientide register", "Klient", "Põhiobjekt teenuse kasutajana.", new String[][] {
            {"kliendi_tunnus", "tunnus", "Kliendi tunnus."},
            {"aktiivsus", "tunnus", "Kas klient saab registreeringuid esitada."},
            {"kliendiks_saamise_aeg", "aeg", "Kliendi rolli algus."}
        });
        ensureClassWithColumns("Klassifikaatorite register", "Klassifikaator", "Kontrollitud väärtuste üldine olemitüüp, mille kaudu kirjeldatakse seisundeid, rolle, riike ja teisi lubatud väärtuste hulki.", new String[][] {
            {"kood", "tunnus", "Klassifikaatori väärtuse kood."},
            {"nimetus", "nimetus", "Klassifikaatori väärtuse nimetus."},
            {"tahendus", "kirjeldus", "Klassifikaatori väärtuse tähendus."},
            {"aktiivsus", "tunnus", "Kas väärtust saab kasutada."}
        });
        ensureClassWithColumns("Klassifikaatorite register", "Seisund", "Klassifikaatori väärtus, mis kirjeldab isiku, töötaja, treeningukorra või registreeringu hetkeseisu.", new String[][] {
            {"kood", "tunnus", "Seisundi kood."},
            {"nimetus", "nimetus", "Seisundi nimetus."},
            {"tahendus", "kirjeldus", "Seisundi tähendus."},
            {"aktiivsus", "tunnus", "Kas seisundit saab kasutada."}
        });
        ensureClassWithColumns("Klassifikaatorite register", "Roll", "Klassifikaatori väärtus, mis kirjeldab töötaja tegutsemisõigust.", new String[][] {
            {"kood", "tunnus", "Rolli kood."},
            {"nimetus", "nimetus", "Rolli nimetus."},
            {"vastutus", "kirjeldus", "Rolli vastutus."},
            {"aktiivsus", "tunnus", "Kas rolli saab kasutada."}
        });
        ensureClassWithColumns("Klassifikaatorite register", "Riik", "Klassifikaatori väärtus, mis toetab isiku andmete kirjeldamist.", new String[][] {
            {"kood", "tunnus", "Riigi kood."},
            {"nimetus", "nimetus", "Riigi nimetus."},
            {"aktiivsus", "tunnus", "Kas riiki saab kasutada."}
        });
    }

    private void removeClassifierGeneralizations() throws Exception {
        Table connectors = db.getTable("t_connector");
        if (connectors == null) {
            return;
        }
        Map<Integer, String> namesById = new LinkedHashMap<>();
        for (Row row : db.getTable("t_object")) {
            Object id = row.get("Object_ID");
            Object name = row.get("Name");
            if (id instanceof Number && name instanceof String) {
                namesById.put(((Number) id).intValue(), (String) name);
            }
        }
        Set<String> classifierClasses = Set.of("Klassifikaator", "Seisund", "Roll", "Riik");
        Set<Integer> connectorIds = new HashSet<>();
        Cursor cursor = CursorBuilder.createCursor(connectors);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            Object connectorId = row.get("Connector_ID");
            Object start = row.get("Start_Object_ID");
            Object end = row.get("End_Object_ID");
            if (!"Generalization".equals(row.get("Connector_Type"))
                || !(connectorId instanceof Number)
                || !(start instanceof Number)
                || !(end instanceof Number)) {
                continue;
            }
            String startName = namesById.get(((Number) start).intValue());
            String endName = namesById.get(((Number) end).intValue());
            if (classifierClasses.contains(startName) || classifierClasses.contains(endName)) {
                connectorIds.add(((Number) connectorId).intValue());
                cursor.deleteCurrentRow();
            }
        }
        deleteConnectorDependencies(connectorIds);
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
        ids.put("osalemine", ensurePhysicalTable("osalemine", "Kohalolu tulemus kinnitatud registreeringule. PK/FK: registreeringu_id; sisaldab osaleja ja treeneri otseseid viiteid.", new String[][] {
            {"registreeringu_id", "integer", "PK, FK registreering.registreeringu_id"},
            {"klient_e_meil", "e_meil_aadress", "FK klient.e_meil"},
            {"treener_e_meil", "e_meil_aadress", "FK tootaja.e_meil"},
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
        addConnectorIfMissing(ids.get("osalemine"), ids.get("klient"), "fk_osalemine_klient", "klient_e_meil -> klient.e_meil");
        addConnectorIfMissing(ids.get("osalemine"), physicalObjectId("tootaja", ids), "fk_osalemine_treener", "treener_e_meil -> tootaja.e_meil");
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

    private boolean diagramLinkExists(int diagramId, int connectorId) throws Exception {
        Table table = db.getTable("t_diagramlinks");
        if (table == null) {
            return true;
        }
        for (Row row : table) {
            if (row.get("ConnectorID") instanceof Number
                && ((Number) row.get("ConnectorID")).intValue() == connectorId
                && row.get("DiagramID") instanceof Number
                && ((Number) row.get("DiagramID")).intValue() == diagramId) {
                return true;
            }
        }
        return false;
    }

    private void addDiagramLinkIfMissing(int connectorId) throws Exception {
        addDiagramLinkIfMissing(PHYSICAL_DIAGRAM, connectorId);
    }

    private void addDiagramLinkIfMissing(int diagramId, int connectorId) throws Exception {
        if (diagramLinkExists(diagramId, connectorId)) {
            return;
        }
        Table table = db.getTable("t_diagramlinks");
        table.setAllowAutoNumberInsert(true);
        Row template = table.iterator().next();
        Map<String, Object> row = copy(template);
        row.put("DiagramID", diagramId);
        row.put("ConnectorID", connectorId);
        row.put("Geometry", "SX=0;SY=0;EX=0;EY=0;EDGE=2;$LLB=;LLT=;LMT=;LMB=;LRT=;LRB=;IRHS=;ILHS=;");
        row.put("Style", "Mode=3;Color=-1;LWidth=0;");
        row.put("Hidden", 0);
        row.put("Path", z());
        row.put("Instance_ID", maxLong(table, "Instance_ID") + 1);
        table.addRowFromMap(row);
    }

    private void ensureClassWithColumns(String name, String note, String[][] columns) throws Exception {
        ensureClassWithColumns("Registreeringute register", name, note, columns);
    }

    private void ensureClassWithColumns(String packageName, String name, String note, String[][] columns) throws Exception {
        int id = ensureObject("Class", packageId(packageName), TEMPLATE_CLASS, name, note);
        deleteRowsByNumber("t_attribute", "Object_ID", id);
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
