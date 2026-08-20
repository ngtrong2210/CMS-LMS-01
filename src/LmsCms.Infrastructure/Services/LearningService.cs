using System.Data;
using Dapper;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;

namespace LmsCms.Infrastructure.Services;

public sealed class LearningService(ISqlConnectionFactory connections) : ILearningService
{
    public async Task<object> GetDashboardAsync(long studentId, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        using var result = await connection.QueryMultipleAsync(new CommandDefinition("dbo.LMS_StudentDashboard_Get", new { StudentId = studentId }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
        var summary = await result.ReadSingleAsync();
        var courses = (await result.ReadAsync()).ToArray();
        return new { Summary = summary, Courses = courses };
    }

    public async Task<IReadOnlyCollection<object>> GetCoursesAsync(long studentId, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return (await connection.QueryAsync(new CommandDefinition("dbo.LMS_StudentCourse_GetList", new { StudentId = studentId }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken))).Cast<object>().ToArray();
    }

    public async Task<object?> GetCourseAsync(long courseId, long studentId, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        using var result = await connection.QueryMultipleAsync(new CommandDefinition("dbo.LMS_StudentCourse_GetDetail", new { CourseId = courseId, StudentId = studentId }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
        var course = await result.ReadSingleOrDefaultAsync();
        if (course is null) return null;
        var chapters = (await result.ReadAsync()).ToArray();
        var lessons = (await result.ReadAsync()).ToArray();
        return new { Course = course, Chapters = chapters, Lessons = lessons };
    }

    public async Task<object> GetResultsAsync(long studentId, long? courseId = null, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        using var result = await connection.QueryMultipleAsync(new CommandDefinition("dbo.LMS_StudentResults_Get", new { StudentId = studentId, CourseId = courseId }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
        var courses = (await result.ReadAsync()).ToArray();
        var lessons = (await result.ReadAsync()).ToArray();
        return new { Courses = courses, Lessons = lessons };
    }

    public async Task<PlayerDataDto?> GetPlayerAsync(long lessonId, long studentId, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        using var result = await connection.QueryMultipleAsync(new CommandDefinition("dbo.LMS_LessonPlayer_GetData", new { LessonId = lessonId, StudentId = studentId }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
        var lesson = await result.ReadSingleOrDefaultAsync(); if (lesson is null) return null;
        var course = await result.ReadSingleOrDefaultAsync(); var video = await result.ReadSingleOrDefaultAsync(); var progress = await result.ReadSingleOrDefaultAsync();
        var interactions = (await result.ReadAsync()).Cast<object>().ToArray(); var answered = (await result.ReadAsync()).Cast<object>().ToArray();
        return new(lesson, course, video, progress, interactions, answered);
    }

    public async Task SaveVideoProgressAsync(long studentId, VideoProgressRequest request, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        await connection.ExecuteAsync(new CommandDefinition("dbo.LMS_StudentVideoProgress_Save", new { StudentId = studentId, request.LessonId, request.VideoId, CurrentTimeSeconds = request.CurrentTime, MaxWatchedTimeSeconds = request.MaxWatchedTime, request.WatchPercent }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
    }

    public async Task<AnswerResultDto> SubmitAnswerAsync(long studentId, SubmitAnswerRequest request, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        var answerText = string.Join("|", request.Answers
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x.Trim().ToUpperInvariant())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(x => x, StringComparer.OrdinalIgnoreCase));
        return await connection.QuerySingleAsync<AnswerResultDto>(new CommandDefinition("dbo.LMS_StudentAnswer_Submit", new { StudentId = studentId, request.LessonId, request.VideoId, request.InteractionId, request.QuestionId, AnswerText = answerText, TimeInVideoSeconds = request.TimeInVideo, TimeSpentSeconds = request.TimeSpent }, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
    }

    public async Task<object> StartStudySessionAsync(long studentId, StudySessionStartRequest request, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleAsync(new CommandDefinition(
            "dbo.LMS_StudySession_Start",
            new
            {
                StudentUserID = studentId,
                request.CourseId,
                request.ChapterId,
                request.LessonId,
                request.PageUrl,
                request.ClientSessionKey
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }

    public async Task<object?> HeartbeatStudySessionAsync(Guid studySessionId, long studentId, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleOrDefaultAsync(new CommandDefinition(
            "dbo.LMS_StudySession_Heartbeat",
            new { StudySessionID = studySessionId, StudentUserID = studentId },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }

    public async Task<object?> EndStudySessionAsync(Guid studySessionId, long studentId, bool isCompleted, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleOrDefaultAsync(new CommandDefinition(
            "dbo.LMS_StudySession_End",
            new { StudySessionID = studySessionId, StudentUserID = studentId, IsCompleted = isCompleted },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<object>> GetAssignmentSubmissionsAsync(long lessonId, long studentId, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return (await connection.QueryAsync(new CommandDefinition(
            "dbo.LMS_AssignmentSubmission_GetByLesson",
            new { LessonID = lessonId, StudentUserID = studentId },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken))).Cast<object>().ToArray();
    }

    public async Task<object> SubmitAssignmentAsync(long lessonId, long studentId, string? submissionText, AssignmentSubmissionFile? file, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleAsync(new CommandDefinition(
            "dbo.LMS_AssignmentSubmission_Create",
            new
            {
                LessonID = lessonId,
                StudentUserID = studentId,
                SubmissionText = submissionText,
                FileUrl = file?.FileUrl,
                OriginalFileName = file?.OriginalFileName,
                StoredFileName = file?.StoredFileName,
                FileSize = file?.FileSize,
                MimeType = file?.MimeType
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }
}
