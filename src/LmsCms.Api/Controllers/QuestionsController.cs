using System.Security.Claims;using LmsCms.Application.Common;using LmsCms.Application.DTOs;using LmsCms.Application.Interfaces;using Microsoft.AspNetCore.Authorization;using Microsoft.AspNetCore.Mvc;
namespace LmsCms.Api.Controllers;
[ApiController,Route("api/questions"),Authorize(Roles="ADMIN,TEACHER")]
public sealed class QuestionsController(IQuestionService questions):ControllerBase
{
 private long UserId=>long.Parse(User.FindFirstValue("userId")!);
 [HttpGet] public async Task<ActionResult<ApiResponse<PagedResult<object>>>> List(string? search,string? type,int page=1,int pageSize=20,CancellationToken ct=default)=>Ok(ApiResponse<PagedResult<object>>.Ok(await questions.GetListAsync(search,type,Math.Max(page,1),Math.Clamp(pageSize,1,100),ct)));
 [HttpGet("{id:long}")] public async Task<ActionResult<ApiResponse<object>>> Get(long id,CancellationToken ct){var x=await questions.GetByIdAsync(id,ct);return x is null?NotFound(ApiResponse<object>.Fail("Không tìm thấy câu hỏi.")):Ok(ApiResponse<object>.Ok(x));}
 [HttpPost] public async Task<ActionResult<ApiResponse<object>>> Create(QuestionSaveRequest r,CancellationToken ct){var id=await questions.CreateAsync(r,UserId,ct);return Ok(ApiResponse<object>.Ok(new{id}));}
 [HttpPut("{id:long}")] public async Task<ActionResult<ApiResponse<object>>> Update(long id,QuestionSaveRequest r,CancellationToken ct)=>await questions.UpdateAsync(id,r,UserId,ct)?Ok(ApiResponse<object>.Ok(new{id})):NotFound(ApiResponse<object>.Fail("Không tìm thấy câu hỏi."));
 [HttpDelete("{id:long}")] public async Task<ActionResult<ApiResponse<object>>> Delete(long id,CancellationToken ct)=>await questions.DeleteAsync(id,UserId,ct)?Ok(ApiResponse<object>.Ok(new{id})):NotFound(ApiResponse<object>.Fail("Không tìm thấy câu hỏi."));
}
