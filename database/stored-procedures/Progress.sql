CREATE OR ALTER PROCEDURE dbo.LMS_LessonPlayer_GetData @LessonId BIGINT,@StudentId BIGINT AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Lessons l JOIN dbo.Courses c ON c.Id=l.CourseId JOIN dbo.Enrollments e ON e.CourseId=c.Id AND e.StudentId=@StudentId WHERE l.Id=@LessonId AND l.IsDeleted=0 AND c.Status='PUBLISHED' AND c.IsDeleted=0 AND e.Status<>'CANCELLED') RETURN;
 SELECT l.Id,l.CourseId,l.ChapterId,l.Title,l.Description,l.LessonType,l.DurationSeconds,l.PassingScore FROM dbo.Lessons l WHERE l.Id=@LessonId AND l.IsDeleted=0;
 SELECT c.Id,c.Code,c.Title,c.Slug,u.FullName TeacherName FROM dbo.Courses c JOIN dbo.Lessons l ON l.CourseId=c.Id JOIN dbo.Users u ON u.Id=c.TeacherId WHERE l.Id=@LessonId;
 SELECT v.Id,v.LessonId,v.Title,v.VideoUrl,v.PosterUrl,v.DurationSeconds,v.AllowSeek,v.AllowSpeed,v.RequiredWatchPercent FROM dbo.Videos v WHERE v.LessonId=@LessonId AND v.Status='ACTIVE';
 SELECT p.Id,p.CurrentTimeSeconds,p.MaxWatchedTimeSeconds,p.WatchedSeconds,p.WatchPercent,p.Completed FROM dbo.StudentVideoProgress p JOIN dbo.Videos v ON v.Id=p.VideoId WHERE v.LessonId=@LessonId AND p.StudentId=@StudentId;
 SELECT vi.Id,vi.VideoId,vi.QuestionId,vi.TimeSeconds,vi.EndTimeSeconds,vi.InteractionType,vi.Required,vi.PauseVideo,vi.AllowSkip,vi.Score,vi.AttemptLimit,vi.SortOrder,q.QuestionType,q.QuestionText,q.Description,q.Difficulty,
  (SELECT o.Id,o.OptionCode,o.OptionText,o.SortOrder FROM dbo.QuestionOptions o WHERE o.QuestionId=q.Id ORDER BY o.SortOrder FOR JSON PATH) Options
 FROM dbo.VideoInteractions vi JOIN dbo.Videos v ON v.Id=vi.VideoId JOIN dbo.Questions q ON q.Id=vi.QuestionId
 WHERE v.LessonId=@LessonId AND vi.IsDeleted=0 AND vi.Status='ACTIVE' AND q.IsDeleted=0 ORDER BY vi.TimeSeconds;
 /* Deliberately omit IsCorrect and answer keys from the player payload. */
 SELECT sa.InteractionId,sa.QuestionId,sa.ScoreAwarded,sa.ReviewStatus,sa.AttemptNumber,sa.AnswerText,sa.AnsweredAt
 FROM dbo.StudentAnswers sa WHERE sa.StudentId=@StudentId AND sa.LessonId=@LessonId;
END
GO

CREATE OR ALTER PROCEDURE dbo.LMS_Enrollment_RecalculateProgress @StudentId BIGINT,@CourseId BIGINT AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @TotalRequired INT=(SELECT COUNT(*) FROM dbo.Lessons WHERE CourseId=@CourseId AND IsRequired=1 AND IsDeleted=0 AND Status='ACTIVE');
 DECLARE @CompletedRequired INT=(SELECT COUNT(*) FROM dbo.Lessons l JOIN dbo.StudentLessonProgress p ON p.LessonId=l.Id AND p.StudentId=@StudentId AND p.Completed=1 WHERE l.CourseId=@CourseId AND l.IsRequired=1 AND l.IsDeleted=0 AND l.Status='ACTIVE');
 DECLARE @Progress DECIMAL(5,2)=CASE WHEN @TotalRequired=0 THEN 0 ELSE ROUND(@CompletedRequired*100.0/@TotalRequired,2) END;
 UPDATE dbo.Enrollments SET ProgressPercent=@Progress,
  Status=CASE WHEN @TotalRequired>0 AND @CompletedRequired=@TotalRequired THEN 'COMPLETED' WHEN Status='CANCELLED' THEN Status ELSE 'IN_PROGRESS' END,
  CompletedAt=CASE WHEN @TotalRequired>0 AND @CompletedRequired=@TotalRequired THEN COALESCE(CompletedAt,SYSUTCDATETIME()) ELSE NULL END,
  LastAccessAt=SYSUTCDATETIME()
 WHERE StudentId=@StudentId AND CourseId=@CourseId AND Status<>'CANCELLED';
END
GO

