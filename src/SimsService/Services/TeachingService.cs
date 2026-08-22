using System.Data;
using Dapper;
using SimsObject.DTOs;
using SimsObject.Interfaces;
using SimsObject.Common;
using SimsData.Data;

namespace SimsService.Services;

public sealed class TeachingService(ISqlConnectionFactory connections) : ITeachingService
{
    public async Task<PagedResult<object>> GetAssignmentSubmissionsAsync(long? classSubjectId, string? status, string? search, int page, int pageSize, long actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        if (classSubjectId <= 0) throw new ArgumentException("Mã môn học lớp phải lớn hơn 0.");
        status = InputGuard.OptionalChoice(status, "Trạng thái", "DRAFT", "SUBMITTED", "GRADED", "RETURNED");
        search = InputGuard.OptionalText(search, 250, "Từ khóa tìm kiếm");
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 100);
        using var connection = connections.CreateConnection();
        using var grid = await connection.QueryMultipleAsync(new CommandDefinition(
            "dbo.LMS_AssignmentSubmission_GetForTeacher",
            new
            {
                ClassSubjectID = classSubjectId,
                Status = status,
                Search = search,
                Page = page,
                PageSize = pageSize,
                ActorID = actorId,
                IsAdmin = isAdmin
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
        var items = (await grid.ReadAsync()).Cast<object>().ToArray();
        var totalItems = await grid.ReadSingleAsync<int>();
        return new PagedResult<object>(items, page, pageSize, totalItems);
    }

    public async Task<object> GradeAssignmentSubmissionAsync(long assignmentSubmissionId, AssignmentGradeRequest request, long actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleAsync(new CommandDefinition(
            "dbo.LMS_AssignmentSubmission_Grade",
            new
            {
                AssignmentSubmissionID = assignmentSubmissionId,
                request.Score,
                request.Feedback,
                request.Action,
                ActorID = actorId,
                IsAdmin = isAdmin
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }
}
