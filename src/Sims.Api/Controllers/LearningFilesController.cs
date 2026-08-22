using System.Security.Claims;
using SimsObject.Common;
using SimsObject.DTOs;
using SimsObject.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Sims.Api.Controllers;

[ApiController, Route("api/learning-files"), Authorize(Roles = "ADMIN,TEACHER")]
public sealed class LearningFilesController(IAssignmentStorageService storage, IContentService content) : ControllerBase
{
    private long UserId => long.Parse(User.FindFirstValue("userId")!);
    private bool IsAdmin => User.IsInRole("ADMIN");

    [HttpPost("lessons/{lessonId:long}/resource")]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<ApiResponse<AssignmentSubmissionFile>>> UploadLessonResource(long lessonId, [FromForm] IFormFile file, CancellationToken cancellationToken)
    {
        if (file is null) return BadRequest(ApiResponse<AssignmentSubmissionFile>.Fail("Vui lòng chọn file tài liệu."));
        if (await content.GetLessonAsync(lessonId, UserId, IsAdmin, cancellationToken) is null)
            return NotFound(ApiResponse<AssignmentSubmissionFile>.Fail("Không tìm thấy bài học hoặc bạn không có quyền cập nhật."));
        await using var stream = file.OpenReadStream();
        var stored = await storage.SaveTeacherResourceAsync(lessonId, stream, file.FileName, file.ContentType, file.Length, cancellationToken);
        return Ok(ApiResponse<AssignmentSubmissionFile>.Ok(stored, "Đã tải tài liệu bài học."));
    }
}
