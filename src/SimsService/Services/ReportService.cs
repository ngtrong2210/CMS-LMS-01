using System.Data;
using Dapper;
using SimsObject.DTOs;
using SimsObject.Interfaces;
using SimsData.Data;

namespace SimsService.Services;

public sealed class ReportService(ISqlConnectionFactory connections) : IReportService
{
    public async Task<DashboardDto> GetDashboardAsync(CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleAsync<DashboardDto>(new CommandDefinition("dbo.LMS_Report_Dashboard", commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
    }
    public async Task<IReadOnlyCollection<object>> GetReportAsync(string report, CancellationToken cancellationToken = default)
    {
        var procedure = report switch
        {
            "course-overview" => "dbo.LMS_Report_CourseOverview",
            "student-progress" => "dbo.LMS_Report_StudentProgress",
            "lesson-completion" => "dbo.LMS_Report_LessonCompletion",
            "question-performance" => "dbo.LMS_Report_QuestionPerformance",
            "video-engagement" => "dbo.LMS_Report_VideoEngagement",
            _ => throw new ArgumentException("Loại báo cáo không hợp lệ.")
        };
        using var connection = connections.CreateConnection();
        return (await connection.QueryAsync(new CommandDefinition(procedure, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken))).Cast<object>().ToArray();
    }
}
