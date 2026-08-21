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
    Task<PagedResult<CourseListItemDto>> GetListAsync(string? search, string? status, int page, int pageSize, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<object?> GetByIdAsync(long id, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<object?> GetContentAsync(long id, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<long> CreateAsync(CourseSaveRequest request, long actorId, CancellationToken cancellationToken = default);
    Task<bool> UpdateAsync(long id, CourseSaveRequest request, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<bool> ChangeStatusAsync(long id, string status, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(long id, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
}
public interface IAcademicService
{
    Task<object> GetCatalogAsync(long actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<object> SaveAsync(AcademicCatalogSaveRequest request, long actorId, CancellationToken cancellationToken = default);
    Task<object> AssignStudentsToClassAsync(AssignStudentsToClassRequest request, long actorId, CancellationToken cancellationToken = default);
    Task<object> EnsureClassSubjectWorkspaceAsync(long classSubjectId, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
}
public interface ILearningService
{
    Task<object> GetDashboardAsync(long studentId, CancellationToken cancellationToken = default);
    Task<IReadOnlyCollection<object>> GetCoursesAsync(long studentId, CancellationToken cancellationToken = default);
    Task<object?> GetCourseAsync(long courseId, long studentId, CancellationToken cancellationToken = default);
    Task<object> GetResultsAsync(long studentId, long? courseId = null, CancellationToken cancellationToken = default);
    Task<PlayerDataDto?> GetPlayerAsync(long lessonId, long studentId, CancellationToken cancellationToken = default);
    Task SaveVideoProgressAsync(long studentId, VideoProgressRequest request, CancellationToken cancellationToken = default);
    Task<AnswerResultDto> SubmitAnswerAsync(long studentId, SubmitAnswerRequest request, CancellationToken cancellationToken = default);
    Task<object> GetInteractiveContentAsync(long lessonId, long studentId, CancellationToken cancellationToken = default);
    Task<AnswerResultDto> SubmitInteractiveContentAnswerAsync(long lessonId, long studentId, InteractiveContentAnswerRequest request, CancellationToken cancellationToken = default);
    Task<object> SaveInteractiveReadingProgressAsync(long lessonId, long studentId, InteractiveReadingProgressRequest request, CancellationToken cancellationToken = default);
    Task<object> CompleteInteractiveContentAsync(long lessonId, long studentId, CancellationToken cancellationToken = default);
    Task<object> StartStudySessionAsync(long studentId, StudySessionStartRequest request, CancellationToken cancellationToken = default);
    Task<object?> HeartbeatStudySessionAsync(Guid studySessionId, long studentId, CancellationToken cancellationToken = default);
    Task<object?> EndStudySessionAsync(Guid studySessionId, long studentId, bool isCompleted, CancellationToken cancellationToken = default);
    Task<IReadOnlyCollection<object>> GetAssignmentSubmissionsAsync(long lessonId, long studentId, CancellationToken cancellationToken = default);
    Task<int> ValidateAssignmentAsync(long lessonId, long studentId, string action, CancellationToken cancellationToken = default);
    Task<object> SaveAssignmentDraftAsync(long lessonId, long studentId, string? submissionText, AssignmentSubmissionFile? file, CancellationToken cancellationToken = default);
    Task<object> SubmitAssignmentAsync(long lessonId, long studentId, string? submissionText, AssignmentSubmissionFile? file, CancellationToken cancellationToken = default);
}
public interface ITeachingService
{
    Task<IReadOnlyCollection<object>> GetAssignmentSubmissionsAsync(long? classSubjectId, string? status, string? search, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<object> GradeAssignmentSubmissionAsync(long assignmentSubmissionId, AssignmentGradeRequest request, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
}
public interface IQuizService
{
    Task<object> GetForTeacherAsync(long lessonId, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<object> SaveAsync(long lessonId, QuizSaveRequest request, long actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<object> GetForStudentAsync(long lessonId, long studentId, CancellationToken cancellationToken = default);
    Task<object> StartAttemptAsync(long lessonId, long studentId, CancellationToken cancellationToken = default);
    Task<object> SubmitAttemptAsync(long quizAttemptId, long studentId, QuizSubmitRequest request, CancellationToken cancellationToken = default);
}
public interface IReportService { Task<DashboardDto> GetDashboardAsync(CancellationToken cancellationToken = default); Task<IReadOnlyCollection<object>> GetReportAsync(string report, CancellationToken cancellationToken = default); }
public interface ISearchService { Task<IReadOnlyCollection<object>> SearchAsync(string search, long actorId, bool isAdmin, int limit = 60, CancellationToken cancellationToken = default); }
public interface INotificationService
{
    Task<NotificationFeedDto> GetAsync(long recipientUserId, int limit, bool unreadOnly, CancellationToken cancellationToken = default);
    Task<bool> MarkReadAsync(long notificationId, long recipientUserId, CancellationToken cancellationToken = default);
    Task<int> MarkAllReadAsync(long recipientUserId, CancellationToken cancellationToken = default);
}
public interface ILessonCommentService
{
    Task<LessonCommentFeedDto> GetByLessonAsync(long lessonId, long actorUserId, bool isAdmin, bool isTeacher, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<long> CreateAsync(long lessonId, LessonCommentCreateRequest request, long actorUserId, bool isAdmin, bool isTeacher, CancellationToken cancellationToken = default);
    Task<long> UpdateAsync(long lessonCommentId, LessonCommentUpdateRequest request, long actorUserId, CancellationToken cancellationToken = default);
    Task<long> DeleteAsync(long lessonCommentId, long actorUserId, bool isAdmin, bool isTeacher, CancellationToken cancellationToken = default);
}
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
    Task<object?> GetVideoAsync(long id, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<long> SaveVideoAsync(long? id, long lessonId, VideoSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<IReadOnlyCollection<object>> GetVideoLibraryAsync(string? search, string? access, string? source, string? usage, string? status, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<object> GetVideoUsageAsync(long id, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<long> CreateVideoAssetAsync(VideoAssetSaveRequest request, long actorId, CancellationToken ct = default);
    Task<bool> UpdateVideoAssetAsync(long id, VideoAssetSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<long> DuplicateVideoAssetAsync(long id, VideoDuplicateRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<bool> DeleteVideoAssetAsync(long id, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<object> GetVideoSharingAsync(long id, long actorId, bool isAdmin, CancellationToken ct = default);
    Task SaveVideoSharingAsync(long id, VideoShareSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<long> AttachVideoAssetAsync(long lessonId, long assetId, VideoAttachRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<long> AttachVideoAsync(long lessonId, long videoId, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<IReadOnlyCollection<object>> GetInteractionsAsync(long videoId, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<PreviewAnswerResultDto> PreviewAnswerAsync(long videoId, PreviewAnswerRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<long> CreateInteractionAsync(long videoId, InteractionSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<bool> UpdateInteractionAsync(long id, InteractionSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<bool> DeleteInteractionAsync(long id, long actorId, bool isAdmin, CancellationToken ct = default);
    Task ReorderInteractionsAsync(ReorderRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<object> GetInteractiveContentForTeacherAsync(long lessonId, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<long> SaveInteractiveContentSettingsAsync(long lessonId, InteractiveContentSettingsRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<long> CreateContentInteractionAsync(long lessonId, ContentInteractionSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<bool> UpdateContentInteractionAsync(long id, ContentInteractionSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<bool> DeleteContentInteractionAsync(long id, long actorId, bool isAdmin, CancellationToken ct = default);
    Task ReorderContentInteractionsAsync(ReorderRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
}
public interface IQuestionService
{
    Task<PagedResult<object>> GetListAsync(string? search, string? type, int page, int pageSize, CancellationToken ct = default);
    Task<object?> GetByIdAsync(long id, CancellationToken ct = default);
    Task<long> CreateAsync(QuestionSaveRequest request, long actorId, CancellationToken ct = default);
    Task<bool> UpdateAsync(long id, QuestionSaveRequest request, long actorId, bool isAdmin, CancellationToken ct = default);
    Task<bool> DeleteAsync(long id, long actorId, bool isAdmin, CancellationToken ct = default);
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
public interface IAssignmentStorageService
{
    Task<AssignmentSubmissionFile> SaveTeacherResourceAsync(long lessonId, Stream content, string originalFileName, string contentType, long fileSize, CancellationToken cancellationToken = default);
    Task<AssignmentSubmissionFile> SaveStudentSubmissionAsync(long lessonId, long studentUserId, Stream content, string originalFileName, string contentType, long fileSize, CancellationToken cancellationToken = default);
    Task<LearningDocumentPreview?> CreateDocumentPreviewAsync(string fileUrl, CancellationToken cancellationToken = default);
}
public enum ProjectStorageArea { Cache, Temp, Exports, Processing }
public sealed record ProjectStoredFile(string RelativePath, long FileSize, DateTime CreatedAtUtc);
public interface IProjectStorageService
{
    string GetDirectory(ProjectStorageArea area);
    Task<ProjectStoredFile> SaveAsync(ProjectStorageArea area, Stream content, string extension = ".tmp", CancellationToken ct = default);
    Task<ProjectStoredFile> WriteTextAsync(ProjectStorageArea area, string content, string extension = ".txt", CancellationToken ct = default);
    bool Exists(string relativePath);
    Task<bool> DeleteAsync(string relativePath, CancellationToken ct = default);
    Task<int> CleanupExpiredAsync(ProjectStorageArea area, TimeSpan maxAge, CancellationToken ct = default);
}
public interface ITokenService { (string Token, DateTime ExpiresAt) CreateAccessToken(long userId, string username, string role); string CreateRefreshToken(); }
