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
    Task<long> CreateAsync(CourseSaveRequest request, long actorId, CancellationToken cancellationToken = default);
    Task<bool> UpdateAsync(long id, CourseSaveRequest request, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<bool> ChangeStatusAsync(long id, string status, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(long id, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
}
public interface ILearningService
{
    Task<PlayerDataDto?> GetPlayerAsync(long lessonId, long studentId, CancellationToken cancellationToken = default);
    Task SaveVideoProgressAsync(long studentId, VideoProgressRequest request, CancellationToken cancellationToken = default);
    Task<AnswerResultDto> SubmitAnswerAsync(long studentId, SubmitAnswerRequest request, CancellationToken cancellationToken = default);
}
public interface IReportService { Task<DashboardDto> GetDashboardAsync(CancellationToken cancellationToken = default); Task<IReadOnlyCollection<object>> GetReportAsync(string report, CancellationToken cancellationToken = default); }
public interface IContentService
{
    Task<IReadOnlyCollection<object>> GetChaptersAsync(long courseId, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<long> CreateChapterAsync(long courseId, ChapterSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<bool> UpdateChapterAsync(long id, ChapterSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<bool> DeleteChapterAsync(long id, long actorId, bool isAdmin, CancellationToken ct = default);
    Task ReorderChaptersAsync(ReorderRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<object?> GetLessonAsync(long id, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<long> CreateLessonAsync(long chapterId, LessonSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<bool> UpdateLessonAsync(long id, LessonSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<bool> DeleteLessonAsync(long id, long actorId, bool isAdmin, CancellationToken ct = default);
    Task ReorderLessonsAsync(ReorderRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<object?> GetVideoAsync(long id, CancellationToken ct = default);
    Task<long> SaveVideoAsync(long? id, long lessonId, VideoSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<IReadOnlyCollection<object>> GetInteractionsAsync(long videoId, CancellationToken ct = default);
    Task<long> CreateInteractionAsync(long videoId, InteractionSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<bool> UpdateInteractionAsync(long id, InteractionSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<bool> DeleteInteractionAsync(long id, long actorId, bool isAdmin, CancellationToken ct = default);
    Task ReorderInteractionsAsync(ReorderRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
}
public interface IQuestionService
{
    Task<PagedResult<object>> GetListAsync(string? search, string? type, int page, int pageSize, CancellationToken ct = default);
    Task<object?> GetByIdAsync(long id, CancellationToken ct = default);
    Task<long> CreateAsync(QuestionSaveRequest request, long actorId, CancellationToken ct = default);
    Task<bool> UpdateAsync(long id, QuestionSaveRequest request, long actorId, CancellationToken ct = default);
    Task<bool> DeleteAsync(long id, long actorId, CancellationToken ct = default);
}
public interface IStudentService
{
    Task<PagedResult<object>> GetStudentsAsync(string? search, string? status, int page, int pageSize, CancellationToken ct = default);
    Task<object?> GetStudentAsync(long id, CancellationToken ct = default);
    Task<PagedResult<object>> GetEnrollmentsAsync(int page, int pageSize, CancellationToken ct = default);
    Task<long> EnrollAsync(EnrollmentCreateRequest request, long actorId, CancellationToken ct = default);
    Task<bool> CancelEnrollmentAsync(long id, long actorId, CancellationToken ct = default);
}
public sealed record StoredVideoFile(string OriginalFileName, string StoredFileName, string VideoUrl, long FileSize, string MimeType);
public interface IVideoStorageService
{
    Task<StoredVideoFile> SaveAsync(Stream content, string originalFileName, string contentType, long fileSize, CancellationToken ct = default);
    Task<bool> DeleteAsync(string videoUrl, CancellationToken ct = default);
    bool Exists(string videoUrl);
    string GetUrl(string videoUrl);
}
public interface ITokenService { (string Token, DateTime ExpiresAt) CreateAccessToken(long userId, string username, string role); string CreateRefreshToken(); }
