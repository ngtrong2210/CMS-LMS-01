using System.Security.Claims;
using SimsObject.Common;
using SimsObject.DTOs;
using SimsObject.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Sims.Api.Controllers;

[ApiController, Route("api/academic"), Authorize(Roles = "ADMIN,TEACHER")]
public sealed class AcademicController(IAcademicService academic) : ControllerBase
{
    private long UserId => long.Parse(User.FindFirstValue("userId")!);
    private bool IsAdmin => User.IsInRole("ADMIN");

    [HttpGet("catalog")]
    public async Task<ActionResult<ApiResponse<object>>> GetCatalog(CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(await academic.GetCatalogAsync(UserId, IsAdmin, cancellationToken)));

    [HttpPost("catalog"), Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<ApiResponse<object>>> Save(AcademicCatalogSaveRequest request, CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(await academic.SaveAsync(request, UserId, cancellationToken), "Đã lưu danh mục đào tạo."));

    [HttpPost("classes/students"), Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<ApiResponse<object>>> AssignStudents(AssignStudentsToClassRequest request, CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(await academic.AssignStudentsToClassAsync(request, UserId, cancellationToken), "Đã phân học viên vào lớp và đồng bộ môn học."));

    [HttpPost("class-subjects/{classSubjectId:long}/workspace")]
    public async Task<ActionResult<ApiResponse<object>>> EnsureWorkspace(long classSubjectId, CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(
            await academic.EnsureClassSubjectWorkspaceAsync(classSubjectId, UserId, IsAdmin, cancellationToken),
            "Đã sẵn sàng không gian soạn bài cho môn học lớp."));
}
