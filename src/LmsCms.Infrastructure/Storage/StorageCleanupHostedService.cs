using LmsCms.Application.Interfaces;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace LmsCms.Infrastructure.Storage;

public sealed class StorageCleanupHostedService(IProjectStorageService storage, IOptions<ProjectStorageOptions> options, ILogger<StorageCleanupHostedService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var settings = options.Value;
        var interval = TimeSpan.FromHours(Math.Max(1, settings.CleanupIntervalHours));
        while (!stoppingToken.IsCancellationRequested)
        {
            await CleanupAsync(settings, stoppingToken);
            try { await Task.Delay(interval, stoppingToken); }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
        }
    }

    private async Task CleanupAsync(ProjectStorageOptions settings, CancellationToken ct)
    {
        try
        {
            var deleted = 0;
            deleted += await storage.CleanupExpiredAsync(ProjectStorageArea.Cache, TimeSpan.FromHours(Math.Max(1, settings.CacheRetentionHours)), ct);
            deleted += await storage.CleanupExpiredAsync(ProjectStorageArea.Temp, TimeSpan.FromHours(Math.Max(1, settings.TempRetentionHours)), ct);
            deleted += await storage.CleanupExpiredAsync(ProjectStorageArea.Exports, TimeSpan.FromHours(Math.Max(1, settings.ExportRetentionHours)), ct);
            deleted += await storage.CleanupExpiredAsync(ProjectStorageArea.Processing, TimeSpan.FromHours(Math.Max(1, settings.ProcessingRetentionHours)), ct);
            if (deleted > 0) logger.LogInformation("Cleaned {Count} expired project runtime files.", deleted);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            logger.LogError(exception, "Project runtime storage cleanup failed.");
        }
    }
}
