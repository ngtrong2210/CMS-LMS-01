using System.Data;
using Dapper;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;

namespace LmsCms.Infrastructure.Services;

public sealed class LessonCommentService(ISqlConnectionFactory connections) : ILessonCommentService
{
    public async Task<LessonCommentFeedDto> GetByLessonAsync(
        long lessonId,
        long actorUserId,
        bool isAdmin,
        bool isTeacher,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        using var connection = connections.CreateConnection();
        using var results = await connection.QueryMultipleAsync(new CommandDefinition(
            "dbo.LMS_LessonComment_GetByLesson",
            new
            {
                LessonID = lessonId,
                ActorUserID = actorUserId,
                IsAdmin = isAdmin,
                IsTeacher = isTeacher,
                Page = page,
                PageSize = pageSize
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));

        var count = await results.ReadSingleAsync<LessonCommentCount>();
        var comments = (await results.ReadAsync<LessonCommentDto>()).ToArray();
        var commentById = comments.ToDictionary(comment => comment.Id);

        foreach (var comment in comments)
        {
            if (comment.ParentCommentID is long parentCommentId && commentById.TryGetValue(parentCommentId, out var parent))
            {
                parent.Replies.Add(comment);
            }
        }

        foreach (var comment in comments)
        {
            comment.Replies = comment.Replies
                .OrderBy(reply => reply.CreatedDate)
                .ThenBy(reply => reply.Id)
                .ToList();
        }

        var roots = comments
            .Where(comment => comment.ParentCommentID is null)
            .OrderByDescending(comment => comment.CreatedDate)
            .ThenByDescending(comment => comment.Id)
            .ToArray();

        return new LessonCommentFeedDto(roots, page, pageSize, count.RootCommentCount, count.TotalCommentCount);
    }

    public async Task<long> CreateAsync(
        long lessonId,
        LessonCommentCreateRequest request,
        long actorUserId,
        bool isAdmin,
        bool isTeacher,
        CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.ExecuteScalarAsync<long>(new CommandDefinition(
            "dbo.LMS_LessonComment_Insert",
            new
            {
                LessonID = lessonId,
                ActorUserID = actorUserId,
                IsAdmin = isAdmin,
                IsTeacher = isTeacher,
                Content = request.Content,
                ParentCommentID = request.ParentCommentId
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }

    public async Task<long> UpdateAsync(
        long lessonCommentId,
        LessonCommentUpdateRequest request,
        long actorUserId,
        CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.ExecuteScalarAsync<long>(new CommandDefinition(
            "dbo.LMS_LessonComment_Update",
            new
            {
                LessonCommentID = lessonCommentId,
                ActorUserID = actorUserId,
                Content = request.Content
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }

    public async Task<long> DeleteAsync(
        long lessonCommentId,
        long actorUserId,
        bool isAdmin,
        bool isTeacher,
        CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.ExecuteScalarAsync<long>(new CommandDefinition(
            "dbo.LMS_LessonComment_Delete",
            new
            {
                LessonCommentID = lessonCommentId,
                ActorUserID = actorUserId,
                IsAdmin = isAdmin,
                IsTeacher = isTeacher
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }

    private sealed class LessonCommentCount
    {
        public int RootCommentCount { get; init; }
        public int TotalCommentCount { get; init; }
    }
}
