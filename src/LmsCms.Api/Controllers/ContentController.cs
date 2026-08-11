using System.Security.Claims;
using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LmsCms.Api.Controllers;
[ApiController,Route("api"),Authorize(Roles="ADMIN,TEACHER")]
public sealed class ContentController(IContentService content):ControllerBase
{
 private long UserId=>long.Parse(User.FindFirstValue("userId")!);private bool IsAdmin=>User.IsInRole("ADMIN");
 [HttpGet("courses/{courseId:long}/chapters")] public async Task<ActionResult<ApiResponse<object>>> Chapters(long courseId,CancellationToken ct)=>Ok(ApiResponse<object>.Ok(await content.GetChaptersAsync(courseId,UserId,IsAdmin,ct)));
 [HttpPost("courses/{courseId:long}/chapters")] public async Task<ActionResult<ApiResponse<object>>> CreateChapter(long courseId,ChapterSaveRequest r,CancellationToken ct){var id=await content.CreateChapterAsync(courseId,r,UserId,IsAdmin,ct);return Ok(ApiResponse<object>.Ok(new{id}));}
 [HttpPut("chapters/{id:long}")] public async Task<ActionResult<ApiResponse<object>>> UpdateChapter(long id,ChapterSaveRequest r,CancellationToken ct)=>await content.UpdateChapterAsync(id,r,UserId,IsAdmin,ct)?Ok(ApiResponse<object>.Ok(new{id})):NotFound(ApiResponse<object>.Fail("Không tìm thấy chương."));
 [HttpDelete("chapters/{id:long}")] public async Task<ActionResult<ApiResponse<object>>> DeleteChapter(long id,CancellationToken ct)=>await content.DeleteChapterAsync(id,UserId,IsAdmin,ct)?Ok(ApiResponse<object>.Ok(new{id})):NotFound(ApiResponse<object>.Fail("Không tìm thấy chương."));
 [HttpPost("chapters/reorder")] public async Task<ActionResult<ApiResponse<object>>> ReorderChapters(ReorderRequest r,CancellationToken ct){await content.ReorderChaptersAsync(r,UserId,IsAdmin,ct);return Ok(ApiResponse<object>.Ok(new{}));}
 [HttpGet("lessons/{id:long}")] public async Task<ActionResult<ApiResponse<object>>> Lesson(long id,CancellationToken ct){var x=await content.GetLessonAsync(id,UserId,IsAdmin,ct);return x is null?NotFound(ApiResponse<object>.Fail("Không tìm thấy bài học.")):Ok(ApiResponse<object>.Ok(x));}
 [HttpPost("chapters/{chapterId:long}/lessons")] public async Task<ActionResult<ApiResponse<object>>> CreateLesson(long chapterId,LessonSaveRequest r,CancellationToken ct){var id=await content.CreateLessonAsync(chapterId,r,UserId,IsAdmin,ct);return Ok(ApiResponse<object>.Ok(new{id}));}
 [HttpPut("lessons/{id:long}")] public async Task<ActionResult<ApiResponse<object>>> UpdateLesson(long id,LessonSaveRequest r,CancellationToken ct)=>await content.UpdateLessonAsync(id,r,UserId,IsAdmin,ct)?Ok(ApiResponse<object>.Ok(new{id})):NotFound(ApiResponse<object>.Fail("Không tìm thấy bài học."));
 [HttpDelete("lessons/{id:long}")] public async Task<ActionResult<ApiResponse<object>>> DeleteLesson(long id,CancellationToken ct)=>await content.DeleteLessonAsync(id,UserId,IsAdmin,ct)?Ok(ApiResponse<object>.Ok(new{id})):NotFound(ApiResponse<object>.Fail("Không tìm thấy bài học."));
 [HttpPost("lessons/reorder")] public async Task<ActionResult<ApiResponse<object>>> ReorderLessons(ReorderRequest r,CancellationToken ct){await content.ReorderLessonsAsync(r,UserId,IsAdmin,ct);return Ok(ApiResponse<object>.Ok(new{}));}
 [HttpGet("videos/{id:long}")] public async Task<ActionResult<ApiResponse<object>>> Video(long id,CancellationToken ct){var x=await content.GetVideoAsync(id,UserId,IsAdmin,ct);return x is null?NotFound(ApiResponse<object>.Fail("Không tìm thấy video.")):Ok(ApiResponse<object>.Ok(x));}
 [HttpPost("lessons/{lessonId:long}/video")] public async Task<ActionResult<ApiResponse<object>>> CreateVideo(long lessonId,VideoSaveRequest r,CancellationToken ct){var id=await content.SaveVideoAsync(null,lessonId,r,UserId,IsAdmin,ct);return Ok(ApiResponse<object>.Ok(new{id}));}
 [HttpPut("videos/{id:long}")] public async Task<ActionResult<ApiResponse<object>>> UpdateVideo(long id,VideoSaveRequest r,CancellationToken ct){if(r.LessonId<=0)return BadRequest(ApiResponse<object>.Fail("LessonId là bắt buộc."));var saved=await content.SaveVideoAsync(id,r.LessonId,r,UserId,IsAdmin,ct);return Ok(ApiResponse<object>.Ok(new{id=saved}));}
 [HttpGet("video-library")] public async Task<ActionResult<ApiResponse<object>>> VideoLibrary([FromQuery]string? search,CancellationToken ct)=>Ok(ApiResponse<object>.Ok(await content.GetVideoLibraryAsync(search,UserId,IsAdmin,ct)));
 [HttpPost("video-library")] public async Task<ActionResult<ApiResponse<object>>> CreateVideoAsset(VideoAssetSaveRequest r,CancellationToken ct){var id=await content.CreateVideoAssetAsync(r,UserId,ct);return Ok(ApiResponse<object>.Ok(new{id}));}
 [HttpDelete("video-library/{id:long}")] public async Task<ActionResult<ApiResponse<object>>> DeleteVideoAsset(long id,CancellationToken ct)=>await content.DeleteVideoAssetAsync(id,UserId,ct)?Ok(ApiResponse<object>.Ok(new{id})):NotFound(ApiResponse<object>.Fail("Không tìm thấy video thư viện."));
 [HttpPost("lessons/{lessonId:long}/video-library/{assetId:long}")] public async Task<ActionResult<ApiResponse<object>>> AttachVideoAsset(long lessonId,long assetId,VideoAttachRequest r,CancellationToken ct){var id=await content.AttachVideoAssetAsync(lessonId,assetId,r,UserId,IsAdmin,ct);return Ok(ApiResponse<object>.Ok(new{id}));}
 [HttpGet("videos/{videoId:long}/interactions")] public async Task<ActionResult<ApiResponse<object>>> Interactions(long videoId,CancellationToken ct)=>Ok(ApiResponse<object>.Ok(await content.GetInteractionsAsync(videoId,UserId,IsAdmin,ct)));
 [HttpPost("videos/{videoId:long}/preview-answer")] public async Task<ActionResult<ApiResponse<PreviewAnswerResultDto>>> PreviewAnswer(long videoId,PreviewAnswerRequest r,CancellationToken ct)=>Ok(ApiResponse<PreviewAnswerResultDto>.Ok(await content.PreviewAnswerAsync(videoId,r,UserId,IsAdmin,ct)));
 [HttpPost("videos/{videoId:long}/interactions")] public async Task<ActionResult<ApiResponse<object>>> CreateInteraction(long videoId,InteractionSaveRequest r,CancellationToken ct){var id=await content.CreateInteractionAsync(videoId,r,UserId,IsAdmin,ct);return Ok(ApiResponse<object>.Ok(new{id}));}
 [HttpPut("video-interactions/{id:long}")] public async Task<ActionResult<ApiResponse<object>>> UpdateInteraction(long id,InteractionSaveRequest r,CancellationToken ct)=>await content.UpdateInteractionAsync(id,r,UserId,IsAdmin,ct)?Ok(ApiResponse<object>.Ok(new{id})):NotFound(ApiResponse<object>.Fail("Không tìm thấy tương tác."));
 [HttpDelete("video-interactions/{id:long}")] public async Task<ActionResult<ApiResponse<object>>> DeleteInteraction(long id,CancellationToken ct)=>await content.DeleteInteractionAsync(id,UserId,IsAdmin,ct)?Ok(ApiResponse<object>.Ok(new{id})):NotFound(ApiResponse<object>.Fail("Không tìm thấy tương tác."));
 [HttpPost("video-interactions/reorder")] public async Task<ActionResult<ApiResponse<object>>> ReorderInteractions(ReorderRequest r,CancellationToken ct){await content.ReorderInteractionsAsync(r,UserId,IsAdmin,ct);return Ok(ApiResponse<object>.Ok(new{}));}
}
