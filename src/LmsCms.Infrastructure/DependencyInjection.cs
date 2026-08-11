using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;
using LmsCms.Infrastructure.Health;
using LmsCms.Infrastructure.Security;
using LmsCms.Infrastructure.Services;
using Microsoft.Extensions.DependencyInjection;

namespace LmsCms.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services)
    {
        services.AddSingleton<ISqlConnectionFactory, SqlConnectionFactory>();
        services.AddSingleton<IDatabaseInitializer, DatabaseInitializer>();
        services.AddSingleton<ITokenService, TokenService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<ICourseService, CourseService>();
        services.AddScoped<ILearningService, LearningService>();
        services.AddScoped<IReportService, ReportService>();
        services.AddScoped<IContentService, ContentService>();
        services.AddScoped<IQuestionService, QuestionService>();
        services.AddScoped<IStudentService, StudentService>();
        services.AddHealthChecks().AddCheck<SqlServerHealthCheck>("sql-server");
        return services;
    }
}
