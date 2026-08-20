using System.Data;
using Dapper;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;

namespace LmsCms.Infrastructure.Services;

public sealed class TeachingService(ISqlConnectionFactory connections) : ITeachingService
{
    public async Task<IReadOnlyCollection<object>> GetAssignmentSubmissionsAsync(long? classSubjectId, string? status, string? search, long actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return (await connection.QueryAsync(new CommandDefinition(
            "dbo.LMS_AssignmentSubmission_GetForTeacher",
            new
            {
                ClassSubjectID = classSubjectId,
                Status = status,
                Search = search,
                ActorID = actorId,
                IsAdmin = isAdmin
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken))).Cast<object>().ToArray();
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
