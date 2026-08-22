namespace SimsData.Storage;

public sealed class ProjectStorageOptions
{
    public const string SectionName = "Storage";
    public string CachePath { get; init; } = "storage/cache";
    public string TempPath { get; init; } = "storage/temp";
    public string ExportPath { get; init; } = "storage/exports";
    public string ProcessingPath { get; init; } = "storage/processing";
    public string LogPath { get; init; } = "logs";
    public int CacheRetentionHours { get; init; } = 24;
    public int TempRetentionHours { get; init; } = 24;
    public int ExportRetentionHours { get; init; } = 24;
    public int ProcessingRetentionHours { get; init; } = 24;
    public int CleanupIntervalHours { get; init; } = 6;
}
