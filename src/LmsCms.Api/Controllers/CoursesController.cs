using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace LmsCms.Api.Controllers;

[ApiController, Route("api/courses"), Authorize(Roles = "ADMIN,TEACHER")]
public sealed class CoursesController(ICourseService courses) : ControllerBase
{
    private long UserId => long.Parse(User.FindFirstValue("userId")!);
    private bool IsAdmin => User.IsInRole("ADMIN");
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResult<CourseListItemDto>>>> GetList([FromQuery] string? search, [FromQuery] string? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page); pageSize = Math.Clamp(pageSize, 1, 100);
        return Ok(ApiResponse<PagedResult<CourseListItemDto>>.Ok(await courses.GetListAsync(search, status, page, pageSize, UserId, IsAdmin, cancellationToken)));
    }
    [HttpGet("{id:long}")]
    public async Task<ActionResult<ApiResponse<object>>> GetById(long id, CancellationToken cancellationToken)
    {
        var item = await courses.GetByIdAsync(id, UserId, IsAdmin, cancellationToken);
        return item is null ? NotFound(ApiResponse<object>.Fail("Không tìm thấy khóa học.")) : Ok(ApiResponse<object>.Ok(item));
    }
    [HttpGet("{id:long}/content")]
    public async Task<ActionResult<ApiResponse<object>>> GetContent(long id, CancellationToken cancellationToken) => Ok(ApiResponse<object>.Ok((await courses.GetContentAsync(id, UserId, IsAdmin, cancellationToken))!));

    [HttpPost, Authorize(Roles = "ADMIN,TEACHER")]
    public async Task<ActionResult<ApiResponse<object>>> Create(CourseSaveRequest request, CancellationToken cancellationToken)
    {
        if (!IsAdmin && request.TeacherId != UserId) return Forbid();
        var id = await courses.CreateAsync(request, UserId, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id }, ApiResponse<object>.Ok(new { id }, "Tạo khóa học thành công."));
    }

    [HttpPut("{id:long}"), Authorize(Roles = "ADMIN,TEACHER")]
    public async Task<ActionResult<ApiResponse<object>>> Update(long id, CourseSaveRequest request, CancellationToken cancellationToken)
    {
        if (!IsAdmin && request.TeacherId != UserId) return Forbid();
        return await courses.UpdateAsync(id, request, UserId, IsAdmin, cancellationToken)
            ? Ok(ApiResponse<object>.Ok(new { id }, "Cập nhật khóa học thành công."))
            : NotFound(ApiResponse<object>.Fail("Không tìm thấy khóa học."));
    }

    [HttpPost("{id:long}/publish"), Authorize(Roles = "ADMIN,TEACHER")]
    public Task<ActionResult<ApiResponse<object>>> Publish(long id, CancellationToken cancellationToken) => ChangeStatus(id, "PUBLISHED", cancellationToken);

    [HttpPost("{id:long}/archive"), Authorize(Roles = "ADMIN,TEACHER")]
    public Task<ActionResult<ApiResponse<object>>> Archive(long id, CancellationToken cancellationToken) => ChangeStatus(id, "ARCHIVED", cancellationToken);

    [HttpDelete("{id:long}"), Authorize(Roles = "ADMIN,TEACHER")]
    public async Task<ActionResult<ApiResponse<object>>> Delete(long id, CancellationToken cancellationToken) =>
        await courses.DeleteAsync(id, UserId, IsAdmin, cancellationToken)
            ? Ok(ApiResponse<object>.Ok(new { id }, "Xóa khóa học thành công."))
            : NotFound(ApiResponse<object>.Fail("Không tìm thấy khóa học."));

    private async Task<ActionResult<ApiResponse<object>>> ChangeStatus(long id, string status, CancellationToken cancellationToken) =>
        await courses.ChangeStatusAsync(id, status, UserId, IsAdmin, cancellationToken)
            ? Ok(ApiResponse<object>.Ok(new { id, status }, "Cập nhật trạng thái thành công."))
            : NotFound(ApiResponse<object>.Fail("Không tìm thấy khóa học."));
}
