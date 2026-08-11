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
