using System.Data;
using Dapper;
using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;

namespace LmsCms.Infrastructure.Services;

public sealed class CourseService(ISqlConnectionFactory connections) : ICourseService
{
    public async Task<PagedResult<CourseListItemDto>> GetListAsync(string? search, string? status, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        using var results = await connection.QueryMultipleAsync(new CommandDefinition("dbo.LMS_Course_GetList", new { Search = search, Status = status, Page = page, PageSize = pageSize }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
        var items = (await results.ReadAsync<CourseListItemDto>()).ToArray();
        var total = await results.ReadSingleAsync<int>();
        return new(items, page, pageSize, total);
    }
    public async Task<object?> GetByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleOrDefaultAsync(new CommandDefinition("dbo.LMS_Course_GetById", new { Id = id }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
    }
    public async Task<object?> GetContentAsync(long id, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        using var results = await connection.QueryMultipleAsync(new CommandDefinition("dbo.LMS_Course_GetContent", new { CourseId = id }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
        var chapters = (await results.ReadAsync()).ToArray(); var lessons = (await results.ReadAsync()).ToArray();
        return new { Chapters = chapters, Lessons = lessons };
    }
}
