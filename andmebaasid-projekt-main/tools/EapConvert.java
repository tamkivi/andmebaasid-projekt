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
import java.nio.charset.Charset;

public class EapConvert {
    private static final Charset EAP_CHARSET = Charset.forName("windows-1252");

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

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            throw new IllegalArgumentException("Usage: EapConvert <source.eap> <target.eap>");
        }
        File sourceFile = new File(args[0]);
        File targetFile = new File(args[1]);
        if (targetFile.exists() && !targetFile.delete()) {
            throw new IllegalStateException("Could not delete existing target: " + targetFile);
        }

        int tableCount = 0;
        int rowCount = 0;
        try (
            Database source = new DatabaseBuilder(sourceFile).setCharset(EAP_CHARSET).open();
            Database target = DatabaseBuilder.create(Database.FileFormat.V2000, targetFile)
        ) {
            for (String tableName : source.getTableNames()) {
                Table sourceTable = source.getTable(tableName);
                if (sourceTable == null) {
                    continue;
                }
                Table targetTable = tableBuilder(sourceTable).toTable(target);
                targetTable.setAllowAutoNumberInsert(true);
                for (Row row : sourceTable) {
                    targetTable.addRowFromMap(row);
                    rowCount++;
                }
                tableCount++;
            }
        }
        System.out.println("Converted tables: " + tableCount);
        System.out.println("Converted rows: " + rowCount);
    }
}