CREATE OR ALTER PROCEDURE dbo.LMS_LessonProgress_Recalculate @StudentId BIGINT,@LessonId BIGINT AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @CourseId BIGINT,@PassingScore DECIMAL(8,2),@VideoCount INT,@WatchPercent DECIMAL(5,2),@WatchSatisfied BIT,@InteractionsSatisfied BIT,@LessonScore DECIMAL(8,2),@Completed BIT;
 SELECT @CourseId=CourseId,@PassingScore=ISNULL(PassingScore,0) FROM dbo.Lessons WHERE Id=@LessonId AND IsDeleted=0;
 IF @CourseId IS NULL RETURN;
 SELECT @VideoCount=COUNT(*) FROM dbo.Videos WHERE LessonId=@LessonId AND Status='ACTIVE';
 SELECT @WatchPercent=ISNULL(AVG(ISNULL(p.WatchPercent,0)),0),
        @WatchSatisfied=IIF(COUNT(*)=SUM(IIF(ISNULL(p.WatchPercent,0)>=v.RequiredWatchPercent,1,0)),1,0)
 FROM dbo.Videos v LEFT JOIN dbo.StudentVideoProgress p ON p.VideoId=v.Id AND p.StudentId=@StudentId WHERE v.LessonId=@LessonId AND v.Status='ACTIVE';
 IF @VideoCount=0 BEGIN SET @WatchPercent=100; SET @WatchSatisfied=1; END;
 SET @InteractionsSatisfied=IIF(NOT EXISTS(
   SELECT 1 FROM dbo.VideoInteractions vi JOIN dbo.Videos v ON v.Id=vi.VideoId
   WHERE v.LessonId=@LessonId AND vi.Required=1 AND vi.IsDeleted=0 AND vi.Status='ACTIVE'
     AND NOT EXISTS(SELECT 1 FROM dbo.StudentAnswers a WHERE a.StudentId=@StudentId AND a.InteractionId=vi.Id)
 ),1,0);
 SELECT @LessonScore=ISNULL(SUM(x.BestScore),0) FROM (
   SELECT MAX(a.ScoreAwarded) BestScore FROM dbo.StudentAnswers a WHERE a.StudentId=@StudentId AND a.LessonId=@LessonId GROUP BY ISNULL(a.InteractionId,-a.QuestionId)
 ) x;
 SET @Completed=IIF(@WatchSatisfied=1 AND @InteractionsSatisfied=1 AND @LessonScore>=@PassingScore,1,0);
 MERGE dbo.StudentLessonProgress AS t
 USING(SELECT @StudentId StudentId,@LessonId LessonId,@CourseId CourseId) AS s ON t.StudentId=s.StudentId AND t.LessonId=s.LessonId
 WHEN MATCHED THEN UPDATE SET ProgressPercent=IIF(@Completed=1,100,@WatchPercent),Score=@LessonScore,Completed=@Completed,CompletedAt=IIF(@Completed=1,COALESCE(t.CompletedAt,SYSUTCDATETIME()),NULL),LastAccessAt=SYSUTCDATETIME(),UpdatedAt=SYSUTCDATETIME()
 WHEN NOT MATCHED THEN INSERT(StudentId,CourseId,LessonId,ProgressPercent,Score,AttemptCount,Completed,CompletedAt,LastAccessAt) VALUES(@StudentId,@CourseId,@LessonId,IIF(@Completed=1,100,@WatchPercent),@LessonScore,0,@Completed,IIF(@Completed=1,SYSUTCDATETIME(),NULL),SYSUTCDATETIME());
 EXEC dbo.LMS_Enrollment_RecalculateProgress @StudentId,@CourseId;
END
GO

