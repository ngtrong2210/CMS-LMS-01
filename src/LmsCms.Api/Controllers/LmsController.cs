using System.Security.Claims;
using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LmsCms.Api.Controllers;

[ApiController, Route("api/lms"), Authorize(Roles = "STUDENT")]
public sealed class LmsController(ILearningService learning) : ControllerBase
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
        return data is null ? NotFound(ApiResponse<object>.Fail("Không tìm thấy khóa học hoặc bạn chưa được ghi danh.")) : Ok(ApiResponse<object>.Ok(data));
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
}
