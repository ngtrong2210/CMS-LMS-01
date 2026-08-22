using System.Security.Claims;
using SimsObject.Common;
using SimsObject.DTOs;
using SimsObject.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Sims.Api.Controllers;

[ApiController, Route("api/cms/system"), Authorize(Roles = "ADMIN")]
public sealed class SystemAdministrationController(ISystemAdministrationService systemAdministration) : ControllerBase
{
    private long UserId => long.Parse(User.FindFirstValue("userId")!);

    [HttpGet("users")]
    public async Task<ActionResult<ApiResponse<PagedResult<object>>>> GetUsers(
        [FromQuery] string? search,
        [FromQuery] string? roleCode,
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var result = await systemAdministration.GetUsersAsync(
            search,
            roleCode,
            status,
            Math.Max(1, page),
            Math.Clamp(pageSize, 1, 100),
            cancellationToken);
        return Ok(ApiResponse<PagedResult<object>>.Ok(result));
    }

    [HttpGet("users/{userId:long}")]
    public async Task<ActionResult<ApiResponse<object>>> GetUser(long userId, CancellationToken cancellationToken)
    {
        var result = await systemAdministration.GetUserAsync(userId, cancellationToken);
        return result is null
            ? NotFound(ApiResponse<object>.Fail("Không tìm thấy người dùng."))
            : Ok(ApiResponse<object>.Ok(result));
    }

    [HttpPost("users")]
    public async Task<ActionResult<ApiResponse<object>>> CreateUser(UserSaveRequest request, CancellationToken cancellationToken)
    {
        var userId = await systemAdministration.CreateUserAsync(request, UserId, cancellationToken);
        return CreatedAtAction(nameof(GetUser), new { userId }, ApiResponse<object>.Ok(new { userId }, "Đã tạo người dùng."));
    }

    [HttpPut("users/{userId:long}")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateUser(long userId, UserSaveRequest request, CancellationToken cancellationToken)
    {
        return await systemAdministration.UpdateUserAsync(userId, request, UserId, cancellationToken)
            ? Ok(ApiResponse<object>.Ok(new { userId }, "Đã cập nhật người dùng."))
            : NotFound(ApiResponse<object>.Fail("Không tìm thấy người dùng."));
    }

    [HttpPatch("users/{userId:long}/status")]
    public async Task<ActionResult<ApiResponse<object>>> SetUserStatus(long userId, UserStatusRequest request, CancellationToken cancellationToken)
    {
        return await systemAdministration.SetUserStatusAsync(userId, request.Status, UserId, cancellationToken)
            ? Ok(ApiResponse<object>.Ok(new { userId, request.Status }, "Đã cập nhật trạng thái tài khoản."))
            : NotFound(ApiResponse<object>.Fail("Không tìm thấy người dùng."));
    }

    [HttpGet("roles")]
    public async Task<ActionResult<ApiResponse<IReadOnlyCollection<object>>>> GetRoles(CancellationToken cancellationToken) =>
        Ok(ApiResponse<IReadOnlyCollection<object>>.Ok(await systemAdministration.GetRolesAsync(cancellationToken)));

    [HttpGet("roles/{roleId:long}/permissions")]
    public async Task<ActionResult<ApiResponse<IReadOnlyCollection<object>>>> GetRolePermissions(long roleId, CancellationToken cancellationToken) =>
        Ok(ApiResponse<IReadOnlyCollection<object>>.Ok(await systemAdministration.GetRolePermissionsAsync(roleId, cancellationToken)));

    [HttpPut("roles/{roleId:long}/permissions")]
    public async Task<ActionResult<ApiResponse<object>>> SaveRolePermissions(long roleId, RolePermissionsSaveRequest request, CancellationToken cancellationToken)
    {
        return await systemAdministration.SaveRolePermissionsAsync(roleId, request, UserId, cancellationToken)
            ? Ok(ApiResponse<object>.Ok(new { roleId }, "Đã lưu phân quyền."))
            : NotFound(ApiResponse<object>.Fail("Không tìm thấy vai trò."));
    }

    [HttpGet("settings")]
    public async Task<ActionResult<ApiResponse<IReadOnlyCollection<object>>>> GetSettings(CancellationToken cancellationToken) =>
        Ok(ApiResponse<IReadOnlyCollection<object>>.Ok(await systemAdministration.GetSettingsAsync(cancellationToken)));

    [HttpPut("settings")]
    public async Task<ActionResult<ApiResponse<object>>> SaveSettings(SystemSettingsSaveRequest request, CancellationToken cancellationToken)
    {
        var updated = await systemAdministration.SaveSettingsAsync(request, UserId, cancellationToken);
        return Ok(ApiResponse<object>.Ok(new { updated }, "Đã lưu cài đặt hệ thống."));
    }
}
