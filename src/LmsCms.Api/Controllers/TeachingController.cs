using System.Security.Claims;
using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LmsCms.Api.Controllers;

[ApiController, Route("api/teaching"), Authorize(Roles = "ADMIN,TEACHER")]
public sealed class TeachingController(ITeachingService teaching) : ControllerBase
{
    private long UserId => long.Parse(User.FindFirstValue("userId")!);
    private bool IsAdmin => User.IsInRole("ADMIN");

    [HttpGet("assignment-submissions")]
    public async Task<ActionResult<ApiResponse<PagedResult<object>>>> GetAssignmentSubmissions(
        [FromQuery] long? classSubjectId,
        [FromQuery] string? status,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default) =>
        Ok(ApiResponse<PagedResult<object>>.Ok(await teaching.GetAssignmentSubmissionsAsync(classSubjectId, status, search, page, pageSize, UserId, IsAdmin, cancellationToken)));

    [HttpPut("assignment-submissions/{assignmentSubmissionId:long}/grade")]
    public async Task<ActionResult<ApiResponse<object>>> Grade(
        long assignmentSubmissionId,
        AssignmentGradeRequest request,
        CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(
            await teaching.GradeAssignmentSubmissionAsync(assignmentSubmissionId, request, UserId, IsAdmin, cancellationToken),
            request.Action == "RETURN" ? "Đã trả bài để học viên bổ sung." : "Đã lưu điểm và nhận xét."));
}
