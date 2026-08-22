using System.Data;
using Dapper;
using SimsObject.DTOs;
using SimsObject.Interfaces;
using SimsData.Data;

namespace SimsService.Services;

public sealed class NotificationService(ISqlConnectionFactory connections) : INotificationService
{
    public async Task<NotificationFeedDto> GetAsync(
        long recipientUserId,
        int limit,
        bool unreadOnly,
        CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        using var results = await connection.QueryMultipleAsync(new CommandDefinition(
            "dbo.SYS_Notification_GetList",
            new
            {
                RecipientUserID = recipientUserId,
                Limit = Math.Clamp(limit, 1, 100),
                UnreadOnly = unreadOnly
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));

        var items = (await results.ReadAsync<NotificationListItemDto>()).ToArray();
        var unreadCount = await results.ReadSingleAsync<int>();
        return new NotificationFeedDto(items, unreadCount);
    }

    public async Task<bool> MarkReadAsync(
        long notificationId,
        long recipientUserId,
        CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        var affectedRows = await connection.ExecuteScalarAsync<int>(new CommandDefinition(
            "dbo.SYS_Notification_MarkRead",
            new
            {
                NotificationID = notificationId,
                RecipientUserID = recipientUserId
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
        return affectedRows > 0;
    }

    public async Task<int> MarkAllReadAsync(long recipientUserId, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(new CommandDefinition(
            "dbo.SYS_Notification_MarkAllRead",
            new { RecipientUserID = recipientUserId },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }
}
