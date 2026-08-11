using LmsCms.Application.Common;
using LmsCms.Application.DTOs;

namespace LmsCms.Application.Interfaces;

public interface IDatabaseInitializer { Task InitializeAsync(CancellationToken cancellationToken = default); }
public interface IAuthService
{
    Task<AuthResponse?> LoginAsync(LoginRequest request, string? ipAddress, CancellationToken cancellationToken = default);
    Task<UserDto?> GetCurrentUserAsync(long userId, CancellationToken cancellationToken = default);
}
public interface ICourseService
{
    Task<PagedResult<CourseListItemDto>> GetListAsync(string? search, string? status, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<object?> GetByIdAsync(long id, CancellationToken cancellationToken = default);
    Task<object?> GetContentAsync(long id, CancellationToken cancellationToken = default);
}
public interface ILearningService
{
    Task<PlayerDataDto?> GetPlayerAsync(long lessonId, long studentId, CancellationToken cancellationToken = default);
    Task SaveVideoProgressAsync(long studentId, VideoProgressRequest request, CancellationToken cancellationToken = default);
    Task<AnswerResultDto> SubmitAnswerAsync(long studentId, SubmitAnswerRequest request, CancellationToken cancellationToken = default);
}
public interface IReportService { Task<DashboardDto> GetDashboardAsync(CancellationToken cancellationToken = default); }
public interface ITokenService { (string Token, DateTime ExpiresAt) CreateAccessToken(long userId, string username, string role); string CreateRefreshToken(); }
