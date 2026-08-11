using System.Security.Claims;using LmsCms.Application.Common;using LmsCms.Application.DTOs;using LmsCms.Application.Interfaces;using Microsoft.AspNetCore.Authorization;using Microsoft.AspNetCore.Mvc;
namespace LmsCms.Api.Controllers;
[ApiController,Route("api/cms"),Authorize(Roles="ADMIN,TEACHER")]
public sealed class StudentsController(IStudentService students):ControllerBase
{
 private long UserId=>long.Parse(User.FindFirstValue("userId")!);
 [HttpGet("students")] public async Task<ActionResult<ApiResponse<PagedResult<object>>>> List(string? search,string? status,int page=1,int pageSize=20,CancellationToken ct=default)=>Ok(ApiResponse<PagedResult<object>>.Ok(await students.GetStudentsAsync(search,status,Math.Max(page,1),Math.Clamp(pageSize,1,100),ct)));
 [HttpGet("students/{id:long}")] public async Task<ActionResult<ApiResponse<object>>> Get(long id,CancellationToken ct){var x=await students.GetStudentAsync(id,ct);return x is null?NotFound(ApiResponse<object>.Fail("Không tìm thấy học viên.")):Ok(ApiResponse<object>.Ok(x));}
 [HttpGet("enrollments")] public async Task<ActionResult<ApiResponse<PagedResult<object>>>> Enrollments(int page=1,int pageSize=20,CancellationToken ct=default)=>Ok(ApiResponse<PagedResult<object>>.Ok(await students.GetEnrollmentsAsync(Math.Max(page,1),Math.Clamp(pageSize,1,100),ct)));
 [HttpPost("enrollments")] public async Task<ActionResult<ApiResponse<object>>> Enroll(EnrollmentCreateRequest r,CancellationToken ct){var id=await students.EnrollAsync(r,UserId,ct);return Ok(ApiResponse<object>.Ok(new{id}));}
 [HttpDelete("enrollments/{id:long}")] public async Task<ActionResult<ApiResponse<object>>> Cancel(long id,CancellationToken ct)=>await students.CancelEnrollmentAsync(id,UserId,ct)?Ok(ApiResponse<object>.Ok(new{id})):NotFound(ApiResponse<object>.Fail("Không tìm thấy ghi danh."));
 [HttpGet("settings"),Authorize(Roles="ADMIN")] public ActionResult<ApiResponse<object>> Settings()=>Ok(ApiResponse<object>.Ok(new{dataMode="api",autoInitialize=false}));
}
