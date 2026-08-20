using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LmsCms.Api.Controllers;

[ApiController, Route("api/learning-files"), Authorize(Roles = "ADMIN,TEACHER")]
public sealed class LearningFilesController(IAssignmentStorageService storage) : ControllerBase
{
    [HttpPost("lessons/{lessonId:long}/resource")]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<ApiResponse<AssignmentSubmissionFile>>> UploadLessonResource(long lessonId, [FromForm] IFormFile file, CancellationToken cancellationToken)
    {
        if (file is null) return BadRequest(ApiResponse<AssignmentSubmissionFile>.Fail("Vui lòng chọn file tài liệu."));
        await using var stream = file.OpenReadStream();
        var stored = await storage.SaveTeacherResourceAsync(lessonId, stream, file.FileName, file.ContentType, file.Length, cancellationToken);
        return Ok(ApiResponse<AssignmentSubmissionFile>.Ok(stored, "Đã tải tài liệu bài học."));
    }
}
