using System.Data;
using System.Text.Json;
using Dapper;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;

namespace LmsCms.Infrastructure.Services;

public sealed class QuizService(ISqlConnectionFactory connections) : IQuizService
{
    public async Task<object> GetForTeacherAsync(long lessonId, long actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        using var result = await connection.QueryMultipleAsync(new CommandDefinition(
            "dbo.LMS_Quiz_GetForTeacher",
            new { LessonID = lessonId, ActorID = actorId, IsAdmin = isAdmin },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
        return new { Quiz = await result.ReadSingleOrDefaultAsync(), Questions = (await result.ReadAsync()).ToArray() };
    }

    public async Task<object> SaveAsync(long lessonId, QuizSaveRequest request, long actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleAsync(new CommandDefinition(
            "dbo.LMS_Quiz_Save",
            new
            {
                LessonID = lessonId,
                request.Title,
                request.Description,
                request.PassingScore,
                request.TimeLimitMinutes,
                request.MaxAttempts,
                request.ShuffleQuestions,
                QuestionIDsJson = JsonSerializer.Serialize(request.QuestionIds.Where(id => id > 0).Distinct()),
                ActorID = actorId,
                IsAdmin = isAdmin
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }

    public async Task<object> GetForStudentAsync(long lessonId, long studentId, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        using var result = await connection.QueryMultipleAsync(new CommandDefinition(
            "dbo.LMS_Quiz_GetForStudent",
            new { LessonID = lessonId, StudentUserID = studentId },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
        return new
        {
            Quiz = await result.ReadSingleAsync(),
            Questions = (await result.ReadAsync()).ToArray(),
            Attempts = (await result.ReadAsync()).ToArray()
        };
    }

    public async Task<object> StartAttemptAsync(long lessonId, long studentId, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleAsync(new CommandDefinition(
            "dbo.LMS_QuizAttempt_Start",
            new { LessonID = lessonId, StudentUserID = studentId },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }

    public async Task<object> SubmitAttemptAsync(long quizAttemptId, long studentId, QuizSubmitRequest request, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        var answers = request.Answers
            .Where(answer => answer.QuestionId > 0)
            .GroupBy(answer => answer.QuestionId)
            .Select(group => new
            {
                questionId = group.Key,
                answerText = group.Last().AnswerText
            });
        return await connection.QuerySingleAsync(new CommandDefinition(
            "dbo.LMS_QuizAttempt_Submit",
            new
            {
                QuizAttemptID = quizAttemptId,
                StudentUserID = studentId,
                AnswersJson = JsonSerializer.Serialize(answers)
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }
}
