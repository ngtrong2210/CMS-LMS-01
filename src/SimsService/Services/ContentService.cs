using System.Data;
using System.Text.Json;
using Dapper;
using SimsObject.Common;
using SimsObject.DTOs;
using SimsObject.Interfaces;
using SimsData.Data;

namespace SimsService.Services;

public sealed class ContentService(ISqlConnectionFactory connections, IVideoStorageService videoStorage) : IContentService
{
    private static readonly HashSet<string> AllowedProcedureNames = new(StringComparer.Ordinal)
    {
        "dbo.LMS_Chapter_Create", "dbo.LMS_Chapter_Update", "dbo.LMS_Chapter_Delete", "dbo.LMS_Chapter_Reorder",
        "dbo.LMS_Lesson_Create", "dbo.LMS_Lesson_Update", "dbo.LMS_Lesson_Delete", "dbo.LMS_Lesson_Reorder",
        "dbo.LMS_Video_Create", "dbo.LMS_Video_Update", "dbo.LMS_VideoLibrary_Create", "dbo.LMS_VideoLibrary_Update",
        "dbo.LMS_VideoLibrary_Duplicate", "dbo.LMS_VideoLibrary_Delete", "dbo.LMS_VideoLibrary_Attach", "dbo.LMS_Video_AttachToLesson",
        "dbo.LMS_VideoInteraction_Create", "dbo.LMS_VideoInteraction_Update", "dbo.LMS_VideoInteraction_Delete", "dbo.LMS_VideoInteraction_Reorder",
        "dbo.LMS_InteractiveContent_SaveSettings", "dbo.LMS_ContentInteraction_Create", "dbo.LMS_ContentInteraction_Update", "dbo.LMS_ContentInteraction_Delete"
    };
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
    public Task<long> CreateLessonAsync(long chapterId,LessonSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>ScalarId("dbo.LMS_Lesson_Create",new{ChapterId=chapterId,r.Title,r.Description,r.LessonType,r.DurationSeconds,r.SortOrder,r.IsRequired,r.PassingScore,r.ContentHtml,r.DocumentUrl,r.AssignmentFolderName,r.AssignmentStartAt,r.DueAt,r.AssignmentMaxScore,r.MaxSubmissionAttempts,r.MaxSubmissionFileSizeMB,r.AllowLateSubmission,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> UpdateLessonAsync(long id,LessonSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_Lesson_Update",new{Id=id,r.Title,r.Description,r.LessonType,r.DurationSeconds,r.SortOrder,r.IsRequired,r.PassingScore,r.ContentHtml,r.DocumentUrl,r.AssignmentFolderName,r.AssignmentStartAt,r.DueAt,r.AssignmentMaxScore,r.MaxSubmissionAttempts,r.MaxSubmissionFileSizeMB,r.AllowLateSubmission,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> DeleteLessonAsync(long id,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_Lesson_Delete",new{Id=id,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task ReorderLessonsAsync(ReorderRequest request,long actorId,bool isAdmin,CancellationToken ct=default)=>Reorder("dbo.LMS_Lesson_Reorder",request,actorId,isAdmin,ct);
    public async Task<object?> GetVideoAsync(long id,long actorId,bool isAdmin,CancellationToken ct=default){using var db=connections.CreateConnection();return await db.QuerySingleOrDefaultAsync(new CommandDefinition("dbo.LMS_Video_GetById",new{Id=id,ActorId=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct));}
    public Task<long> SaveVideoAsync(long? id,long lessonId,VideoSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)
    {
        var sourceType = ValidateVideoSource(r.SourceType, r.VideoUrl);
        return ScalarId(id is null?"dbo.LMS_Video_Create":"dbo.LMS_Video_Update",new{Id=id,LessonId=lessonId,r.Title,SourceType=sourceType,r.VideoUrl,r.PosterUrl,r.DurationSeconds,r.AllowSeek,r.AllowSpeed,r.RequiredWatchPercent,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    }
    public async Task<IReadOnlyCollection<object>> GetVideoLibraryAsync(string? search,string? access,string? source,string? usage,string? status,long actorId,bool isAdmin,CancellationToken ct=default){search=InputGuard.OptionalText(search,500,"Từ khóa tìm kiếm");access=NormalizeFilter(access,"ALL","MINE","SHARED","SCHOOL");source=NormalizeFilter(source,"ALL","LOCAL","YOUTUBE");usage=NormalizeFilter(usage,"ALL","USED","UNUSED");status=NormalizeFilter(status,"ALL","ACTIVE","INACTIVE");using var db=connections.CreateConnection();return(await db.QueryAsync(new CommandDefinition("dbo.LMS_VideoLibrary_GetList",new{Search=search,Access=access,Source=source,Usage=usage,Status=status,ActorId=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct))).Cast<object>().ToArray();}
    public async Task<object> GetVideoUsageAsync(long id,long actorId,bool isAdmin,CancellationToken ct=default)
    {
        using var db=connections.CreateConnection();
        using var grid=await db.QueryMultipleAsync(new CommandDefinition("dbo.LMS_VideoVersion_GetUsageByVideoAsset",new{Id=id,ActorId=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct));
        var summary=await grid.ReadSingleAsync();
        var lessons=(await grid.ReadAsync()).Cast<object>().ToArray();
        return new { Summary=summary, Lessons=lessons };
    }
    public Task<long> CreateVideoAssetAsync(VideoAssetSaveRequest r,long actorId,CancellationToken ct=default)
    {
        var sourceType = ValidateVideoSource(r.SourceType, r.VideoUrl);
        return ScalarId("dbo.LMS_VideoLibrary_Create",new{r.Title,SourceType=sourceType,r.VideoUrl,r.PosterUrl,r.DurationSeconds,r.OriginalFileName,r.FileSize,r.MimeType,ActorId=actorId},ct);
    }
    public Task<bool> UpdateVideoAssetAsync(long id,VideoAssetSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)
    {
        var sourceType = ValidateVideoSource(r.SourceType, r.VideoUrl);
        var lessonIds=InputGuard.PositiveDistinctIds(r.LessonIds,"Danh sách bài học");
        return Affected("dbo.LMS_VideoLibrary_Update",new{Id=id,r.Title,SourceType=sourceType,r.VideoUrl,r.PosterUrl,r.DurationSeconds,r.OriginalFileName,r.FileSize,r.MimeType,r.Status,LessonIdsJson=JsonSerializer.Serialize(lessonIds),r.ChangeSummary,ActorId=actorId,IsAdmin=isAdmin},ct);
    }
    public Task<long> DuplicateVideoAssetAsync(long id,VideoDuplicateRequest r,long actorId,bool isAdmin,CancellationToken ct=default)
        => ScalarId("dbo.LMS_VideoLibrary_Duplicate",new{Id=id,r.Title,ActorId=actorId,IsAdmin=isAdmin},ct);
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
        var teacherIds=InputGuard.PositiveDistinctIds(r.TeacherIds,"Danh sách giảng viên");
        using var db=connections.CreateConnection();
        await db.ExecuteScalarAsync<long>(new CommandDefinition("dbo.LMS_VideoLibrary_Sharing_Save",new{Id=id,ShareScope=scope,TeacherIdsJson=JsonSerializer.Serialize(teacherIds),ActorId=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct));
    }
    public Task<long> AttachVideoAssetAsync(long lessonId,long assetId,VideoAttachRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>ScalarId("dbo.LMS_VideoLibrary_Attach",new{LessonId=lessonId,VideoAssetId=assetId,r.AllowSeek,r.AllowSpeed,r.RequiredWatchPercent,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<long> AttachVideoAsync(long lessonId,long videoId,long actorId,bool isAdmin,CancellationToken ct=default)=>ScalarId("dbo.LMS_Video_AttachToLesson",new{LessonId=lessonId,VideoId=videoId,ActorId=actorId,IsAdmin=isAdmin},ct);
    public async Task<IReadOnlyCollection<object>> GetInteractionsAsync(long videoId,long actorId,bool isAdmin,CancellationToken ct=default){using var db=connections.CreateConnection();return(await db.QueryAsync(new CommandDefinition("dbo.LMS_VideoInteraction_GetByVideo",new{VideoId=videoId,ActorId=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct))).Cast<object>().ToArray();}
    public async Task<PreviewAnswerResultDto> PreviewAnswerAsync(long videoId,PreviewAnswerRequest r,long actorId,bool isAdmin,CancellationToken ct=default)
    {
        using var db=connections.CreateConnection();
        var answers=InputGuard.TextItems(r.Answers,100,10000,"Câu trả lời");
        var answerText=string.Join("|",answers.Where(x=>!string.IsNullOrWhiteSpace(x)).Select(x=>x.Trim().ToUpperInvariant()).Distinct(StringComparer.OrdinalIgnoreCase).OrderBy(x=>x,StringComparer.OrdinalIgnoreCase));
        return await db.QuerySingleAsync<PreviewAnswerResultDto>(new CommandDefinition("dbo.LMS_VideoInteraction_PreviewAnswer",new{VideoId=videoId,r.InteractionId,r.QuestionId,AnswerText=answerText,ActorId=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct));
    }
    public Task<long> CreateInteractionAsync(long videoId,InteractionSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>ScalarId("dbo.LMS_VideoInteraction_Create",new{VideoId=videoId,r.QuestionId,r.TimeSeconds,r.EndTimeSeconds,r.InteractionType,r.Required,r.PauseVideo,r.AllowSkip,r.Score,r.AttemptLimit,r.SortOrder,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> UpdateInteractionAsync(long id,InteractionSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_VideoInteraction_Update",new{Id=id,r.QuestionId,r.TimeSeconds,r.EndTimeSeconds,r.InteractionType,r.Required,r.PauseVideo,r.AllowSkip,r.Score,r.AttemptLimit,r.SortOrder,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> DeleteInteractionAsync(long id,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_VideoInteraction_Delete",new{Id=id,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task ReorderInteractionsAsync(ReorderRequest request,long actorId,bool isAdmin,CancellationToken ct=default)=>Reorder("dbo.LMS_VideoInteraction_Reorder",request,actorId,isAdmin,ct);
    public async Task<object> GetInteractiveContentForTeacherAsync(long lessonId,long actorId,bool isAdmin,CancellationToken ct=default)
    {
        using var db=connections.CreateConnection();
        using var grid=await db.QueryMultipleAsync(new CommandDefinition("dbo.LMS_InteractiveContent_GetForTeacher",new{LessonID=lessonId,ActorUserID=actorId,IsAdmin=isAdmin},commandType:CommandType.StoredProcedure,cancellationToken:ct));
        var settings=await grid.ReadSingleAsync();
        var interactions=(await grid.ReadAsync()).Cast<object>().ToArray();
        var analytics=await grid.ReadSingleAsync();
        return new { Settings=settings, Interactions=interactions, Analytics=analytics };
    }
    public Task<long> SaveInteractiveContentSettingsAsync(long lessonId,InteractiveContentSettingsRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>ScalarId("dbo.LMS_InteractiveContent_SaveSettings",new{LessonID=lessonId,r.CompletionRule,r.RequireReading,r.PassingScore,r.ShowResultImmediately,r.ShowScore,ActorUserID=actorId,IsAdmin=isAdmin},ct);
    public Task<long> CreateContentInteractionAsync(long lessonId,ContentInteractionSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>ScalarId("dbo.LMS_ContentInteraction_Create",new{LessonID=lessonId,r.QuestionId,r.ContentAnchor,r.Required,r.AllowRetry,r.Score,r.AttemptLimit,r.SortOrder,r.Status,ActorUserID=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> UpdateContentInteractionAsync(long id,ContentInteractionSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_ContentInteraction_Update",new{ContentInteractionID=id,r.QuestionId,r.ContentAnchor,r.Required,r.AllowRetry,r.Score,r.AttemptLimit,r.SortOrder,r.Status,ActorUserID=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> DeleteContentInteractionAsync(long id,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_ContentInteraction_Delete",new{ContentInteractionID=id,ActorUserID=actorId,IsAdmin=isAdmin},ct);
    public async Task ReorderContentInteractionsAsync(ReorderRequest request,long actorId,bool isAdmin,CancellationToken ct=default)
    {
        using var db=connections.CreateConnection();
        db.Open();
        using var tx=db.BeginTransaction();
        try
        {
            foreach(var item in request.Items)
                await db.ExecuteAsync(new CommandDefinition("dbo.LMS_ContentInteraction_Reorder",new{ContentInteractionID=item.Id,item.SortOrder,ActorUserID=actorId,IsAdmin=isAdmin},transaction:tx,commandType:CommandType.StoredProcedure,cancellationToken:ct));
            tx.Commit();
        }
        catch
        {
            tx.Rollback();
            throw;
        }
    }
    private async Task<long> ScalarId(string procedure,object args,CancellationToken ct){EnsureStoredProcedureAllowed(procedure);using var db=connections.CreateConnection();return await db.QuerySingleAsync<long>(new CommandDefinition(procedure,args,commandType:CommandType.StoredProcedure,cancellationToken:ct));}
    private async Task<bool> Affected(string procedure,object args,CancellationToken ct){EnsureStoredProcedureAllowed(procedure);using var db=connections.CreateConnection();return await db.ExecuteScalarAsync<int>(new CommandDefinition(procedure,args,commandType:CommandType.StoredProcedure,cancellationToken:ct))>0;}
    private async Task Reorder(string procedure,ReorderRequest request,long actorId,bool isAdmin,CancellationToken ct){EnsureStoredProcedureAllowed(procedure);using var db=connections.CreateConnection();db.Open();using var tx=db.BeginTransaction();try{foreach(var item in request.Items)await db.ExecuteAsync(new CommandDefinition(procedure,new{item.Id,item.SortOrder,ActorId=actorId,IsAdmin=isAdmin},transaction:tx,commandType:CommandType.StoredProcedure,cancellationToken:ct));tx.Commit();}catch{tx.Rollback();throw;}}
    private static void EnsureStoredProcedureAllowed(string procedure){if(!AllowedProcedureNames.Contains(procedure))throw new InvalidOperationException("Stored procedure is not allowed for this service.");}
    private string ValidateVideoSource(string? sourceType, string? videoUrl)
    {
        if (string.IsNullOrWhiteSpace(videoUrl)) throw new ArgumentException("Nguồn video không được để trống.");
        var normalizedSourceType = TryGetYouTubeVideoId(videoUrl, out _)
            ? "YOUTUBE"
            : NormalizeSourceType(sourceType);

        if (normalizedSourceType == "LOCAL")
        {
            if (!videoUrl.StartsWith("/Media/Video/",StringComparison.OrdinalIgnoreCase)||videoUrl.Contains("..",StringComparison.Ordinal)||videoUrl.Contains('\\')||videoUrl.Contains('?')||videoUrl.Contains('#')) throw new ArgumentException("VideoUrl phải là URL tương đối an toàn trong /Media/Video/.");
            if (!videoStorage.Exists(videoUrl)) throw new ArgumentException("File video không tồn tại trong project.");
            return normalizedSourceType;
        }

        if (!TryGetYouTubeVideoId(videoUrl, out _)) throw new ArgumentException("Liên kết YouTube không hợp lệ hoặc không chứa mã video 11 ký tự.");
        return normalizedSourceType;
    }
    private static string NormalizeSourceType(string? value)
    {
        var normalized = (value ?? "LOCAL").Trim().ToUpperInvariant();
        return normalized is "LOCAL" or "YOUTUBE"
            ? normalized
            : throw new ArgumentException("Loại nguồn video chỉ hỗ trợ LOCAL hoặc YOUTUBE.");
    }
    private static bool TryGetYouTubeVideoId(string value,out string videoId)
    {
        videoId="";
        if (!Uri.TryCreate(value,UriKind.Absolute,out var uri)||uri.Scheme!=Uri.UriSchemeHttps) return false;
        var host=uri.Host.ToLowerInvariant();
        string? candidate=null;
        if (host is "youtu.be" or "www.youtu.be") candidate=uri.AbsolutePath.Trim('/').Split('/')[0];
        else if (host is "youtube.com" or "www.youtube.com" or "m.youtube.com" or "youtube-nocookie.com" or "www.youtube-nocookie.com")
        {
            var parts=uri.AbsolutePath.Trim('/').Split('/',StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length>=2 && parts[0] is "embed" or "shorts" or "live") candidate=parts[1];
            else if (parts.Length==1 && parts[0]=="watch") candidate=uri.Query.TrimStart('?').Split('&',StringSplitOptions.RemoveEmptyEntries).Select(x=>x.Split('=',2)).Where(x=>x.Length==2&&x[0]=="v").Select(x=>Uri.UnescapeDataString(x[1])).FirstOrDefault();
        }
        if (candidate?.Length!=11||candidate.Any(ch=>!(char.IsLetterOrDigit(ch)||ch is '-' or '_'))) return false;
        videoId=candidate;
        return true;
    }
    private static string NormalizeFilter(string? value,params string[] allowedValues)=>InputGuard.OptionalChoice(value,"Bộ lọc",allowedValues)??"ALL";
}
