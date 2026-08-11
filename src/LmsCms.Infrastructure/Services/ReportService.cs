using System.Data;
using Dapper;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;

namespace LmsCms.Infrastructure.Services;

public sealed class ReportService(ISqlConnectionFactory connections) : IReportService
{
    public async Task<DashboardDto> GetDashboardAsync(CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        return await connection.QuerySingleAsync<DashboardDto>(new CommandDefinition("dbo.LMS_Report_Dashboard", commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken));
    }
}
