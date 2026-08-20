namespace LmsCms.Application.DTOs;

using System.ComponentModel.DataAnnotations;

public sealed record LoginRequest(string Username, string Password);
public sealed record RefreshTokenRequest(string RefreshToken);
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
public sealed record VideoProgressRequest(long LessonId, long VideoId, decimal CurrentTime, decimal MaxWatchedTime, decimal WatchPercent);
public sealed record SubmitAnswerRequest(long LessonId, long? VideoId, long? InteractionId, long QuestionId, IReadOnlyCollection<string> Answers, decimal? TimeInVideo, int? TimeSpent);
public sealed record AnswerResultDto(long AnswerId, bool? IsCorrect, decimal ScoreAwarded, decimal CurrentLessonScore, int AttemptNumber, string ReviewStatus, string? Explanation);
public sealed record PreviewAnswerRequest(long InteractionId, long QuestionId, IReadOnlyCollection<string> Answers);
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
    [RegularExpression("VIDEO|INTERACTIVE_VIDEO|QUIZ|DOCUMENT|EDITOR|ASSIGNMENT")] public string LessonType { get; init; } = "VIDEO";
    [Range(0, int.MaxValue)] public int DurationSeconds { get; init; }
    [Range(1, int.MaxValue)] public int SortOrder { get; init; } = 1;
    public bool IsRequired { get; init; } = true;
    [Range(0, 100)] public decimal? PassingScore { get; init; }
    public string? ContentHtml { get; init; }
    [StringLength(1000)] public string? DocumentUrl { get; init; }
    [StringLength(250)] public string? AssignmentFolderName { get; init; }
    public DateTime? DueAt { get; init; }
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
    public IReadOnlyCollection<long> LessonIds { get; init; } = [];
}
public sealed class VideoDuplicateRequest
{
    [StringLength(500)] public string? Title { get; init; }
}
public sealed class VideoShareSaveRequest
{
    [RegularExpression("PRIVATE|SELECTED|SCHOOL")] public string ShareScope { get; init; } = "PRIVATE";
    public IReadOnlyCollection<long> TeacherIds { get; init; } = [];
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
public sealed record QuestionOptionInput(string OptionCode, string OptionText, bool IsCorrect, int SortOrder);
public sealed record AnswerKeyInput(string AnswerText, bool IsCaseSensitive, int SortOrder);
public sealed class QuestionSaveRequest
{
    [RegularExpression("SINGLE_CHOICE|MULTIPLE_CHOICE|TRUE_FALSE|SHORT_ANSWER")] public string QuestionType { get; init; } = "SINGLE_CHOICE";
    [Required] public string QuestionText { get; init; } = "";
    public string? Description { get; init; }
    public string? Explanation { get; init; }
    [RegularExpression("EASY|MEDIUM|HARD")] public string Difficulty { get; init; } = "EASY";
    [Range(0, 10000)] public decimal DefaultScore { get; init; } = 10;
    public string? ShortAnswerMode { get; init; }
    [RegularExpression("ACTIVE|INACTIVE")] public string Status { get; init; } = "ACTIVE";
    public IReadOnlyCollection<QuestionOptionInput> Options { get; init; } = [];
    public IReadOnlyCollection<AnswerKeyInput> AnswerKeys { get; init; } = [];
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
    public int? YearId { get; init; }
    [Range(1, 3)] public byte? Semester { get; init; }
    public long? ClassSubjectId { get; init; }
    [StringLength(50)] public string? ClassId { get; init; }
    [StringLength(50)] public string? SubjectId { get; init; }
    [StringLength(50)] public string? TeacherId { get; init; }
    [Range(0, 10000)] public int ClassSize { get; init; }
    [Range(0, 50)] public byte CreditCount { get; init; }
    [Range(0, 10000)] public int TheoryQuantity { get; init; }
    [Range(0, 10000)] public int PracticeQuantity { get; init; }
    public long? TimetableId { get; init; }
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
    [Required, MinLength(1)] public IReadOnlyCollection<long> StudentUserIds { get; init; } = [];
}

public sealed class StudySessionStartRequest
{
    public long? CourseId { get; init; }
    public long? ChapterId { get; init; }
    public long? LessonId { get; init; }
    [StringLength(1000)] public string? PageUrl { get; init; }
    [StringLength(100)] public string? ClientSessionKey { get; init; }
}

public sealed class StudySessionEndRequest
{
    public bool IsCompleted { get; init; }
}

public sealed record AssignmentSubmissionFile(
    string OriginalFileName,
    string StoredFileName,
    string FileUrl,
    long FileSize,
    string MimeType);