CREATE OR ALTER PROCEDURE dbo.LMS_StudentVideoProgress_Save @StudentId BIGINT,@LessonId BIGINT,@VideoId BIGINT,@CurrentTimeSeconds DECIMAL(10,2),@MaxWatchedTimeSeconds DECIMAL(10,2),@WatchPercent DECIMAL(5,2) AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DECLARE @CourseId BIGINT,@Duration INT;
 SELECT @CourseId=l.CourseId,@Duration=v.DurationSeconds FROM dbo.Videos v JOIN dbo.Lessons l ON l.Id=v.LessonId WHERE v.Id=@VideoId AND l.Id=@LessonId AND l.IsDeleted=0 AND v.Status='ACTIVE';
 IF @CourseId IS NULL THROW 50001,N'Video hoặc bài học không hợp lệ.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Enrollments e JOIN dbo.Courses c ON c.Id=e.CourseId WHERE e.StudentId=@StudentId AND e.CourseId=@CourseId AND e.Status<>'CANCELLED' AND c.Status='PUBLISHED' AND c.IsDeleted=0) THROW 50003,N'Bạn chưa được ghi danh vào khóa học này.',1;
 SET @CurrentTimeSeconds=CASE WHEN @CurrentTimeSeconds<0 THEN 0 WHEN @CurrentTimeSeconds>@Duration THEN @Duration ELSE @CurrentTimeSeconds END;
 SET @MaxWatchedTimeSeconds=CASE WHEN @MaxWatchedTimeSeconds<0 THEN 0 WHEN @MaxWatchedTimeSeconds>@Duration THEN @Duration ELSE @MaxWatchedTimeSeconds END;
 BEGIN TRANSACTION;
 UPDATE dbo.StudentVideoProgress SET CurrentTimeSeconds=@CurrentTimeSeconds,
  MaxWatchedTimeSeconds=CASE WHEN MaxWatchedTimeSeconds>@MaxWatchedTimeSeconds THEN MaxWatchedTimeSeconds ELSE @MaxWatchedTimeSeconds END,
  WatchedSeconds=CASE WHEN WatchedSeconds>@MaxWatchedTimeSeconds THEN WatchedSeconds ELSE @MaxWatchedTimeSeconds END,
  WatchPercent=CASE WHEN WatchPercent>ROUND(@MaxWatchedTimeSeconds*100.0/NULLIF(@Duration,0),2) THEN WatchPercent ELSE ROUND(@MaxWatchedTimeSeconds*100.0/NULLIF(@Duration,0),2) END,
  LastAccessAt=SYSUTCDATETIME(),UpdatedAt=SYSUTCDATETIME()
 WHERE StudentId=@StudentId AND VideoId=@VideoId;
 IF @@ROWCOUNT=0 INSERT dbo.StudentVideoProgress(StudentId,CourseId,LessonId,VideoId,CurrentTimeSeconds,MaxWatchedTimeSeconds,WatchedSeconds,WatchPercent,Completed,LastAccessAt)
  VALUES(@StudentId,@CourseId,@LessonId,@VideoId,@CurrentTimeSeconds,@MaxWatchedTimeSeconds,@MaxWatchedTimeSeconds,ROUND(@MaxWatchedTimeSeconds*100.0/NULLIF(@Duration,0),2),0,SYSUTCDATETIME());
 DECLARE @Required DECIMAL(5,2)=(SELECT RequiredWatchPercent FROM dbo.Videos WHERE Id=@VideoId);
 UPDATE dbo.StudentVideoProgress SET Completed=IIF(WatchPercent>=@Required,1,0),CompletedAt=IIF(WatchPercent>=@Required,COALESCE(CompletedAt,SYSUTCDATETIME()),NULL) WHERE StudentId=@StudentId AND VideoId=@VideoId;
 EXEC dbo.LMS_LessonProgress_Recalculate @StudentId,@LessonId;
 COMMIT TRANSACTION;
END
GO

