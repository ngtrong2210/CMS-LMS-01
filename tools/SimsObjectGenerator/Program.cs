using System.Security;
using System.Text;
using System.Text.Json;
using Microsoft.Data.SqlClient;

const string localSettingsPath = "src/Sims.Api/appsettings.Local.json";
const string baseFolder = "src/SimsObject/Base";
const string extensionFolder = "src/SimsObject";

var repositoryRoot = FindRepositoryRoot(Directory.GetCurrentDirectory());
var connectionString = Environment.GetEnvironmentVariable("SIMS_OBJECT_CONNECTION_STRING")
    ?? ReadLocalConnectionString(Path.Combine(repositoryRoot, localSettingsPath));

var tables = await ReadSchemaAsync(connectionString);
if (tables.Count == 0)
{
    Console.Error.WriteLine("Không tìm thấy bảng người dùng trong SQL Server.");
    return 1;
}

var outputFolder = Path.Combine(repositoryRoot, baseFolder);
Directory.CreateDirectory(outputFolder);

foreach (var staleFile in Directory.GetFiles(outputFolder, "*Base.cs"))
{
    File.Delete(staleFile);
}

foreach (var table in tables)
{
    var className = ToIdentifier(table.TableName);
    var baseFile = Path.Combine(outputFolder, $"{className}Base.cs");
    await File.WriteAllTextAsync(baseFile, RenderBaseClass(table, className), new UTF8Encoding(false));

    var extensionFile = Path.Combine(repositoryRoot, extensionFolder, $"{className}.cs");
    if (!File.Exists(extensionFile))
    {
        await File.WriteAllTextAsync(extensionFile, RenderExtensionClass(table, className), new UTF8Encoding(false));
    }
}

Console.WriteLine($"Đã sinh {tables.Count} object từ schema SQL Server vào {baseFolder}.");
return 0;

static string FindRepositoryRoot(string startPath)
{
    var current = new DirectoryInfo(startPath);
    while (current is not null)
    {
        if (File.Exists(Path.Combine(current.FullName, "Sims.sln")))
        {
            return current.FullName;
        }

        current = current.Parent;
    }

    throw new DirectoryNotFoundException("Không tìm thấy thư mục gốc chứa Sims.sln.");
}

static string ReadLocalConnectionString(string settingsPath)
{
    if (!File.Exists(settingsPath))
    {
        throw new FileNotFoundException(
            "Không tìm thấy appsettings.Local.json. Hãy đặt biến môi trường SIMS_OBJECT_CONNECTION_STRING.",
            settingsPath);
    }

    using var document = JsonDocument.Parse(File.ReadAllText(settingsPath));
    if (document.RootElement.TryGetProperty("ConnectionStrings", out var connectionStrings)
        && connectionStrings.TryGetProperty("DefaultConnection", out var defaultConnection)
        && !string.IsNullOrWhiteSpace(defaultConnection.GetString()))
    {
        return defaultConnection.GetString()!;
    }

    throw new InvalidOperationException(
        "ConnectionStrings:DefaultConnection chưa được cấu hình. Hãy đặt biến môi trường SIMS_OBJECT_CONNECTION_STRING.");
}

