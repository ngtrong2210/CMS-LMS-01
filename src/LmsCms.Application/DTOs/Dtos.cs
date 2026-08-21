namespace LmsCms.Application.DTOs;

using System.ComponentModel.DataAnnotations;

public sealed record LoginRequest(
    [Required, StringLength(100)] string Username,
    [Required, StringLength(200)] string Password);
public sealed record RefreshTokenRequest([Required, StringLength(500)] string RefreshToken);
public sealed record UserDto(long Id, string Username, string FullName, string Email, string Role, IReadOnlyCollection<string> Permissions);
public sealed record AuthResponse(string AccessToken, string RefreshToken, DateTime ExpiresAt, UserDto User);
public sealed class CourseListItemDto
{
    public long Id { get; init; }
    public string Code { get; init; } = "";
    public string Title { get; init; } = "";
    public string Slug { get; init; } = "";
    public string? ThumbnailUrl { get; init; }
    public string? ShortDescription { get; init; }
    public string TeacherName { get; init; } = "";
    public string Level { get; init; } = "";
    public string Status { get; init; } = "";
    public int LessonCount { get; init; }
    public int StudentCount { get; init; }
    public DateTime CreatedAt { get; init; }
}
public sealed record DashboardDto(int TotalCourses, int TotalStudents, int TotalTeachers, int TotalLessons, int TotalVideos, int TotalQuestions, decimal CompletionRate, decimal AverageScore);
public sealed class NotificationListItemDto
{
    public long Id { get; init; }
    public string NotificationType { get; init; } = "";
    public string Title { get; init; } = "";
    public string Message { get; init; } = "";
    public string? ReferenceType { get; init; }
    public long? ReferenceId { get; init; }
    public string? ActionUrl { get; init; }
    public bool IsRead { get; init; }
    public DateTime? ReadAt { get; init; }
    public DateTime CreatedAt { get; init; }
    public string? ActorName { get; init; }
    public string? ActorAvatarUrl { get; init; }
}
public sealed record NotificationFeedDto(IReadOnlyCollection<NotificationListItemDto> Items, int UnreadCount);
public sealed class LessonCommentDto
{
    public long Id { get; init; }
    public long CourseID { get; init; }
    public long LessonID { get; init; }
    public long UserID { get; init; }
    public long? ParentCommentID { get; init; }
    public string Content { get; init; } = "";
    public bool IsEdited { get; init; }
    public bool IsDeleted { get; init; }
    public DateTime CreatedDate { get; init; }
    public DateTime? UpdatedDate { get; init; }
    public string UserFullName { get; init; } = "";
    public string? UserAvatarUrl { get; init; }
    public string UserRole { get; init; } = "STUDENT";
    public bool CanEdit { get; init; }
    public bool CanDelete { get; init; }
    public int CommentLevel { get; init; }
    public List<LessonCommentDto> Replies { get; set; } = [];
}
public sealed record LessonCommentFeedDto(
    IReadOnlyCollection<LessonCommentDto> Items,
    int Page,
    int PageSize,
    int RootCommentCount,
    int TotalCommentCount);
public sealed class LessonCommentCreateRequest
{
    [Required, StringLength(5000, MinimumLength = 1)] public string Content { get; init; } = "";
    public long? ParentCommentId { get; init; }
}
public sealed class LessonCommentUpdateRequest
{
    [Required, StringLength(5000, MinimumLength = 1)] public string Content { get; init; } = "";
}
[System.Diagnostics.CodeAnalysis.SuppressMessage("Style", "IDE0290")]
public sealed class CourseSaveRequest
{
    [Required, StringLength(100)] public string Code { get; init; } = "";
    [Required, StringLength(500)] public string Title { get; init; } = "";
    [StringLength(500)] public string? Slug { get; init; }
    [StringLength(1000)] public string? ThumbnailUrl { get; init; }
    [StringLength(1000)] public string? ShortDescription { get; init; }
    public string? Description { get; init; }
    [Range(1, long.MaxValue)] public long TeacherId { get; init; }
    public long? CategoryId { get; init; }
    public long? ClassSubjectId { get; init; }
    [Required, StringLength(50)] public string Level { get; init; } = "BEGINNER";
    [Range(0, 100)] public decimal PassingScore { get; init; }
    [RegularExpression("DRAFT|PUBLISHED|ARCHIVED")] public string Status { get; init; } = "DRAFT";
}
public sealed record VideoProgressRequest(
    [Range(1, long.MaxValue)] long LessonId,
    [Range(1, long.MaxValue)] long VideoId,
    [Range(0, double.MaxValue)] decimal CurrentTime,
    [Range(0, double.MaxValue)] decimal MaxWatchedTime,
    [Range(0, 100)] decimal WatchPercent);
