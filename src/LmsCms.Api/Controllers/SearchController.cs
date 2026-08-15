using System.Security.Claims;
using LmsCms.Application.Common;
using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LmsCms.Api.Controllers;

[ApiController, Route("api/cms/search"), Authorize(Roles = "ADMIN,TEACHER")]
public sealed class SearchController(ISearchService search) : ControllerBase
{
    private long UserId => long.Parse(User.FindFirstValue("userId")!);
    private bool IsAdmin => User.IsInRole("ADMIN");

    [HttpGet]
    public async Task<ActionResult<ApiResponse<IReadOnlyCollection<object>>>> Search(
        [FromQuery] string? q,
        [FromQuery] int limit = 60,
        CancellationToken cancellationToken = default)
    {
        var term = q?.Trim() ?? string.Empty;
        if (term.Length is > 0 and < 2)
            return BadRequest(ApiResponse<IReadOnlyCollection<object>>.Fail("Từ khóa tìm kiếm cần ít nhất 2 ký tự."));

        var results = term.Length == 0
            ? Array.Empty<object>()
            : await search.SearchAsync(term, UserId, IsAdmin, Math.Clamp(limit, 1, 100), cancellationToken);
        return Ok(ApiResponse<IReadOnlyCollection<object>>.Ok(results));
    }
}