static async Task<List<TableDefinition>> ReadSchemaAsync(string connectionString)
{
    const string sql = """
        Select
            SchemaName = schemaInfo.name,
            TableName = tableInfo.name,
            TableDescription = Convert(nvarchar(4000), tableDescription.value),
            ColumnID = columnInfo.column_id,
            ColumnName = columnInfo.name,
            SqlType = typeInfo.name,
            MaxLength = columnInfo.max_length,
            PrecisionValue = columnInfo.precision,
            ScaleValue = columnInfo.scale,
            IsNullable = columnInfo.is_nullable,
            IsIdentity = columnInfo.is_identity,
            IsComputed = columnInfo.is_computed,
            IsPrimaryKey = Convert(bit, Case when primaryKey.column_id Is null then 0 else 1 end),
            ColumnDescription = Convert(nvarchar(4000), columnDescription.value)
        From sys.tables tableInfo
        Inner Join sys.schemas schemaInfo On tableInfo.schema_id = schemaInfo.schema_id
        Inner Join sys.columns columnInfo On tableInfo.object_id = columnInfo.object_id
        Inner Join sys.types typeInfo On columnInfo.user_type_id = typeInfo.user_type_id
        Left Join sys.extended_properties tableDescription On tableDescription.major_id = tableInfo.object_id And tableDescription.minor_id = 0 And tableDescription.name = N'MS_Description'
        Left Join sys.extended_properties columnDescription On columnDescription.major_id = tableInfo.object_id And columnDescription.minor_id = columnInfo.column_id And columnDescription.name = N'MS_Description'
        Left Join
        (
            Select
                indexColumn.object_id,
                indexColumn.column_id
            From sys.indexes indexInfo
            Inner Join sys.index_columns indexColumn On indexInfo.object_id = indexColumn.object_id And indexInfo.index_id = indexColumn.index_id
            Where (indexInfo.is_primary_key = 1)
        ) primaryKey On primaryKey.object_id = tableInfo.object_id And primaryKey.column_id = columnInfo.column_id
        Where (tableInfo.is_ms_shipped = 0)
        Order By
            schemaInfo.name,
            tableInfo.name,
            columnInfo.column_id
        """;

    var tables = new List<TableDefinition>();
    await using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync();
    await using var command = new SqlCommand(sql, connection);
    await using var reader = await command.ExecuteReaderAsync();

    TableDefinition? currentTable = null;
    while (await reader.ReadAsync())
    {
        var schemaName = reader.GetString(reader.GetOrdinal("SchemaName"));
        var tableName = reader.GetString(reader.GetOrdinal("TableName"));
        if (currentTable is null || currentTable.SchemaName != schemaName || currentTable.TableName != tableName)
        {
            currentTable = new TableDefinition(
                schemaName,
                tableName,
                GetNullableString(reader, "TableDescription"),
                []);
            tables.Add(currentTable);
        }

        currentTable.Columns.Add(new ColumnDefinition(
            reader.GetInt32(reader.GetOrdinal("ColumnID")),
            reader.GetString(reader.GetOrdinal("ColumnName")),
            reader.GetString(reader.GetOrdinal("SqlType")),
            reader.GetInt16(reader.GetOrdinal("MaxLength")),
            reader.GetByte(reader.GetOrdinal("PrecisionValue")),
            reader.GetByte(reader.GetOrdinal("ScaleValue")),
            reader.GetBoolean(reader.GetOrdinal("IsNullable")),
            reader.GetBoolean(reader.GetOrdinal("IsIdentity")),
            reader.GetBoolean(reader.GetOrdinal("IsComputed")),
            reader.GetBoolean(reader.GetOrdinal("IsPrimaryKey")),
            GetNullableString(reader, "ColumnDescription")));
    }

    return tables;
}

static string? GetNullableString(SqlDataReader reader, string name)
{
    var ordinal = reader.GetOrdinal(name);
    return reader.IsDBNull(ordinal) ? null : reader.GetString(ordinal);
}

static string RenderBaseClass(TableDefinition table, string className)
{
    var builder = new StringBuilder();
    builder.AppendLine("// <auto-generated>");
    builder.AppendLine("// File được sinh bởi tools/SimsObjectGenerator. Không sửa trực tiếp file này.");
    builder.AppendLine("// </auto-generated>");
    builder.AppendLine();
    builder.AppendLine("#nullable enable");
    builder.AppendLine();
    builder.AppendLine("namespace SimsObject;");
    builder.AppendLine();
    AppendSummary(builder, table.TableDescription ?? $"Đối tượng ánh xạ bảng {table.SchemaName}.{table.TableName}.");
    builder.AppendLine($"public partial class {className}");
    builder.AppendLine("{");
    builder.AppendLine($"    public const string TableSchema = \"{EscapeString(table.SchemaName)}\";");
    builder.AppendLine($"    public const string TableName = \"{EscapeString(table.TableName)}\";");
    builder.AppendLine($"    public const string QualifiedTableName = \"[{EscapeString(table.SchemaName)}].[{EscapeString(table.TableName)}]\";");

    foreach (var column in table.Columns)
    {
        var identifier = ToIdentifier(column.ColumnName);
        builder.AppendLine();
        builder.AppendLine($"    public const string C_{identifier} = \"{EscapeString(column.ColumnName)}\";");
        builder.AppendLine($"    public const string P_{identifier} = \"@{EscapeString(column.ColumnName)}\";");
    }

    foreach (var column in table.Columns)
    {
        var identifier = ToIdentifier(column.ColumnName);
        var typeName = GetCSharpType(column.SqlType, column.IsNullable);
        var flags = new List<string>();
        if (column.IsPrimaryKey) flags.Add("Khóa chính");
        if (column.IsIdentity) flags.Add("Tự tăng");
        if (column.IsComputed) flags.Add("Cột tính toán");
        var description = column.Description ?? $"Cột {column.ColumnName}.";
        if (flags.Count > 0) description += $" ({string.Join(", ", flags)}).";

        builder.AppendLine();
        AppendSummary(builder, description, 4);
        builder.AppendLine($"    public {typeName} {identifier} {{ get; set; }}{GetInitializer(typeName)}");
    }

    builder.AppendLine("}");
    return builder.ToString();
}

