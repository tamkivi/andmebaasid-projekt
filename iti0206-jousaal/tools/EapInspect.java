import com.healthmarketscience.jackcess.Database;
import com.healthmarketscience.jackcess.DatabaseBuilder;
import com.healthmarketscience.jackcess.Table;

import java.io.File;

public class EapInspect {
    public static void main(String[] args) throws Exception {
        try (Database db = DatabaseBuilder.open(new File(args[0]))) {
            System.out.println("Tables:");
            for (String tableName : db.getTableNames()) {
                System.out.println(tableName);
            }
            for (String tableName : new String[]{"t_package", "t_object", "t_diagram"}) {
                Table table = db.getTable(tableName);
                System.out.println(tableName + ": " + (table == null ? "missing" : table.getColumns()));
                if (table != null) {
                    table.iterator().forEachRemaining(row -> {
                        System.out.println(row);
                    });
                }
            }
        }
    }
}
