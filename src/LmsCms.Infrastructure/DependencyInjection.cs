using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;
using LmsCms.Infrastructure.Health;
using LmsCms.Infrastructure.Security;
using LmsCms.Infrastructure.Services;
using LmsCms.Infrastructure.Storage;
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
        services.AddScoped<IAcademicService, AcademicService>();
        services.AddScoped<ILearningService, LearningService>();
        services.AddScoped<ITeachingService, TeachingService>();
        services.AddScoped<IQuizService, QuizService>();
        services.AddScoped<IReportService, ReportService>();
        services.AddScoped<ISearchService, SearchService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<ISystemAdministrationService, SystemAdministrationService>();
        services.AddScoped<ILessonCommentService, LessonCommentService>();
        services.AddScoped<IContentService, ContentService>();
        services.AddScoped<IQuestionService, QuestionService>();
        services.AddScoped<IStudentService, StudentService>();
        services.AddSingleton<IVideoStorageService, LocalVideoStorageService>();
        services.AddSingleton<IAssignmentStorageService, LocalAssignmentStorageService>();
        services.AddSingleton<IProjectStorageService, ProjectStorageService>();
        services.AddHostedService<StorageCleanupHostedService>();
        services.AddHealthChecks().AddCheck<SqlServerHealthCheck>("sql-server");
        return services;
    }
}