static string RenderExtensionClass(TableDefinition table, string className)
{
    var builder = new StringBuilder();
    builder.AppendLine("namespace SimsObject;");
    builder.AppendLine();
    builder.AppendLine("/// <summary>");
    builder.AppendLine($"/// Phần mở rộng nghiệp vụ của object {SecurityElement.Escape(table.TableName)}.");
    builder.AppendLine("/// File này không bị ghi đè khi sinh lại object từ SQL Server.");
    builder.AppendLine("/// </summary>");
    builder.AppendLine($"public partial class {className}");
    builder.AppendLine("{");
    builder.AppendLine("}");
    return builder.ToString();
}

static void AppendSummary(StringBuilder builder, string text, int indent = 0)
{
    var prefix = new string(' ', indent);
    builder.AppendLine($"{prefix}/// <summary>");
    foreach (var line in NormalizeDescription(text).Split('\n'))
    {
        builder.AppendLine($"{prefix}/// {SecurityElement.Escape(line)}");
    }
    builder.AppendLine($"{prefix}/// </summary>");
}

static string NormalizeDescription(string text)
{
    return text.Replace("\r\n", "\n", StringComparison.Ordinal)
        .Replace('\r', '\n')
        .Trim();
}

static string GetCSharpType(string sqlType, bool isNullable)
{
    var baseType = sqlType.ToLowerInvariant() switch
    {
        "bigint" => "long",
        "int" => "int",
        "smallint" => "short",
        "tinyint" => "byte",
        "bit" => "bool",
        "decimal" or "numeric" or "money" or "smallmoney" => "decimal",
        "float" => "double",
        "real" => "float",
        "date" or "datetime" or "datetime2" or "smalldatetime" => "DateTime",
        "datetimeoffset" => "DateTimeOffset",
        "time" => "TimeSpan",
        "uniqueidentifier" => "Guid",
        "binary" or "varbinary" or "image" or "rowversion" or "timestamp" => "byte[]",
        "char" or "nchar" or "varchar" or "nvarchar" or "text" or "ntext" or "xml" => "string",
        "sql_variant" => "object",
        _ => "object"
    };

    if (isNullable || baseType is "string" or "byte[]" or "object")
    {
        return baseType + "?";
    }

    return baseType;
}

static string GetInitializer(string typeName)
{
    return typeName switch
    {
        "string" => " = string.Empty;",
        "byte[]" => " = [];",
        "object" => " = new();",
        _ => string.Empty
    };
}

static string EscapeString(string value) => value.Replace("\\", "\\\\", StringComparison.Ordinal).Replace("\"", "\\\"", StringComparison.Ordinal);

static string ToIdentifier(string value)
{
    var builder = new StringBuilder(value.Length + 1);
    for (var index = 0; index < value.Length; index++)
    {
        var character = value[index];
        if ((index == 0 && (char.IsLetter(character) || character == '_'))
            || (index > 0 && (char.IsLetterOrDigit(character) || character == '_')))
        {
            builder.Append(character);
        }
        else
        {
            builder.Append('_');
        }
    }

    if (builder.Length == 0 || char.IsDigit(builder[0]))
    {
        builder.Insert(0, '_');
    }

    return IsCSharpKeyword(builder.ToString()) ? "@" + builder : builder.ToString();
}

static bool IsCSharpKeyword(string value)
{
    return value is
        "abstract" or "as" or "base" or "bool" or "break" or "byte" or "case" or "catch" or "char" or
        "checked" or "class" or "const" or "continue" or "decimal" or "default" or "delegate" or "do" or
        "double" or "else" or "enum" or "event" or "explicit" or "extern" or "false" or "finally" or
        "fixed" or "float" or "for" or "foreach" or "goto" or "if" or "implicit" or "in" or "int" or
        "interface" or "internal" or "is" or "lock" or "long" or "namespace" or "new" or "null" or
        "object" or "operator" or "out" or "override" or "params" or "private" or "protected" or "public" or
        "readonly" or "ref" or "return" or "sbyte" or "sealed" or "short" or "sizeof" or "stackalloc" or
        "static" or "string" or "struct" or "switch" or "this" or "throw" or "true" or "try" or "typeof" or
        "uint" or "ulong" or "unchecked" or "unsafe" or "ushort" or "using" or "virtual" or "void" or
        "volatile" or "while";
}

internal sealed record TableDefinition(
    string SchemaName,
    string TableName,
    string? TableDescription,
    List<ColumnDefinition> Columns);

internal sealed record ColumnDefinition(
    int ColumnID,
    string ColumnName,
    string SqlType,
    short MaxLength,
    byte Precision,
    byte Scale,
    bool IsNullable,
    bool IsIdentity,
    bool IsComputed,
    bool IsPrimaryKey,
    string? Description);
