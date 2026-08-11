CREATE OR ALTER PROCEDURE dbo.LMS_Course_GetList @Search NVARCHAR(500)=NULL,@Status VARCHAR(30)=NULL,@Page INT=1,@PageSize INT=20 AS
BEGIN SET NOCOUNT ON;
 ;WITH Data AS (SELECT c.Id,c.Code,c.Title,c.Slug,c.ThumbnailUrl,c.ShortDescription,u.FullName TeacherName,c.Level,c.Status,c.CreatedAt,
  (SELECT COUNT(*) FROM dbo.Lessons l WHERE l.CourseId=c.Id AND l.IsDeleted=0) LessonCount,
  (SELECT COUNT(*) FROM dbo.Enrollments e WHERE e.CourseId=c.Id AND e.Status<>'CANCELLED') StudentCount
 FROM dbo.Courses c JOIN dbo.Users u ON u.Id=c.TeacherId WHERE c.IsDeleted=0 AND (@Status IS NULL OR @Status='' OR c.Status=@Status) AND (@Search IS NULL OR @Search='' OR c.Title LIKE '%'+@Search+'%' OR c.Code LIKE '%'+@Search+'%'))
 SELECT * FROM Data ORDER BY CreatedAt DESC OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
 SELECT COUNT(*) FROM dbo.Courses c WHERE c.IsDeleted=0 AND (@Status IS NULL OR @Status='' OR c.Status=@Status) AND (@Search IS NULL OR @Search='' OR c.Title LIKE '%'+@Search+'%' OR c.Code LIKE '%'+@Search+'%');
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Course_GetById @Id BIGINT AS
BEGIN SET NOCOUNT ON; SELECT c.*,u.FullName TeacherName,cc.Name CategoryName FROM dbo.Courses c JOIN dbo.Users u ON u.Id=c.TeacherId LEFT JOIN dbo.CourseCategories cc ON cc.Id=c.CategoryId WHERE c.Id=@Id AND c.IsDeleted=0; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Course_GetContent @CourseId BIGINT AS
BEGIN SET NOCOUNT ON; SELECT Id,CourseId,Title,Description,SortOrder,Status FROM dbo.Chapters WHERE CourseId=@CourseId AND IsDeleted=0 ORDER BY SortOrder; SELECT l.Id,l.CourseId,l.ChapterId,l.Title,l.Description,l.LessonType,l.DurationSeconds,l.SortOrder,l.IsRequired,l.PassingScore,l.Status,v.Id VideoId,v.VideoAssetId,v.Title VideoTitle,v.VideoUrl FROM dbo.Lessons l LEFT JOIN dbo.Videos v ON v.LessonId=l.Id WHERE l.CourseId=@CourseId AND l.IsDeleted=0 ORDER BY l.ChapterId,l.SortOrder; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Course_Create
 @Code NVARCHAR(100),@Title NVARCHAR(500),@Slug NVARCHAR(500)=NULL,@ThumbnailUrl NVARCHAR(1000)=NULL,@ShortDescription NVARCHAR(1000)=NULL,@Description NVARCHAR(MAX)=NULL,
 @TeacherId BIGINT,@CategoryId BIGINT=NULL,@Level VARCHAR(50),@PassingScore DECIMAL(5,2),@Status VARCHAR(30),@ActorId BIGINT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SET @Code=LTRIM(RTRIM(@Code)); SET @Title=LTRIM(RTRIM(@Title)); SET @Slug=COALESCE(NULLIF(LTRIM(RTRIM(@Slug)),''),LOWER(REPLACE(@Code,' ','-')));
 IF @Code='' OR @Title='' OR @PassingScore<0 OR @PassingScore>100 OR @Status NOT IN('DRAFT','PUBLISHED','ARCHIVED') THROW 50001,N'Dữ liệu khóa học không hợp lệ.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Users WHERE Id=@TeacherId AND TeacherCode IS NOT NULL AND IsDeleted=0) THROW 50002,N'Giảng viên không tồn tại.',1;
 IF @CategoryId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CourseCategories WHERE Id=@CategoryId AND Status='ACTIVE') THROW 50002,N'Danh mục không tồn tại.',1;
 IF EXISTS(SELECT 1 FROM dbo.Courses WHERE (Code=@Code OR Slug=@Slug) AND IsDeleted=0) THROW 50006,N'Mã hoặc slug khóa học đã tồn tại.',1;
 BEGIN TRANSACTION;
 INSERT dbo.Courses(Code,Title,Slug,ThumbnailUrl,ShortDescription,Description,TeacherId,CategoryId,Level,PassingScore,Status,PublishedAt,CreatedBy)
 VALUES(@Code,@Title,@Slug,@ThumbnailUrl,@ShortDescription,@Description,@TeacherId,@CategoryId,@Level,@PassingScore,@Status,IIF(@Status='PUBLISHED',SYSUTCDATETIME(),NULL),@ActorId);
 DECLARE @Id BIGINT=SCOPE_IDENTITY();
 INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId,NewValuesJson,CreatedAt) VALUES(@ActorId,'CREATE','COURSE','Course',CONVERT(NVARCHAR(100),@Id),(SELECT @Code code,@Title title,@Status status FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),SYSUTCDATETIME());
 COMMIT TRANSACTION; SELECT @Id;
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Course_Update
 @Id BIGINT,@Code NVARCHAR(100),@Title NVARCHAR(500),@Slug NVARCHAR(500)=NULL,@ThumbnailUrl NVARCHAR(1000)=NULL,@ShortDescription NVARCHAR(1000)=NULL,@Description NVARCHAR(MAX)=NULL,
 @TeacherId BIGINT,@CategoryId BIGINT=NULL,@Level VARCHAR(50),@PassingScore DECIMAL(5,2),@Status VARCHAR(30),@ActorId BIGINT,@IsAdmin BIT=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SET @Code=LTRIM(RTRIM(@Code)); SET @Title=LTRIM(RTRIM(@Title)); SET @Slug=COALESCE(NULLIF(LTRIM(RTRIM(@Slug)),''),LOWER(REPLACE(@Code,' ','-')));
 IF @Code='' OR @Title='' OR @PassingScore<0 OR @PassingScore>100 OR @Status NOT IN('DRAFT','PUBLISHED','ARCHIVED') THROW 50001,N'Dữ liệu khóa học không hợp lệ.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Users WHERE Id=@TeacherId AND TeacherCode IS NOT NULL AND IsDeleted=0) THROW 50002,N'Giảng viên không tồn tại.',1;
 IF @CategoryId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CourseCategories WHERE Id=@CategoryId AND Status='ACTIVE') THROW 50002,N'Danh mục không tồn tại.',1;
 IF EXISTS(SELECT 1 FROM dbo.Courses WHERE Id<>@Id AND (Code=@Code OR Slug=@Slug) AND IsDeleted=0) THROW 50006,N'Mã hoặc slug khóa học đã tồn tại.',1;
 DECLARE @Old NVARCHAR(MAX)=(SELECT Code code,Title title,Status status FROM dbo.Courses WHERE Id=@Id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 BEGIN TRANSACTION;
 UPDATE dbo.Courses SET Code=@Code,Title=@Title,Slug=@Slug,ThumbnailUrl=@ThumbnailUrl,ShortDescription=@ShortDescription,Description=@Description,TeacherId=@TeacherId,CategoryId=@CategoryId,Level=@Level,PassingScore=@PassingScore,Status=@Status,PublishedAt=IIF(@Status='PUBLISHED',COALESCE(PublishedAt,SYSUTCDATETIME()),PublishedAt),UpdatedAt=SYSUTCDATETIME(),UpdatedBy=@ActorId
 WHERE Id=@Id AND IsDeleted=0 AND (@IsAdmin=1 OR TeacherId=@ActorId);
 DECLARE @Rows INT=@@ROWCOUNT;
 IF @Rows>0 INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId,OldValuesJson,NewValuesJson,CreatedAt) VALUES(@ActorId,'UPDATE','COURSE','Course',CONVERT(NVARCHAR(100),@Id),@Old,(SELECT @Code code,@Title title,@Status status FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),SYSUTCDATETIME());
 COMMIT TRANSACTION; SELECT @Rows;
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Course_ChangeStatus @Id BIGINT,@Status VARCHAR(30),@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @Status NOT IN('PUBLISHED','ARCHIVED','DRAFT') THROW 50001,N'Trạng thái khóa học không hợp lệ.',1;
 DECLARE @OldStatus VARCHAR(30)=(SELECT Status FROM dbo.Courses WHERE Id=@Id AND IsDeleted=0);
 BEGIN TRANSACTION;
 UPDATE dbo.Courses SET Status=@Status,PublishedAt=IIF(@Status='PUBLISHED',COALESCE(PublishedAt,SYSUTCDATETIME()),PublishedAt),UpdatedAt=SYSUTCDATETIME(),UpdatedBy=@ActorId WHERE Id=@Id AND IsDeleted=0 AND (@IsAdmin=1 OR TeacherId=@ActorId);
 DECLARE @Rows INT=@@ROWCOUNT;
 IF @Rows>0 INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId,OldValuesJson,NewValuesJson,CreatedAt) VALUES(@ActorId,@Status,'COURSE','Course',CONVERT(NVARCHAR(100),@Id),(SELECT @OldStatus status FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),(SELECT @Status status FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),SYSUTCDATETIME());
 COMMIT TRANSACTION; SELECT @Rows;
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Course_Publish @Id BIGINT,@UserId BIGINT AS BEGIN SET NOCOUNT ON; EXEC dbo.LMS_Course_ChangeStatus @Id,'PUBLISHED',@UserId,1; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Course_Delete @Id BIGINT,@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Courses WHERE Id=@Id AND IsDeleted=0 AND (@IsAdmin=1 OR TeacherId=@ActorId)) BEGIN SELECT 0; RETURN; END;
 BEGIN TRANSACTION;
 UPDATE dbo.Courses SET IsDeleted=1,UpdatedAt=SYSUTCDATETIME(),UpdatedBy=@ActorId WHERE Id=@Id;
 UPDATE dbo.Chapters SET IsDeleted=1,UpdatedAt=SYSUTCDATETIME() WHERE CourseId=@Id;
 UPDATE dbo.Lessons SET IsDeleted=1,UpdatedAt=SYSUTCDATETIME() WHERE CourseId=@Id;
 UPDATE vi SET IsDeleted=1,UpdatedAt=SYSUTCDATETIME() FROM dbo.VideoInteractions vi JOIN dbo.Videos v ON v.Id=vi.VideoId JOIN dbo.Lessons l ON l.Id=v.LessonId WHERE l.CourseId=@Id;
 INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId,NewValuesJson,CreatedAt) VALUES(@ActorId,'DELETE','COURSE','Course',CONVERT(NVARCHAR(100),@Id),N'{"isDeleted":true}',SYSUTCDATETIME());
 COMMIT TRANSACTION; SELECT 1;
END
GO
