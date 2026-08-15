CREATE OR ALTER PROCEDURE dbo.LMS_GlobalSearch
 @Search NVARCHAR(250),
 @ActorId BIGINT,
 @IsAdmin BIT=0,
 @Limit INT=60
AS
BEGIN
 SET NOCOUNT ON;

 DECLARE @Term NVARCHAR(250)=LTRIM(RTRIM(ISNULL(@Search,N'')));
 IF LEN(@Term)<2
 BEGIN
  SELECT TOP (0)
   CAST(NULL AS VARCHAR(30)) ResultType,
   CAST(NULL AS BIGINT) EntityId,
   CAST(NULL AS BIGINT) ParentId,
   CAST(NULL AS NVARCHAR(500)) Title,
   CAST(NULL AS NVARCHAR(1000)) Subtitle,
   CAST(NULL AS NVARCHAR(1000)) Description,
   CAST(NULL AS VARCHAR(30)) Status,
   CAST(NULL AS NVARCHAR(1000)) TargetUrl,
   CAST(NULL AS VARCHAR(100)) Icon,
   CAST(NULL AS DATETIME2) UpdatedAt,
   CAST(NULL AS INT) Relevance;
  RETURN;
 END;

 SET @Limit=IIF(@Limit BETWEEN 1 AND 100,@Limit,60);
 DECLARE @Pattern NVARCHAR(520)=N'%'+REPLACE(REPLACE(REPLACE(@Term,N'[',N'[[]'),N'%',N'[%]'),N'_',N'[_]')+N'%';
 DECLARE @StartsWith NVARCHAR(510)=REPLACE(REPLACE(REPLACE(@Term,N'[',N'[[]'),N'%',N'[%]'),N'_',N'[_]')+N'%';

 DECLARE @Results TABLE(
  ResultType VARCHAR(30) NOT NULL,
  EntityId BIGINT NOT NULL,
  ParentId BIGINT NULL,
  Title NVARCHAR(500) NOT NULL,
  Subtitle NVARCHAR(1000) NULL,
  Description NVARCHAR(1000) NULL,
  Status VARCHAR(30) NULL,
  TargetUrl NVARCHAR(1000) NOT NULL,
  Icon VARCHAR(100) NOT NULL,
  UpdatedAt DATETIME2 NULL,
  Relevance INT NOT NULL
 );

 INSERT @Results(ResultType,EntityId,ParentId,Title,Subtitle,Description,Status,TargetUrl,Icon,UpdatedAt,Relevance)
 SELECT 'COURSE',c.Id,NULL,c.Title,
  CONCAT(c.Code,N' · ',ISNULL(cat.Name,N'Chưa phân loại'),N' · ',teacher.FullName),
  LEFT(COALESCE(c.ShortDescription,c.Description,N''),1000),c.Status,
  CONCAT(N'/cms/courses/',c.Id,N'/content'),'bi-journal-bookmark',COALESCE(c.UpdatedAt,c.CreatedAt),
  CASE WHEN c.Code=@Term THEN 120 WHEN c.Title=@Term THEN 115 WHEN c.Code LIKE @StartsWith THEN 100 WHEN c.Title LIKE @StartsWith THEN 90 ELSE 60 END
 FROM dbo.Courses c
 JOIN dbo.Users teacher ON teacher.Id=c.TeacherId
 LEFT JOIN dbo.CourseCategories cat ON cat.Id=c.CategoryId
 WHERE c.IsDeleted=0 AND (@IsAdmin=1 OR c.TeacherId=@ActorId)
  AND (c.Code LIKE @Pattern OR c.Title LIKE @Pattern OR c.ShortDescription LIKE @Pattern OR c.Description LIKE @Pattern OR cat.Name LIKE @Pattern OR teacher.FullName LIKE @Pattern);

 INSERT @Results(ResultType,EntityId,ParentId,Title,Subtitle,Description,Status,TargetUrl,Icon,UpdatedAt,Relevance)
 SELECT 'LESSON',l.Id,l.CourseId,l.Title,
  CONCAT(c.Code,N' · ',c.Title,N' · ',ch.Title),LEFT(ISNULL(l.Description,N''),1000),l.Status,
  CONCAT(N'/cms/courses/',l.CourseId,N'/content'),'bi-play-btn',COALESCE(l.UpdatedAt,l.CreatedAt),
  CASE WHEN l.Title=@Term THEN 110 WHEN l.Title LIKE @StartsWith THEN 85 ELSE 55 END
 FROM dbo.Lessons l
 JOIN dbo.Courses c ON c.Id=l.CourseId AND c.IsDeleted=0
 JOIN dbo.Chapters ch ON ch.Id=l.ChapterId AND ch.IsDeleted=0
 WHERE l.IsDeleted=0 AND (@IsAdmin=1 OR c.TeacherId=@ActorId)
  AND (l.Title LIKE @Pattern OR l.Description LIKE @Pattern OR c.Code LIKE @Pattern OR c.Title LIKE @Pattern OR ch.Title LIKE @Pattern);

 INSERT @Results(ResultType,EntityId,ParentId,Title,Subtitle,Description,Status,TargetUrl,Icon,UpdatedAt,Relevance)
 SELECT 'VIDEO',a.Id,ownedUse.FirstVideoId,a.Title,
  CONCAT(COALESCE(NULLIF(a.OriginalFileName,N''),N'Tệp video'),N' · ',a.DurationSeconds,N' giây · Đang dùng ',usageInfo.UsageCount,N' bài học'),
  N'Video trong thư viện dùng chung cho nhiều bài học và khóa học.',a.Status,
  CASE WHEN ownedUse.FirstVideoId IS NULL THEN N'/cms/videos' ELSE CONCAT(N'/cms/videos/',ownedUse.FirstVideoId,N'/editor') END,
  'bi-collection-play',COALESCE(a.UpdatedAt,a.CreatedAt),
  CASE WHEN a.Title=@Term THEN 110 WHEN a.Title LIKE @StartsWith THEN 85 WHEN a.OriginalFileName LIKE @StartsWith THEN 80 ELSE 55 END
 FROM dbo.VideoAssets a
 OUTER APPLY(SELECT COUNT(*) UsageCount FROM dbo.Videos v JOIN dbo.Lessons l ON l.VideoId=v.Id AND l.IsDeleted=0 WHERE v.VideoAssetId=a.Id) usageInfo
 OUTER APPLY(SELECT MIN(v.Id) FirstVideoId FROM dbo.Videos v WHERE v.VideoAssetId=a.Id) ownedUse
 WHERE a.IsDeleted=0
  AND (@IsAdmin=1 OR a.CreatedBy=@ActorId OR a.ShareScope='SCHOOL' OR EXISTS(SELECT 1 FROM dbo.VideoAssetShares s WHERE s.VideoAssetId=a.Id AND s.TeacherId=@ActorId))
  AND (a.Title LIKE @Pattern OR a.OriginalFileName LIKE @Pattern OR a.VideoUrl LIKE @Pattern);

 INSERT @Results(ResultType,EntityId,ParentId,Title,Subtitle,Description,Status,TargetUrl,Icon,UpdatedAt,Relevance)
 SELECT 'QUESTION',q.Id,NULL,LEFT(q.QuestionText,500),
  CONCAT(q.QuestionType,N' · ',q.Difficulty,N' · ',q.DefaultScore,N' điểm'),LEFT(COALESCE(q.Description,q.Explanation,N''),1000),q.Status,
  CONCAT(N'/cms/questions?edit=',q.Id),'bi-patch-question',COALESCE(q.UpdatedAt,q.CreatedAt),
  CASE WHEN q.QuestionText=@Term THEN 110 WHEN q.QuestionText LIKE @StartsWith THEN 85 ELSE 55 END
 FROM dbo.Questions q
 WHERE q.IsDeleted=0 AND (q.QuestionText LIKE @Pattern OR q.Description LIKE @Pattern OR q.Explanation LIKE @Pattern OR q.QuestionType LIKE @Pattern OR q.Difficulty LIKE @Pattern);

 INSERT @Results(ResultType,EntityId,ParentId,Title,Subtitle,Description,Status,TargetUrl,Icon,UpdatedAt,Relevance)
 SELECT 'STUDENT',u.Id,NULL,u.FullName,
  CONCAT(COALESCE(NULLIF(u.StudentCode,N''),u.Username),N' · ',u.Email),
  CONCAT(N'Đang tham gia ',(SELECT COUNT(*) FROM dbo.Enrollments e WHERE e.StudentId=u.Id AND e.Status<>'CANCELLED'),N' khóa học.'),u.Status,
  CONCAT(N'/cms/enrollments?studentId=',u.Id),'bi-people',COALESCE(u.UpdatedAt,u.CreatedAt),
  CASE WHEN u.StudentCode=@Term OR u.Username=@Term THEN 120 WHEN u.FullName=@Term THEN 110 WHEN u.StudentCode LIKE @StartsWith OR u.Username LIKE @StartsWith THEN 95 WHEN u.FullName LIKE @StartsWith THEN 85 ELSE 55 END
 FROM dbo.Users u
 WHERE u.IsDeleted=0 AND u.StudentCode IS NOT NULL
  AND (u.FullName LIKE @Pattern OR u.StudentCode LIKE @Pattern OR u.Username LIKE @Pattern OR u.Email LIKE @Pattern);

 SELECT TOP (@Limit) ResultType,EntityId,ParentId,Title,Subtitle,Description,Status,TargetUrl,Icon,UpdatedAt,Relevance
 FROM @Results
 ORDER BY Relevance DESC,UpdatedAt DESC,ResultType,Title;
END
GO
