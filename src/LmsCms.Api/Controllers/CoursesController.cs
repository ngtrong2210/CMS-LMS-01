using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LmsCms.Api.Controllers;

[ApiController, Route("api/courses"), Authorize]
public sealed class CoursesController(ICourseService courses) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResult<CourseListItemDto>>>> GetList([FromQuery] string? search, [FromQuery] string? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page); pageSize = Math.Clamp(pageSize, 1, 100);
        return Ok(ApiResponse<PagedResult<CourseListItemDto>>.Ok(await courses.GetListAsync(search, status, page, pageSize, cancellationToken)));
    }
    [HttpGet("{id:long}")]
    public async Task<ActionResult<ApiResponse<object>>> GetById(long id, CancellationToken cancellationToken)
    {
        var item = await courses.GetByIdAsync(id, cancellationToken);
        return item is null ? NotFound(ApiResponse<object>.Fail("Không tìm thấy khóa học.")) : Ok(ApiResponse<object>.Ok(item));
    }
    [HttpGet("{id:long}/content")]
    public async Task<ActionResult<ApiResponse<object>>> GetContent(long id, CancellationToken cancellationToken) => Ok(ApiResponse<object>.Ok((await courses.GetContentAsync(id, cancellationToken))!));
}
