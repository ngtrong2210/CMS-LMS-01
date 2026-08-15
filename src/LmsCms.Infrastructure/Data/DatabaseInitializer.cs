using System.Text.RegularExpressions;
using BCrypt.Net;
using Dapper;
using LmsCms.Application.Interfaces;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Hosting;

namespace LmsCms.Infrastructure.Data;

public sealed class DatabaseInitializer(IConfiguration configuration, IWebHostEnvironment environment) : IDatabaseInitializer
{
    private static readonly SemaphoreSlim InitializationLock = new(1, 1);

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        await InitializationLock.WaitAsync(cancellationToken);
        try
        {
        var bootstrap = configuration.GetConnectionString("BootstrapConnection")
            ?? throw new InvalidOperationException("ConnectionStrings:BootstrapConnection is not configured.");
        var application = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("ConnectionStrings:DefaultConnection is not configured.");
        var databaseRoot = ResolveDatabaseRoot();
        await ExecuteFolderAsync(bootstrap, Path.Combine(databaseRoot, "bootstrap"), cancellationToken);

        var normalizedSchemaExists = await TableExistsAsync(application, "dbo.SYS_Users", cancellationToken);
        if (!normalizedSchemaExists)
        {
            // Dựng dữ liệu theo schema cũ trước để các migration có thể chuyển đổi an toàn.
            foreach (var folder in new[] { "tables", "indexes", "seed" })
                await ExecuteFolderAsync(application, Path.Combine(databaseRoot, folder), cancellationToken);
        }

        // Migration phải chạy trước stored procedure vì procedure mới phụ thuộc schema mới nhất.
        await ExecuteFolderAsync(application, Path.Combine(databaseRoot, "migrations"), cancellationToken);
        await ExecuteFolderAsync(application, Path.Combine(databaseRoot, "stored-procedures"), cancellationToken);

        await using var connection = new SqlConnection(application);
        await connection.OpenAsync(cancellationToken);
        foreach (var username in new[]
        {
            "admin", "teacher", "student", "teacher02", "teacher03",
            "student02", "student03", "student04", "student05", "student06"
        })
        {
            var hash = BCrypt.Net.BCrypt.HashPassword("123456", workFactor: 11);
            await connection.ExecuteAsync(new CommandDefinition(
                "UPDATE dbo.Users SET PasswordHash=@hash WHERE Username=@username",
                new { hash, username }, cancellationToken: cancellationToken));
        }
        }
        finally
        {
            InitializationLock.Release();
        }
    }

    private static async Task<bool> TableExistsAsync(string connectionString, string qualifiedTableName, CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<int>(new CommandDefinition(
            "SELECT CASE WHEN OBJECT_ID(@tableName, 'U') IS NULL THEN 0 ELSE 1 END",
            new { tableName = qualifiedTableName }, cancellationToken: cancellationToken)) == 1;
    }

    private static async Task ExecuteFolderAsync(string connectionString, string folder, CancellationToken cancellationToken)
    {
        if (!Directory.Exists(folder)) return;
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);
        foreach (var file in Directory.GetFiles(folder, "*.sql").OrderBy(x => x))
        {
            var script = await File.ReadAllTextAsync(file, cancellationToken);
            foreach (var batch in Regex.Split(script, @"^\s*GO\s*($|--.*$)", RegexOptions.Multiline | RegexOptions.IgnoreCase).Where(x => !string.IsNullOrWhiteSpace(x)))
                await connection.ExecuteAsync(new CommandDefinition(batch, commandTimeout: 120, cancellationToken: cancellationToken));
        }
    }

    private string ResolveDatabaseRoot()
    {
        var configured = configuration.GetValue<string>("Database:ScriptsPath") ?? "../../database";
        if (Path.IsPathRooted(configured)) throw new InvalidOperationException("Database:ScriptsPath phải là đường dẫn tương đối.");
        var path = Path.GetFullPath(Path.Combine(environment.ContentRootPath, configured.Replace('/', Path.DirectorySeparatorChar)));
        return Directory.Exists(path) ? path : throw new DirectoryNotFoundException($"Không tìm thấy thư mục SQL scripts: {path}");
    }
}
