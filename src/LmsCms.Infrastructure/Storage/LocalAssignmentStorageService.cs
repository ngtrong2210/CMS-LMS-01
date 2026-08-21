using System.IO.Compression;
using System.Net;
using System.Text;
using System.Xml.Linq;
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
    private readonly long _maximumFileSize;

    public LocalAssignmentStorageService(IWebHostEnvironment environment, IOptions<MediaStorageOptions> options)
    {
        var webRoot = Path.GetFullPath(environment.WebRootPath ?? Path.Combine(environment.ContentRootPath, "wwwroot"));
        _relativeRoot = options.Value.FilePath.Replace('\\', '/').Trim('/');
        _maximumFileSize = Math.Clamp(options.Value.MaxLearningFileSizeMB, 1, 200) * 1024L * 1024L;
        if (!_relativeRoot.StartsWith("Media/File", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("File học tập phải được lưu trong /Media/File/.");

        _storageRoot = Path.GetFullPath(Path.Combine(webRoot, _relativeRoot.Replace('/', Path.DirectorySeparatorChar)));
        if (!IsInside(_storageRoot, webRoot)) throw new InvalidOperationException("Thư mục file học tập phải nằm trong wwwroot.");
        Directory.CreateDirectory(_storageRoot);
    }

    public Task<AssignmentSubmissionFile> SaveTeacherResourceAsync(long lessonId, Stream content, string originalFileName, string contentType, long fileSize, CancellationToken cancellationToken = default) =>
        SaveAsync(Path.Combine("Lessons", lessonId.ToString(), "Teacher"), content, originalFileName, contentType, fileSize, cancellationToken);

    public Task<AssignmentSubmissionFile> SaveStudentSubmissionAsync(long lessonId, long studentUserId, Stream content, string originalFileName, string contentType, long fileSize, CancellationToken cancellationToken = default) =>
        SaveAsync(Path.Combine("Assignments", lessonId.ToString(), "Students", studentUserId.ToString()), content, originalFileName, contentType, fileSize, cancellationToken);

    public async Task<LearningDocumentPreview?> CreateDocumentPreviewAsync(string fileUrl, CancellationToken cancellationToken = default)
    {
        var physicalPath = ResolvePhysicalPath(fileUrl);
        if (physicalPath is null || !File.Exists(physicalPath)) return null;

        var extension = Path.GetExtension(physicalPath);
        if (!extension.Equals(".docx", StringComparison.OrdinalIgnoreCase)) return null;

        await using var input = new FileStream(
            physicalPath,
            FileMode.Open,
            FileAccess.Read,
            FileShare.Read,
            81920,
            FileOptions.Asynchronous | FileOptions.SequentialScan);
        using var archive = new ZipArchive(input, ZipArchiveMode.Read, leaveOpen: false);
        var documentEntry = archive.GetEntry("word/document.xml");
        if (documentEntry is null) return null;

        await using var documentStream = documentEntry.Open();
        var document = await XDocument.LoadAsync(documentStream, LoadOptions.None, cancellationToken);
        return new LearningDocumentPreview("DOCX", ConvertWordDocumentToHtml(document), Path.GetFileName(physicalPath));
    }

    private async Task<AssignmentSubmissionFile> SaveAsync(string subdirectory, Stream content, string originalFileName, string contentType, long fileSize, CancellationToken cancellationToken)
    {
        if (fileSize <= 0) throw new ArgumentException("File tải lên bị rỗng.");
        if (fileSize > _maximumFileSize) throw new ArgumentException($"File tải lên vượt quá giới hạn {_maximumFileSize / 1024L / 1024L} MB.");

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

    private string? ResolvePhysicalPath(string fileUrl)
    {
        if (string.IsNullOrWhiteSpace(fileUrl)) return null;

        var cleanUrl = Uri.UnescapeDataString(fileUrl.Split('?', '#')[0]).Replace('\\', '/');
        var expectedPrefix = $"/{_relativeRoot}/";
        if (!cleanUrl.StartsWith(expectedPrefix, StringComparison.OrdinalIgnoreCase)) return null;

        var relativePath = cleanUrl[expectedPrefix.Length..].Replace('/', Path.DirectorySeparatorChar);
        var physicalPath = Path.GetFullPath(Path.Combine(_storageRoot, relativePath));
        return IsInside(physicalPath, _storageRoot) ? physicalPath : null;
    }

    private static string ConvertWordDocumentToHtml(XDocument document)
    {
        XNamespace word = "http://schemas.openxmlformats.org/wordprocessingml/2006/main";
        var body = document.Root?.Element(word + "body");
        if (body is null) return "<p>Tài liệu chưa có nội dung có thể hiển thị.</p>";

        var html = new StringBuilder();
        foreach (var element in body.Elements())
        {
            if (element.Name == word + "p") AppendParagraph(html, element, word);
            else if (element.Name == word + "tbl") AppendTable(html, element, word);
        }

        return html.Length > 0 ? html.ToString() : "<p>Tài liệu chưa có nội dung có thể hiển thị.</p>";
    }

    private static void AppendParagraph(StringBuilder html, XElement paragraph, XNamespace word)
    {
        var text = ReadText(paragraph, word);
        if (string.IsNullOrWhiteSpace(text)) return;

        var style = paragraph.Element(word + "pPr")?.Element(word + "pStyle")?.Attribute(word + "val")?.Value ?? string.Empty;
        var hasNumbering = paragraph.Element(word + "pPr")?.Element(word + "numPr") is not null;
        var tag = style.StartsWith("Heading1", StringComparison.OrdinalIgnoreCase) ? "h2"
            : style.StartsWith("Heading", StringComparison.OrdinalIgnoreCase) ? "h3"
            : hasNumbering ? "li"
            : "p";
        html.Append('<').Append(tag).Append('>')
            .Append(WebUtility.HtmlEncode(text))
            .Append("</").Append(tag).Append('>');
    }

    private static void AppendTable(StringBuilder html, XElement table, XNamespace word)
    {
        html.Append("<table><tbody>");
        foreach (var row in table.Elements(word + "tr"))
        {
            html.Append("<tr>");
            foreach (var cell in row.Elements(word + "tc"))
                html.Append("<td>").Append(WebUtility.HtmlEncode(ReadText(cell, word))).Append("</td>");
            html.Append("</tr>");
        }
        html.Append("</tbody></table>");
    }

    private static string ReadText(XElement element, XNamespace word)
    {
        var text = new StringBuilder();
        foreach (var node in element.Descendants())
        {
            if (node.Name == word + "t") text.Append(node.Value);
            else if (node.Name == word + "tab") text.Append('\t');
            else if (node.Name == word + "br") text.AppendLine();
        }
        return text.ToString().Trim();
    }
}
