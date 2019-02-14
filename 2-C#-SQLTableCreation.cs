/*This Code was used to create tables*/
using System;
using System.Data;
using System.Data.SqlClient;
using System.Linq;

namespace QBUtility
{
    /// <summary>
    ///     SqlTableCreator - public class to deal with Tables creating in DB
    /// </summary>
    public class SqlTableCreator
    {
        private string _tableName;

        /// <summary>
        ///     Empty consructor for TableCreator class
        /// </summary>
        public SqlTableCreator()
        {
        }

        /// <summary>
        ///     Consructor for TableCreator class
        /// </summary>
        public SqlTableCreator(SqlConnection connection)
            : this(connection, null)
        {
        }

        /// <summary>
        ///     Consructor for TableCreator class
        /// </summary>
        private SqlTableCreator(SqlConnection connection, SqlTransaction transaction)
        {
            Connection = connection;
            Transaction = transaction;
        }

        /// <summary>
        ///     Connection - public property for connection string
        /// </summary>
        private SqlConnection Connection { get; }

        /// <summary>
        ///     Transaction - public property for transaction
        /// </summary>
        private SqlTransaction Transaction { get; }

        /// <summary>
        ///     DestinationTable - public property for DestinationTable to create
        /// </summary>
        public string DestinationTableName
        {
            get { return _tableName; }
            set { _tableName = value; }
        }

        /// <summary>
        ///     Create schema in DB
        /// </summary>
        public object Create(DataTable schema)
        {
            return Create(schema, null);
        }

        /// <summary>
        ///     Create schema in DB with primary key
        /// </summary>
        public object Create(DataTable schema, int numKeys)
        {
            var primaryKeys = new int[numKeys];
            for (var i = 0; i < numKeys; i++)
            {
                primaryKeys[i] = i;
            }
            return Create(schema, primaryKeys);
        }

        /// <summary>
        ///     Create schema in DB with set of primary keys
        /// </summary>
        private object Create(DataTable schema, int[] primaryKeys)
        {
            var sql = GetCreateSql(_tableName, schema, primaryKeys);

            var cmd = Transaction?.Connection != null ? new SqlCommand(sql, Connection, Transaction) : new SqlCommand(sql, Connection);
            return cmd.ExecuteNonQuery();
        }

        /// <summary>
        ///     Create table based on DataTable
        /// </summary>
        public object CreateFromDataTable(DataTable table)
        {
            var sql = GetCreateFromDataTableSql(_tableName, table);

            var cmd = Transaction?.Connection != null ? new SqlCommand(sql, Connection, Transaction) : new SqlCommand(sql, Connection);
            return cmd.ExecuteNonQuery();
        }

        /// <summary>
        ///     Create table in DN based on SQl query
        /// </summary>
        private static string GetCreateSql(string tableName, DataTable schema, int[] primaryKeys)
        {
            var sql = "CREATE TABLE [" + tableName + "] (\n";

            foreach (DataRow column in schema.Rows)
            {
                if (!(schema.Columns.Contains("IsHidden") && (bool)column["IsHidden"]))
                {
                    sql += "\t[" + column["ColumnName"] + "] " + SqlGetType(column);

                    if (schema.Columns.Contains("AllowDBNull") && (bool)column["AllowDBNull"] == false)
                    {
                        sql += " NOT NULL";
                    }
                    sql += ",\n";
                }
            }
            sql = sql.TrimEnd(',', '\n') + "\n";

            var pk = ", CONSTRAINT PK_" + tableName + " PRIMARY KEY CLUSTERED (";
            var hasKeys = (primaryKeys != null && primaryKeys.Length > 0);
            if (hasKeys)
            {
                foreach (var key in primaryKeys)
                {
                    pk += schema.Rows[key]["ColumnName"] + ", ";
                }
            }
            else
            {
                var keys = string.Join(", ", GetPrimaryKeys(schema));
                pk += keys;
                hasKeys = keys.Length > 0;
            }
            pk = pk.TrimEnd(',', ' ', '\n') + ")\n";
            if (hasKeys)
            {
                sql += pk;
            }
            sql += ")";

            return sql;
        }

