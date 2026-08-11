using System.Data;
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
    public async Task<object?> GetVideoAsync(long id,CancellationToken ct=default){using var db=connections.CreateConnection();return await db.QuerySingleOrDefaultAsync(new CommandDefinition("dbo.LMS_Video_GetById",new{Id=id},commandType:CommandType.StoredProcedure,cancellationToken:ct));}
    public Task<long> SaveVideoAsync(long? id,long lessonId,VideoSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)
    {
        if (!string.IsNullOrWhiteSpace(r.VideoUrl))
        {
            if (!r.VideoUrl.StartsWith("/uploads/videos/", StringComparison.OrdinalIgnoreCase)
                || r.VideoUrl.Contains("..", StringComparison.Ordinal)
                || r.VideoUrl.Contains('\\')
                || r.VideoUrl.Contains('?')
                || r.VideoUrl.Contains('#'))
                throw new ArgumentException("VideoUrl phải là URL tương đối an toàn trong /uploads/videos/.");
            if (!videoStorage.Exists(r.VideoUrl)) throw new ArgumentException("File video không tồn tại trong project.");
        }
        return ScalarId(id is null?"dbo.LMS_Video_Create":"dbo.LMS_Video_Update",new{Id=id,LessonId=lessonId,r.Title,r.VideoUrl,r.PosterUrl,r.DurationSeconds,r.AllowSeek,r.AllowSpeed,r.RequiredWatchPercent,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    }
    public async Task<IReadOnlyCollection<object>> GetInteractionsAsync(long videoId,CancellationToken ct=default){using var db=connections.CreateConnection();return(await db.QueryAsync(new CommandDefinition("dbo.LMS_VideoInteraction_GetByVideo",new{VideoId=videoId},commandType:CommandType.StoredProcedure,cancellationToken:ct))).Cast<object>().ToArray();}
    public Task<long> CreateInteractionAsync(long videoId,InteractionSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>ScalarId("dbo.LMS_VideoInteraction_Create",new{VideoId=videoId,r.QuestionId,r.TimeSeconds,r.EndTimeSeconds,r.InteractionType,r.Required,r.PauseVideo,r.AllowSkip,r.Score,r.AttemptLimit,r.SortOrder,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> UpdateInteractionAsync(long id,InteractionSaveRequest r,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_VideoInteraction_Update",new{Id=id,r.QuestionId,r.TimeSeconds,r.EndTimeSeconds,r.InteractionType,r.Required,r.PauseVideo,r.AllowSkip,r.Score,r.AttemptLimit,r.SortOrder,r.Status,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task<bool> DeleteInteractionAsync(long id,long actorId,bool isAdmin,CancellationToken ct=default)=>Affected("dbo.LMS_VideoInteraction_Delete",new{Id=id,ActorId=actorId,IsAdmin=isAdmin},ct);
    public Task ReorderInteractionsAsync(ReorderRequest request,long actorId,bool isAdmin,CancellationToken ct=default)=>Reorder("dbo.LMS_VideoInteraction_Reorder",request,actorId,isAdmin,ct);
    private async Task<long> ScalarId(string procedure,object args,CancellationToken ct){using var db=connections.CreateConnection();return await db.QuerySingleAsync<long>(new CommandDefinition(procedure,args,commandType:CommandType.StoredProcedure,cancellationToken:ct));}
    private async Task<bool> Affected(string procedure,object args,CancellationToken ct){using var db=connections.CreateConnection();return await db.ExecuteScalarAsync<int>(new CommandDefinition(procedure,args,commandType:CommandType.StoredProcedure,cancellationToken:ct))>0;}
    private async Task Reorder(string procedure,ReorderRequest request,long actorId,bool isAdmin,CancellationToken ct){using var db=connections.CreateConnection();db.Open();using var tx=db.BeginTransaction();try{foreach(var item in request.Items)await db.ExecuteAsync(new CommandDefinition(procedure,new{item.Id,item.SortOrder,ActorId=actorId,IsAdmin=isAdmin},transaction:tx,commandType:CommandType.StoredProcedure,cancellationToken:ct));tx.Commit();}catch{tx.Rollback();throw;}}
}
