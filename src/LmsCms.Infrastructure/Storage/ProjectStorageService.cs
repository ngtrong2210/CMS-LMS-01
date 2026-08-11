using System.Text;
using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Options;

namespace LmsCms.Infrastructure.Storage;

public sealed class ProjectStorageService : IProjectStorageService
{
    private readonly string _contentRoot;
    private readonly IReadOnlyDictionary<ProjectStorageArea, StorageLocation> _locations;

    public ProjectStorageService(IWebHostEnvironment environment, IOptions<ProjectStorageOptions> options)
    {
        _contentRoot = Path.GetFullPath(environment.ContentRootPath);
        var settings = options.Value;
        _locations = new Dictionary<ProjectStorageArea, StorageLocation>
        {
            [ProjectStorageArea.Cache] = CreateLocation(settings.CachePath),
            [ProjectStorageArea.Temp] = CreateLocation(settings.TempPath),
            [ProjectStorageArea.Exports] = CreateLocation(settings.ExportPath),
            [ProjectStorageArea.Processing] = CreateLocation(settings.ProcessingPath)
        };
        foreach (var location in _locations.Values) Directory.CreateDirectory(location.PhysicalPath);
        _ = ResolveProjectPath(settings.LogPath);
        Directory.CreateDirectory(ResolveProjectPath(settings.LogPath));
    }

    public string GetDirectory(ProjectStorageArea area) => _locations[area].PhysicalPath;

    public async Task<ProjectStoredFile> SaveAsync(ProjectStorageArea area, Stream content, string extension = ".tmp", CancellationToken ct = default)
    {
        var safeExtension = NormalizeExtension(extension);
        var location = _locations[area];
        var now = DateTime.UtcNow;
        var directory = Path.Combine(location.PhysicalPath, now.ToString("yyyy"), now.ToString("MM"), now.ToString("dd"));
        Directory.CreateDirectory(directory);
        var physicalPath = Path.GetFullPath(Path.Combine(directory, $"{Guid.NewGuid():N}{safeExtension}"));
        EnsureInside(physicalPath, location.PhysicalPath);
        try
        {
            await using var output = new FileStream(physicalPath, FileMode.CreateNew, FileAccess.Write, FileShare.None, 81920, FileOptions.Asynchronous | FileOptions.SequentialScan);
            await content.CopyToAsync(output, ct);
        }
        catch
        {
            if (File.Exists(physicalPath)) File.Delete(physicalPath);
            throw;
        }
        var info = new FileInfo(physicalPath);
        return new ProjectStoredFile(Path.GetRelativePath(_contentRoot, physicalPath).Replace('\\', '/'), info.Length, now);
    }

    public async Task<ProjectStoredFile> WriteTextAsync(ProjectStorageArea area, string content, string extension = ".txt", CancellationToken ct = default)
    {
        var bytes = Encoding.UTF8.GetBytes(content);
        using var stream = new MemoryStream(bytes, writable: false);
        return await SaveAsync(area, stream, extension, ct);
    }

    public bool Exists(string relativePath) => File.Exists(ResolveRuntimeFile(relativePath));

    public Task<bool> DeleteAsync(string relativePath, CancellationToken ct = default)
    {
        ct.ThrowIfCancellationRequested();
        var path = ResolveRuntimeFile(relativePath);
        if (!File.Exists(path)) return Task.FromResult(false);
        File.Delete(path);
        return Task.FromResult(true);
    }

    public Task<int> CleanupExpiredAsync(ProjectStorageArea area, TimeSpan maxAge, CancellationToken ct = default)
    {
        if (maxAge <= TimeSpan.Zero) throw new ArgumentOutOfRangeException(nameof(maxAge));
        var root = _locations[area].PhysicalPath;
        var cutoff = DateTime.UtcNow.Subtract(maxAge);
        var deleted = 0;
        foreach (var file in Directory.EnumerateFiles(root, "*", SearchOption.AllDirectories))
        {
            ct.ThrowIfCancellationRequested();
            if (Path.GetFileName(file).Equals(".gitkeep", StringComparison.OrdinalIgnoreCase)) continue;
            if (File.GetLastWriteTimeUtc(file) >= cutoff) continue;
            File.Delete(file);
            deleted++;
        }
        return Task.FromResult(deleted);
    }

    private StorageLocation CreateLocation(string configuredPath)
    {
        var physical = ResolveProjectPath(configuredPath);
        return new(configuredPath.Replace('\\', '/').Trim('/'), physical);
    }

    private string ResolveProjectPath(string configuredPath)
    {
        if (string.IsNullOrWhiteSpace(configuredPath) || Path.IsPathRooted(configuredPath) || configuredPath.Split('/', '\\').Any(x => x == ".."))
            throw new InvalidOperationException("Storage paths phải là đường dẫn tương đối an toàn.");
        var physical = Path.GetFullPath(Path.Combine(_contentRoot, configuredPath.Replace('/', Path.DirectorySeparatorChar)));
        EnsureInside(physical, _contentRoot);
        if (physical.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}", StringComparison.OrdinalIgnoreCase)
            || physical.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Runtime storage không được nằm trong bin hoặc obj.");
        return physical;
    }

    private string ResolveRuntimeFile(string relativePath)
    {
        if (string.IsNullOrWhiteSpace(relativePath) || Path.IsPathRooted(relativePath) || relativePath.Split('/', '\\').Any(x => x == ".."))
            throw new ArgumentException("Runtime file path không hợp lệ.");
        var physical = Path.GetFullPath(Path.Combine(_contentRoot, relativePath.Replace('/', Path.DirectorySeparatorChar)));
        if (!_locations.Values.Any(x => IsInside(physical, x.PhysicalPath))) throw new ArgumentException("File không thuộc project runtime storage.");
        return physical;
    }

    private static string NormalizeExtension(string extension)
    {
        var value = extension.StartsWith('.') ? extension : $".{extension}";
        if (value.Length is < 2 or > 12 || value.Skip(1).Any(x => !char.IsLetterOrDigit(x))) throw new ArgumentException("Phần mở rộng file không hợp lệ.");
        return value.ToLowerInvariant();
    }

    private static void EnsureInside(string path, string root)
    {
        if (!IsInside(path, root)) throw new InvalidOperationException("Storage path phải nằm trong project.");
    }

    private static bool IsInside(string path, string root)
    {
        var normalizedRoot = Path.TrimEndingDirectorySeparator(Path.GetFullPath(root)) + Path.DirectorySeparatorChar;
        return Path.GetFullPath(path).StartsWith(normalizedRoot, OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal);
    }

    private sealed record StorageLocation(string RelativePath, string PhysicalPath);
}
