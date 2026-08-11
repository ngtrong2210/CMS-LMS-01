CREATE OR ALTER PROCEDURE dbo.LMS_LessonPlayer_GetData @LessonId BIGINT,@StudentId BIGINT AS
BEGIN SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Lessons l JOIN dbo.Courses c ON c.Id=l.CourseId JOIN dbo.Enrollments e ON e.CourseId=c.Id AND e.StudentId=@StudentId WHERE l.Id=@LessonId AND c.Status='PUBLISHED' AND e.Status<>'CANCELLED') RETURN;
 SELECT l.Id,l.CourseId,l.ChapterId,l.Title,l.Description,l.LessonType,l.DurationSeconds,l.PassingScore FROM dbo.Lessons l WHERE l.Id=@LessonId AND l.IsDeleted=0;
 SELECT c.Id,c.Code,c.Title,c.Slug,u.FullName TeacherName FROM dbo.Courses c JOIN dbo.Lessons l ON l.CourseId=c.Id JOIN dbo.Users u ON u.Id=c.TeacherId WHERE l.Id=@LessonId;
 SELECT v.Id,v.LessonId,v.Title,v.VideoUrl,v.PosterUrl,v.DurationSeconds,v.AllowSeek,v.AllowSpeed,v.RequiredWatchPercent FROM dbo.Videos v WHERE v.LessonId=@LessonId;
 SELECT p.Id,p.CurrentTimeSeconds,p.MaxWatchedTimeSeconds,p.WatchedSeconds,p.WatchPercent,p.Completed FROM dbo.StudentVideoProgress p JOIN dbo.Videos v ON v.Id=p.VideoId WHERE v.LessonId=@LessonId AND p.StudentId=@StudentId;
 SELECT vi.Id,vi.VideoId,vi.QuestionId,vi.TimeSeconds,vi.EndTimeSeconds,vi.InteractionType,vi.Required,vi.PauseVideo,vi.AllowSkip,vi.Score,vi.AttemptLimit,vi.SortOrder,q.QuestionType,q.QuestionText,q.Description,q.Difficulty,
  (SELECT o.Id,o.OptionCode,o.OptionText,o.SortOrder FROM dbo.QuestionOptions o WHERE o.QuestionId=q.Id ORDER BY o.SortOrder FOR JSON PATH) Options
 FROM dbo.VideoInteractions vi JOIN dbo.Videos v ON v.Id=vi.VideoId JOIN dbo.Questions q ON q.Id=vi.QuestionId WHERE v.LessonId=@LessonId AND vi.IsDeleted=0 AND vi.Status='ACTIVE' ORDER BY vi.TimeSeconds;
 SELECT sa.InteractionId,sa.QuestionId,sa.IsCorrect,sa.ScoreAwarded,sa.ReviewStatus,sa.AttemptNumber,sa.AnswerText FROM dbo.StudentAnswers sa WHERE sa.StudentId=@StudentId AND sa.LessonId=@LessonId;
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_StudentVideoProgress_Save @StudentId BIGINT,@LessonId BIGINT,@VideoId BIGINT,@CurrentTimeSeconds DECIMAL(10,2),@MaxWatchedTimeSeconds DECIMAL(10,2),@WatchPercent DECIMAL(5,2) AS
BEGIN SET NOCOUNT ON;
 DECLARE @CourseId BIGINT,@Duration INT,@Required DECIMAL(5,2); SELECT @CourseId=l.CourseId,@Duration=v.DurationSeconds,@Required=v.RequiredWatchPercent FROM dbo.Videos v JOIN dbo.Lessons l ON l.Id=v.LessonId WHERE v.Id=@VideoId AND l.Id=@LessonId;
 IF @CourseId IS NULL THROW 50001,'Video không hợp lệ.',1;
 SET @CurrentTimeSeconds=CASE WHEN @CurrentTimeSeconds<0 THEN 0 WHEN @CurrentTimeSeconds>@Duration THEN @Duration ELSE @CurrentTimeSeconds END;
 SET @MaxWatchedTimeSeconds=CASE WHEN @MaxWatchedTimeSeconds<0 THEN 0 WHEN @MaxWatchedTimeSeconds>@Duration THEN @Duration ELSE @MaxWatchedTimeSeconds END;
 SET @WatchPercent=CASE WHEN @Duration=0 THEN 0 ELSE ROUND(@MaxWatchedTimeSeconds*100.0/@Duration,2) END;
 UPDATE dbo.StudentVideoProgress SET CurrentTimeSeconds=@CurrentTimeSeconds,MaxWatchedTimeSeconds=CASE WHEN MaxWatchedTimeSeconds>@MaxWatchedTimeSeconds THEN MaxWatchedTimeSeconds ELSE @MaxWatchedTimeSeconds END,WatchedSeconds=CASE WHEN WatchedSeconds>@MaxWatchedTimeSeconds THEN WatchedSeconds ELSE @MaxWatchedTimeSeconds END,WatchPercent=CASE WHEN WatchPercent>@WatchPercent THEN WatchPercent ELSE @WatchPercent END,Completed=CASE WHEN @WatchPercent>=@Required THEN 1 ELSE Completed END,CompletedAt=CASE WHEN @WatchPercent>=@Required THEN COALESCE(CompletedAt,SYSUTCDATETIME()) ELSE CompletedAt END,LastAccessAt=SYSUTCDATETIME(),UpdatedAt=SYSUTCDATETIME() WHERE StudentId=@StudentId AND VideoId=@VideoId;
 IF @@ROWCOUNT=0 INSERT dbo.StudentVideoProgress(StudentId,CourseId,LessonId,VideoId,CurrentTimeSeconds,MaxWatchedTimeSeconds,WatchedSeconds,WatchPercent,Completed,CompletedAt) VALUES(@StudentId,@CourseId,@LessonId,@VideoId,@CurrentTimeSeconds,@MaxWatchedTimeSeconds,@MaxWatchedTimeSeconds,@WatchPercent,IIF(@WatchPercent>=@Required,1,0),IIF(@WatchPercent>=@Required,SYSUTCDATETIME(),NULL));
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_StudentAnswer_Submit @StudentId BIGINT,@LessonId BIGINT,@VideoId BIGINT=NULL,@InteractionId BIGINT=NULL,@QuestionId BIGINT,@AnswerText NVARCHAR(MAX),@TimeInVideoSeconds DECIMAL(10,2)=NULL,@TimeSpentSeconds INT=NULL AS
BEGIN SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @CourseId BIGINT,@Type VARCHAR(50),@Mode VARCHAR(30),@Score DECIMAL(8,2),@Correct NVARCHAR(MAX),@IsCorrect BIT,@Attempt INT;
 SELECT @CourseId=CourseId FROM dbo.Lessons WHERE Id=@LessonId; SELECT @Type=QuestionType,@Mode=ShortAnswerMode,@Score=DefaultScore FROM dbo.Questions WHERE Id=@QuestionId AND IsDeleted=0;
 IF @CourseId IS NULL OR @Type IS NULL THROW 50002,'Câu hỏi hoặc bài học không hợp lệ.',1;
 SELECT @Attempt=COUNT(*)+1 FROM dbo.StudentAnswers WHERE StudentId=@StudentId AND QuestionId=@QuestionId AND ISNULL(InteractionId,0)=ISNULL(@InteractionId,0);
 IF @Type IN('SINGLE_CHOICE','TRUE_FALSE','MULTIPLE_CHOICE') BEGIN SELECT @Correct=STRING_AGG(OptionCode,'|') WITHIN GROUP(ORDER BY OptionCode) FROM dbo.QuestionOptions WHERE QuestionId=@QuestionId AND IsCorrect=1; SET @IsCorrect=IIF(@AnswerText=@Correct,1,0); END
 ELSE IF @Mode='MANUAL_REVIEW' SET @IsCorrect=NULL;
 ELSE BEGIN SELECT TOP 1 @Correct=AnswerText FROM dbo.QuestionAnswerKeys WHERE QuestionId=@QuestionId ORDER BY SortOrder; SET @IsCorrect=IIF((@Mode='CONTAINS' AND LOWER(@AnswerText) LIKE '%'+LOWER(@Correct)+'%') OR (@Mode<>'CONTAINS' AND LOWER(@AnswerText)=LOWER(@Correct)),1,0); END
 INSERT dbo.StudentAnswers(StudentId,CourseId,LessonId,VideoId,InteractionId,QuestionId,AttemptNumber,AnswerText,IsCorrect,ScoreAwarded,ReviewStatus,TimeInVideoSeconds,TimeSpentSeconds) VALUES(@StudentId,@CourseId,@LessonId,@VideoId,@InteractionId,@QuestionId,@Attempt,@AnswerText,@IsCorrect,IIF(@IsCorrect=1,@Score,0),IIF(@IsCorrect IS NULL,'PENDING_REVIEW','AUTO_GRADED'),@TimeInVideoSeconds,@TimeSpentSeconds);
 DECLARE @AnswerId BIGINT=SCOPE_IDENTITY(); SELECT @AnswerId AnswerId,@IsCorrect IsCorrect,CAST(IIF(@IsCorrect=1,@Score,0) AS DECIMAL(8,2)) ScoreAwarded,CAST((SELECT ISNULL(SUM(ScoreAwarded),0) FROM dbo.StudentAnswers WHERE StudentId=@StudentId AND LessonId=@LessonId) AS DECIMAL(8,2)) CurrentLessonScore,@Attempt AttemptNumber,IIF(@IsCorrect IS NULL,'PENDING_REVIEW','AUTO_GRADED') ReviewStatus,(SELECT Explanation FROM dbo.Questions WHERE Id=@QuestionId) Explanation;
END
GO
