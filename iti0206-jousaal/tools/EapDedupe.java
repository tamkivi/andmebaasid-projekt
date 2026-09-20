import com.healthmarketscience.jackcess.Column;
import com.healthmarketscience.jackcess.ColumnBuilder;
import com.healthmarketscience.jackcess.Database;
import com.healthmarketscience.jackcess.DatabaseBuilder;
import com.healthmarketscience.jackcess.DataType;
import com.healthmarketscience.jackcess.Index;
import com.healthmarketscience.jackcess.IndexBuilder;
import com.healthmarketscience.jackcess.Row;
import com.healthmarketscience.jackcess.Table;
import com.healthmarketscience.jackcess.TableBuilder;

import java.io.File;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class EapDedupe {
    private static TableBuilder tableBuilder(Table source) throws Exception {
        TableBuilder builder = new TableBuilder(source.getName());
        for (Column column : source.getColumns()) {
            ColumnBuilder columnBuilder = new ColumnBuilder(column.getName()).setFromColumn(column);
            if (column.getType() == DataType.TEXT) {
                columnBuilder.setLengthInUnits(Math.max(1, column.getLengthInUnits()));
            }
            builder.addColumn(columnBuilder);
        }
        for (Index index : source.getIndexes()) {
            if (index.isForeignKey()) {
                continue;
            }
            IndexBuilder indexBuilder = new IndexBuilder(index.getName());
            if (index.isPrimaryKey()) {
                indexBuilder.setPrimaryKey();
            }
            if (index.isUnique()) {
                indexBuilder.setUnique();
            }
            if (index.isRequired()) {
                indexBuilder.setRequired();
            }
            if (index.shouldIgnoreNulls()) {
                indexBuilder.setIgnoreNulls();
            }
            for (Index.Column column : index.getColumns()) {
                indexBuilder.addColumns(column.isAscending(), column.getName());
            }
            builder.addIndex(indexBuilder);
        }
        return builder;
    }

    private static String s(Object value) {
        return value == null ? "" : value.toString();
    }

    private static String groupKey(String tableName, Row row) {
        if ("t_connector".equals(tableName)) {
            return s(row.get("Connector_ID"));
        }
        if ("t_attribute".equals(tableName)) {
            return s(row.get("ID"));
        }
        if ("t_object".equals(tableName)) {
            return s(row.get("Object_ID"));
        }
        return "";
    }

    private static int rowQuality(String tableName, Row row) {
        if ("t_connector".equals(tableName)) {
            String name = s(row.get("Name"));
            String op = s(row.get("PDATA3"));
            int score = 0;
            if (!name.contains("<Siia") && !op.contains("OP..") && !op.contains("OP ...")) {
                score += 100;
            }
            if (!name.isBlank() && Character.isUpperCase(name.codePointAt(0))) {
                score += 10;
            }
            if (op.equals("OP3") || op.equals("OP6") || op.equals("OP8") || op.equals("OP11") || op.equals("OP13") || op.equals("OP15")) {
                score += 30;
            }
            if (op.contains("OP1, OP7, OP8") || op.equals("OP2") || op.equals("OP4") || op.equals("OP5")) {
                score -= 15;
            }
            return score;
        }
        if ("t_attribute".equals(tableName)) {
            return s(row.get("Notes")).isBlank() ? 0 : 100;
        }
        if ("t_object".equals(tableName)) {
            return s(row.get("Note")).isBlank() ? 0 : 100;
        }
        return 0;
    }

    private static List<Map<String, Object>> filteredRows(String tableName, Table sourceTable) {
        if (!"t_connector".equals(tableName) && !"t_attribute".equals(tableName) && !"t_object".equals(tableName)) {
            List<Map<String, Object>> rows = new ArrayList<>();
            for (Row row : sourceTable) {
                rows.add(new LinkedHashMap<>(row));
            }
            return rows;
        }

        Map<String, Row> bestRows = new LinkedHashMap<>();
        Map<String, Integer> bestScores = new LinkedHashMap<>();
        for (Row row : sourceTable) {
            String key = groupKey(tableName, row);
            if (key.isBlank()) {
                bestRows.put("row-" + bestRows.size(), row);
                continue;
            }
            int score = rowQuality(tableName, row);
            if (!bestRows.containsKey(key) || score >= bestScores.get(key)) {
                bestRows.put(key, row);
                bestScores.put(key, score);
            }
        }

        List<Map<String, Object>> rows = new ArrayList<>();
        for (Row row : bestRows.values()) {
            rows.add(new LinkedHashMap<>(row));
        }
        return rows;
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            throw new IllegalArgumentException("Usage: EapDedupe <source.eap> <target.eap>");
        }
        File sourceFile = new File(args[0]);
        File targetFile = new File(args[1]);
        if (targetFile.exists() && !targetFile.delete()) {
            throw new IllegalStateException("Could not delete existing target: " + targetFile);
        }

        int tableCount = 0;
        int rowCount = 0;
        try (
            Database source = new DatabaseBuilder(sourceFile).open();
            Database target = DatabaseBuilder.create(Database.FileFormat.V2000, targetFile)
        ) {
            for (String tableName : source.getTableNames()) {
                Table sourceTable = source.getTable(tableName);
                if (sourceTable == null) {
                    continue;
                }
                Table targetTable = tableBuilder(sourceTable).toTable(target);
                targetTable.setAllowAutoNumberInsert(true);
                List<Map<String, Object>> rows = filteredRows(tableName, sourceTable);
                for (Map<String, Object> row : rows) {
                    targetTable.addRowFromMap(row);
                    rowCount++;
                }
                tableCount++;
            }
        }
        System.out.println("Deduped tables: " + tableCount);
        System.out.println("Copied rows: " + rowCount);
    }
}