public sealed record SubmitAnswerRequest(
    [Range(1, long.MaxValue)] long LessonId,
    [Range(1, long.MaxValue)] long? VideoId,
    [Range(1, long.MaxValue)] long? InteractionId,
    [Range(1, long.MaxValue)] long QuestionId,
    [Required, MinLength(1), MaxLength(100)] IReadOnlyCollection<string> Answers,
    [Range(0, double.MaxValue)] decimal? TimeInVideo,
    [Range(0, 86400)] int? TimeSpent);
public sealed record AnswerResultDto(long AnswerId, bool? IsCorrect, decimal ScoreAwarded, decimal CurrentLessonScore, int AttemptNumber, string ReviewStatus, string? Explanation);
public sealed class InteractiveContentSettingsRequest
{
    [RegularExpression("REQUIRED_QUESTIONS|ALL_QUESTIONS|PASSING_SCORE")] public string CompletionRule { get; init; } = "REQUIRED_QUESTIONS";
    public bool RequireReading { get; init; } = true;
    [Range(0, 100)] public decimal PassingScore { get; init; } = 70;
    public bool ShowResultImmediately { get; init; } = true;
    public bool ShowScore { get; init; } = true;
}
public sealed class ContentInteractionSaveRequest
{
    [Range(1, long.MaxValue)] public long QuestionId { get; init; }
    [StringLength(100)] public string? ContentAnchor { get; init; }
    public bool Required { get; init; } = true;
    public bool AllowRetry { get; init; } = true;
    [Range(0, 10000)] public decimal Score { get; init; } = 10;
    [Range(1, 100)] public int AttemptLimit { get; init; } = 2;
    [Range(1, int.MaxValue)] public int SortOrder { get; init; } = 1;
    [RegularExpression("ACTIVE|INACTIVE")] public string Status { get; init; } = "ACTIVE";
}
public sealed class InteractiveContentAnswerRequest
{
    [Range(1, long.MaxValue)] public long ContentInteractionId { get; init; }
    [Range(1, long.MaxValue)] public long QuestionId { get; init; }
    [Required, MinLength(1)] public IReadOnlyCollection<string> Answers { get; init; } = [];
    public int? TimeSpentSeconds { get; init; }
}
public sealed class InteractiveReadingProgressRequest
{
    [Range(0, 100)] public decimal ReadingProgressPercent { get; init; }
    [Range(0, 100)] public decimal LastScrollPercent { get; init; }
}
public sealed record PreviewAnswerRequest(
    [Range(1, long.MaxValue)] long InteractionId,
    [Range(1, long.MaxValue)] long QuestionId,
    [Required, MinLength(1), MaxLength(100)] IReadOnlyCollection<string> Answers);
