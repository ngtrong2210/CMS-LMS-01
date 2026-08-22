using System.Security.Claims;
using SimsObject.Common;
using SimsObject.DTOs;
using SimsObject.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Sims.Api.Controllers;

[ApiController]
[Route("api/notifications")]
[Authorize]
public sealed class NotificationsController(INotificationService notifications) : ControllerBase
{
    private long UserId => long.Parse(User.FindFirstValue("userId")!);

    [HttpGet]
    public async Task<ActionResult<ApiResponse<NotificationFeedDto>>> Get(
        [FromQuery] int limit = 20,
        [FromQuery] bool unreadOnly = false,
        CancellationToken cancellationToken = default)
    {
        var feed = await notifications.GetAsync(UserId, Math.Clamp(limit, 1, 100), unreadOnly, cancellationToken);
        return Ok(ApiResponse<NotificationFeedDto>.Ok(feed));
    }

    [HttpPut("{id:long}/read")]
    public async Task<ActionResult<ApiResponse<object>>> MarkRead(long id, CancellationToken cancellationToken = default)
    {
        var updated = await notifications.MarkReadAsync(id, UserId, cancellationToken);
        return updated
            ? Ok(ApiResponse<object>.Ok(new { id }))
            : NotFound(ApiResponse<object>.Fail("Không tìm thấy thông báo."));
    }

    [HttpPut("read-all")]
    public async Task<ActionResult<ApiResponse<object>>> MarkAllRead(CancellationToken cancellationToken = default)
    {
        var updatedCount = await notifications.MarkAllReadAsync(UserId, cancellationToken);
        return Ok(ApiResponse<object>.Ok(new { updatedCount }));
    }
}
