using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Options;

namespace LmsCms.Infrastructure.Storage;

public sealed class LocalVideoStorageService : IVideoStorageService
{
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase) { ".mp4", ".webm", ".ogv", ".mov" };
    private static readonly HashSet<string> AllowedMimeTypes = new(StringComparer.OrdinalIgnoreCase) { "video/mp4", "video/webm", "video/ogg", "video/quicktime", "application/octet-stream" };
    private readonly string _webRoot;
    private readonly string _storageRoot;
    private readonly string _relativeRoot;
    private readonly long _maxFileSize;

    public LocalVideoStorageService(IWebHostEnvironment environment, IOptions<VideoUploadOptions> options)
    {
        var settings = options.Value;
        if (string.IsNullOrWhiteSpace(settings.RootFolder) || Path.IsPathRooted(settings.RootFolder) || settings.RootFolder.Split('/', '\\').Any(x => x == ".."))
            throw new InvalidOperationException("VideoUpload:RootFolder phải là đường dẫn tương đối an toàn.");
        if (settings.MaxFileSizeMB <= 0) throw new InvalidOperationException("VideoUpload:MaxFileSizeMB phải lớn hơn 0.");

        _webRoot = Path.GetFullPath(environment.WebRootPath ?? Path.Combine(environment.ContentRootPath, "wwwroot"));
        _relativeRoot = settings.RootFolder.Replace('\\', '/').Trim('/');
        _storageRoot = Path.GetFullPath(Path.Combine(_webRoot, _relativeRoot.Replace('/', Path.DirectorySeparatorChar)));
        if (!IsInside(_storageRoot, _webRoot)) throw new InvalidOperationException("Thư mục video phải nằm trong wwwroot.");
        _maxFileSize = checked(settings.MaxFileSizeMB * 1024L * 1024L);
        Directory.CreateDirectory(_storageRoot);
    }

    public async Task<StoredVideoFile> SaveAsync(Stream content, string originalFileName, string contentType, long fileSize, CancellationToken ct = default)
    {
        if (fileSize <= 0) throw new ArgumentException("File video rỗng.");
        if (fileSize > _maxFileSize) throw new ArgumentException($"File video vượt quá giới hạn {_maxFileSize / 1024 / 1024} MB.");
        var safeOriginalName = Path.GetFileName(originalFileName);
        var extension = Path.GetExtension(safeOriginalName).ToLowerInvariant();
        if (!AllowedExtensions.Contains(extension)) throw new ArgumentException("Định dạng video không được hỗ trợ.");
        if (!AllowedMimeTypes.Contains(contentType)) throw new ArgumentException("MIME type video không hợp lệ.");

        var now = DateTime.UtcNow;
        var storedFileName = $"{Guid.NewGuid():N}{extension}";
        var year = now.ToString("yyyy");
        var month = now.ToString("MM");
        var directory = Path.Combine(_storageRoot, year, month);
        Directory.CreateDirectory(directory);
        var physicalPath = Path.GetFullPath(Path.Combine(directory, storedFileName));
        if (!IsInside(physicalPath, _storageRoot)) throw new InvalidOperationException("Đường dẫn lưu video không hợp lệ.");

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

        var videoUrl = $"/{_relativeRoot}/{year}/{month}/{storedFileName}";
        return new StoredVideoFile(safeOriginalName, storedFileName, videoUrl, fileSize, contentType);
    }

    public Task<bool> DeleteAsync(string videoUrl, CancellationToken ct = default)
    {
        ct.ThrowIfCancellationRequested();
        var path = ResolvePhysicalPath(videoUrl);
        if (!File.Exists(path)) return Task.FromResult(false);
        File.Delete(path);
        return Task.FromResult(true);
    }

    public bool Exists(string videoUrl) => File.Exists(ResolvePhysicalPath(videoUrl));
    public string GetUrl(string videoUrl) { _ = ResolvePhysicalPath(videoUrl); return videoUrl; }

    private string ResolvePhysicalPath(string videoUrl)
    {
        if (string.IsNullOrWhiteSpace(videoUrl) || !videoUrl.StartsWith($"/{_relativeRoot}/", StringComparison.OrdinalIgnoreCase) || Uri.TryCreate(videoUrl, UriKind.Absolute, out _))
            throw new ArgumentException("URL video phải là đường dẫn tương đối trong thư mục upload.");
        var relative = videoUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
        var path = Path.GetFullPath(Path.Combine(_webRoot, relative));
        if (!IsInside(path, _storageRoot)) throw new ArgumentException("URL video không hợp lệ.");
        return path;
    }

    private static bool IsInside(string path, string root)
    {
        var normalizedRoot = Path.TrimEndingDirectorySeparator(Path.GetFullPath(root)) + Path.DirectorySeparatorChar;
        var normalizedPath = Path.GetFullPath(path);
        return normalizedPath.StartsWith(normalizedRoot, OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal);
    }
}
