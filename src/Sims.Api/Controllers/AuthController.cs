using System.Security.Claims;
using SimsObject.Common;
using SimsObject.DTOs;
using SimsObject.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Sims.Api.Controllers;

[ApiController, Route("api/auth")]
public sealed class AuthController(IAuthService authService) : ControllerBase
{
    [HttpPost("login"), AllowAnonymous]
    public async Task<ActionResult<ApiResponse<AuthResponse>>> Login(LoginRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password)) return BadRequest(ApiResponse<AuthResponse>.Fail("Vui lòng nhập đầy đủ thông tin."));
        var result = await authService.LoginAsync(request, HttpContext.Connection.RemoteIpAddress?.ToString(), cancellationToken);
        return result is null ? Unauthorized(ApiResponse<AuthResponse>.Fail("Tên đăng nhập hoặc mật khẩu không đúng.")) : Ok(ApiResponse<AuthResponse>.Ok(result));
    }

    [HttpGet("me"), Authorize]
    public async Task<ActionResult<ApiResponse<UserDto>>> Me(CancellationToken cancellationToken)
    {
        var id = long.Parse(User.FindFirstValue("userId")!);
        var user = await authService.GetCurrentUserAsync(id, cancellationToken);
        return user is null ? NotFound(ApiResponse<UserDto>.Fail("Không tìm thấy người dùng.")) : Ok(ApiResponse<UserDto>.Ok(user));
    }

    [HttpPost("logout"), Authorize]
    public ActionResult<ApiResponse<object>> Logout() => Ok(ApiResponse<object>.Ok(new { }, "Đăng xuất thành công."));
}
