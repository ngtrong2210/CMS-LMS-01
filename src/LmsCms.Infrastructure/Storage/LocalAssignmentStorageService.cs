using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Options;

namespace LmsCms.Infrastructure.Storage;

public sealed class LocalAssignmentStorageService : IAssignmentStorageService
{
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx", ".zip", ".txt", ".png", ".jpg", ".jpeg"
    };

    private readonly string _storageRoot;
    private readonly string _relativeRoot;
    private const long MaximumFileSize = 50L * 1024L * 1024L;

    public LocalAssignmentStorageService(IWebHostEnvironment environment, IOptions<MediaStorageOptions> options)
    {
        var webRoot = Path.GetFullPath(environment.WebRootPath ?? Path.Combine(environment.ContentRootPath, "wwwroot"));
        _relativeRoot = options.Value.FilePath.Replace('\\', '/').Trim('/');
        if (!_relativeRoot.StartsWith("Media/File", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("File học tập phải được lưu trong /Media/File/.");

        _storageRoot = Path.GetFullPath(Path.Combine(webRoot, _relativeRoot.Replace('/', Path.DirectorySeparatorChar)));
        if (!IsInside(_storageRoot, webRoot)) throw new InvalidOperationException("Thư mục file học tập phải nằm trong wwwroot.");
        Directory.CreateDirectory(_storageRoot);
    }

    public Task<AssignmentSubmissionFile> SaveTeacherResourceAsync(long lessonId, Stream content, string originalFileName, string contentType, long fileSize, CancellationToken cancellationToken = default) =>
        SaveAsync(Path.Combine("Assignments", lessonId.ToString(), "Teacher"), content, originalFileName, contentType, fileSize, cancellationToken);

    public Task<AssignmentSubmissionFile> SaveStudentSubmissionAsync(long lessonId, long studentUserId, Stream content, string originalFileName, string contentType, long fileSize, CancellationToken cancellationToken = default) =>
        SaveAsync(Path.Combine("Assignments", lessonId.ToString(), "Students", studentUserId.ToString()), content, originalFileName, contentType, fileSize, cancellationToken);

    private async Task<AssignmentSubmissionFile> SaveAsync(string subdirectory, Stream content, string originalFileName, string contentType, long fileSize, CancellationToken cancellationToken)
    {
        if (fileSize <= 0) throw new ArgumentException("File tải lên bị rỗng.");
        if (fileSize > MaximumFileSize) throw new ArgumentException("File tải lên vượt quá giới hạn 50 MB.");

        var safeOriginalName = Path.GetFileName(originalFileName);
        var extension = Path.GetExtension(safeOriginalName).ToLowerInvariant();
        if (!AllowedExtensions.Contains(extension))
            throw new ArgumentException("Định dạng file không được hỗ trợ. Hãy dùng PDF, Office, ZIP, TXT hoặc ảnh.");

        var now = DateTime.UtcNow;
        var storedFileName = $"{Guid.NewGuid():N}{extension}";
        var relativeDirectory = Path.Combine(subdirectory, now.ToString("yyyy"), now.ToString("MM"));
        var physicalDirectory = Path.GetFullPath(Path.Combine(_storageRoot, relativeDirectory));
        if (!IsInside(physicalDirectory, _storageRoot)) throw new InvalidOperationException("Đường dẫn lưu file không hợp lệ.");
        Directory.CreateDirectory(physicalDirectory);

        var physicalPath = Path.GetFullPath(Path.Combine(physicalDirectory, storedFileName));
        if (!IsInside(physicalPath, _storageRoot)) throw new InvalidOperationException("Đường dẫn file không hợp lệ.");

        try
        {
            await using var output = new FileStream(physicalPath, FileMode.CreateNew, FileAccess.Write, FileShare.None, 81920, FileOptions.Asynchronous | FileOptions.SequentialScan);
            await content.CopyToAsync(output, cancellationToken);
        }
        catch
        {
            if (File.Exists(physicalPath)) File.Delete(physicalPath);
            throw;
        }

        var relativeUrl = $"/{_relativeRoot}/{relativeDirectory.Replace('\\', '/')}/{storedFileName}";
        return new AssignmentSubmissionFile(safeOriginalName, storedFileName, relativeUrl, fileSize, string.IsNullOrWhiteSpace(contentType) ? "application/octet-stream" : contentType);
    }

    private static bool IsInside(string path, string root)
    {
        var normalizedRoot = Path.TrimEndingDirectorySeparator(Path.GetFullPath(root)) + Path.DirectorySeparatorChar;
        var normalizedPath = Path.GetFullPath(path);
        return normalizedPath.StartsWith(normalizedRoot, OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal);
    }
}
