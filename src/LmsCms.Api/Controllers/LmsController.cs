using System.Security.Claims;
using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LmsCms.Api.Controllers;

[ApiController, Route("api/lms"), Authorize(Roles = "STUDENT")]
public sealed class LmsController(ILearningService learning, IAssignmentStorageService assignmentStorage) : ControllerBase
{
    private long UserId => long.Parse(User.FindFirstValue("userId")!);
    [HttpGet("dashboard")]
    public async Task<ActionResult<ApiResponse<object>>> GetDashboard(CancellationToken cancellationToken) => Ok(ApiResponse<object>.Ok(await learning.GetDashboardAsync(UserId, cancellationToken)));
    [HttpGet("courses")]
    public async Task<ActionResult<ApiResponse<IReadOnlyCollection<object>>>> GetCourses(CancellationToken cancellationToken) => Ok(ApiResponse<IReadOnlyCollection<object>>.Ok(await learning.GetCoursesAsync(UserId, cancellationToken)));
    [HttpGet("courses/{courseId:long}")]
    public async Task<ActionResult<ApiResponse<object>>> GetCourse(long courseId, CancellationToken cancellationToken)
    {
        var data = await learning.GetCourseAsync(courseId, UserId, cancellationToken);
        return data is null ? NotFound(ApiResponse<object>.Fail("Không tìm thấy môn học hoặc bạn chưa được ghi danh.")) : Ok(ApiResponse<object>.Ok(data));
    }
    [HttpGet("results")]
    public async Task<ActionResult<ApiResponse<object>>> GetResults(CancellationToken cancellationToken) => Ok(ApiResponse<object>.Ok(await learning.GetResultsAsync(UserId, null, cancellationToken)));
    [HttpGet("results/{courseId:long}")]
    public async Task<ActionResult<ApiResponse<object>>> GetCourseResults(long courseId, CancellationToken cancellationToken) => Ok(ApiResponse<object>.Ok(await learning.GetResultsAsync(UserId, courseId, cancellationToken)));
    [HttpGet("lessons/{lessonId:long}/player")]
    public async Task<ActionResult<ApiResponse<PlayerDataDto>>> GetPlayer(long lessonId, CancellationToken cancellationToken)
    {
        var data = await learning.GetPlayerAsync(lessonId, UserId, cancellationToken);
        return data is null ? NotFound(ApiResponse<PlayerDataDto>.Fail("Không tìm thấy bài học hoặc bạn chưa được ghi danh.")) : Ok(ApiResponse<PlayerDataDto>.Ok(data));
    }
    [HttpPost("progress/video")]
    public async Task<ActionResult<ApiResponse<object>>> SaveProgress(VideoProgressRequest request, CancellationToken cancellationToken)
    {
        await learning.SaveVideoProgressAsync(UserId, request, cancellationToken);
        return Ok(ApiResponse<object>.Ok(new { }, "Đã lưu tiến độ."));
    }
    [HttpPost("answers")]
    public async Task<ActionResult<ApiResponse<AnswerResultDto>>> SubmitAnswer(SubmitAnswerRequest request, CancellationToken cancellationToken) => Ok(ApiResponse<AnswerResultDto>.Ok(await learning.SubmitAnswerAsync(UserId, request, cancellationToken)));

    [HttpGet("lessons/{lessonId:long}/interactive-content")]
    public async Task<ActionResult<ApiResponse<object>>> GetInteractiveContent(long lessonId, CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(await learning.GetInteractiveContentAsync(lessonId, UserId, cancellationToken)));

    [HttpPost("lessons/{lessonId:long}/interactive-content/answers")]
    public async Task<ActionResult<ApiResponse<AnswerResultDto>>> SubmitInteractiveContentAnswer(long lessonId, InteractiveContentAnswerRequest request, CancellationToken cancellationToken) =>
        Ok(ApiResponse<AnswerResultDto>.Ok(await learning.SubmitInteractiveContentAnswerAsync(lessonId, UserId, request, cancellationToken)));

    [HttpPut("lessons/{lessonId:long}/interactive-content/reading-progress")]
    public async Task<ActionResult<ApiResponse<object>>> SaveInteractiveReadingProgress(long lessonId, InteractiveReadingProgressRequest request, CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(await learning.SaveInteractiveReadingProgressAsync(lessonId, UserId, request, cancellationToken), "Đã lưu vị trí đọc."));