        /// <summary>
        ///     Creates table in DB with certain number of columns
        /// </summary>
        public object Create(string tableName, int columnsNumber)
        {
            var numofCol = columnsNumber;
            var sql = "CREATE TABLE " + tableName + " (";
            sql += "[rowID] " + "[int] IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED" + ",";
            for (var column = 1; column <= numofCol; column++)
            {
                sql += "[column" + column + "] " + "[varchar](255) NULL" + ",";
            }
            sql = sql.TrimEnd(',', '\n');

            if (!sql.EndsWith(")"))
            {
                sql += ")";
            }


            var cmd = Transaction?.Connection != null ? new SqlCommand(sql, Connection, Transaction) : new SqlCommand(sql, Connection);
            return cmd.ExecuteNonQuery();
        }

        /// <summary>
        ///     Return SQL based on Data table and Table name
        /// </summary>
        private static string GetCreateFromDataTableSql(string tableName, DataTable table)
        {
            var sql = "CREATE TABLE [" + tableName + "] (";
            sql = table.Columns.Cast<DataColumn>().Aggregate(sql, (current, column) => current + ("[" + column.ColumnName + "] " + SqlGetType(column).ToLower() + ","));

            sql = sql.TrimEnd(',', '\n');
            if (table.PrimaryKey.Length > 0)
            {
                sql += "CONSTRAINT [PK_" + tableName + "] PRIMARY KEY CLUSTERED (";
                sql = table.PrimaryKey.Aggregate(sql, (current, column) => current + ("[" + column.ColumnName + "],"));
                sql = sql.TrimEnd(',') + "))\n";
            }

            if ((table.PrimaryKey.Length == 0) && (!sql.EndsWith("))")))
            {
                sql += ")";
            }

            return sql;
        }

        /// <summary>
        ///     Get primary key from DB
        /// </summary>
        private static string[] GetPrimaryKeys(DataTable schema)
        {
            return (from DataRow column in schema.Rows where schema.Columns.Contains("IsKey") && (bool) column["IsKey"] select column["ColumnName"].ToString()).ToArray();
        }

        /// <summary>
        ///     Return DB column type
        /// </summary>
        private static string SqlGetType(object type, int columnSize, int numericPrecision, int numericScale)
        {
            switch (type.ToString())
            {
                // HACK:
                // Default all string types to MAX size, save a lot of hassle later
                case "System.String":
                    return "NVARCHAR(MAX)";

                case "System.Decimal":
                    return "Decimal(13,2)";
                    //if (numericScale > 0)
                    //{
                    //    return "Decimal";
                    //}

                    //return numericPrecision > 10 ? "BIGINT" : "INT";
                case "System.Double":
                case "System.Single":
                    return "REAL";

                case "System.Int64":
                    return "BIGINT";

                case "System.Int16":
                case "System.Int32":
                    return "INT";

                case "System.DateTime":
                    return "DATETIME";

                case "System.Boolean":
                    return "BIT";

                case "System.Byte":
                    return "TINYINT";

                case "System.Guid":
                    return "UNIQUEIDENTIFIER";

                default:
                    throw new Exception(type + " not implemented.");
            }
        }

        /// <summary>
        ///     SQLGetType
        /// </summary>
        private static string SqlGetType(DataRow schemaRow)
        {
            return SqlGetType(schemaRow["DataType"],
                int.Parse(schemaRow["ColumnSize"].ToString()),
                int.Parse(schemaRow["NumericPrecision"].ToString()),
                int.Parse(schemaRow["NumericScale"].ToString()));
        }

        /// <summary>
        ///     Return type of Column in Table from Data Base
        /// </summary>
        private static string SqlGetType(DataColumn column)
        {
            return SqlGetType(column.DataType, column.MaxLength, 10, 2);
        }

        /// <summary>
        ///     Insert data to Table in Data Base ( table already created)
        /// </summary>
        public void BulkInsertDataTable(string connectionString, string tableName, DataTable table)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                var bulkCopy =
                    new SqlBulkCopy
                        (
                        connection,
                        SqlBulkCopyOptions.TableLock |
                        SqlBulkCopyOptions.FireTriggers |
                        SqlBulkCopyOptions.UseInternalTransaction,
                        null
                        )
                    { DestinationTableName = $"[{tableName}]" };

                connection.Open();

                bulkCopy.WriteToServer(table);
                connection.Close();
            }
        }
    }
}