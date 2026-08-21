using System.Data;
using Dapper;
using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;

namespace LmsCms.Infrastructure.Services;
public sealed class StudentService(ISqlConnectionFactory connections):IStudentService
{
 public async Task<PagedResult<object>> GetStudentsAsync(string? search,string? status,int page,int pageSize,CancellationToken ct=default){search=InputGuard.OptionalText(search,250,"Từ khóa tìm kiếm");status=InputGuard.OptionalChoice(status,"Trạng thái","ACTIVE","INACTIVE","LOCKED");using var db=connections.CreateConnection();using var g=await db.QueryMultipleAsync(new CommandDefinition("dbo.LMS_Student_GetList",new{Search=search,Status=status,Page=page,PageSize=pageSize},commandType:CommandType.StoredProcedure,cancellationToken:ct));var rows=(await g.ReadAsync()).Cast<object>().ToArray();var total=await g.ReadSingleAsync<int>();return new(rows,page,pageSize,total);}
 public async Task<object?> GetStudentAsync(long id,CancellationToken ct=default){using var db=connections.CreateConnection();using var g=await db.QueryMultipleAsync(new CommandDefinition("dbo.LMS_Student_GetById",new{Id=id},commandType:CommandType.StoredProcedure,cancellationToken:ct));var profile=await g.ReadSingleOrDefaultAsync();if(profile is null)return null;return new{Profile=profile,Courses=(await g.ReadAsync()).ToArray(),Progress=(await g.ReadAsync()).ToArray(),Answers=(await g.ReadAsync()).ToArray(),LearningSessions=(await g.ReadAsync()).ToArray()};}
 public async Task<PagedResult<object>> GetEnrollmentsAsync(int page,int pageSize,CancellationToken ct=default){using var db=connections.CreateConnection();using var g=await db.QueryMultipleAsync(new CommandDefinition("dbo.LMS_Enrollment_GetList",new{Page=page,PageSize=pageSize},commandType:CommandType.StoredProcedure,cancellationToken:ct));var rows=(await g.ReadAsync()).Cast<object>().ToArray();var total=await g.ReadSingleAsync<int>();return new(rows,page,pageSize,total);}
 public async Task<long> EnrollAsync(EnrollmentCreateRequest r,long actorId,CancellationToken ct=default){using var db=connections.CreateConnection();return await db.QuerySingleAsync<long>(new CommandDefinition("dbo.LMS_Enrollment_Create",new{r.CourseId,r.StudentId,ActorId=actorId},commandType:CommandType.StoredProcedure,cancellationToken:ct));}
 public async Task<bool> CancelEnrollmentAsync(long id,long actorId,CancellationToken ct=default){using var db=connections.CreateConnection();return await db.ExecuteScalarAsync<int>(new CommandDefinition("dbo.LMS_Enrollment_Cancel",new{Id=id,ActorId=actorId},commandType:CommandType.StoredProcedure,cancellationToken:ct))>0;}
}