CREATE OR ALTER PROCEDURE dbo.LMS_StudentAnswer_Submit @StudentId BIGINT,@LessonId BIGINT,@VideoId BIGINT=NULL,@InteractionId BIGINT=NULL,@QuestionId BIGINT,@AnswerText NVARCHAR(MAX),@TimeInVideoSeconds DECIMAL(10,2)=NULL,@TimeSpentSeconds INT=NULL AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DECLARE @CourseId BIGINT,@Type VARCHAR(50),@Mode VARCHAR(30),@Score DECIMAL(8,2),@Correct NVARCHAR(MAX),@IsCorrect BIT,@Attempt INT,@AttemptLimit INT=1;
 SELECT @CourseId=CourseId FROM dbo.Lessons WHERE Id=@LessonId AND IsDeleted=0;
 SELECT @Type=QuestionType,@Mode=ShortAnswerMode,@Score=DefaultScore FROM dbo.Questions WHERE Id=@QuestionId AND IsDeleted=0 AND Status='ACTIVE';
 IF @CourseId IS NULL OR @Type IS NULL THROW 50002,N'Câu hỏi hoặc bài học không hợp lệ.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Enrollments e JOIN dbo.Courses c ON c.Id=e.CourseId WHERE e.StudentId=@StudentId AND e.CourseId=@CourseId AND e.Status<>'CANCELLED' AND c.Status='PUBLISHED' AND c.IsDeleted=0) THROW 50003,N'Bạn chưa được ghi danh vào khóa học này.',1;
 IF @VideoId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Videos WHERE Id=@VideoId AND LessonId=@LessonId AND Status='ACTIVE') THROW 50005,N'Video không thuộc bài học này.',1;
 IF @InteractionId IS NOT NULL
 BEGIN
   SELECT @AttemptLimit=vi.AttemptLimit,@Score=vi.Score FROM dbo.VideoInteractions vi JOIN dbo.Videos v ON v.Id=vi.VideoId WHERE vi.Id=@InteractionId AND vi.QuestionId=@QuestionId AND v.LessonId=@LessonId AND (@VideoId IS NULL OR v.Id=@VideoId) AND vi.IsDeleted=0 AND vi.Status='ACTIVE';
   IF @@ROWCOUNT=0 OR @AttemptLimit IS NULL THROW 50005,N'Câu hỏi không thuộc tương tác của bài học này.',1;
 END
 SELECT @Attempt=COUNT(*)+1 FROM dbo.StudentAnswers WHERE StudentId=@StudentId AND QuestionId=@QuestionId AND ISNULL(InteractionId,0)=ISNULL(@InteractionId,0);
 IF @Attempt>@AttemptLimit THROW 50004,N'Bạn đã sử dụng hết số lần trả lời cho câu hỏi này.',1;
 IF @Type IN('SINGLE_CHOICE','TRUE_FALSE','MULTIPLE_CHOICE')
 BEGIN
   SELECT @Correct=STRING_AGG(UPPER(LTRIM(RTRIM(OptionCode))),'|') WITHIN GROUP(ORDER BY UPPER(LTRIM(RTRIM(OptionCode)))) FROM dbo.QuestionOptions WHERE QuestionId=@QuestionId AND IsCorrect=1;
   SET @IsCorrect=IIF(UPPER(ISNULL(@AnswerText,''))=ISNULL(@Correct,''),1,0);
 END
 ELSE IF @Mode='MANUAL_REVIEW' SET @IsCorrect=NULL;
 ELSE IF @Mode='CONTAINS'
   SET @IsCorrect=IIF(EXISTS(SELECT 1 FROM dbo.QuestionAnswerKeys WHERE QuestionId=@QuestionId AND ((IsCaseSensitive=1 AND CHARINDEX(AnswerText,@AnswerText COLLATE Latin1_General_100_CS_AS)>0) OR (IsCaseSensitive=0 AND CHARINDEX(LOWER(AnswerText),LOWER(@AnswerText))>0))),1,0);
 ELSE
   SET @IsCorrect=IIF(EXISTS(SELECT 1 FROM dbo.QuestionAnswerKeys WHERE QuestionId=@QuestionId AND ((IsCaseSensitive=1 AND AnswerText=@AnswerText COLLATE Latin1_General_100_CS_AS) OR (IsCaseSensitive=0 AND LOWER(AnswerText)=LOWER(@AnswerText)))),1,0);
 BEGIN TRY
   BEGIN TRANSACTION;
   INSERT dbo.StudentAnswers(StudentId,CourseId,LessonId,VideoId,InteractionId,QuestionId,AttemptNumber,AnswerText,IsCorrect,ScoreAwarded,ReviewStatus,TimeInVideoSeconds,TimeSpentSeconds)
   VALUES(@StudentId,@CourseId,@LessonId,@VideoId,@InteractionId,@QuestionId,@Attempt,@AnswerText,@IsCorrect,IIF(@IsCorrect=1,@Score,0),IIF(@IsCorrect IS NULL,'PENDING_REVIEW','AUTO_GRADED'),@TimeInVideoSeconds,@TimeSpentSeconds);
   DECLARE @AnswerId BIGINT=SCOPE_IDENTITY();
   IF @Type IN('SINGLE_CHOICE','TRUE_FALSE','MULTIPLE_CHOICE')
     INSERT dbo.StudentAnswerOptions(StudentAnswerId,QuestionOptionId)
     SELECT @AnswerId,o.Id FROM dbo.QuestionOptions o JOIN STRING_SPLIT(@AnswerText,'|') s ON UPPER(LTRIM(RTRIM(s.value)))=UPPER(o.OptionCode) WHERE o.QuestionId=@QuestionId;
   EXEC dbo.LMS_LessonProgress_Recalculate @StudentId,@LessonId;
   SELECT @AnswerId AnswerId,@IsCorrect IsCorrect,CAST(IIF(@IsCorrect=1,@Score,0) AS DECIMAL(8,2)) ScoreAwarded,
    CAST((SELECT ISNULL(SUM(BestScore),0) FROM (SELECT MAX(ScoreAwarded) BestScore FROM dbo.StudentAnswers WHERE StudentId=@StudentId AND LessonId=@LessonId GROUP BY ISNULL(InteractionId,-QuestionId)) scores) AS DECIMAL(8,2)) CurrentLessonScore,
    @Attempt AttemptNumber,IIF(@IsCorrect IS NULL,'PENDING_REVIEW','AUTO_GRADED') ReviewStatus,(SELECT Explanation FROM dbo.Questions WHERE Id=@QuestionId) Explanation;
   COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
   IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
   THROW;
 END CATCH
END
GO
