using System.Data;
using Dapper;
using SimsObject.Interfaces;
using SimsObject.Common;
using SimsData.Data;

namespace SimsService.Services;

public sealed class SearchService(ISqlConnectionFactory connections) : ISearchService
{
    public async Task<IReadOnlyCollection<object>> SearchAsync(string search, long actorId, bool isAdmin, int limit = 60, CancellationToken cancellationToken = default)
    {
        var term = InputGuard.OptionalText(search, 250, "Từ khóa tìm kiếm") ?? string.Empty;
        if (term.Length < 2) return Array.Empty<object>();
        using var connection = connections.CreateConnection();
        var rows = await connection.QueryAsync(new CommandDefinition(
            "dbo.LMS_GlobalSearch",
            new { Search = term, ActorId = actorId, IsAdmin = isAdmin, Limit = Math.Clamp(limit, 1, 100) },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
        return rows.Cast<object>().ToArray();
    }
}