public sealed record PreviewAnswerResultDto(bool? IsCorrect, decimal ScoreAwarded, string ReviewStatus, string? Explanation);
public sealed record PlayerDataDto(object? Lesson, object? Course, object? Video, object? Progress, IReadOnlyCollection<object> Interactions, IReadOnlyCollection<object> AnsweredInteractions);
public sealed class ChapterSaveRequest
{
    [Required, StringLength(500)] public string Title { get; init; } = "";
    [StringLength(1000)] public string? Description { get; init; }
    [Range(1, int.MaxValue)] public int SortOrder { get; init; } = 1;
    [RegularExpression("ACTIVE|INACTIVE")] public string Status { get; init; } = "ACTIVE";
}
public sealed class LessonSaveRequest
{
    [Required, StringLength(500)] public string Title { get; init; } = "";
    [StringLength(1000)] public string? Description { get; init; }
    [RegularExpression("VIDEO|INTERACTIVE_VIDEO|QUIZ|DOCUMENT|EDITOR|ASSIGNMENT|INTERACTIVE_CONTENT")] public string LessonType { get; init; } = "VIDEO";
    [Range(0, int.MaxValue)] public int DurationSeconds { get; init; }
    [Range(1, int.MaxValue)] public int SortOrder { get; init; } = 1;
    public bool IsRequired { get; init; } = true;
    [Range(0, 100)] public decimal? PassingScore { get; init; }
    [StringLength(1000000)] public string? ContentHtml { get; init; }
    [StringLength(1000)] public string? DocumentUrl { get; init; }
    [StringLength(250)] public string? AssignmentFolderName { get; init; }
    public DateTime? AssignmentStartAt { get; init; }
    public DateTime? DueAt { get; init; }
    [Range(1, 10000)] public decimal AssignmentMaxScore { get; init; } = 100;
    [Range(1, 20)] public int MaxSubmissionAttempts { get; init; } = 3;
    [Range(1, 200)] public int MaxSubmissionFileSizeMB { get; init; } = 50;
    public bool AllowLateSubmission { get; init; }
    [RegularExpression("ACTIVE|INACTIVE")] public string Status { get; init; } = "ACTIVE";
}
public sealed class VideoSaveRequest
{
    public long LessonId { get; init; }
    [Required, StringLength(500)] public string Title { get; init; } = "";
    [RegularExpression("LOCAL|YOUTUBE")] public string SourceType { get; init; } = "LOCAL";
    [StringLength(1000)] public string? VideoUrl { get; init; }
    [StringLength(1000)] public string? PosterUrl { get; init; }
    [Range(1, int.MaxValue)] public int DurationSeconds { get; init; }
    public bool AllowSeek { get; init; }
    public bool AllowSpeed { get; init; } = true;
    [Range(0, 100)] public decimal RequiredWatchPercent { get; init; } = 80;
    [RegularExpression("ACTIVE|INACTIVE")] public string Status { get; init; } = "ACTIVE";
}
public sealed class VideoAssetSaveRequest
{
    [Required, StringLength(500)] public string Title { get; init; } = "";
    [RegularExpression("LOCAL|YOUTUBE")] public string SourceType { get; init; } = "LOCAL";
    [Required, StringLength(1000)] public string VideoUrl { get; init; } = "";
    [StringLength(1000)] public string? PosterUrl { get; init; }
    [Range(1, int.MaxValue)] public int DurationSeconds { get; init; }
    [StringLength(500)] public string? OriginalFileName { get; init; }
    [Range(0, long.MaxValue)] public long? FileSize { get; init; }
    [StringLength(150)] public string? MimeType { get; init; }
    [RegularExpression("ACTIVE|INACTIVE")] public string Status { get; init; } = "ACTIVE";
    [StringLength(1000)] public string? ChangeSummary { get; init; }
    [MaxLength(500)] public IReadOnlyCollection<long> LessonIds { get; init; } = [];
}
public sealed class VideoDuplicateRequest
{
    [StringLength(500)] public string? Title { get; init; }
}
public sealed class VideoShareSaveRequest
{
    [RegularExpression("PRIVATE|SELECTED|SCHOOL")] public string ShareScope { get; init; } = "PRIVATE";
    [MaxLength(500)] public IReadOnlyCollection<long> TeacherIds { get; init; } = [];
}
public sealed class VideoAttachRequest
{
    public bool AllowSeek { get; init; }
    public bool AllowSpeed { get; init; } = true;
    [Range(0, 100)] public decimal RequiredWatchPercent { get; init; } = 80;
}
public sealed class InteractionSaveRequest
{
    [Range(1, long.MaxValue)] public long QuestionId { get; init; }
    [Range(0, int.MaxValue)] public int TimeSeconds { get; init; }
    public int? EndTimeSeconds { get; init; }
    [Required] public string InteractionType { get; init; } = "QUESTION";
    public bool Required { get; init; } = true;
    public bool PauseVideo { get; init; } = true;
    public bool AllowSkip { get; init; }
    [Range(0, 10000)] public decimal Score { get; init; } = 10;
    [Range(1, 100)] public int AttemptLimit { get; init; } = 1;
    [Range(1, int.MaxValue)] public int SortOrder { get; init; } = 1;
    [RegularExpression("ACTIVE|INACTIVE")] public string Status { get; init; } = "ACTIVE";
}
public sealed class ReorderItem
{
    [Range(1, long.MaxValue)] public long Id { get; init; }
    [Range(1, int.MaxValue)] public int SortOrder { get; init; }
}
public sealed class ReorderRequest
{
    [Required, MinLength(1)] public IReadOnlyCollection<ReorderItem> Items { get; init; } = [];
}
public sealed record QuestionOptionInput(
    [Required, StringLength(20)] string OptionCode,
    [Required, StringLength(2000)] string OptionText,
    bool IsCorrect,
    [Range(1, int.MaxValue)] int SortOrder);
public sealed record AnswerKeyInput(
    [Required, StringLength(2000)] string AnswerText,
    bool IsCaseSensitive,
    [Range(1, int.MaxValue)] int SortOrder);
public sealed class QuestionSaveRequest
{
    [RegularExpression("SINGLE_CHOICE|MULTIPLE_CHOICE|TRUE_FALSE|SHORT_ANSWER")] public string QuestionType { get; init; } = "SINGLE_CHOICE";
    [Required, StringLength(10000)] public string QuestionText { get; init; } = "";
    [StringLength(10000)] public string? Description { get; init; }
    [StringLength(10000)] public string? Explanation { get; init; }
    [RegularExpression("EASY|MEDIUM|HARD")] public string Difficulty { get; init; } = "EASY";
    [Range(0, 10000)] public decimal DefaultScore { get; init; } = 10;
    [RegularExpression("EXACT_MATCH|CONTAINS|MANUAL_REVIEW")] public string? ShortAnswerMode { get; init; }
    [RegularExpression("ACTIVE|INACTIVE")] public string Status { get; init; } = "ACTIVE";
    [MaxLength(100)] public IReadOnlyCollection<QuestionOptionInput> Options { get; init; } = [];
    [MaxLength(100)] public IReadOnlyCollection<AnswerKeyInput> AnswerKeys { get; init; } = [];
}
public sealed class EnrollmentCreateRequest
{
    [Range(1, long.MaxValue)] public long CourseId { get; init; }
    [Range(1, long.MaxValue)] public long StudentId { get; init; }
}

