using System.Data;
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

public sealed class SecurityTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public SecurityTests(WebApplicationFactory<Program> factory)
    {
        var apiContentRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "..", "src", "LmsCms.Api"));
        _factory = factory.WithWebHostBuilder(builder => builder.UseContentRoot(apiContentRoot));
        _client = _factory.CreateClient(new WebApplicationFactoryClientOptions { AllowAutoRedirect = false });
    }

    [Theory]
    [InlineData("' OR '1'='1")]
    [InlineData("'; SELECT 1; --")]
    public async Task Login_InjectionPayload_DoesNotBypassAuthentication(string payload)
    {
        await _factory.Services.GetRequiredService<IDatabaseInitializer>().InitializeAsync();

        var response = await _client.PostAsJsonAsync("/api/auth/login", new { username = payload, password = payload });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.DoesNotContain("SQL Server", body, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("stored procedure", body, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("SqlException", body, StringComparison.OrdinalIgnoreCase);
    }

    [Theory]
    [InlineData("O'Brien")]
    [InlineData("' OR '1'='1")]
    [InlineData("'; SELECT 1; --")]
    [InlineData("%%")]
    public async Task SearchAndAssignmentFilter_TreatPayloadAsLiteralData(string payload)
    {
        await _factory.Services.GetRequiredService<IDatabaseInitializer>().InitializeAsync();
        await AuthorizeAs("admin");

        var encoded = Uri.EscapeDataString(payload);
        var globalSearch = await _client.GetAsync($"/api/cms/search?q={encoded}");
        var courseSearch = await _client.GetAsync($"/api/courses?search={encoded}&page=1&pageSize=1000000");
        var assignmentSearch = await _client.GetAsync($"/api/teaching/assignment-submissions?search={encoded}");

        globalSearch.EnsureSuccessStatusCode();
        courseSearch.EnsureSuccessStatusCode();
        assignmentSearch.EnsureSuccessStatusCode();
        Assert.DoesNotContain("SQL Server", await globalSearch.Content.ReadAsStringAsync(), StringComparison.OrdinalIgnoreCase);

        var courses = await courseSearch.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(100, courses.GetProperty("data").GetProperty("pageSize").GetInt32());
        if (payload == "%%")
        {
            var globalData = await globalSearch.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Empty(globalData.GetProperty("data").EnumerateArray());
            Assert.Empty(courses.GetProperty("data").GetProperty("items").EnumerateArray());
        }
    }

    [Fact]
    public async Task NumericRouteIds_MustBePositive()
    {
        await _factory.Services.GetRequiredService<IDatabaseInitializer>().InitializeAsync();
        await AuthorizeAs("admin");

        var response = await _client.GetAsync("/api/questions/0");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Contains("lớn hơn 0", await response.Content.ReadAsStringAsync(), StringComparison.OrdinalIgnoreCase);
    }

    [Theory]
    [InlineData("Hôm nay em học phần 'JOIN' trong SQL.")]
    [InlineData("' OR '1'='1")]
    [InlineData("'; SELECT 1; --")]
    public async Task LessonComment_SpecialCharactersAreStoredAsData(string content)
    {
        await _factory.Services.GetRequiredService<IDatabaseInitializer>().InitializeAsync();
        var connectionFactory = _factory.Services.GetRequiredService<ISqlConnectionFactory>();
        using var connection = connectionFactory.CreateConnection();
        var lessonId = await connection.QuerySingleAsync<long>("""
            Select Top (1)
                dbo.SIM_Lessons.LessonID
            From dbo.SIM_Lessons
            Inner Join dbo.LMS_Enrollments On dbo.LMS_Enrollments.CourseID = dbo.SIM_Lessons.CourseID
            Inner Join dbo.SYS_Users On dbo.SYS_Users.UserID = dbo.LMS_Enrollments.StudentUserID
            Where (dbo.SYS_Users.Username = 'student')
                And (dbo.LMS_Enrollments.Status <> 'CANCELLED')
                And (dbo.SIM_Lessons.IsDeleted = 0)
            Order By dbo.SIM_Lessons.LessonID
            """);

        await AuthorizeAs("student");
        var create = await _client.PostAsJsonAsync($"/api/lms/lessons/{lessonId}/comments", new { content });
        create.EnsureSuccessStatusCode();
        var created = await create.Content.ReadFromJsonAsync<JsonElement>();
        var commentId = created.GetProperty("data").GetProperty("lessonCommentId").GetInt64();

        try
        {
            var storedContent = await connection.ExecuteScalarAsync<string>(
                "Select Content From dbo.LMS_LessonComments Where LessonCommentID = @CommentID",
                new { CommentID = commentId });
            Assert.Equal(content, storedContent);
        }
        finally
        {
            (await _client.DeleteAsync($"/api/lms/comments/{commentId}")).EnsureSuccessStatusCode();
        }
    }

    [Fact]
    public async Task Teacher_CannotModifyAnotherTeachersQuestion()
    {
        await _factory.Services.GetRequiredService<IDatabaseInitializer>().InitializeAsync();
        var connectionFactory = _factory.Services.GetRequiredService<ISqlConnectionFactory>();
        using var connection = connectionFactory.CreateConnection();
        var questionId = await connection.QuerySingleAsync<long>("""
            Select Top (1)
                dbo.LMS_Questions.QuestionID
            From dbo.LMS_Questions
            Inner Join dbo.SYS_Users On dbo.SYS_Users.UserID = dbo.LMS_Questions.CreatedByUserID
            Where (dbo.SYS_Users.Username <> 'teacher')
                And (dbo.LMS_Questions.IsDeleted = 0)
            Order By dbo.LMS_Questions.QuestionID
            """);

        await AuthorizeAs("teacher");
        var response = await _client.DeleteAsync($"/api/questions/{questionId}");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Equal(0, await connection.ExecuteScalarAsync<int>(
            "Select Count(*) From dbo.LMS_Questions Where QuestionID = @QuestionID And IsDeleted = 1",
            new { QuestionID = questionId }));
    }

    private async Task AuthorizeAs(string username)
    {
        _client.DefaultRequestHeaders.Authorization = null;
        var response = await _client.PostAsJsonAsync("/api/auth/login", new { username, password = "123456" });
        response.EnsureSuccessStatusCode();
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            "Bearer",
            json.GetProperty("data").GetProperty("accessToken").GetString());
    }
}
