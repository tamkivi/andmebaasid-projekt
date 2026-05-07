import com.healthmarketscience.jackcess.Cursor;
import com.healthmarketscience.jackcess.CursorBuilder;
import com.healthmarketscience.jackcess.Database;
import com.healthmarketscience.jackcess.DatabaseBuilder;
import com.healthmarketscience.jackcess.Row;
import com.healthmarketscience.jackcess.Table;
import com.healthmarketscience.jackcess.Column;

import java.io.File;
import java.nio.channels.FileChannel;
import java.nio.file.StandardOpenOption;
import java.util.LinkedHashMap;
import java.util.Map;

public class EapRename {
    private static final Map<String, String> REPLACEMENTS = new LinkedHashMap<>();

    static {
        REPLACEMENTS.put("Y infosüsteem", "Jõusaali infosüsteem");
        REPLACEMENTS.put("X funktsionaalne allsüsteem", "treeningute funktsionaalne allsüsteem");
        REPLACEMENTS.put("X register", "treeningute register");
        REPLACEMENTS.put("X elutsüklid", "treeningute elutsüklid");
        REPLACEMENTS.put("X haldur", "treener");
        REPLACEMENTS.put("Registreeri X", "Registreeri treening");
        REPLACEMENTS.put("Unusta X", "Unusta treening");
        REPLACEMENTS.put("Muuda X mittaktiivseks", "Muuda treening mitteaktiivseks");
        REPLACEMENTS.put("Muuda X mitteaktiivseks", "Muuda treening mitteaktiivseks");
        REPLACEMENTS.put("Muuda X", "Muuda treeningut");
        REPLACEMENTS.put("Aktiveeri X", "Aktiveeri treening");
        REPLACEMENTS.put("Lõpeta X", "Lõpeta treening");
        REPLACEMENTS.put("Lõpeta valitud X", "Lõpeta valitud treening");
        REPLACEMENTS.put("Otsi X", "Otsi treeningut");
        REPLACEMENTS.put("Vali X", "Vali treening");
        REPLACEMENTS.put("Vaata aktiivseid X", "Vaata aktiivseid treeninguid");
        REPLACEMENTS.put("Vaata kõiki X", "Vaata kõiki treeninguid");
        REPLACEMENTS.put("Vaata kõiki X, mida saab lõpetada", "Vaata kõiki treeninguid, mida saab lõpetada");
        REPLACEMENTS.put("Vaata kõiki ootel või mitteaktiivseid X", "Vaata kõiki ootel või mitteaktiivseid treeninguid");
        REPLACEMENTS.put("Vaata X koondaruannet", "Vaata treeningute koondaruannet");
        REPLACEMENTS.put("X lõpetamise tegevusdiagramm", "treeningu lõpetamise tegevusdiagramm");
        REPLACEMENTS.put("X seisundidiagramm", "treeningu seisundidiagramm");
        REPLACEMENTS.put("X FASiga seotud pädevusalad ja registrid", "treeningute FASiga seotud pädevusalad ja registrid");
        REPLACEMENTS.put("X_kategooria_omamine", "treeningu_kategooria_omamine");
        REPLACEMENTS.put("X_kategooria_tüüp", "treeningu_kategooria_tüüp");
        REPLACEMENTS.put("X_kategooria", "treeningu_kategooria");
        REPLACEMENTS.put("X_seisundi_liik", "treeningu_seisundi_liik");
        REPLACEMENTS.put("X_kood", "treeningu_kood");
    }

    private static String rename(String value) {
        if (value == null) {
            return null;
        }
        String result = value;
        for (Map.Entry<String, String> entry : REPLACEMENTS.entrySet()) {
            result = result.replace(entry.getKey(), entry.getValue());
        }
        if (result.equals("X")) {
            return "Treening";
        }
        result = result.replaceAll("\\bX\\b", "treening");
        return result;
    }

    private static String findColumn(Table table, String columnName) {
        for (Column column : table.getColumns()) {
            if (column.getName().equalsIgnoreCase(columnName)) {
                return column.getName();
            }
        }
        return null;
    }

    private static int updateColumn(Database db, String tableName, String columnName) throws Exception {
        Table table = db.getTable(tableName);
        if (table == null) {
            return 0;
        }
        String actualColumnName = findColumn(table, columnName);
        if (actualColumnName == null) {
            return 0;
        }
        Cursor cursor = CursorBuilder.createCursor(table);
        int count = 0;
        for (Row row : cursor) {
            Object value = row.get(actualColumnName);
            if (!(value instanceof String)) {
                continue;
            }
            String oldValue = (String) value;
            String newValue = rename(oldValue);
            if (!newValue.equals(oldValue)) {
                row.put(actualColumnName, newValue);
                table.updateRow(row);
                count++;
            }
        }
        return count;
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            throw new IllegalArgumentException("Usage: EapRename <file.eap>");
        }
        int count = 0;
        File file = new File(args[0]);
        try (
            FileChannel channel = FileChannel.open(
                file.toPath(),
                StandardOpenOption.READ,
                StandardOpenOption.WRITE
            );
            Database db = new DatabaseBuilder(file)
                .setChannel(channel)
                .setReadOnly(false)
                .open()
        ) {
            count += updateColumn(db, "t_package", "Name");
            count += updateColumn(db, "t_object", "Name");
            count += updateColumn(db, "t_object", "Alias");
            count += updateColumn(db, "t_object", "Note");
            count += updateColumn(db, "t_object", "Author");
            count += updateColumn(db, "t_diagram", "Name");
            count += updateColumn(db, "t_attribute", "Name");
            count += updateColumn(db, "t_attribute", "Notes");
            count += updateColumn(db, "t_attribute", "Type");
            count += updateColumn(db, "t_operation", "Name");
            count += updateColumn(db, "t_connector", "Name");
            count += updateColumn(db, "t_connector", "SourceRole");
            count += updateColumn(db, "t_connector", "DestRole");
            count += updateColumn(db, "t_connector", "PDATA1");
            count += updateColumn(db, "t_connector", "PDATA2");
            count += updateColumn(db, "t_connector", "PDATA3");
            count += updateColumn(db, "t_connector", "PDATA4");
            count += updateColumn(db, "t_connector", "PDATA5");
        }
        System.out.println("Updated fields: " + count);
    }
}
