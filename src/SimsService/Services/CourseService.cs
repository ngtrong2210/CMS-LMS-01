using System.Data;
using Dapper;
using SimsObject.Common;
using SimsObject.DTOs;
using SimsObject.Interfaces;
using SimsData.Data;

namespace SimsService.Services;

public sealed class CourseService(ISqlConnectionFactory connections) : ICourseService
{
    public async Task<PagedResult<CourseListItemDto>> GetListAsync(string? search, string? status, int page, int pageSize, long actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        search = InputGuard.OptionalText(search, 500, "Từ khóa tìm kiếm");
        status = InputGuard.OptionalChoice(status, "Trạng thái", "DRAFT", "PUBLISHED", "ARCHIVED");
        using var connection = connections.CreateConnection();
        using var results = await connection.QueryMultipleAsync(new CommandDefinition("dbo.LMS_Course_GetList", new { Search = search, Status = status, Page = page, PageSize = pageSize, ActorId=actorId, IsAdmin=isAdmin }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
        var items = (await results.ReadAsync<CourseListItemDto>()).ToArray();
        var total = await results.ReadSingleAsync<int>();
        return new(items, page, pageSize, total);
    }
    public async Task<object?> GetByIdAsync(long id, long actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleOrDefaultAsync(new CommandDefinition("dbo.LMS_Course_GetById", new { Id = id, ActorId=actorId, IsAdmin=isAdmin }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
    }
    public async Task<object?> GetContentAsync(long id, long actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        using var results = await connection.QueryMultipleAsync(new CommandDefinition("dbo.LMS_Course_GetContent", new { CourseId = id, ActorId=actorId, IsAdmin=isAdmin }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
        var chapters = (await results.ReadAsync()).ToArray(); var lessons = (await results.ReadAsync()).ToArray();
        return new { Chapters = chapters, Lessons = lessons };
    }

    public async Task<long> CreateAsync(CourseSaveRequest request, long actorId, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleAsync<long>(new CommandDefinition("dbo.LMS_Course_Create", new
        {
            request.Code, request.Title, request.Slug, request.ThumbnailUrl, request.ShortDescription, request.Description,
            request.TeacherId, request.CategoryId, request.ClassSubjectId, request.Level, request.PassingScore, request.Status, ActorId = actorId
        }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
    }

    public async Task<bool> UpdateAsync(long id, CourseSaveRequest request, long actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        var affected = await connection.ExecuteScalarAsync<int>(new CommandDefinition("dbo.LMS_Course_Update", new
        {
            Id = id, request.Code, request.Title, request.Slug, request.ThumbnailUrl, request.ShortDescription, request.Description,
            request.TeacherId, request.CategoryId, request.ClassSubjectId, request.Level, request.PassingScore, request.Status, ActorId = actorId, IsAdmin = isAdmin
        }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
        return affected > 0;
    }

    public async Task<bool> ChangeStatusAsync(long id, string status, long actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        var affected = await connection.ExecuteScalarAsync<int>(new CommandDefinition("dbo.LMS_Course_ChangeStatus", new { Id = id, Status = status, ActorId = actorId, IsAdmin = isAdmin }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
        return affected > 0;
    }

    public async Task<bool> DeleteAsync(long id, long actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        var affected = await connection.ExecuteScalarAsync<int>(new CommandDefinition("dbo.LMS_Course_Delete", new { Id = id, ActorId = actorId, IsAdmin = isAdmin }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
        return affected > 0;
    }
}
