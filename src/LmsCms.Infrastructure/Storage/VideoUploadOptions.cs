namespace LmsCms.Infrastructure.Storage;

public sealed class VideoUploadOptions
{
    public const string SectionName = "VideoUpload";
    public string RootFolder { get; init; } = "uploads/videos";
    public long MaxFileSizeMB { get; init; } = 500;
}
