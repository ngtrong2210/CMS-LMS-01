namespace LmsCms.Domain;

public sealed class User
{
    public long Id { get; init; }
    public string Username { get; init; } = "";
    public string PasswordHash { get; init; } = "";
    public string FullName { get; init; } = "";
    public string Email { get; init; } = "";
    public string? StudentCode { get; init; }
    public string? TeacherCode { get; init; }
    public string Status { get; init; } = "ACTIVE";
    public string Role { get; init; } = "";
}

public sealed class Course
{
    public long Id { get; init; }
    public string Code { get; init; } = "";
    public string Title { get; init; } = "";
    public string Slug { get; init; } = "";
    public string? ThumbnailUrl { get; init; }
    public string? ShortDescription { get; init; }
    public string? Description { get; init; }
    public long TeacherId { get; init; }
    public string TeacherName { get; init; } = "";
    public string Level { get; init; } = "";
    public decimal PassingScore { get; init; }
    public string Status { get; init; } = "DRAFT";
    public int LessonCount { get; init; }
    public int StudentCount { get; init; }
    public DateTime CreatedAt { get; init; }
}
