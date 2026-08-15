using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Dapper;
using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;
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
    public async Task Teacher_CanSaveOwnedVideoInteraction_AndCannotOpenAnotherTeachersVideo()
    {
        await _factory.Services.GetRequiredService<IDatabaseInitializer>().InitializeAsync();
        var factory = _factory.Services.GetRequiredService<ISqlConnectionFactory>();
        using var connection = factory.CreateConnection();
        var otherVideoId = await connection.ExecuteScalarAsync<long>("""
            SELECT TOP(1) v.Id
            FROM dbo.Videos v
            JOIN dbo.VideoAssets a ON a.Id=v.VideoAssetId
            WHERE a.CreatedBy<>2 AND a.IsDeleted=0
            ORDER BY v.Id
            """);

        await AuthorizeAs("teacher");

        var coursesResponse = await _client.GetAsync("/api/courses?pageSize=100");
        coursesResponse.EnsureSuccessStatusCode();
        var courses = (await coursesResponse.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("data").GetProperty("items").EnumerateArray().ToArray();
        Assert.NotEmpty(courses);
        var exposedCourseIds = courses.Select(course => Int64(course, "Id", "id")).ToArray();
        var unauthorizedCourseCount = await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM dbo.Courses WHERE Id IN @Ids AND TeacherId<>2",
            new { Ids = exposedCourseIds });
        Assert.Equal(0, unauthorizedCourseCount);

        var libraryResponse = await _client.GetAsync("/api/video-library");
        libraryResponse.EnsureSuccessStatusCode();
        var libraryAssets = (await libraryResponse.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("data").EnumerateArray().ToArray();
        var libraryAssetIds = libraryAssets
            .Select(asset => Int64(asset, "Id", "id")).ToArray();
        var unauthorizedAssetCount = await connection.ExecuteScalarAsync<int>("""
            SELECT COUNT(*)
            FROM dbo.VideoAssets a
            WHERE a.Id IN @Ids
              AND a.CreatedBy<>2
              AND a.ShareScope<>'SCHOOL'
              AND NOT EXISTS(SELECT 1 FROM dbo.VideoAssetShares s WHERE s.VideoAssetId=a.Id AND s.TeacherId=2)
            """, new { Ids = libraryAssetIds });
        Assert.Equal(0, unauthorizedAssetCount);

        var editableVideoIds = libraryAssets
            .Where(asset => asset.TryGetProperty("CanEdit", out var canEdit) ? canEdit.GetBoolean() : asset.GetProperty("canEdit").GetBoolean())
            .Select(asset => asset.TryGetProperty("FirstVideoId", out var id) ? id : asset.GetProperty("firstVideoId"))
            .Where(id => id.ValueKind is not JsonValueKind.Null)
            .Select(id => id.GetInt64()).ToArray();
        var unauthorizedLibraryLinkCount = await connection.ExecuteScalarAsync<int>("""
            SELECT COUNT(*)
            FROM dbo.Videos v
            JOIN dbo.VideoAssets a ON a.Id=v.VideoAssetId
            WHERE v.Id IN @Ids AND a.CreatedBy<>2
            """, new { Ids = editableVideoIds });
        Assert.Equal(0, unauthorizedLibraryLinkCount);

        var ownedVideoId = editableVideoIds.First();
        var payload = new Dictionary<string, object?>
        {
            ["questionId"] = 1,
            ["timeSeconds"] = 1,
            ["endTimeSeconds"] = null,
            ["interactionType"] = "QUESTION",
            ["required"] = true,
            ["pauseVideo"] = true,
            ["allowSkip"] = false,
            ["score"] = 10,
            ["attemptLimit"] = 1,
            ["sortOrder"] = 99,
            ["status"] = "ACTIVE"
        };
        var createResponse = await _client.PostAsJsonAsync($"/api/videos/{ownedVideoId}/interactions", payload);
        createResponse.EnsureSuccessStatusCode();
        var interactionId = Int64((await createResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("data"), "id", "Id");
        var saveResponse = await _client.PutAsJsonAsync($"/api/video-interactions/{interactionId}", payload);
        Assert.True(saveResponse.IsSuccessStatusCode, await saveResponse.Content.ReadAsStringAsync());

        Assert.Equal(HttpStatusCode.Forbidden, (await _client.GetAsync($"/api/videos/{otherVideoId}")).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await _client.GetAsync($"/api/videos/{otherVideoId}/interactions")).StatusCode);
        (await _client.DeleteAsync($"/api/video-interactions/{interactionId}")).EnsureSuccessStatusCode();
    }

    [Fact]
    public async Task Admin_CanEditEveryVideoAsset_WhileTeacherCannotEditAnotherAuthorsAsset()
    {
        await _factory.Services.GetRequiredService<IDatabaseInitializer>().InitializeAsync();
        var factory = _factory.Services.GetRequiredService<ISqlConnectionFactory>();
        using var connection = factory.CreateConnection();
        var asset = await connection.QuerySingleAsync<(long Id, string Title, string VideoUrl, string? PosterUrl, int DurationSeconds, string? OriginalFileName, long? FileSize, string? MimeType, string Status)>("""
            SELECT TOP(1) Id,Title,VideoUrl,PosterUrl,DurationSeconds,OriginalFileName,FileSize,MimeType,Status
            FROM dbo.VideoAssets
            WHERE IsDeleted=0 AND CreatedBy NOT IN(1,2) AND VideoUrl LIKE '/Media/Video/%'
            ORDER BY Id DESC
            """);
        var updatedTitle = $"{asset.Title} [ADMIN-QA]";
        var payload = new
        {
            title = updatedTitle,
            asset.VideoUrl,
            asset.PosterUrl,
            asset.DurationSeconds,
            asset.OriginalFileName,
            asset.FileSize,
            asset.MimeType,
            asset.Status
        };

        try
        {
            await AuthorizeAs("admin");
            var adminResponse = await _client.PutAsJsonAsync($"/api/video-library/{asset.Id}", payload);
            Assert.True(adminResponse.IsSuccessStatusCode, await adminResponse.Content.ReadAsStringAsync());
            Assert.Equal(updatedTitle, await connection.ExecuteScalarAsync<string>("SELECT Title FROM dbo.VideoAssets WHERE Id=@Id", new { asset.Id }));

            var library = await _client.GetFromJsonAsync<JsonElement>("/api/video-library?pageSize=100");
            var row = library.GetProperty("data").EnumerateArray().Single(item => Int64(item, "Id", "id") == asset.Id);
            Assert.True(Boolean(row, "CanEdit", "canEdit"));

            await AuthorizeAs("teacher");
            var teacherResponse = await _client.PutAsJsonAsync($"/api/video-library/{asset.Id}", payload);
            Assert.Equal(HttpStatusCode.Forbidden, teacherResponse.StatusCode);
        }
        finally
        {
            await connection.ExecuteAsync("UPDATE dbo.VideoAssets SET Title=@Title WHERE Id=@Id", new { asset.Title, asset.Id });
            await connection.ExecuteAsync("UPDATE dbo.Videos SET Title=@Title WHERE VideoAssetId=@Id", new { asset.Title, asset.Id });
            await connection.ExecuteAsync("DELETE dbo.AuditLogs WHERE Module='VIDEO_LIBRARY' AND EntityId=@EntityId AND Action='UPDATE'", new { EntityId = asset.Id.ToString() });
        }
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
    public async Task CmsPreviewAnswer_ScoresWithoutCreatingStudentAnswer()
    {
        await AuthorizeAs("admin");
        await _factory.Services.GetRequiredService<IDatabaseInitializer>().InitializeAsync();
        var factory = _factory.Services.GetRequiredService<ISqlConnectionFactory>();
        using var connection = factory.CreateConnection();
        var row = await connection.QuerySingleAsync<(long InteractionId, long QuestionId)>("SELECT TOP(1) vi.Id InteractionId,vi.QuestionId FROM dbo.VideoInteractions vi WHERE vi.VideoId=1 AND vi.IsDeleted=0 ORDER BY vi.TimeSeconds");
        var before = await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM dbo.StudentAnswers");
        var response = await _client.PostAsJsonAsync("/api/videos/1/preview-answer", new { row.InteractionId, row.QuestionId, answers = new[] { "A" } });
        Assert.True(response.IsSuccessStatusCode, await response.Content.ReadAsStringAsync());
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.GetProperty("success").GetBoolean());
        Assert.Equal(before, await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM dbo.StudentAnswers"));
    }

    [Fact]
    public async Task Player_NonEnrolledCourse_IsNotAccessible()
    {
        await AuthorizeAs("student");
        var response = await _client.GetAsync("/api/lms/lessons/16/player");
        Assert.Contains(response.StatusCode, new[] { HttpStatusCode.Forbidden, HttpStatusCode.NotFound });
    }

    [Fact]
    public async Task StudentLearningEndpoints_ReturnOnlyEnrolledSqlBackedData()
    {
        await AuthorizeAs("student");
        foreach (var path in new[] { "/api/lms/dashboard", "/api/lms/courses", "/api/lms/courses/1", "/api/lms/results", "/api/lms/results/1" })
        {
            var response = await _client.GetAsync(path);
            Assert.True(response.IsSuccessStatusCode, $"{path} returned {(int)response.StatusCode}: {await response.Content.ReadAsStringAsync()}");
            Assert.Contains("\"success\":true", await response.Content.ReadAsStringAsync(), StringComparison.OrdinalIgnoreCase);
        }

        var courses = await _client.GetStringAsync("/api/lms/courses");
        Assert.Contains("VUE3-001", courses, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("AGILE-010", courses, StringComparison.OrdinalIgnoreCase);
        Assert.Equal(HttpStatusCode.NotFound, (await _client.GetAsync("/api/lms/courses/2")).StatusCode);
    }

    [Fact]
    public async Task Answer_RejectsInteractionQuestionMismatch_AndTamperingFields()
    {
        await AuthorizeAs("student");
        var response = await _client.PostAsJsonAsync("/api/lms/answers", new { lessonId = 1, videoId = 1, interactionId = 1, questionId = 2, answers = new[] { "B" }, isCorrect = true, scoreAwarded = 999999 });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Answer_ForVideoLesson_RejectsQuestionWithoutInteraction()
    {
        await AuthorizeAs("student");
        var response = await _client.PostAsJsonAsync("/api/lms/answers", new { lessonId = 1, videoId = 1, interactionId = (long?)null, questionId = 1, answers = new[] { "B" } });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Progress_RejectsVideoFromNonEnrolledCourse()
    {
        var factory = _factory.Services.GetRequiredService<ISqlConnectionFactory>();
        using var connection = factory.CreateConnection();
        var candidate = await connection.QuerySingleAsync<(long LessonId,long VideoId)>("""
            SELECT TOP(1) l.Id LessonId,l.VideoId
            FROM dbo.Lessons l
            WHERE l.VideoId IS NOT NULL AND l.CourseId<>1 AND l.IsDeleted=0
            ORDER BY l.Id
            """);
        await AuthorizeAs("student");
        var response = await _client.PostAsJsonAsync("/api/lms/progress/video", new { lessonId=candidate.LessonId, videoId=candidate.VideoId, currentTime = 10, maxWatchedTime = 10, watchPercent = 2 });
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
    public async Task QuestionValidation_RejectsDuplicateOptionsWithoutPartialQuestion()
    {
        await AuthorizeAs("admin");
        var marker = $"QA duplicate option {Guid.NewGuid():N}";
        var response = await _client.PostAsJsonAsync("/api/questions", new
        {
            questionType = "SINGLE_CHOICE",
            questionText = marker,
            difficulty = "EASY",
            defaultScore = 10,
            status = "ACTIVE",
            options = new[]
            {
                new { optionCode = "A", optionText = "Một", isCorrect = true, sortOrder = 1 },
                new { optionCode = "A", optionText = "Trùng mã", isCorrect = false, sortOrder = 2 }
            },
            answerKeys = Array.Empty<object>()
        });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var search = await _client.GetStringAsync($"/api/questions?search={Uri.EscapeDataString(marker)}&pageSize=10");
        Assert.DoesNotContain(marker, search, StringComparison.Ordinal);
    }

    [Fact]
    public async Task DatabaseSchemaAndDemoSeed_HaveRequiredIntegrity()
    {
        await _factory.Services.GetRequiredService<IDatabaseInitializer>().InitializeAsync();
        var factory = _factory.Services.GetRequiredService<ISqlConnectionFactory>();
        using var connection = factory.CreateConnection();
        var requiredTables = new[]
        {
            "SYS_Users", "SYS_Roles", "SYS_UserRoles", "SYS_Permissions", "SYS_RolePermissions", "SYS_RefreshTokens", "SYS_AuditLogs",
            "SIM_Courses", "SIM_CourseCategories", "SIM_Chapters", "SIM_Lessons", "SIM_Videos", "SIM_VideoAssets", "SIM_VideoAssetShares",
            "LMS_Questions", "LMS_QuestionOptions", "LMS_QuestionAnswerKeys", "LMS_VideoInteractions", "LMS_Enrollments",
            "LMS_StudentVideoProgress", "LMS_StudentLessonProgress", "LMS_StudentAnswers", "LMS_StudentAnswerOptions", "LMS_LearningSessions"
        };
        var existingTables = (await connection.QueryAsync<string>("SELECT name FROM sys.tables WHERE schema_id=SCHEMA_ID('dbo')")).ToHashSet(StringComparer.OrdinalIgnoreCase);
        Assert.Empty(requiredTables.Where(table => !existingTables.Contains(table)));
        Assert.Empty(existingTables.Where(table => !table.StartsWith("SYS_", StringComparison.OrdinalIgnoreCase)
                                                   && !table.StartsWith("SIM_", StringComparison.OrdinalIgnoreCase)
                                                   && !table.StartsWith("LMS_", StringComparison.OrdinalIgnoreCase)));

        Assert.Equal(0, await connection.ExecuteScalarAsync<int>("""
            SELECT COUNT(*) FROM sys.tables t
            JOIN sys.schemas s ON s.schema_id=t.schema_id
            JOIN sys.columns c ON c.object_id=t.object_id
            WHERE s.name='dbo' AND c.name='Id'
            """));
        Assert.Equal(0, await connection.ExecuteScalarAsync<int>("""
            SELECT COUNT(*) FROM sys.tables t
            JOIN sys.schemas s ON s.schema_id=t.schema_id
            JOIN sys.columns c ON c.object_id=t.object_id
            LEFT JOIN sys.extended_properties ep
              ON ep.class=1 AND ep.major_id=t.object_id AND ep.minor_id=c.column_id AND ep.name='MS_Description'
            WHERE s.name='dbo' AND ep.value IS NULL
            """));
        Assert.Equal(0, await connection.ExecuteScalarAsync<int>("""
            SELECT COUNT(*) FROM sys.tables t
            JOIN sys.schemas s ON s.schema_id=t.schema_id
            LEFT JOIN sys.extended_properties ep
              ON ep.class=1 AND ep.major_id=t.object_id AND ep.minor_id=0 AND ep.name='MS_Description'
            WHERE s.name='dbo' AND ep.value IS NULL
            """));
        Assert.True(await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM sys.views WHERE schema_id=SCHEMA_ID('dbo') AND name IN ('Users','Courses','Questions','StudentAnswers')") == 4);

        Assert.True(await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM sys.foreign_keys") >= 15);
        Assert.True(await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM sys.indexes WHERE is_primary_key=0 AND name IS NOT NULL") >= 8);
        Assert.True(await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID('dbo') AND name LIKE 'LMS[_]%'") >= 25);
        Assert.True(await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM dbo.Users") >= 10);
        Assert.True(await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM dbo.Courses") >= 10);
        Assert.True(await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM dbo.Questions WHERE IsDeleted=0") >= 10);
        Assert.Equal(0, await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM dbo.StudentAnswers a JOIN dbo.VideoInteractions vi ON vi.Id=a.InteractionId WHERE a.QuestionId<>vi.QuestionId"));
        Assert.Equal(0, await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM dbo.StudentAnswerOptions sao JOIN dbo.StudentAnswers a ON a.Id=sao.StudentAnswerId JOIN dbo.QuestionOptions qo ON qo.Id=sao.QuestionOptionId WHERE qo.QuestionId<>a.QuestionId"));
    }

    [Fact]
    public async Task ContentCrud_AndReusableVideoLibrary_PersistToSql()
    {
        await AuthorizeAs("admin");
        var marker = $"QA content {Guid.NewGuid():N}";
        long chapterId = 0, lesson1 = 0, lesson2 = 0, video1 = 0, video2 = 0;
        var factory = _factory.Services.GetRequiredService<ISqlConnectionFactory>();
        try
        {
            var library = await _client.GetFromJsonAsync<JsonElement>("/api/video-library");
            var asset = library.GetProperty("data").EnumerateArray().First();
            var assetId = Int64(asset, "Id", "id");
            var reusableVideoId = Int64(asset, "VideoId", "videoId");

            var chapterResponse = await _client.PostAsJsonAsync("/api/courses/1/chapters", new { title = marker, description = "CRUD chapter", sortOrder = 99, status = "ACTIVE" });
            chapterResponse.EnsureSuccessStatusCode();
            chapterId = Int64((await chapterResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("data"), "id", "Id");
            (await _client.PutAsJsonAsync($"/api/chapters/{chapterId}", new { title = marker + " updated", description = "CRUD chapter updated", sortOrder = 98, status = "ACTIVE" })).EnsureSuccessStatusCode();

            async Task<long> CreateLesson(string suffix, int order)
            {
                var response = await _client.PostAsJsonAsync($"/api/chapters/{chapterId}/lessons", new { title = marker + suffix, description = "Reusable video", lessonType = "INTERACTIVE_VIDEO", durationSeconds = 0, sortOrder = order, isRequired = true, passingScore = 0, status = "ACTIVE" });
                response.EnsureSuccessStatusCode();
                return Int64((await response.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("data"), "id", "Id");
            }
            lesson1 = await CreateLesson(" lesson A", 1);
            lesson2 = await CreateLesson(" lesson B", 2);

            async Task<long> Attach(long lessonId)
            {
                var response = await _client.PutAsync($"/api/lessons/{lessonId}/video/{reusableVideoId}", null);
                response.EnsureSuccessStatusCode();
                return Int64((await response.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("data"), "id", "Id");
            }
            video1 = await Attach(lesson1);
            video2 = await Attach(lesson2);
            Assert.Equal(video1, video2);
            Assert.Equal(reusableVideoId, video1);

            var firstVideo = await _client.GetFromJsonAsync<JsonElement>($"/api/videos/{video1}");
            var secondVideo = await _client.GetFromJsonAsync<JsonElement>($"/api/videos/{video2}");
            Assert.Equal(assetId, Int64(firstVideo.GetProperty("data"), "VideoAssetId", "videoAssetId"));
            Assert.Equal(assetId, Int64(secondVideo.GetProperty("data"), "VideoAssetId", "videoAssetId"));
            var content = await _client.GetStringAsync("/api/courses/1/content");
            Assert.Contains(marker + " updated", content, StringComparison.Ordinal);
            Assert.Contains(marker + " lesson A", content, StringComparison.Ordinal);
        }
        finally
        {
            using var connection = factory.CreateConnection();
            if (lesson1 > 0 || lesson2 > 0) await connection.ExecuteAsync("DELETE dbo.Lessons WHERE Id IN @ids", new { ids = new[] { lesson1, lesson2 }.Where(x => x > 0).ToArray() });
            if (chapterId > 0) await connection.ExecuteAsync("DELETE dbo.Chapters WHERE Id=@chapterId", new { chapterId });
            await connection.ExecuteAsync("DELETE dbo.AuditLogs WHERE EntityId IN @ids", new { ids = new[] { chapterId, lesson1, lesson2, video1, video2 }.Where(x => x > 0).Select(x => x.ToString()).ToArray() });
        }
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
        Assert.StartsWith("/Media/Video/", videoUrl, StringComparison.Ordinal);
        Assert.DoesNotContain(":", videoUrl, StringComparison.Ordinal);

        var environment = _factory.Services.GetRequiredService<IWebHostEnvironment>();
        var webRoot = environment.WebRootPath ?? Path.Combine(environment.ContentRootPath, "wwwroot");
        var physicalPath = Path.GetFullPath(Path.Combine(webRoot, videoUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar)));
        var uploadRoot = Path.GetFullPath(Path.Combine(webRoot, "Media", "Video")) + Path.DirectorySeparatorChar;
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
            "/Media/Video/../../lecture.mp4",
            "/Media/Video/2099/01/missing.mp4"
        };
        foreach (var videoUrl in invalidUrls)
        {
            var response = await _client.PutAsJsonAsync("/api/videos/1", new { lessonId = 1, title = "Video validation", videoUrl, durationSeconds = 60, allowSeek = false, allowSpeed = true, requiredWatchPercent = 80, status = "ACTIVE" });
            Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        }
    }

    [Fact]
    public async Task ProjectRuntimeStorage_UsesContentRoot_AndCleansOnlyExpiredRuntimeFiles()
    {
        var storage = _factory.Services.GetRequiredService<LmsCms.Application.Interfaces.IProjectStorageService>();
        var environment = _factory.Services.GetRequiredService<IWebHostEnvironment>();
        var contentRoot = Path.GetFullPath(environment.ContentRootPath) + Path.DirectorySeparatorChar;
        var created = new List<string>();
        try
        {
            foreach (var area in Enum.GetValues<LmsCms.Application.Interfaces.ProjectStorageArea>())
            {
                var stored = await storage.WriteTextAsync(area, $"qa-{area}", ".tmp");
                created.Add(stored.RelativePath);
                var directory = Path.GetFullPath(storage.GetDirectory(area));
                var physical = Path.GetFullPath(Path.Combine(environment.ContentRootPath, stored.RelativePath.Replace('/', Path.DirectorySeparatorChar)));
                Assert.StartsWith(contentRoot, directory + Path.DirectorySeparatorChar, OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal);
                Assert.DoesNotContain($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}", physical, StringComparison.OrdinalIgnoreCase);
                Assert.DoesNotContain($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}", physical, StringComparison.OrdinalIgnoreCase);
                Assert.True(storage.Exists(stored.RelativePath));
            }

            var oldCachePath = Path.GetFullPath(Path.Combine(environment.ContentRootPath, created[0].Replace('/', Path.DirectorySeparatorChar)));
            File.SetLastWriteTimeUtc(oldCachePath, DateTime.UtcNow.AddHours(-25));
            Assert.Equal(1, await storage.CleanupExpiredAsync(LmsCms.Application.Interfaces.ProjectStorageArea.Cache, TimeSpan.FromHours(24)));
            Assert.False(storage.Exists(created[0]));
            created.RemoveAt(0);

            var videoStorage = _factory.Services.GetRequiredService<LmsCms.Application.Interfaces.IVideoStorageService>();
            await using var videoBytes = new MemoryStream("00000018ftypmp42runtime-storage-video"u8.ToArray());
            var video = await videoStorage.SaveAsync(videoBytes, "runtime-storage.mp4", "video/mp4", videoBytes.Length);
            try
            {
                foreach (var area in Enum.GetValues<LmsCms.Application.Interfaces.ProjectStorageArea>())
                    await storage.CleanupExpiredAsync(area, TimeSpan.FromHours(24));
                Assert.True(videoStorage.Exists(video.VideoUrl));
            }
            finally { await videoStorage.DeleteAsync(video.VideoUrl); }
        }
        finally
        {
            foreach (var relativePath in created)
                if (storage.Exists(relativePath)) await storage.DeleteAsync(relativePath);
        }
    }

    [Fact]
    public async Task QuestionAndInteractionUpdates_AreImmediatelyVisibleToPreviewQueries()
    {
        await AuthorizeAs("admin");
        var interactionsResponse = await _client.GetAsync("/api/videos/1/interactions");
        interactionsResponse.EnsureSuccessStatusCode();
        var interactions = (await interactionsResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("data").EnumerateArray().ToArray();
        var interaction = interactions.First();
        var interactionId = Int64(interaction, "Id", "id");
        var questionId = Int64(interaction, "QuestionId", "questionId");
        var originalScore = Decimal(interaction, "Score", "score");

        var questionResponse = await _client.GetAsync($"/api/questions/{questionId}");
        questionResponse.EnsureSuccessStatusCode();
        var questionData = (await questionResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("data");
        var question = Property(questionData, "question", "Question");
        var options = Property(questionData, "options", "Options").EnumerateArray().ToArray();
        var answerKeys = Property(questionData, "answerKeys", "AnswerKeys").EnumerateArray().ToArray();
        var originalQuestionText = String(question, "QuestionText", "questionText")!;

        var marker = $"{originalQuestionText} [QA-{Guid.NewGuid():N}]";

        Dictionary<string, object?> QuestionPayload(string text) => new()
        {
            ["questionType"] = String(question, "QuestionType", "questionType"),
            ["questionText"] = text,
            ["description"] = NullableString(question, "Description", "description"),
            ["explanation"] = NullableString(question, "Explanation", "explanation"),
            ["difficulty"] = String(question, "Difficulty", "difficulty"),
            ["defaultScore"] = Decimal(question, "DefaultScore", "defaultScore"),
            ["shortAnswerMode"] = NullableString(question, "ShortAnswerMode", "shortAnswerMode"),
            ["status"] = String(question, "Status", "status"),
            ["options"] = options.Select((x, index) => new Dictionary<string, object?>
            {
                ["optionCode"] = String(x, "OptionCode", "optionCode"),
                ["optionText"] = String(x, "OptionText", "optionText"),
                ["isCorrect"] = Boolean(x, "IsCorrect", "isCorrect"),
                ["sortOrder"] = Int32(x, "SortOrder", "sortOrder", index + 1)
            }).ToArray(),
            ["answerKeys"] = answerKeys.Select((x, index) => new Dictionary<string, object?>
            {
                ["answerText"] = String(x, "AnswerText", "answerText"),
                ["isCaseSensitive"] = Boolean(x, "IsCaseSensitive", "isCaseSensitive"),
                ["sortOrder"] = Int32(x, "SortOrder", "sortOrder", index + 1)
            }).ToArray()
        };

        Dictionary<string, object?> InteractionPayload(decimal score) => new()
        {
            ["questionId"] = Int64(interaction, "QuestionId", "questionId"),
            ["timeSeconds"] = Int32(interaction, "TimeSeconds", "timeSeconds"),
            ["endTimeSeconds"] = NullableInt32(interaction, "EndTimeSeconds", "endTimeSeconds"),
            ["interactionType"] = String(interaction, "InteractionType", "interactionType"),
            ["required"] = Boolean(interaction, "Required", "required"),
            ["pauseVideo"] = Boolean(interaction, "PauseVideo", "pauseVideo"),
            ["allowSkip"] = Boolean(interaction, "AllowSkip", "allowSkip"),
            ["score"] = score,
            ["attemptLimit"] = Int32(interaction, "AttemptLimit", "attemptLimit", 1),
            ["sortOrder"] = Int32(interaction, "SortOrder", "sortOrder", 1),
            ["status"] = String(interaction, "Status", "status")
        };

        try
        {
            (await _client.PutAsJsonAsync($"/api/questions/{questionId}", QuestionPayload(marker))).EnsureSuccessStatusCode();
            var freshQuestion = await _client.GetFromJsonAsync<JsonElement>($"/api/questions/{questionId}?_fresh=1");
            Assert.Equal(marker, String(Property(freshQuestion.GetProperty("data"), "question", "Question"), "QuestionText", "questionText"));

            var preview = await _client.GetFromJsonAsync<JsonElement>("/api/videos/1/interactions?_fresh=1");
            var previewInteraction = preview.GetProperty("data").EnumerateArray().First(x => Int64(x, "Id", "id") == interactionId);
            Assert.Equal(marker, String(previewInteraction, "QuestionText", "questionText"));

            var changedScore = originalScore + 1;
            (await _client.PutAsJsonAsync($"/api/video-interactions/{interactionId}", InteractionPayload(changedScore))).EnsureSuccessStatusCode();
            preview = await _client.GetFromJsonAsync<JsonElement>("/api/videos/1/interactions?_fresh=2");
            previewInteraction = preview.GetProperty("data").EnumerateArray().First(x => Int64(x, "Id", "id") == interactionId);
            Assert.Equal(changedScore, Decimal(previewInteraction, "Score", "score"));
        }
        finally
        {
            (await _client.PutAsJsonAsync($"/api/video-interactions/{interactionId}", InteractionPayload(originalScore))).EnsureSuccessStatusCode();
            (await _client.PutAsJsonAsync($"/api/questions/{questionId}", QuestionPayload(originalQuestionText))).EnsureSuccessStatusCode();
        }
    }

    private static JsonElement Property(JsonElement source, params string[] names)
    {
        foreach (var name in names) if (source.TryGetProperty(name, out var value)) return value;
        throw new KeyNotFoundException($"Missing JSON property: {string.Join('/', names)}");
    }

    private static string? String(JsonElement source, params string[] names) => Property(source, names).GetString();
    private static string? NullableString(JsonElement source, params string[] names)
    {
        var value = Property(source, names);
        return value.ValueKind is JsonValueKind.Null or JsonValueKind.Undefined ? null : value.GetString();
    }
    private static long Int64(JsonElement source, params string[] names) => Property(source, names).GetInt64();
    private static decimal Decimal(JsonElement source, params string[] names) => Property(source, names).GetDecimal();
    private static bool Boolean(JsonElement source, params string[] names) => Property(source, names).GetBoolean();
    private static int Int32(JsonElement source, string first, string second, int fallback = 0)
    {
        if (source.TryGetProperty(first, out var value) || source.TryGetProperty(second, out value)) return value.GetInt32();
        return fallback;
    }
    private static int? NullableInt32(JsonElement source, params string[] names)
    {
        var value = Property(source, names);
        return value.ValueKind is JsonValueKind.Null or JsonValueKind.Undefined ? null : value.GetInt32();
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
