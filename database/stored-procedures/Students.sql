CREATE OR ALTER PROCEDURE dbo.LMS_Student_GetList @Search NVARCHAR(500)=NULL,@Status VARCHAR(30)=NULL,@Page INT=1,@PageSize INT=20 AS
BEGIN SET NOCOUNT ON; SELECT u.Id,u.StudentCode,u.FullName,u.Email,u.AvatarUrl,u.Status,u.LastLoginAt,COUNT(e.Id) CourseCount,CAST(ISNULL(AVG(e.ProgressPercent),0) AS DECIMAL(5,2)) ProgressPercent,CAST(ISNULL(AVG(e.FinalScore),0) AS DECIMAL(8,2)) AverageScore FROM dbo.Users u LEFT JOIN dbo.Enrollments e ON e.StudentId=u.Id AND e.Status<>'CANCELLED' WHERE u.StudentCode IS NOT NULL AND u.IsDeleted=0 AND (@Status IS NULL OR @Status='' OR u.Status=@Status) AND (@Search IS NULL OR @Search='' OR u.FullName LIKE '%'+@Search+'%' OR u.StudentCode LIKE '%'+@Search+'%' OR u.Email LIKE '%'+@Search+'%') GROUP BY u.Id,u.StudentCode,u.FullName,u.Email,u.AvatarUrl,u.Status,u.LastLoginAt ORDER BY u.FullName OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY; SELECT COUNT(*) FROM dbo.Users u WHERE u.StudentCode IS NOT NULL AND u.IsDeleted=0 AND (@Status IS NULL OR @Status='' OR u.Status=@Status) AND (@Search IS NULL OR @Search='' OR u.FullName LIKE '%'+@Search+'%' OR u.StudentCode LIKE '%'+@Search+'%' OR u.Email LIKE '%'+@Search+'%'); END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Student_GetById @Id BIGINT AS
BEGIN SET NOCOUNT ON; SELECT Id,Username,FullName,Email,StudentCode,AvatarUrl,Status,LastLoginAt,CreatedAt FROM dbo.Users WHERE Id=@Id AND StudentCode IS NOT NULL AND IsDeleted=0; SELECT e.Id,c.Code,c.Title,e.Status,e.ProgressPercent,e.FinalScore,e.EnrolledAt,e.CompletedAt FROM dbo.Enrollments e JOIN dbo.Courses c ON c.Id=e.CourseId WHERE e.StudentId=@Id; SELECT p.CourseId,p.LessonId,l.Title,p.ProgressPercent,p.Score,p.Completed,p.LastAccessAt FROM dbo.StudentLessonProgress p JOIN dbo.Lessons l ON l.Id=p.LessonId WHERE p.StudentId=@Id; SELECT a.CourseId,a.LessonId,a.QuestionId,a.AttemptNumber,a.AnswerText,a.IsCorrect,a.ScoreAwarded,a.ReviewStatus,a.AnsweredAt FROM dbo.StudentAnswers a WHERE a.StudentId=@Id ORDER BY a.AnsweredAt DESC; SELECT SessionId,CourseId,LessonId,VideoId,StartedAt,EndedAt,WatchDurationSeconds,LastPositionSeconds,Completed FROM dbo.LearningSessions WHERE StudentId=@Id ORDER BY StartedAt DESC; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Enrollment_GetList @Page INT=1,@PageSize INT=20 AS
BEGIN SET NOCOUNT ON; SELECT e.Id,e.CourseId,c.Code CourseCode,c.Title CourseTitle,e.StudentId,u.StudentCode,u.FullName StudentName,e.EnrolledAt,e.Status,e.ProgressPercent,e.FinalScore,e.LastAccessAt FROM dbo.Enrollments e JOIN dbo.Courses c ON c.Id=e.CourseId JOIN dbo.Users u ON u.Id=e.StudentId ORDER BY e.EnrolledAt DESC OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY; SELECT COUNT(*) FROM dbo.Enrollments; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Enrollment_Create @CourseId BIGINT,@StudentId BIGINT,@ActorId BIGINT AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Courses WHERE Id=@CourseId AND IsDeleted=0)
    OR NOT EXISTS(SELECT 1 FROM dbo.Users WHERE Id=@StudentId AND StudentCode IS NOT NULL AND IsDeleted=0)
  THROW 50002,N'Khóa học hoặc học viên không tồn tại.',1;
 IF EXISTS(SELECT 1 FROM dbo.Enrollments WHERE CourseId=@CourseId AND StudentId=@StudentId AND Status<>'CANCELLED')
  THROW 50006,N'Học viên đã được ghi danh vào khóa học.',1;
 BEGIN TRANSACTION;
 DECLARE @Id BIGINT;
 SELECT @Id=Id FROM dbo.Enrollments WITH(UPDLOCK,HOLDLOCK) WHERE CourseId=@CourseId AND StudentId=@StudentId AND Status='CANCELLED';
 IF @Id IS NOT NULL
  UPDATE dbo.Enrollments SET Status='ENROLLED',ProgressPercent=0,FinalScore=NULL,EnrolledAt=SYSUTCDATETIME(),StartedAt=NULL,CompletedAt=NULL,LastAccessAt=NULL,CreatedBy=@ActorId WHERE Id=@Id;
 ELSE
 BEGIN
  INSERT dbo.Enrollments(CourseId,StudentId,Status,ProgressPercent,CreatedBy) VALUES(@CourseId,@StudentId,'ENROLLED',0,@ActorId);
  SET @Id=SCOPE_IDENTITY();
 END
 INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'CREATE','ENROLLMENT','Enrollment',CONVERT(NVARCHAR(100),@Id));
 COMMIT;
 SELECT @Id;
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Enrollment_Cancel @Id BIGINT,@ActorId BIGINT AS
BEGIN SET NOCOUNT ON; UPDATE dbo.Enrollments SET Status='CANCELLED',LastAccessAt=SYSUTCDATETIME() WHERE Id=@Id AND Status<>'CANCELLED'; DECLARE @Rows INT=@@ROWCOUNT; IF @Rows>0 INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'CANCEL','ENROLLMENT','Enrollment',CONVERT(NVARCHAR(100),@Id)); SELECT @Rows; END
GO
