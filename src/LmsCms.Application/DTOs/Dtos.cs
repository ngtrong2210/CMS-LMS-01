namespace LmsCms.Application.DTOs;

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
public sealed record VideoProgressRequest(long LessonId, long VideoId, decimal CurrentTime, decimal MaxWatchedTime, decimal WatchPercent);
public sealed record SubmitAnswerRequest(long LessonId, long? VideoId, long? InteractionId, long QuestionId, IReadOnlyCollection<string> Answers, decimal? TimeInVideo, int? TimeSpent);
public sealed record AnswerResultDto(long AnswerId, bool? IsCorrect, decimal ScoreAwarded, decimal CurrentLessonScore, int AttemptNumber, string ReviewStatus, string? Explanation);
public sealed record PlayerDataDto(object? Lesson, object? Course, object? Video, object? Progress, IReadOnlyCollection<object> Interactions, IReadOnlyCollection<object> AnsweredInteractions);
