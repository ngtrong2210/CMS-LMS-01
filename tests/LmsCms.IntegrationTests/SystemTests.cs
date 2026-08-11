using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;

namespace LmsCms.IntegrationTests;

public sealed class SystemTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;
    public SystemTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient(new WebApplicationFactoryClientOptions { AllowAutoRedirect = false });
    }

    [Fact]
    public async Task Health_Reports_ApiAndSqlHealthy()
    {
        var response = await _client.GetAsync("/health");
        response.EnsureSuccessStatusCode();
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Healthy", json.GetProperty("status").GetString());
        Assert.Equal("Healthy", json.GetProperty("sqlServer").GetString());
    }

    [Theory]
    [InlineData("admin", "ADMIN")]
    [InlineData("teacher", "TEACHER")]
    [InlineData("student", "STUDENT")]
    public async Task Login_DemoAccounts_ReturnTokensAndRole(string username, string role)
    {
        var response = await _client.PostAsJsonAsync("/api/auth/login", new { username, password = "123456" });
        response.EnsureSuccessStatusCode();
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.False(string.IsNullOrWhiteSpace(json.GetProperty("data").GetProperty("accessToken").GetString()));
        Assert.Equal(role, json.GetProperty("data").GetProperty("user").GetProperty("role").GetString());
    }

    [Theory]
    [InlineData("admin", "wrong-password")]
    [InlineData("missing-user-qa", "123456")]
    public async Task Login_InvalidCredentials_ReturnsGeneric401(string username, string password)
    {
        var response = await _client.PostAsJsonAsync("/api/auth/login", new { username, password });
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.DoesNotContain("SqlException", body, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("not found", body, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Authorization_RejectsMissingInvalidAndStudentTokens()
    {
        Assert.Equal(HttpStatusCode.Unauthorized, (await _client.GetAsync("/api/cms/dashboard")).StatusCode);
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "invalid-token");
        Assert.Equal(HttpStatusCode.Unauthorized, (await _client.GetAsync("/api/cms/dashboard")).StatusCode);
        await AuthorizeAs("student");
        Assert.Equal(HttpStatusCode.Forbidden, (await _client.GetAsync("/api/cms/dashboard")).StatusCode);
        await AuthorizeAs("teacher");
        Assert.Equal(HttpStatusCode.Forbidden, (await _client.GetAsync("/api/cms/settings")).StatusCode);
    }

    [Fact]
    public async Task Player_EnrolledStudent_DoesNotExposeCorrectAnswers()
    {
        await AuthorizeAs("student");
        var response = await _client.GetAsync("/api/lms/lessons/1/player");
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        foreach (var forbidden in new[] { "isCorrect", "correctAnswer", "correctAnswers", "answerKey", "QuestionAnswerKeys" })
            Assert.DoesNotContain(forbidden, body, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Player_NonEnrolledCourse_IsNotAccessible()
    {
        await AuthorizeAs("student");
        var response = await _client.GetAsync("/api/lms/lessons/16/player");
        Assert.Contains(response.StatusCode, new[] { HttpStatusCode.Forbidden, HttpStatusCode.NotFound });
    }

    [Fact]
    public async Task Answer_RejectsInteractionQuestionMismatch_AndTamperingFields()
    {
        await AuthorizeAs("student");
        var response = await _client.PostAsJsonAsync("/api/lms/answers", new { lessonId = 1, videoId = 1, interactionId = 1, questionId = 2, answers = new[] { "B" }, isCorrect = true, scoreAwarded = 999999 });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Progress_RejectsVideoFromNonEnrolledCourse()
    {
        await AuthorizeAs("admin");
        long videoId = 0, lessonId = 0;
        for (var id = 1; id <= 50 && videoId == 0; id++)
        {
            var candidateResponse = await _client.GetAsync($"/api/videos/{id}");
            if (!candidateResponse.IsSuccessStatusCode) continue;
            var video = await candidateResponse.Content.ReadFromJsonAsync<JsonElement>();
            var candidateLesson = video.GetProperty("data").GetProperty("LessonId").GetInt64();
            if (candidateLesson >= 16) { videoId = id; lessonId = candidateLesson; }
        }
        Assert.True(videoId > 0, "No video outside the student's enrolled course was found.");
        await AuthorizeAs("student");
        var response = await _client.PostAsJsonAsync("/api/lms/progress/video", new { lessonId, videoId, currentTime = 10, maxWatchedTime = 10, watchPercent = 2 });
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task CmsListsAndReports_ReturnStructuredData()
    {
        await AuthorizeAs("admin");
        foreach (var path in new[] { "/api/cms/students", "/api/cms/enrollments", "/api/questions", "/api/cms/reports/course-overview", "/api/cms/reports/student-progress", "/api/cms/reports/lesson-completion", "/api/cms/reports/question-performance", "/api/cms/reports/video-engagement" })
        {
            var response = await _client.GetAsync(path);
            Assert.True(response.IsSuccessStatusCode, $"{path} returned {(int)response.StatusCode}");
            Assert.Contains("\"success\":true", await response.Content.ReadAsStringAsync(), StringComparison.OrdinalIgnoreCase);
        }
    }

    [Fact]
    public async Task CourseValidation_RejectsInvalidAndDuplicateData()
    {
        await AuthorizeAs("admin");
        var invalid = await _client.PostAsJsonAsync("/api/courses", new { code = "", title = "", teacherId = 999999, level = "BEGINNER", passingScore = 101, status = "DRAFT" });
        Assert.Equal(HttpStatusCode.BadRequest, invalid.StatusCode);
        var duplicate = await _client.PostAsJsonAsync("/api/courses", new { code = "VUE3-001", title = "Duplicate", slug = "vue-js-3-tu-co-ban-den-nang-cao", teacherId = 2, categoryId = 1, level = "BEGINNER", passingScore = 60, status = "DRAFT" });
        Assert.Equal(HttpStatusCode.Conflict, duplicate.StatusCode);
    }

    [Fact]
    public async Task EnrollmentValidation_Returns400Or409_InsteadOf500()
    {
        await AuthorizeAs("admin");
        var invalid = await _client.PostAsJsonAsync("/api/cms/enrollments", new { courseId = 0, studentId = 0 });
        Assert.Equal(HttpStatusCode.BadRequest, invalid.StatusCode);
        var duplicate = await _client.PostAsJsonAsync("/api/cms/enrollments", new { courseId = 1, studentId = 3 });
        Assert.Equal(HttpStatusCode.Conflict, duplicate.StatusCode);
    }

    [Fact]
    public async Task VideoUpload_SavesInsideProject_AndServesStaticRelativeUrl()
    {
        await AuthorizeAs("admin");
        var bytes = "00000018ftypmp42lms-cms-test-video"u8.ToArray();
        using var multipart = new MultipartFormDataContent();
        using var file = new ByteArrayContent(bytes);
        file.Headers.ContentType = new MediaTypeHeaderValue("video/mp4");
        multipart.Add(file, "file", "test-video.mp4");

        var response = await _client.PostAsync("/api/videos/upload", multipart);
        response.EnsureSuccessStatusCode();
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var videoUrl = json.GetProperty("data").GetProperty("videoUrl").GetString()!;
        Assert.StartsWith("/uploads/videos/", videoUrl, StringComparison.Ordinal);
        Assert.DoesNotContain(":", videoUrl, StringComparison.Ordinal);

        var environment = _factory.Services.GetRequiredService<IWebHostEnvironment>();
        var webRoot = environment.WebRootPath ?? Path.Combine(environment.ContentRootPath, "wwwroot");
        var physicalPath = Path.GetFullPath(Path.Combine(webRoot, videoUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar)));
        var uploadRoot = Path.GetFullPath(Path.Combine(webRoot, "uploads", "videos")) + Path.DirectorySeparatorChar;
        Assert.StartsWith(uploadRoot, physicalPath, OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal);
        Assert.True(File.Exists(physicalPath));
        var storage = _factory.Services.GetRequiredService<LmsCms.Application.Interfaces.IVideoStorageService>();
        Assert.True(storage.Exists(videoUrl));
        Assert.Equal(videoUrl, storage.GetUrl(videoUrl));

        try
        {
            var staticResponse = await _client.GetAsync(videoUrl);
            staticResponse.EnsureSuccessStatusCode();
            Assert.Equal("video/mp4", staticResponse.Content.Headers.ContentType?.MediaType);
            Assert.Equal(bytes, await staticResponse.Content.ReadAsByteArrayAsync());
        }
        finally { Assert.True(await storage.DeleteAsync(videoUrl)); }
    }

    [Fact]
    public async Task VideoSave_RejectsAbsoluteTraversalAndMissingFiles()
    {
        await AuthorizeAs("admin");
        var invalidUrls = new[]
        {
            string.Concat("G:", Path.DirectorySeparatorChar, "Videos", Path.DirectorySeparatorChar, "lecture.mp4"),
            "/uploads/videos/../../lecture.mp4",
            "/uploads/videos/2099/01/missing.mp4"
        };
        foreach (var videoUrl in invalidUrls)
        {
            var response = await _client.PutAsJsonAsync("/api/videos/1", new { lessonId = 1, title = "Video validation", videoUrl, durationSeconds = 60, allowSeek = false, allowSpeed = true, requiredWatchPercent = 80, status = "ACTIVE" });
            Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        }
    }

    private async Task AuthorizeAs(string username)
    {
        _client.DefaultRequestHeaders.Authorization = null;
        var response = await _client.PostAsJsonAsync("/api/auth/login", new { username, password = "123456" });
        response.EnsureSuccessStatusCode();
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", json.GetProperty("data").GetProperty("accessToken").GetString());
    }
}
