using System.Security.Claims;
using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LmsCms.Api.Controllers;

[ApiController]
[Authorize(Roles = "STUDENT,TEACHER,ADMIN")]
public sealed class LessonCommentsController(ILessonCommentService lessonComments) : ControllerBase
{
    private long UserId => long.Parse(User.FindFirstValue("userId")!);
    private bool IsAdmin => User.IsInRole("ADMIN");
    private bool IsTeacher => User.IsInRole("TEACHER");

    [HttpGet("api/lms/lessons/{lessonId:long}/comments")]
    public async Task<ActionResult<ApiResponse<LessonCommentFeedDto>>> GetByLesson(
        long lessonId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var feed = await lessonComments.GetByLessonAsync(lessonId, UserId, IsAdmin, IsTeacher, page, pageSize, cancellationToken);
        return Ok(ApiResponse<LessonCommentFeedDto>.Ok(feed));
    }

    [HttpPost("api/lms/lessons/{lessonId:long}/comments")]
    public async Task<ActionResult<ApiResponse<object>>> Create(
        long lessonId,
        LessonCommentCreateRequest request,
        CancellationToken cancellationToken = default)
    {
        var lessonCommentId = await lessonComments.CreateAsync(lessonId, request, UserId, IsAdmin, IsTeacher, cancellationToken);
        return Ok(ApiResponse<object>.Ok(new { lessonCommentId }, "Đã đăng bình luận."));
    }

    [HttpPut("api/lms/comments/{lessonCommentId:long}")]
    public async Task<ActionResult<ApiResponse<object>>> Update(
        long lessonCommentId,
        LessonCommentUpdateRequest request,
        CancellationToken cancellationToken = default)
    {
        await lessonComments.UpdateAsync(lessonCommentId, request, UserId, cancellationToken);
        return Ok(ApiResponse<object>.Ok(new { lessonCommentId }, "Đã cập nhật bình luận."));
    }

    [HttpDelete("api/lms/comments/{lessonCommentId:long}")]
    public async Task<ActionResult<ApiResponse<object>>> Delete(long lessonCommentId, CancellationToken cancellationToken = default)
    {
        await lessonComments.DeleteAsync(lessonCommentId, UserId, IsAdmin, IsTeacher, cancellationToken);
        return Ok(ApiResponse<object>.Ok(new { lessonCommentId }, "Đã xóa bình luận."));
    }
}