    [HttpPost("lessons/{lessonId:long}/interactive-content/complete")]
    public async Task<ActionResult<ApiResponse<object>>> CompleteInteractiveContent(long lessonId, CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(await learning.CompleteInteractiveContentAsync(lessonId, UserId, cancellationToken)));

    [HttpPost("study-sessions")]
    public async Task<ActionResult<ApiResponse<object>>> StartStudySession(StudySessionStartRequest request, CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(await learning.StartStudySessionAsync(UserId, request, cancellationToken)));

    [HttpPut("study-sessions/{studySessionId:guid}/heartbeat")]
    public async Task<ActionResult<ApiResponse<object>>> HeartbeatStudySession(Guid studySessionId, CancellationToken cancellationToken)
    {
        var data = await learning.HeartbeatStudySessionAsync(studySessionId, UserId, cancellationToken);
        return data is null ? NotFound(ApiResponse<object>.Fail("Phiên học không còn hoạt động.")) : Ok(ApiResponse<object>.Ok(data));
    }

    [HttpPost("study-sessions/{studySessionId:guid}/end")]
    public async Task<ActionResult<ApiResponse<object>>> EndStudySession(Guid studySessionId, StudySessionEndRequest request, CancellationToken cancellationToken)
    {
        var data = await learning.EndStudySessionAsync(studySessionId, UserId, request.IsCompleted, cancellationToken);
        return data is null ? NotFound(ApiResponse<object>.Fail("Không tìm thấy phiên học.")) : Ok(ApiResponse<object>.Ok(data));
    }

    [HttpGet("lessons/{lessonId:long}/submissions")]
    public async Task<ActionResult<ApiResponse<IReadOnlyCollection<object>>>> GetAssignmentSubmissions(long lessonId, CancellationToken cancellationToken) =>
        Ok(ApiResponse<IReadOnlyCollection<object>>.Ok(await learning.GetAssignmentSubmissionsAsync(lessonId, UserId, cancellationToken)));

    [HttpPost("lessons/{lessonId:long}/submissions")]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<ApiResponse<object>>> SubmitAssignment(long lessonId, [FromForm] string? submissionText, [FromForm] IFormFile? file, CancellationToken cancellationToken)
    {
        var maximumFileSizeMb = await learning.ValidateAssignmentAsync(lessonId, UserId, "SUBMIT", cancellationToken);
        if (file is not null && file.Length > maximumFileSizeMb * 1024L * 1024L)
            return BadRequest(ApiResponse<object>.Fail($"File bài làm vượt quá giới hạn {maximumFileSizeMb} MB."));

        AssignmentSubmissionFile? stored = null;
        if (file is not null)
        {
            await using var stream = file.OpenReadStream();
            stored = await assignmentStorage.SaveStudentSubmissionAsync(lessonId, UserId, stream, file.FileName, file.ContentType, file.Length, cancellationToken);
        }

        return Ok(ApiResponse<object>.Ok(await learning.SubmitAssignmentAsync(lessonId, UserId, submissionText, stored, cancellationToken), "Đã nộp bài tập."));
    }

    [HttpPut("lessons/{lessonId:long}/submission-draft")]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<ApiResponse<object>>> SaveAssignmentDraft(long lessonId, [FromForm] string? submissionText, [FromForm] IFormFile? file, CancellationToken cancellationToken)
    {
        var maximumFileSizeMb = await learning.ValidateAssignmentAsync(lessonId, UserId, "DRAFT", cancellationToken);
        if (file is not null && file.Length > maximumFileSizeMb * 1024L * 1024L)
            return BadRequest(ApiResponse<object>.Fail($"File bài làm vượt quá giới hạn {maximumFileSizeMb} MB."));

        AssignmentSubmissionFile? stored = null;
        if (file is not null)
        {
            await using var stream = file.OpenReadStream();
            stored = await assignmentStorage.SaveStudentSubmissionAsync(lessonId, UserId, stream, file.FileName, file.ContentType, file.Length, cancellationToken);
        }

        return Ok(ApiResponse<object>.Ok(await learning.SaveAssignmentDraftAsync(lessonId, UserId, submissionText, stored, cancellationToken), "Đã lưu nháp bài làm."));
    }
}
