using SimsObject.Common;
using SimsObject.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Sims.Api.Controllers;

[ApiController, Route("api/videos"), Authorize(Roles = "ADMIN,TEACHER")]
public sealed class VideoFilesController(IVideoStorageService storage) : ControllerBase
{
    [HttpPost("upload")]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<ApiResponse<StoredVideoFile>>> Upload([FromForm] IFormFile file, CancellationToken ct)
    {
        if (file is null) return BadRequest(ApiResponse<StoredVideoFile>.Fail("Vui lòng chọn file video."));
        await using var stream = file.OpenReadStream();
        var stored = await storage.SaveAsync(stream, file.FileName, file.ContentType, file.Length, ct);
        return Ok(ApiResponse<StoredVideoFile>.Ok(stored, "Upload video thành công."));
    }

    [HttpDelete("upload")]
    public async Task<ActionResult<ApiResponse<object>>> Delete([FromQuery] string videoUrl, CancellationToken ct)
    {
        var deleted = await storage.DeleteAsync(videoUrl, ct);
        return deleted
            ? Ok(ApiResponse<object>.Ok(new { videoUrl }, "Đã xóa file video."))
            : NotFound(ApiResponse<object>.Fail("Không tìm thấy file video."));
    }
}
