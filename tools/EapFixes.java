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
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
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
        removeStaleDuplicateRows();
        renameModelItems();
        ensureActorSet();
        fixStateTransitions();
        populateActivationScenario();
        addCompetencyDiagram();
        addRegisterDiagrams();
        populateDesignRegisterPackage();
        addUseCaseExtendsAndScenarioText();
        addUseCaseNotes();
        fixUseCaseDiagramConsistency();
        populatePackageDiagramRelatedRegisters();
        ensureConceptualAttributeCoverage();
        populatePhysicalTableColumns();
        addAttributeNotesAndConstraints();
        removeResidualDuplicateIds();
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
        Cursor cursor = CursorBuilder.createCursor(table);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            Object actual = row.get(idColumn);
            if (actual instanceof Number && ((Number) actual).intValue() == id) {
                row.putAll(values);
                cursor.updateCurrentRowFromMap(row);
                return;
            }
        }
        throw new IllegalStateException("Missing " + tableName + "." + idColumn + "=" + id);
    }

    private void removeStaleDuplicateRows() throws Exception {
        Table connectors = db.getTable("t_connector");
        Cursor connectorCursor = CursorBuilder.createCursor(connectors);
        Row connectorRow;
        while ((connectorRow = connectorCursor.getNextRow()) != null) {
            Object idValue = connectorRow.get("Connector_ID");
            if (!(idValue instanceof Number)) {
                continue;
            }
            int id = ((Number) idValue).intValue();
            if ((id == 43 || id == 45 || id == 49 || id == 50 || id == 51 || id == 52)
                && isStaleConnector(connectorRow)) {
                connectorCursor.deleteCurrentRow();
            }
        }

        Table attributes = db.getTable("t_attribute");
        Cursor attributeCursor = CursorBuilder.createCursor(attributes);
        Row attributeRow;
        while ((attributeRow = attributeCursor.getNextRow()) != null) {
            Object idValue = attributeRow.get("ID");
            Object objectValue = attributeRow.get("Object_ID");
            if (idValue instanceof Number
                && objectValue instanceof Number
                && ((Number) idValue).intValue() == 4
                && ((Number) objectValue).intValue() == 53
                && s(attributeRow.get("Notes")).isBlank()) {
                attributeCursor.deleteCurrentRow();
            }
        }
    }

    private boolean isStaleConnector(Row row) {
        String name = s(row.get("Name"));
        String operation = s(row.get("PDATA3"));
        return name.contains("<Siia")
            || name.startsWith("treener ")
            || name.startsWith("juhataja ")
            || operation.contains("OP..")
            || operation.contains("OP ...")
            || operation.contains("OP  ");
    }

    private void removeResidualDuplicateIds() throws Exception {
        removeResidualDuplicateIds("t_connector", "Connector_ID");
        removeResidualDuplicateIds("t_attribute", "ID");
    }

    private void removeResidualDuplicateIds(String tableName, String idColumn) throws Exception {
        Table table = db.getTable(tableName);
        Set<String> seen = new HashSet<>();
        Cursor cursor = CursorBuilder.createCursor(table);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            String key = s(row.get(idColumn));
            if (key.isBlank()) {
                continue;
            }
            if (seen.contains(key)) {
                cursor.deleteCurrentRow();
            } else {
                seen.add(key);
            }
        }
    }

    private void renamePackage(int packageId, String name) throws Exception {
        updateById("t_package", "Package_ID", packageId, Map.of("Name", name, "ModifiedDate", new Date()));
        Table objects = db.getTable("t_object");
        Cursor cursor = CursorBuilder.createCursor(objects);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            if ("Package".equals(row.get("Object_Type")) && String.valueOf(packageId).equals(s(row.get("PDATA1")))) {
                row.put("Name", name);
                row.put("ModifiedDate", new Date());
                cursor.updateCurrentRowFromMap(row);
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
            "PDATA3", "OP3"
        ));
        updateById("t_connector", "Connector_ID", 50, Map.of(
            "Name", "Treener tahab treeningu unustada, sest organisatsiooni jõuab teave, et treening sellisel kujul ei realiseeru ning seda ei saa hakata klientidele tehinguteks pakkuma.",
            "PDATA3", "OP6"
        ));
        updateById("t_connector", "Connector_ID", 51, Map.of(
            "Name", "Treener tahab muuta treeningu andmeid, sest ilmneb, et nende registreerimisel on tehtud viga või treeningu atribuutide väärtuste ja seoste hulgas on toimunud muudatus.",
            "PDATA3", "OP8"
        ));
        updateById("t_connector", "Connector_ID", 52, Map.of(
            "Name", "Treener tahab muuta treeningu andmeid, sest ilmneb, et nende registreerimisel on tehtud viga või treeningu atribuutide väärtuste ja seoste hulgas on toimunud muudatus.",
            "PDATA3", "OP8"
        ));
    }

    private int findObjectId(String type, String name) throws Exception {
        for (Row row : db.getTable("t_object")) {
            if (type.equals(row.get("Object_Type")) && name.equals(row.get("Name")) && row.get("Object_ID") instanceof Number) {
                return ((Number) row.get("Object_ID")).intValue();
            }
        }
        return 0;
    }

    private int ensureActor(String name, String note) throws Exception {
        int id = findObjectId("Actor", name);
        if (id == 0) {
            id = addObjectFromTemplate(16, PKG_PADEVUSALAD, "Actor", 0, name, note);
        }
        updateById("t_object", "Object_ID", id, Map.of("Name", name, "Note", note, "ModifiedDate", new Date()));
        return id;
    }

    private void ensureActorSet() throws Exception {
        ensureActor("Treener", "Sisemine pädevusala. Treener registreerib, muudab ja aktiveerib treeninguid.");
        ensureActor("Juhataja", "Sisemine pädevusala. Juhataja vaatab koondaruandeid ja lõpetab treeninguid.");
        ensureActor("Klient", "Väline pädevusala. Klient vaatab aktiivseid treeninguid.");
        ensureActor("Uudistaja", "Väline pädevusala. Uudistaja vaatab avalikult nähtavat treeningute infot.");
        ensureActor("Klassifikaatorite haldur", "Sisemine pädevusala. Klassifikaatorite haldur haldab treeningu seisundeid ja kategooriaid.");
        ensureActor("Töötajate haldur", "Sisemine pädevusala. Töötajate haldur haldab töötajate ja rollide põhiandmeid.");
    }

    private void fixStateTransitions() throws Exception {
        updateById("t_connector", "Connector_ID", 49, Map.of(
            "Name", "Treener tahab treeningu aktiveerida, sest treeningu ooteperiood või treeninguga seotud ajutised probleemid on lahenenud",
            "PDATA2", "Treening kuulub vähemalt ühte Treeningu_kategooriasse",
            "PDATA3", "OP11"
        ));
        updateById("t_connector", "Connector_ID", 45, Map.of(
            "Name", "Treener tahab treeningu uuesti aktiveerida, sest treeninguga seotud ajutised probleemid on lahenenud",
            "PDATA2", "Treening kuulub vähemalt ühte Treeningu_kategooriasse",
            "PDATA3", "OP11"
        ));
        updateById("t_connector", "Connector_ID", 44, Map.of(
            "Name", "Treener tahab treeningu ajutiselt kasutusest eemaldada, sest treeninguga on ilmnenud ajutise iseloomuga probleemid",
            "PDATA2", z(),
            "PDATA3", "OP13"
        ));
        updateById("t_connector", "Connector_ID", 46, Map.of(
            "Name", "Juhataja tahab treeningu lõpetada, sest treeninguga on ilmnenud püsiva iseloomuga probleemid või treeningut enam ei pakuta",
            "PDATA2", z(),
            "PDATA3", "OP15"
        ));
        updateById("t_connector", "Connector_ID", 47, Map.of(
            "Name", "Juhataja tahab mitteaktiivse treeningu lõpetada, sest treeninguga on ilmnenud püsiva iseloomuga probleemid või treeningut enam ei pakuta",
            "PDATA2", z(),
            "PDATA3", "OP15"
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

    private void addDiagramLinkIfMissing(int diagramId, int connectorId) throws Exception {
        Table table = db.getTable("t_diagramlinks");
        for (Row row : table) {
            if (row.get("DiagramID") instanceof Number
                && row.get("ConnectorID") instanceof Number
                && ((Number) row.get("DiagramID")).intValue() == diagramId
                && ((Number) row.get("ConnectorID")).intValue() == connectorId) {
                return;
            }
        }
        table.setAllowAutoNumberInsert(true);
        Row template = table.iterator().next();
        Map<String, Object> row = copy(template);
        row.put("DiagramID", diagramId);
        row.put("ConnectorID", connectorId);
        row.put("Geometry", z());
        row.put("Style", z());
        row.put("Hidden", false);
        row.put("Path", z());
        row.put("Instance_ID", maxLong(table, "Instance_ID") + 1);
        table.addRowFromMap(row);
    }

    private void ensureConnectorOnDiagram(int diagramId, int templateConnectorId, String type, String stereotype, int sourceId, int targetId, String name) throws Exception {
        for (Row row : db.getTable("t_connector")) {
            if (type.equals(row.get("Connector_Type"))
                && row.get("Start_Object_ID") instanceof Number
                && row.get("End_Object_ID") instanceof Number
                && ((Number) row.get("Start_Object_ID")).intValue() == sourceId
                && ((Number) row.get("End_Object_ID")).intValue() == targetId) {
                addDiagramLinkIfMissing(diagramId, ((Number) row.get("Connector_ID")).intValue());
                return;
            }
        }
        int connectorId = addConnectorFromTemplate(templateConnectorId, type, stereotype, sourceId, targetId, name, z(), z());
        addDiagramLinkIfMissing(diagramId, connectorId);
    }

    private void removeConnectorAndLinks(String type, int sourceId, int targetId) throws Exception {
        Set<Integer> connectorIds = new HashSet<>();
        Table connectors = db.getTable("t_connector");
        Cursor cursor = CursorBuilder.createCursor(connectors);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            if (type.equals(row.get("Connector_Type"))
                && row.get("Start_Object_ID") instanceof Number
                && row.get("End_Object_ID") instanceof Number
                && ((Number) row.get("Start_Object_ID")).intValue() == sourceId
                && ((Number) row.get("End_Object_ID")).intValue() == targetId) {
                connectorIds.add(((Number) row.get("Connector_ID")).intValue());
                cursor.deleteCurrentRow();
            }
        }
        if (connectorIds.isEmpty()) {
            return;
        }
        Table links = db.getTable("t_diagramlinks");
        Cursor linkCursor = CursorBuilder.createCursor(links);
        Row linkRow;
        while ((linkRow = linkCursor.getNextRow()) != null) {
            if (linkRow.get("ConnectorID") instanceof Number
                && connectorIds.contains(((Number) linkRow.get("ConnectorID")).intValue())) {
                linkCursor.deleteCurrentRow();
            }
        }
    }

    private void removeObjectAndReferences(String type, String name) throws Exception {
        Set<Integer> objectIds = new HashSet<>();
        Set<String> guids = new HashSet<>();
        Table objects = db.getTable("t_object");
        Cursor objectCursor = CursorBuilder.createCursor(objects);
        Row objectRow;
        while ((objectRow = objectCursor.getNextRow()) != null) {
            if (type.equals(objectRow.get("Object_Type")) && name.equals(objectRow.get("Name")) && objectRow.get("Object_ID") instanceof Number) {
                objectIds.add(((Number) objectRow.get("Object_ID")).intValue());
                guids.add(s(objectRow.get("ea_guid")));
                objectCursor.deleteCurrentRow();
            }
        }
        if (objectIds.isEmpty()) {
            return;
        }

        Set<Integer> connectorIds = new HashSet<>();
        Table connectors = db.getTable("t_connector");
        Cursor connectorCursor = CursorBuilder.createCursor(connectors);
        Row connectorRow;
        while ((connectorRow = connectorCursor.getNextRow()) != null) {
            boolean matchesStart = connectorRow.get("Start_Object_ID") instanceof Number
                && objectIds.contains(((Number) connectorRow.get("Start_Object_ID")).intValue());
            boolean matchesEnd = connectorRow.get("End_Object_ID") instanceof Number
                && objectIds.contains(((Number) connectorRow.get("End_Object_ID")).intValue());
            if (matchesStart || matchesEnd) {
                if (connectorRow.get("Connector_ID") instanceof Number) {
                    connectorIds.add(((Number) connectorRow.get("Connector_ID")).intValue());
                }
                connectorCursor.deleteCurrentRow();
            }
        }

        Table diagramObjects = db.getTable("t_diagramobjects");
        Cursor diagramObjectCursor = CursorBuilder.createCursor(diagramObjects);
        Row diagramObjectRow;
        while ((diagramObjectRow = diagramObjectCursor.getNextRow()) != null) {
            if (diagramObjectRow.get("Object_ID") instanceof Number
                && objectIds.contains(((Number) diagramObjectRow.get("Object_ID")).intValue())) {
                diagramObjectCursor.deleteCurrentRow();
            }
        }

        Table attributes = db.getTable("t_attribute");
        Cursor attributeCursor = CursorBuilder.createCursor(attributes);
        Row attributeRow;
        while ((attributeRow = attributeCursor.getNextRow()) != null) {
            if (attributeRow.get("Object_ID") instanceof Number
                && objectIds.contains(((Number) attributeRow.get("Object_ID")).intValue())) {
                attributeCursor.deleteCurrentRow();
            }
        }

        Table scenarios = db.getTable("t_objectscenarios");
        Cursor scenarioCursor = CursorBuilder.createCursor(scenarios);
        Row scenarioRow;
        while ((scenarioRow = scenarioCursor.getNextRow()) != null) {
            if (scenarioRow.get("Object_ID") instanceof Number
                && objectIds.contains(((Number) scenarioRow.get("Object_ID")).intValue())) {
                scenarioCursor.deleteCurrentRow();
            }
        }

        if (!connectorIds.isEmpty()) {
            Table links = db.getTable("t_diagramlinks");
            Cursor linkCursor = CursorBuilder.createCursor(links);
            Row linkRow;
            while ((linkRow = linkCursor.getNextRow()) != null) {
                if (linkRow.get("ConnectorID") instanceof Number
                    && connectorIds.contains(((Number) linkRow.get("ConnectorID")).intValue())) {
                    linkCursor.deleteCurrentRow();
                }
            }
        }

        if (db.getTableNames().contains("t_xref")) {
            Table xrefs = db.getTable("t_xref");
            Cursor xrefCursor = CursorBuilder.createCursor(xrefs);
            Row xrefRow;
            while ((xrefRow = xrefCursor.getNextRow()) != null) {
                if (guids.contains(s(xrefRow.get("Client")))) {
                    xrefCursor.deleteCurrentRow();
                }
            }
        }
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
        int diagram = findDiagramId(PKG_PADEVUSALAD, "Pädevusalad");
        if (diagram == 0) {
            diagram = addDiagramFromTemplate(2, PKG_PADEVUSALAD, "Use Case", "Pädevusalad");
        }
        int treener = findObjectId("Actor", "Treener");
        int juhataja = findObjectId("Actor", "Juhataja");
        int klient = findObjectId("Actor", "Klient");
        int uudistaja = findObjectId("Actor", "Uudistaja");
        int klassifikaatoriteHaldur = findObjectId("Actor", "Klassifikaatorite haldur");
        int tootajateHaldur = findObjectId("Actor", "Töötajate haldur");
        ensureDiagramObject(diagram, treener, 80, -80, 125, -170, 7);
        ensureDiagramObject(diagram, juhataja, 230, -80, 275, -170, 6);
        ensureDiagramObject(diagram, klient, 380, -80, 425, -170, 5);
        ensureDiagramObject(diagram, uudistaja, 530, -80, 575, -170, 4);
        ensureDiagramObject(diagram, klassifikaatoriteHaldur, 80, -250, 185, -350, 3);
        ensureDiagramObject(diagram, tootajateHaldur, 280, -250, 385, -350, 2);
    }

    private boolean diagramExists(int packageId, String name) throws Exception {
        return findDiagramId(packageId, name) != 0;
    }

    private int findDiagramId(int packageId, String name) throws Exception {
        for (Row row : db.getTable("t_diagram")) {
            if (name.equals(row.get("Name")) && row.get("Package_ID") instanceof Number && ((Number) row.get("Package_ID")).intValue() == packageId) {
                return ((Number) row.get("Diagram_ID")).intValue();
            }
        }
        return 0;
    }

    private boolean diagramHasObject(int diagramId, int objectId) throws Exception {
        for (Row row : db.getTable("t_diagramobjects")) {
            if (row.get("Diagram_ID") instanceof Number
                && row.get("Object_ID") instanceof Number
                && ((Number) row.get("Diagram_ID")).intValue() == diagramId
                && ((Number) row.get("Object_ID")).intValue() == objectId) {
                return true;
            }
        }
        return false;
    }

    private void ensureDiagramObject(int diagramId, int objectId, int left, int top, int right, int bottom, int sequence) throws Exception {
        if (objectId != 0 && !diagramHasObject(diagramId, objectId)) {
            addDiagramObject(diagramId, objectId, left, top, right, bottom, sequence);
        }
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
            "PostgreSQL tabel. PK: isikukood + riigi_kood. UK: e_meil. Veerud: isikukood, riigi_kood, isiku_seisundi_liik_kood, synni_kp, reg_aeg, viimase_muutm_aeg, eesnimi, perenimi, elukoht, e_meil.",
            "PostgreSQL tabel. PK: e_meil. FK kasutajakonto.e_meil viitab isik.e_meil unikaalsele võtmele. Veerud: e_meil, parool, on_aktiivne.",
            "PostgreSQL tabel. PK: kood. Veerud: kood, nimetus, on_aktiivne.",
            "PostgreSQL tabel. PK/FK: e_meil. Veerud: e_meil, tootaja_seisundi_liik_kood.",
            "PostgreSQL tabel. PK: kood. Veerud: kood, nimetus, on_aktiivne, kirjeldus.",
            "PostgreSQL tabel. PK: tootaja_e_meil + tootaja_roll_kood + alguse_aeg. Veerud: tootaja_e_meil, tootaja_roll_kood, alguse_aeg, lopu_aeg.",
            "PostgreSQL tabel. PK: kood. Veerud: kood, nimetus, on_aktiivne.",
            "PostgreSQL tabel. PK: kood. Veerud: kood, nimetus, on_aktiivne.",
            "PostgreSQL tabel. PK: kood. Veerud: kood, treeningu_kategooria_tyyp_kood, nimetus, on_aktiivne.",
            "PostgreSQL tabel. PK: treeningu_kood. UK: nimetus. Veerud: treeningu_kood, treeningu_seisundi_liik_kood, registreerija_e_meil, viimase_muutja_e_meil, reg_aeg, viimase_muutm_aeg, nimetus, kirjeldus, kestus_minutites, maksimaalne_osalejate_arv, vajalik_varustus, hind.",
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
        notesById.put(3, "Treeningu ametlik nimetus. Kohustuslik, mittetühi ja treeningute registris unikaalne.");
        notesById.put(5, "Treeningu sisu kirjeldus. Kohustuslik ja mittetühi.");
        notesById.put(22, "Treeningu kestus minutites. Kohustuslik väärtus vahemikus 15 kuni 240.");
        notesById.put(23, "Treeningule lubatud maksimaalne osalejate arv. Kohustuslik positiivne täisarv.");
        notesById.put(24, "Treeningul vajalik varustus. Kohustuslik ja mittetühi.");
        notesById.put(25, "Treeningu hind eurodes. Kohustuslik null või positiivne rahasumma.");

        Cursor cursor = CursorBuilder.createCursor(attributes);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            int id = ((Number) row.get("ID")).intValue();
            if (notesById.containsKey(id)) {
                row.put("Notes", notesById.get(id));
            }
            if (id == 4 || id == 7) {
                row.put("LowerBound", "1");
                row.put("UpperBound", "1");
            }
            cursor.updateCurrentRowFromMap(row);
        }
        setAttributeNoteByName(53, "nimetus", "Treeningu ametlik nimetus. Kohustuslik, mittetühi ja treeningute registris unikaalne.");
        setAttributeNoteByName(53, "kirjeldus", "Klientidele ja töötajatele mõeldud treeningu sisu kirjeldus. Kohustuslik ja mittetühi.");
        setAttributeNoteByName(53, "kestus_minutites", "Treeningu kestus minutites. Kohustuslik väärtus vahemikus 15 kuni 240.");
        setAttributeNoteByName(53, "maksimaalne_osalejate_arv", "Treeningule lubatud maksimaalne osalejate arv. Kohustuslik positiivne täisarv.");
        setAttributeNoteByName(53, "vajalik_varustus", "Treeningul vajalik varustus klientidele ja treenerile. Kohustuslik ja mittetühi.");
        setAttributeNoteByName(53, "hind", "Treeningu hind eurodes koos käibemaksuga. Kohustuslik null või positiivne rahasumma, maksimaalselt kaks kohta pärast koma.");
        setAttributeNoteByName(53, "seisund", "Treeningu elutsükli seisund.");
        setAttributeNoteByName(53, "registreerija_e_meil", "Treeningu registreerinud kasutajakonto e-posti aadress.");
        setAttributeNoteByName(53, "viimase_muutja_e_meil", "Treeningut viimati muutnud kasutajakonto e-posti aadress.");

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
        addAttrConstraint(50, 10, "synni_kp", "Mandatory", "Sünnikuupäev on kohustuslik.");
        addAttrConstraint(50, 10, "synni_kp", "Range", "Väärtus peab olema vahemikus 01.01.1900 kuni 31.12.2100.");
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
        addAttrConstraint(53, 3, "nimetus", "Mandatory", "Treeningu nimetus on kohustuslik.");
        addAttrConstraint(53, 3, "nimetus", "Not empty", "Treeningu nimetus ei tohi olla tühi string.");
        addAttrConstraint(53, 3, "nimetus", "Unique", "Treeningu nimetus on treeningute registris unikaalne.");
        addAttrConstraint(53, 5, "kirjeldus", "Mandatory", "Treeningu kirjeldus on kohustuslik.");
        addAttrConstraint(53, 5, "kirjeldus", "Not empty", "Treeningu kirjeldus ei tohi olla tühi string.");
        addAttrConstraint(53, 22, "kestus_minutites", "Mandatory", "Treeningu kestus on kohustuslik.");
        addAttrConstraint(53, 22, "kestus_minutites", "Range", "Treeningu kestus peab olema 15 kuni 240 minutit.");
        addAttrConstraint(53, 23, "maksimaalne_osalejate_arv", "Mandatory", "Maksimaalne osalejate arv on kohustuslik.");
        addAttrConstraint(53, 23, "maksimaalne_osalejate_arv", "Range", "Maksimaalne osalejate arv peab olema positiivne täisarv.");
        addAttrConstraint(53, 24, "vajalik_varustus", "Mandatory", "Vajalik varustus on kohustuslik.");
        addAttrConstraint(53, 24, "vajalik_varustus", "Not empty", "Vajalik varustus ei tohi olla tühi string.");
        addAttrConstraint(53, 25, "hind", "Mandatory", "Treeningu hind on kohustuslik.");
        addAttrConstraint(53, 25, "hind", "Range", "Treeningu hind peab olema null või positiivne rahasumma.");
        addAttrConstraint(53, 6, "reg_aeg", "Mandatory", "Registreerimise aeg on kohustuslik.");
        addAttrConstraint(53, 20, "viimase_muutm_aeg", "Range", "Viimase muutmise aeg peab olema registreerimise ajast suurem või sellega võrdne.");
    }

    private void setAttributeNoteByName(int objectId, String name, String note) throws Exception {
        Table table = db.getTable("t_attribute");
        Cursor cursor = CursorBuilder.createCursor(table);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            if (row.get("Object_ID") instanceof Number
                && ((Number) row.get("Object_ID")).intValue() == objectId
                && name.equals(row.get("Name"))) {
                row.put("Notes", note);
                cursor.updateCurrentRowFromMap(row);
                return;
            }
        }
    }

    private void addUseCaseExtendsAndScenarioText() throws Exception {
        removeUnsupportedUseCaseRelationship(63, 23, "extend");
        removeUnsupportedUseCaseRelationship(22, 28, "extend");
        addActivationScenarioRows();
    }

    private void removeUnsupportedUseCaseRelationship(int sourceId, int targetId, String stereotype) throws Exception {
        Table table = db.getTable("t_connector");
        Cursor cursor = CursorBuilder.createCursor(table);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            if ("UseCase".equals(row.get("Connector_Type"))
                && row.get("Start_Object_ID") instanceof Number
                && row.get("End_Object_ID") instanceof Number
                && ((Number) row.get("Start_Object_ID")).intValue() == sourceId
                && ((Number) row.get("End_Object_ID")).intValue() == targetId
                && stereotype.equals(s(row.get("Stereotype")).trim())) {
                cursor.deleteCurrentRow();
            }
        }
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
                + "5. Süsteem salvestab seisundimuudatuse operatsiooniga OP11.");
        addScenario(25, "Alternatiivid", "Alternate",
            "3a. Kui nimekirjas ei ole ühtegi ootel või mitteaktiivset treeningut, siis ei saa Treener jätkata.\n"
                + "4a. Kui treening ei kuulu ühtegi Treeningu_kategooriasse, siis aktiveerimine ebaõnnestub.");
    }

    private void addUseCaseNotes() throws Exception {
        Map<Integer, String> notesById = new LinkedHashMap<>();
        notesById.put(20, "Kasutaja esitab süsteemile autentimiseks vajalikud andmed ning süsteem seob kasutaja tema pädevusalaga.");
        notesById.put(21, "Juhataja vaatab treeningute arvu seisundite ja kategooriate kaupa.");
        notesById.put(22, "Juhataja lõpetab aktiivse või mitteaktiivse treeningu, mida jõusaal enam ei paku.");
        notesById.put(23, "Treener registreerib uue treeningu põhiandmed ja seob treeningu sobivate kategooriatega.");
        notesById.put(24, "Treener muudab ootel või mitteaktiivse treeningu põhiandmeid ja kategooriaseoseid.");
        notesById.put(25, "Treener muudab ootel või mitteaktiivse treeningu aktiivseks, kui treening kuulub vähemalt ühte kategooriasse.");
        notesById.put(26, "Treener eemaldab aktiivse treeningu ajutiselt kasutusest, kui treeninguga on ilmnenud ajutine probleem.");
        notesById.put(27, "Klient või uudistaja vaatab aktiivsete treeningute avalikke andmeid.");
        notesById.put(28, "Juhataja vaatab kõigi treeningute tööalaseid andmeid ja seisundeid.");
        notesById.put(29, "Treener vaatab ootel ja mitteaktiivseid treeninguid, et valida muutmiseks või aktiveerimiseks sobiv treening.");
        notesById.put(63, "Treener eemaldab ootel treeningu edasisest kasutusest, kui treeningut ei ole vaja pakkuda.");
        for (Map.Entry<Integer, String> entry : notesById.entrySet()) {
            updateById("t_object", "Object_ID", entry.getKey(), Map.of("Note", entry.getValue(), "ModifiedDate", new Date()));
        }
    }

    private void fixUseCaseDiagramConsistency() throws Exception {
        int diagram = 2;
        int treener = findObjectId("Actor", "Treener");
        int juhataja = findObjectId("Actor", "Juhataja");
        int klient = findObjectId("Actor", "Klient");
        int klassifikaatoriteHaldur = findObjectId("Actor", "Klassifikaatorite haldur");
        int tootajateHaldur = findObjectId("Actor", "Töötajate haldur");
        int tuvasta = findObjectId("UseCase", "Tuvasta kasutaja");
        int vaataKoiki = findObjectId("UseCase", "Vaata kõiki treeninguid");
        int muuda = findObjectId("UseCase", "Muuda treeningut");
        int aktiveeri = findObjectId("UseCase", "Aktiveeri treening");
        int vaataOotel = findObjectId("UseCase", "Vaata kõiki ootel või mitteaktiivseid treeninguid");

        removeConnectorAndLinks("Association", klient, tuvasta);
        removeConnectorAndLinks("Association", treener, vaataKoiki);
        removeConnectorAndLinks("UseCase", muuda, vaataOotel);
        removeConnectorAndLinks("UseCase", aktiveeri, vaataOotel);

        ensureConnectorOnDiagram(diagram, 1, "Association", "", treener, tuvasta, z());
        ensureConnectorOnDiagram(diagram, 1, "Association", "", juhataja, tuvasta, z());
        ensureConnectorOnDiagram(diagram, 1, "Association", "", klassifikaatoriteHaldur, tuvasta, z());
        ensureConnectorOnDiagram(diagram, 1, "Association", "", tootajateHaldur, tuvasta, z());
        ensureConnectorOnDiagram(diagram, 1, "Association", "", juhataja, vaataKoiki, z());
        ensureDiagramObject(diagram, klassifikaatoriteHaldur, 40, -710, 155, -810, 1);
        ensureDiagramObject(diagram, tootajateHaldur, 210, -710, 325, -810, 1);
    }

    private int ensurePackageObject(String name) throws Exception {
        int id = findObjectId("Package", name);
        if (id == 0) {
            id = addObjectFromTemplate(15, 9, "Package", 0, name, "Register, mida treeningute funktsionaalne allsüsteem loeb või kasutab seotud protsessides.");
        }
        updateById("t_object", "Object_ID", id, Map.of("Name", name, "Stereotype", "subsystem", "ModifiedDate", new Date()));
        Row row = findRow(db.getTable("t_object"), "Object_ID", id);
        addStereotypeXref("element", s(row.get("ea_guid")), "subsystem");
        return id;
    }

    private void populatePackageDiagramRelatedRegisters() throws Exception {
        // Scope is limited to the training-management subsystem and its directly used registers.
    }

    private void renameAttribute(int objectId, String oldName, String newName) throws Exception {
        Table table = db.getTable("t_attribute");
        Cursor cursor = CursorBuilder.createCursor(table);
        Row row;
        while ((row = cursor.getNextRow()) != null) {
            if (row.get("Object_ID") instanceof Number
                && ((Number) row.get("Object_ID")).intValue() == objectId
                && oldName.equals(row.get("Name"))) {
                row.put("Name", newName);
                cursor.updateCurrentRowFromMap(row);
            }
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

    private void addAttributeIfMissing(int objectId, String name, String type, String lower, String upper, String stereotype, String note) throws Exception {
        if (attributeExists(objectId, name)) {
            return;
        }
        Table table = db.getTable("t_attribute");
        table.setAllowAutoNumberInsert(true);
        Row template = table.iterator().next();
        Map<String, Object> row = copy(template);
        row.put("Object_ID", objectId);
        row.put("Name", name);
        row.put("Scope", "Private");
        row.put("Stereotype", stereotype == null || stereotype.isBlank() ? z() : stereotype);
        row.put("LowerBound", lower);
        row.put("UpperBound", upper);
        row.put("Notes", note);
        row.put("ID", maxLong(table, "ID") + 1);
        row.put("Pos", maxAttributePos(objectId) + 1);
        row.put("Type", type);
        row.put("ea_guid", guid());
        table.addRowFromMap(row);
    }

    private void ensureConceptualAttributeCoverage() throws Exception {
        renameAttribute(50, "sünni_kp", "synni_kp");
        addAttributeIfMissing(53, "nimetus", "varchar(200)", "1", "1", "", "Treeningu ametlik nimetus. Kohustuslik, mittetühi ja unikaalne.");
        addAttributeIfMissing(53, "kirjeldus", "text", "1", "1", "", "Klientidele ja töötajatele mõeldud treeningu sisu kirjeldus.");
        addAttributeIfMissing(53, "kestus_minutites", "integer", "1", "1", "", "Treeningu kestus minutites vahemikus 15 kuni 240.");
        addAttributeIfMissing(53, "maksimaalne_osalejate_arv", "integer", "1", "1", "", "Treeningule lubatud maksimaalne osalejate arv.");
        addAttributeIfMissing(53, "vajalik_varustus", "text", "1", "1", "", "Treeningul vajalik varustus klientidele ja treenerile.");
        addAttributeIfMissing(53, "hind", "numeric(8,2)", "1", "1", "", "Treeningu hind eurodes koos käibemaksuga, maksimaalselt kaks kohta pärast koma.");
        addAttributeIfMissing(53, "seisund", "varchar(20)", "1", "1", "", "Treeningu elutsükli seisund.");
        addAttributeIfMissing(53, "registreerija_e_meil", "varchar(254)", "1", "1", "", "Treeningu registreerinud kasutajakonto e-posti aadress.");
        addAttributeIfMissing(53, "viimase_muutja_e_meil", "varchar(254)", "1", "1", "", "Treeningut viimati muutnud kasutajakonto e-posti aadress.");
    }

    private void populatePhysicalTableColumns() throws Exception {
        addPhysicalColumns(79, new String[][] {
            {"riigi_kood", "varchar(10)", "PK, NOT NULL"},
            {"nimetus", "varchar(200)", "NOT NULL"},
            {"on_aktiivne", "boolean", "NOT NULL DEFAULT TRUE"}
        });
        addPhysicalColumns(80, new String[][] {
            {"kood", "varchar(10)", "PK, NOT NULL"},
            {"nimetus", "varchar(200)", "NOT NULL"},
            {"on_aktiivne", "boolean", "NOT NULL DEFAULT TRUE"}
        });
        addPhysicalColumns(81, new String[][] {
            {"isikukood", "varchar(20)", "PK, NOT NULL"},
            {"riigi_kood", "varchar(10)", "PK, FK riik.riigi_kood, NOT NULL"},
            {"isiku_seisundi_liik_kood", "varchar(10)", "FK isiku_seisundi_liik.kood, NOT NULL"},
            {"synni_kp", "date", "NOT NULL"},
            {"reg_aeg", "timestamp with time zone", "NOT NULL"},
            {"viimase_muutm_aeg", "timestamp with time zone", "NOT NULL"},
            {"eesnimi", "varchar(200)", "NULL"},
            {"perenimi", "varchar(200)", "NULL"},
            {"elukoht", "varchar(500)", "NULL"},
            {"e_meil", "varchar(254)", "UK, NOT NULL"}
        });
        addPhysicalColumns(82, new String[][] {
            {"e_meil", "varchar(254)", "PK, FK isik.e_meil, NOT NULL"},
            {"parool", "varchar(255)", "NOT NULL"},
            {"on_aktiivne", "boolean", "NOT NULL DEFAULT TRUE"}
        });
        addPhysicalColumns(83, new String[][] {
            {"kood", "varchar(10)", "PK, NOT NULL"},
            {"nimetus", "varchar(200)", "NOT NULL"},
            {"on_aktiivne", "boolean", "NOT NULL DEFAULT TRUE"}
        });
        addPhysicalColumns(84, new String[][] {
            {"e_meil", "varchar(254)", "PK, FK kasutajakonto.e_meil, NOT NULL"},
            {"tootaja_seisundi_liik_kood", "varchar(10)", "FK tootaja_seisundi_liik.kood, NOT NULL"}
        });
        addPhysicalColumns(85, new String[][] {
            {"kood", "varchar(10)", "PK, NOT NULL"},
            {"nimetus", "varchar(200)", "NOT NULL"},
            {"on_aktiivne", "boolean", "NOT NULL DEFAULT TRUE"},
            {"kirjeldus", "text", "NULL"}
        });
        addPhysicalColumns(86, new String[][] {
            {"tootaja_e_meil", "varchar(254)", "PK, FK tootaja.e_meil, NOT NULL"},
            {"tootaja_roll_kood", "varchar(10)", "PK, FK tootaja_roll.kood, NOT NULL"},
            {"alguse_aeg", "timestamp with time zone", "PK, NOT NULL"},
            {"lopu_aeg", "timestamp with time zone", "NULL"}
        });
        addPhysicalColumns(87, new String[][] {
            {"kood", "varchar(10)", "PK, NOT NULL"},
            {"nimetus", "varchar(200)", "NOT NULL"},
            {"on_aktiivne", "boolean", "NOT NULL DEFAULT TRUE"}
        });
        addPhysicalColumns(88, new String[][] {
            {"kood", "varchar(10)", "PK, NOT NULL"},
            {"nimetus", "varchar(200)", "NOT NULL"},
            {"on_aktiivne", "boolean", "NOT NULL DEFAULT TRUE"}
        });
        addPhysicalColumns(89, new String[][] {
            {"kood", "varchar(10)", "PK, NOT NULL"},
            {"treeningu_kategooria_tyyp_kood", "varchar(10)", "FK treeningu_kategooria_tyyp.kood, NOT NULL"},
            {"nimetus", "varchar(200)", "NOT NULL"},
            {"on_aktiivne", "boolean", "NOT NULL DEFAULT TRUE"}
        });
        addPhysicalColumns(90, new String[][] {
            {"treeningu_kood", "integer", "PK, NOT NULL"},
            {"treeningu_seisundi_liik_kood", "varchar(10)", "FK treeningu_seisundi_liik.kood, NOT NULL"},
            {"registreerija_e_meil", "varchar(254)", "FK kasutajakonto.e_meil, NOT NULL"},
            {"viimase_muutja_e_meil", "varchar(254)", "FK kasutajakonto.e_meil, NOT NULL"},
            {"reg_aeg", "timestamp with time zone", "NOT NULL"},
            {"viimase_muutm_aeg", "timestamp with time zone", "NOT NULL"},
            {"nimetus", "varchar(200)", "UK, NOT NULL"},
            {"kirjeldus", "text", "NOT NULL"},
            {"kestus_minutites", "integer", "NOT NULL"},
            {"maksimaalne_osalejate_arv", "integer", "NOT NULL"},
            {"vajalik_varustus", "text", "NOT NULL"},
            {"hind", "numeric(8,2)", "NOT NULL"}
        });
        addPhysicalColumns(91, new String[][] {
            {"treeningu_kood", "integer", "PK, FK treening.treeningu_kood, NOT NULL"},
            {"treeningu_kategooria_kood", "varchar(10)", "PK, FK treeningu_kategooria.kood, NOT NULL"}
        });
    }

    private void addPhysicalColumns(int objectId, String[][] columns) throws Exception {
        for (String[] column : columns) {
            String stereotype = column[2].contains("PK") ? "PK" : (column[2].contains("FK") ? "FK" : "");
            addAttributeIfMissing(objectId, column[0], column[1], column[2].contains("NULL") && !column[2].contains("NOT NULL") ? "0" : "1", "1", stereotype, column[2]);
        }
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
