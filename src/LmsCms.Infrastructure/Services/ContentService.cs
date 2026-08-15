using System.Data;
using System.Text.Json;
using Dapper;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;

namespace LmsCms.Infrastructure.Services;

public sealed class ContentService(ISqlConnectionFactory connections, IVideoStorageService videoStorage) : IContentService
{
    public async Task<IReadOnlyCollection<object>> GetChaptersAsync(long courseId, long actorId, bool isAdmin, CancellationToken ct = default)
    {
        using var db = connections.CreateConnection();
        return (await db.QueryAsync(new CommandDefinition("dbo.LMS_Chapter_GetByCourse", new { CourseId=courseId, ActorId=actorId, IsAdmin=isAdmin }, commandType:CommandType.StoredProcedure,cancellationToken:ct))).Cast<object>().ToArray();
    }
    public Task<long> CreateChapterAsync(long courseId, ChapterSaveRequest r, long actorId, bool isAdmin, CancellationToken ct=default) => ScalarId("dbo.LMS_Chapter_Create",new{CourseId=courseId,r.Title,r.Description,r.SortOrder,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> UpdateChapterAsync(long id, ChapterSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_Chapter_Update",new{Id=id,r.Title,r.Description,r.SortOrder,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> DeleteChapterAsync(long id,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_Chapter_Delete",new{Id=id,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task ReorderChaptersAsync(ReorderRequest request,long actorId,bool isAdmin,CancellationToken ct=default)=>Reorder("dbo.LMS_Chapter_Reorder",request,actorId,isAdmin,ct);
    public async Task<object?> GetLessonAsync(long id,long actorId,bool isAdmin,CancellationToken ct=default){using var db=connections.CreateConnection();return await db.QuerySingleOrDefaultAsync(new CommandDefinition("dbo.LMS_Lesson_GetById",new{Id=id,ActorId=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct));}
    public Task<long> CreateLessonAsync(long chapterId,LessonSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>ScalarId("dbo.LMS_Lesson_Create",new{ChapterId=chapterId,r.Title,r.Description,r.LessonType,r.DurationSeconds,r.SortOrder,r.IsRequired,r.PassingScore,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> UpdateLessonAsync(long id,LessonSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_Lesson_Update",new{Id=id,r.Title,r.Description,r.LessonType,r.DurationSeconds,r.SortOrder,r.IsRequired,r.PassingScore,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> DeleteLessonAsync(long id,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_Lesson_Delete",new{Id=id,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task ReorderLessonsAsync(ReorderRequest request,long actorId,bool isAdmin,CancellationToken ct=default)=>Reorder("dbo.LMS_Lesson_Reorder",request,actorId,isAdmin,ct);
    public async Task<object?> GetVideoAsync(long id,long actorId,bool isAdmin,CancellationToken ct=default){using var db=connections.CreateConnection();return await db.QuerySingleOrDefaultAsync(new CommandDefinition("dbo.LMS_Video_GetById",new{Id=id,ActorId=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct));}
    public Task<long> SaveVideoAsync(long? id,long lessonId,VideoSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)
    {
        if (!string.IsNullOrWhiteSpace(r.VideoUrl))
        {
            if (!r.VideoUrl.StartsWith("/Media/Video/", StringComparison.OrdinalIgnoreCase)
                || r.VideoUrl.Contains("..", StringComparison.Ordinal)
                || r.VideoUrl.Contains('\\')
                || r.VideoUrl.Contains('?')
                || r.VideoUrl.Contains('#'))
                throw new ArgumentException("VideoUrl phải là URL tương đối an toàn trong /Media/Video/.");
            if (!videoStorage.Exists(r.VideoUrl)) throw new ArgumentException("File video không tồn tại trong project.");
        }
        return ScalarId(id is null?"dbo.LMS_Video_Create":"dbo.LMS_Video_Update",new{Id=id,LessonId=lessonId,r.Title,r.VideoUrl,r.PosterUrl,r.DurationSeconds,r.AllowSeek,r.AllowSpeed,r.RequiredWatchPercent,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    }
    public async Task<IReadOnlyCollection<object>> GetVideoLibraryAsync(string? search,string? access,string? source,string? usage,string? status,long actorId,bool isAdmin,CancellationToken ct=default){using var db=connections.CreateConnection();return(await db.QueryAsync(new CommandDefinition("dbo.LMS_VideoLibrary_GetList",new{Search=search,Access=NormalizeFilter(access),Source=NormalizeFilter(source),Usage=NormalizeFilter(usage),Status=NormalizeFilter(status),ActorId=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct))).Cast<object>().ToArray();}
    public Task<long> CreateVideoAssetAsync(VideoAssetSaveRequest r,long actorId,CancellationToken ct=default)
    {
        ValidateStoredVideoUrl(r.VideoUrl);
        return ScalarId("dbo.LMS_VideoLibrary_Create",new{r.Title,r.VideoUrl,r.PosterUrl,r.DurationSeconds,r.OriginalFileName,r.FileSize,r.MimeType,ActorId=actorId},ct);
    }
    public Task<bool> UpdateVideoAssetAsync(long id,VideoAssetSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)
    {
        ValidateStoredVideoUrl(r.VideoUrl);
        return Affected("dbo.LMS_VideoLibrary_Update",new{Id=id,r.Title,r.VideoUrl,r.PosterUrl,r.DurationSeconds,r.OriginalFileName,r.FileSize,r.MimeType,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    }
    public Task<bool> DeleteVideoAssetAsync(long id,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_VideoLibrary_Delete",new{Id=id,ActorId=actorId,IsAdmin=isAdmin},ct);
    public async Task<object> GetVideoSharingAsync(long id,long actorId,bool isAdmin,CancellationToken ct=default)
    {
        using var db=connections.CreateConnection();
        using var grid=await db.QueryMultipleAsync(new CommandDefinition("dbo.LMS_VideoLibrary_Sharing_Get",new{Id=id,ActorId=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct));
        var asset=await grid.ReadSingleAsync();
        var teachers=(await grid.ReadAsync()).Cast<object>().ToArray();
        return new { Asset=asset, Teachers=teachers };
    }
    public async Task SaveVideoSharingAsync(long id,VideoShareSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)
    {
        var scope=(r.ShareScope??"PRIVATE").Trim().ToUpperInvariant();
        if (scope is not ("PRIVATE" or "SELECTED" or "SCHOOL")) throw new ArgumentException("Phạm vi chia sẻ không hợp lệ.");
        var teacherIds=r.TeacherIds.Where(x=>x>0).Distinct().ToArray();
        using var db=connections.CreateConnection();
        await db.ExecuteScalarAsync<long>(new CommandDefinition("dbo.LMS_VideoLibrary_Sharing_Save",new{Id=id,ShareScope=scope,TeacherIdsJson=JsonSerializer.Serialize(teacherIds),ActorId=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct));
    }
    public Task<long> AttachVideoAssetAsync(long lessonId,long assetId,VideoAttachRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>ScalarId("dbo.LMS_VideoLibrary_Attach",new{LessonId=lessonId,VideoAssetId=assetId,r.AllowSeek,r.AllowSpeed,r.RequiredWatchPercent,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<long> AttachVideoAsync(long lessonId,long videoId,long actorId,bool isAdmin,CancellationToken ct=default)=>ScalarId("dbo.LMS_Video_AttachToLesson",new{LessonId=lessonId,VideoId=videoId,ActorId=actorId,IsAdmin=isAdmin},ct);
    public async Task<IReadOnlyCollection<object>> GetInteractionsAsync(long videoId,long actorId,bool isAdmin,CancellationToken ct=default){using var db=connections.CreateConnection();return(await db.QueryAsync(new CommandDefinition("dbo.LMS_VideoInteraction_GetByVideo",new{VideoId=videoId,ActorId=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct))).Cast<object>().ToArray();}
    public async Task<PreviewAnswerResultDto> PreviewAnswerAsync(long videoId,PreviewAnswerRequest r,long actorId,bool isAdmin,CancellationToken ct=default)
    {
        using var db=connections.CreateConnection();
        var answerText=string.Join("|",r.Answers.Where(x=>!string.IsNullOrWhiteSpace(x)).Select(x=>x.Trim().ToUpperInvariant()).Distinct(StringComparer.OrdinalIgnoreCase).OrderBy(x=>x,StringComparer.OrdinalIgnoreCase));
        return await db.QuerySingleAsync<PreviewAnswerResultDto>(new CommandDefinition("dbo.LMS_VideoInteraction_PreviewAnswer",new{VideoId=videoId,r.InteractionId,r.QuestionId,AnswerText=answerText,ActorId=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct));
    }
    public Task<long> CreateInteractionAsync(long videoId,InteractionSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>ScalarId("dbo.LMS_VideoInteraction_Create",new{VideoId=videoId,r.QuestionId,r.TimeSeconds,r.EndTimeSeconds,r.InteractionType,r.Required,r.PauseVideo,r.AllowSkip,r.Score,r.AttemptLimit,r.SortOrder,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> UpdateInteractionAsync(long id,InteractionSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_VideoInteraction_Update",new{Id=id,r.QuestionId,r.TimeSeconds,r.EndTimeSeconds,r.InteractionType,r.Required,r.PauseVideo,r.AllowSkip,r.Score,r.AttemptLimit,r.SortOrder,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> DeleteInteractionAsync(long id,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_VideoInteraction_Delete",new{Id=id,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task ReorderInteractionsAsync(ReorderRequest request,long actorId,bool isAdmin,CancellationToken ct=default)=>Reorder("dbo.LMS_VideoInteraction_Reorder",request,actorId,isAdmin,ct);
    private async Task<long> ScalarId(string procedure,object args,CancellationToken ct){using var db=connections.CreateConnection();return await db.QuerySingleAsync<long>(new CommandDefinition(procedure,args,commandType:CommandType.StoredProcedure,cancellationToken:ct));}
    private async Task<bool> Affected(string procedure,object args,CancellationToken ct){using var db=connections.CreateConnection();return await db.ExecuteScalarAsync<int>(new CommandDefinition(procedure,args,commandType:CommandType.StoredProcedure,cancellationToken:ct))>0;}
    private async Task Reorder(string procedure,ReorderRequest request,long actorId,bool isAdmin,CancellationToken ct){using var db=connections.CreateConnection();db.Open();using var tx=db.BeginTransaction();try{foreach(var item in request.Items)await db.ExecuteAsync(new CommandDefinition(procedure,new{item.Id,item.SortOrder,ActorId=actorId,IsAdmin=isAdmin},transaction:tx,commandType:CommandType.StoredProcedure,cancellationToken:ct));tx.Commit();}catch{tx.Rollback();throw;}}
    private void ValidateStoredVideoUrl(string videoUrl)
    {
        if (!videoUrl.StartsWith("/Media/Video/",StringComparison.OrdinalIgnoreCase)||videoUrl.Contains("..",StringComparison.Ordinal)||videoUrl.Contains('\\')||videoUrl.Contains('?')||videoUrl.Contains('#')) throw new ArgumentException("VideoUrl phải là URL tương đối an toàn trong /Media/Video/.");
        if (!videoStorage.Exists(videoUrl)) throw new ArgumentException("File video không tồn tại trong project.");
    }
    private static string NormalizeFilter(string? value)=>string.IsNullOrWhiteSpace(value)?"ALL":value.Trim().ToUpperInvariant();
}
