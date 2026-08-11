using Dapper;
using LmsCms.Infrastructure.Data;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace LmsCms.Infrastructure.Health;

public sealed class SqlServerHealthCheck(ISqlConnectionFactory connections) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            using var connection = connections.CreateConnection();
            var value = await connection.ExecuteScalarAsync<int>(new CommandDefinition("SELECT 1", cancellationToken: cancellationToken));
            return value == 1 ? HealthCheckResult.Healthy("SQL Server is reachable.") : HealthCheckResult.Unhealthy("SQL Server returned an unexpected result.");
        }
        catch (Exception exception)
        {
            return HealthCheckResult.Unhealthy("SQL Server is unavailable.", exception);
        }
    }
}
