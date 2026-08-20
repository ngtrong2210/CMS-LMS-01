using System.Data;
using System.Text.Json;
using Dapper;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;

namespace LmsCms.Infrastructure.Services;

public sealed class AcademicService(ISqlConnectionFactory connections) : IAcademicService
{
    public async Task<object> GetCatalogAsync(long actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        using var result = await connection.QueryMultipleAsync(new CommandDefinition(
            "dbo.LMS_Academic_GetCatalog",
            new { ActorID = actorId, IsAdmin = isAdmin },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));

        var summary = await result.ReadSingleAsync();
        var years = (await result.ReadAsync()).ToArray();
        var sciences = (await result.ReadAsync()).ToArray();
        var cohorts = (await result.ReadAsync()).ToArray();
        var classes = (await result.ReadAsync()).ToArray();
        var subjects = (await result.ReadAsync()).ToArray();
        var teachers = (await result.ReadAsync()).ToArray();
        var students = (await result.ReadAsync()).ToArray();
        var classSubjects = (await result.ReadAsync()).ToArray();
        var timetables = (await result.ReadAsync()).ToArray();

        return new
        {
            Summary = summary,
            Years = years,
            Sciences = sciences,
            Cohorts = cohorts,
            Classes = classes,
            Subjects = subjects,
            Teachers = teachers,
            Students = students,
            ClassSubjects = classSubjects,
            Timetables = timetables
        };
    }

    public async Task<object> SaveAsync(AcademicCatalogSaveRequest request, long actorId, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleAsync(new CommandDefinition(
            "dbo.LMS_Academic_Save",
            new
            {
                request.EntityType,
                request.DataGroupId,
                request.Code,
                request.Name,
                request.ShortName,
                request.ParentCode,
                request.StartYear,
                request.FinishYear,
                request.StartAt,
                request.FinishAt,
                request.YearId,
                request.Semester,
                request.ClassSubjectId,
                request.ClassId,
                request.SubjectId,
                request.TeacherId,
                request.ClassSize,
                request.CreditCount,
                request.TheoryQuantity,
                request.PracticeQuantity,
                request.TimetableId,
                request.DayOfWeek,
                request.StartPeriod,
                request.EndPeriod,
                request.StartTime,
                request.EndTime,
                request.RoomName,
                request.EffectiveFrom,
                request.EffectiveTo,
                ActorID = actorId
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }

    public async Task<object> AssignStudentsToClassAsync(AssignStudentsToClassRequest request, long actorId, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleAsync(new CommandDefinition(
            "dbo.LMS_Academic_Student_AssignClass",
            new
            {
                request.DataGroupId,
                request.ClassId,
                StudentUserIDsJson = JsonSerializer.Serialize(request.StudentUserIds.Distinct()),
                ActorID = actorId
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }
}
