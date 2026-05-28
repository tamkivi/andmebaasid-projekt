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
        REPLACEMENTS.put("X funktsionaalne allsüsteem", "registreeringukeskne rühmatreeningute funktsionaalne allsüsteem");
        REPLACEMENTS.put("X register", "registreeringute register");
        REPLACEMENTS.put("X elutsüklid", "registreeringu ja treeningukorra elutsüklid");
        REPLACEMENTS.put("X haldur", "juhataja");
        REPLACEMENTS.put("Registreeri X", "Planeeri treeningukord");
        REPLACEMENTS.put("Unusta X", "Tühista treeningukord");
        REPLACEMENTS.put("Muuda X mittaktiivseks", "Sulge treeningukord");
        REPLACEMENTS.put("Muuda X mitteaktiivseks", "Sulge treeningukord");
        REPLACEMENTS.put("Muuda X", "Muuda treeningukorra andmeid");
        REPLACEMENTS.put("Aktiveeri X", "Ava registreerimine");
        REPLACEMENTS.put("Lõpeta X", "Lõpeta treeningukord");
        REPLACEMENTS.put("Lõpeta valitud X", "Lõpeta valitud treeningukord");
        REPLACEMENTS.put("Otsi X", "Otsi treeningukorda");
        REPLACEMENTS.put("Vali X", "Vali treeningukord");
        REPLACEMENTS.put("Vaata aktiivseid X", "Vaata avatud rühmatreeningute ajakava");
        REPLACEMENTS.put("Vaata kõiki X", "Vaata enda registreeringuid");
        REPLACEMENTS.put("Vaata kõiki X, mida saab lõpetada", "Vaata treeningukordi, mida saab lõpetada");
        REPLACEMENTS.put("Vaata kõiki ootel või mitteaktiivseid X", "Vaata kavandatud või suletud treeningukordi");
        REPLACEMENTS.put("Vaata X koondaruannet", "Vaata treeningukordade täituvuse statistikat");
        REPLACEMENTS.put("X lõpetamise tegevusdiagramm", "treeningukorra lõpetamise tegevusdiagramm");
        REPLACEMENTS.put("X seisundidiagramm", "treeningukorra seisundidiagramm");
        REPLACEMENTS.put("X FASiga seotud pädevusalad ja registrid", "registreeringukeskse FASiga seotud pädevusalad ja registrid");
        REPLACEMENTS.put("X_kategooria_omamine", "treeninguliigi_kategooria_omamine");
        REPLACEMENTS.put("X_kategooria_tüüp", "treeningu_kategooria_tyyp");
        REPLACEMENTS.put("X_kategooria", "treeningu_kategooria");
        REPLACEMENTS.put("X_seisundi_liik", "treeningukorra_seisundi_liik");
        REPLACEMENTS.put("X_kood", "treeningukorra_id");
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
            return "Treeningukord";
        }
        result = result.replaceAll("\\bX\\b", "treeningukord");
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
