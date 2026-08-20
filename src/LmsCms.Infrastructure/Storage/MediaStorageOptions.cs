namespace LmsCms.Infrastructure.Storage;

public sealed class MediaStorageOptions
{
    public const string SectionName = "Media";
    public string VideoPath { get; init; } = "Media/Video";
    public string ImagePath { get; init; } = "Media/Image";
    public string FilePath { get; init; } = "Media/File";
    public string ThumbnailPath { get; init; } = "Media/Thumbnail";
    public string AudioPath { get; init; } = "Media/Audio";
    public long MaxVideoFileSizeMB { get; init; } = 500;
    public long MaxLearningFileSizeMB { get; init; } = 200;
}
