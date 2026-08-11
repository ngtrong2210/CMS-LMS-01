using System.Data;
using Dapper;
using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;

namespace LmsCms.Infrastructure.Services;

public sealed class QuestionService(ISqlConnectionFactory connections) : IQuestionService
{
    public async Task<PagedResult<object>> GetListAsync(string? search,string? type,int page,int pageSize,CancellationToken ct=default){using var db=connections.CreateConnection();using var grid=await db.QueryMultipleAsync(new CommandDefinition("dbo.LMS_Question_GetList",new{Search=search,Type=type,Page=page,PageSize=pageSize},commandType:CommandType.StoredProcedure,cancellationToken:ct));var items=(await grid.ReadAsync()).Cast<object>().ToArray();var total=await grid.ReadSingleAsync<int>();return new(items,page,pageSize,total);}
    public async Task<object?> GetByIdAsync(long id,CancellationToken ct=default){using var db=connections.CreateConnection();using var grid=await db.QueryMultipleAsync(new CommandDefinition("dbo.LMS_Question_GetById",new{Id=id},commandType:CommandType.StoredProcedure,cancellationToken:ct));var question=await grid.ReadSingleOrDefaultAsync();if(question is null)return null;return new{Question=question,Options=(await grid.ReadAsync()).ToArray(),AnswerKeys=(await grid.ReadAsync()).ToArray()};}
    public Task<long> CreateAsync(QuestionSaveRequest request,long actorId,CancellationToken ct=default)=>Save(null,request,actorId,ct);
    public async Task<bool> UpdateAsync(long id,QuestionSaveRequest request,long actorId,CancellationToken ct=default){await Save(id,request,actorId,ct);return true;}
    public async Task<bool> DeleteAsync(long id,long actorId,CancellationToken ct=default){using var db=connections.CreateConnection();return await db.ExecuteScalarAsync<int>(new CommandDefinition("dbo.LMS_Question_Delete",new{Id=id,ActorId=actorId},commandType:CommandType.StoredProcedure,cancellationToken:ct))>0;}
    private async Task<long> Save(long? id,QuestionSaveRequest r,long actorId,CancellationToken ct)
    {
        Validate(r);using var db=connections.CreateConnection();db.Open();using var tx=db.BeginTransaction();
        try{
            var questionId=await db.QuerySingleAsync<long>(new CommandDefinition(id is null?"dbo.LMS_Question_Create":"dbo.LMS_Question_Update",new{Id=id,r.QuestionType,r.QuestionText,r.Description,r.Explanation,r.Difficulty,r.DefaultScore,r.ShortAnswerMode,r.Status,ActorId=actorId},transaction:tx,commandType:CommandType.StoredProcedure,cancellationToken:ct));
            await db.ExecuteAsync(new CommandDefinition("dbo.LMS_QuestionAnswers_DeleteByQuestion",new{QuestionId=questionId},transaction:tx,commandType:CommandType.StoredProcedure,cancellationToken:ct));
            foreach(var o in r.Options)await db.ExecuteAsync(new CommandDefinition("dbo.LMS_QuestionOption_Create",new{QuestionId=questionId,o.OptionCode,o.OptionText,o.IsCorrect,o.SortOrder},transaction:tx,commandType:CommandType.StoredProcedure,cancellationToken:ct));
            foreach(var k in r.AnswerKeys)await db.ExecuteAsync(new CommandDefinition("dbo.LMS_QuestionAnswerKey_Create",new{QuestionId=questionId,k.AnswerText,k.IsCaseSensitive,k.SortOrder},transaction:tx,commandType:CommandType.StoredProcedure,cancellationToken:ct));
            tx.Commit();return questionId;
        }catch{tx.Rollback();throw;}
    }
    private static void Validate(QuestionSaveRequest r){if(string.IsNullOrWhiteSpace(r.QuestionText))throw new ArgumentException("Nội dung câu hỏi không được để trống.");if(r.QuestionType=="SHORT_ANSWER"){if(r.ShortAnswerMode is not("EXACT_MATCH" or "CONTAINS" or "MANUAL_REVIEW"))throw new ArgumentException("Chế độ câu trả lời ngắn không hợp lệ.");if(r.ShortAnswerMode!="MANUAL_REVIEW"&&r.AnswerKeys.Count==0)throw new ArgumentException("Câu trả lời ngắn cần ít nhất một đáp án mẫu.");if(r.AnswerKeys.Any(x=>string.IsNullOrWhiteSpace(x.AnswerText)))throw new ArgumentException("Đáp án mẫu không được để trống.");}else{if(r.Options.Count<2)throw new ArgumentException("Câu hỏi lựa chọn cần ít nhất hai phương án.");if(r.Options.Any(x=>string.IsNullOrWhiteSpace(x.OptionCode)||string.IsNullOrWhiteSpace(x.OptionText)))throw new ArgumentException("Mã và nội dung phương án không được để trống.");if(r.Options.Select(x=>x.OptionCode.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).Count()!=r.Options.Count)throw new ArgumentException("Mã phương án không được trùng nhau.");if(!r.Options.Any(x=>x.IsCorrect))throw new ArgumentException("Câu hỏi cần ít nhất một đáp án đúng.");if(r.QuestionType is "SINGLE_CHOICE" or "TRUE_FALSE"&&r.Options.Count(x=>x.IsCorrect)!=1)throw new ArgumentException("Câu hỏi chỉ được có một đáp án đúng.");}}
}