public sealed class AcademicCatalogSaveRequest
{
    [RegularExpression("YEAR|SCIENCE|COHORT|SUBJECT|CLASS|CLASS_SUBJECT|TIMETABLE")] public string EntityType { get; init; } = "";
    [Range(1, int.MaxValue)] public int DataGroupId { get; init; } = 1;
    [StringLength(50)] public string? Code { get; init; }
    [StringLength(500)] public string? Name { get; init; }
    [StringLength(100)] public string? ShortName { get; init; }
    [StringLength(50)] public string? ParentCode { get; init; }
    public int? StartYear { get; init; }
    public int? FinishYear { get; init; }
    public DateTime? StartAt { get; init; }
    public DateTime? FinishAt { get; init; }
    [Range(1, int.MaxValue)] public int? YearId { get; init; }
    [Range(1, 3)] public byte? Semester { get; init; }
    [Range(1, long.MaxValue)] public long? ClassSubjectId { get; init; }
    [StringLength(50)] public string? ClassId { get; init; }
    [StringLength(50)] public string? SubjectId { get; init; }
    [StringLength(50)] public string? TeacherId { get; init; }
    [Range(0, 10000)] public int ClassSize { get; init; }
    [Range(0, 50)] public byte CreditCount { get; init; }
    [Range(0, 10000)] public int TheoryQuantity { get; init; }
    [Range(0, 10000)] public int PracticeQuantity { get; init; }
    [Range(1, long.MaxValue)] public long? TimetableId { get; init; }
    [Range(2, 8)] public byte? DayOfWeek { get; init; }
    [Range(1, 30)] public byte? StartPeriod { get; init; }
    [Range(1, 30)] public byte? EndPeriod { get; init; }
    public TimeSpan? StartTime { get; init; }
    public TimeSpan? EndTime { get; init; }
    [StringLength(100)] public string? RoomName { get; init; }
    public DateTime? EffectiveFrom { get; init; }
    public DateTime? EffectiveTo { get; init; }
}

public sealed class AssignStudentsToClassRequest
{
    [Range(1, int.MaxValue)] public int DataGroupId { get; init; } = 1;
    [Required, StringLength(50)] public string ClassId { get; init; } = "";
    [Required, MinLength(1), MaxLength(1000)] public IReadOnlyCollection<long> StudentUserIds { get; init; } = [];
}

public sealed class StudySessionStartRequest
{
    [Range(1, long.MaxValue)] public long? CourseId { get; init; }
    [Range(1, long.MaxValue)] public long? ChapterId { get; init; }
    [Range(1, long.MaxValue)] public long? LessonId { get; init; }
    [StringLength(1000)] public string? PageUrl { get; init; }
    [StringLength(100)] public string? ClientSessionKey { get; init; }
}

public sealed class StudySessionEndRequest
{
    public bool IsCompleted { get; init; }
}

public sealed class AssignmentGradeRequest
{
    [Range(0, 10000)] public decimal? Score { get; init; }
    [StringLength(5000)] public string? Feedback { get; init; }
    [RegularExpression("GRADE|RETURN")] public string Action { get; init; } = "GRADE";
}

public sealed class QuizSaveRequest
{
    [Required, StringLength(500)] public string Title { get; init; } = string.Empty;
    [StringLength(2000)] public string? Description { get; init; }
    [Range(0, 100)] public decimal PassingScore { get; init; } = 50;
    [Range(1, 600)] public int? TimeLimitMinutes { get; init; }
    [Range(1, 20)] public int MaxAttempts { get; init; } = 1;
    public bool ShuffleQuestions { get; init; }
    [MinLength(1), MaxLength(500)] public IReadOnlyCollection<long> QuestionIds { get; init; } = Array.Empty<long>();
}

public sealed class QuizAnswerRequest
{
    [Range(1, long.MaxValue)] public long QuestionId { get; init; }
    [StringLength(10000)] public string? AnswerText { get; init; }
}

public sealed class QuizSubmitRequest
{
    [MinLength(1), MaxLength(500)] public IReadOnlyCollection<QuizAnswerRequest> Answers { get; init; } = Array.Empty<QuizAnswerRequest>();
}

public sealed record AssignmentSubmissionFile(
    string OriginalFileName,
    string StoredFileName,
    string FileUrl,
    long FileSize,
    string MimeType);

public sealed record LearningDocumentPreview(
    string FileType,
    string Html,
    string Title);
