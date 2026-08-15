CREATE OR ALTER PROCEDURE dbo.LMS_Chapter_GetByCourse @CourseId BIGINT,@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; IF NOT EXISTS(SELECT 1 FROM dbo.Courses WHERE Id=@CourseId AND IsDeleted=0 AND (@IsAdmin=1 OR TeacherId=@ActorId)) THROW 50003,N'Bạn không có quyền quản lý khóa học này.',1; SELECT Id,CourseId,Title,Description,SortOrder,Status FROM dbo.Chapters WHERE CourseId=@CourseId AND IsDeleted=0 ORDER BY SortOrder,Id; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Chapter_Create @CourseId BIGINT,@Title NVARCHAR(500),@Description NVARCHAR(1000)=NULL,@SortOrder INT,@Status VARCHAR(30),@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; IF NULLIF(LTRIM(RTRIM(@Title)),'') IS NULL OR @SortOrder<1 THROW 50001,N'Dữ liệu chương không hợp lệ.',1; IF NOT EXISTS(SELECT 1 FROM dbo.Courses WHERE Id=@CourseId AND IsDeleted=0 AND (@IsAdmin=1 OR TeacherId=@ActorId)) THROW 50003,N'Bạn không có quyền quản lý khóa học này.',1; INSERT dbo.Chapters(CourseId,Title,Description,SortOrder,Status) VALUES(@CourseId,@Title,@Description,@SortOrder,@Status); DECLARE @Id BIGINT=SCOPE_IDENTITY(); INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId,NewValuesJson) VALUES(@ActorId,'CREATE','CHAPTER','Chapter',CONVERT(NVARCHAR(100),@Id),(SELECT @Title title FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)); SELECT @Id; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Chapter_Update @Id BIGINT,@Title NVARCHAR(500),@Description NVARCHAR(1000)=NULL,@SortOrder INT,@Status VARCHAR(30),@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; IF NULLIF(LTRIM(RTRIM(@Title)),'') IS NULL OR @SortOrder<1 THROW 50001,N'Dữ liệu chương không hợp lệ.',1; UPDATE ch SET Title=@Title,Description=@Description,SortOrder=@SortOrder,Status=@Status,UpdatedAt=SYSUTCDATETIME() FROM dbo.Chapters ch JOIN dbo.Courses c ON c.Id=ch.CourseId WHERE ch.Id=@Id AND ch.IsDeleted=0 AND (@IsAdmin=1 OR c.TeacherId=@ActorId); DECLARE @Rows INT=@@ROWCOUNT; IF @Rows>0 INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'UPDATE','CHAPTER','Chapter',CONVERT(NVARCHAR(100),@Id)); SELECT @Rows; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Chapter_Delete @Id BIGINT,@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRANSACTION; UPDATE ch SET IsDeleted=1,UpdatedAt=SYSUTCDATETIME() FROM dbo.Chapters ch JOIN dbo.Courses c ON c.Id=ch.CourseId WHERE ch.Id=@Id AND ch.IsDeleted=0 AND (@IsAdmin=1 OR c.TeacherId=@ActorId); DECLARE @Rows INT=@@ROWCOUNT; IF @Rows>0 BEGIN UPDATE dbo.Lessons SET IsDeleted=1,UpdatedAt=SYSUTCDATETIME() WHERE ChapterId=@Id; INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'DELETE','CHAPTER','Chapter',CONVERT(NVARCHAR(100),@Id)); END; COMMIT; SELECT @Rows; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Chapter_Reorder @Id BIGINT,@SortOrder INT,@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; UPDATE ch SET SortOrder=@SortOrder,UpdatedAt=SYSUTCDATETIME() FROM dbo.Chapters ch JOIN dbo.Courses c ON c.Id=ch.CourseId WHERE ch.Id=@Id AND ch.IsDeleted=0 AND (@IsAdmin=1 OR c.TeacherId=@ActorId); IF @@ROWCOUNT=0 THROW 50003,N'Không thể sắp xếp chương này.',1; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Lesson_GetById @Id BIGINT,@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; SELECT l.* FROM dbo.Lessons l JOIN dbo.Courses c ON c.Id=l.CourseId WHERE l.Id=@Id AND l.IsDeleted=0 AND (@IsAdmin=1 OR c.TeacherId=@ActorId); END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Lesson_Create @ChapterId BIGINT,@Title NVARCHAR(500),@Description NVARCHAR(1000)=NULL,@LessonType VARCHAR(50),@DurationSeconds INT,@SortOrder INT,@IsRequired BIT,@PassingScore DECIMAL(5,2)=NULL,@Status VARCHAR(30),@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; DECLARE @CourseId BIGINT=(SELECT ch.CourseId FROM dbo.Chapters ch JOIN dbo.Courses c ON c.Id=ch.CourseId WHERE ch.Id=@ChapterId AND ch.IsDeleted=0 AND (@IsAdmin=1 OR c.TeacherId=@ActorId)); IF @CourseId IS NULL THROW 50003,N'Bạn không có quyền quản lý chương này.',1; IF NULLIF(LTRIM(RTRIM(@Title)),'') IS NULL OR @LessonType NOT IN('VIDEO','INTERACTIVE_VIDEO','QUIZ','DOCUMENT') OR @DurationSeconds<0 OR @SortOrder<1 OR @PassingScore NOT BETWEEN 0 AND 100 THROW 50001,N'Dữ liệu bài học không hợp lệ.',1; INSERT dbo.Lessons(CourseId,ChapterId,Title,Description,LessonType,DurationSeconds,SortOrder,IsRequired,PassingScore,Status) VALUES(@CourseId,@ChapterId,@Title,@Description,@LessonType,@DurationSeconds,@SortOrder,@IsRequired,@PassingScore,@Status); DECLARE @Id BIGINT=SCOPE_IDENTITY(); INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'CREATE','LESSON','Lesson',CONVERT(NVARCHAR(100),@Id)); SELECT @Id; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Lesson_Update @Id BIGINT,@Title NVARCHAR(500),@Description NVARCHAR(1000)=NULL,@LessonType VARCHAR(50),@DurationSeconds INT,@SortOrder INT,@IsRequired BIT,@PassingScore DECIMAL(5,2)=NULL,@Status VARCHAR(30),@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; IF NULLIF(LTRIM(RTRIM(@Title)),'') IS NULL OR @LessonType NOT IN('VIDEO','INTERACTIVE_VIDEO','QUIZ','DOCUMENT') OR @DurationSeconds<0 OR @SortOrder<1 OR @PassingScore NOT BETWEEN 0 AND 100 THROW 50001,N'Dữ liệu bài học không hợp lệ.',1; UPDATE l SET Title=@Title,Description=@Description,LessonType=@LessonType,DurationSeconds=@DurationSeconds,SortOrder=@SortOrder,IsRequired=@IsRequired,PassingScore=@PassingScore,Status=@Status,UpdatedAt=SYSUTCDATETIME() FROM dbo.Lessons l JOIN dbo.Courses c ON c.Id=l.CourseId WHERE l.Id=@Id AND l.IsDeleted=0 AND (@IsAdmin=1 OR c.TeacherId=@ActorId); DECLARE @Rows INT=@@ROWCOUNT; IF @Rows>0 INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'UPDATE','LESSON','Lesson',CONVERT(NVARCHAR(100),@Id)); SELECT @Rows; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Lesson_Delete @Id BIGINT,@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; UPDATE l SET IsDeleted=1,UpdatedAt=SYSUTCDATETIME() FROM dbo.Lessons l JOIN dbo.Courses c ON c.Id=l.CourseId WHERE l.Id=@Id AND l.IsDeleted=0 AND (@IsAdmin=1 OR c.TeacherId=@ActorId); DECLARE @Rows INT=@@ROWCOUNT; IF @Rows>0 INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'DELETE','LESSON','Lesson',CONVERT(NVARCHAR(100),@Id)); SELECT @Rows; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Lesson_Reorder @Id BIGINT,@SortOrder INT,@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; UPDATE l SET SortOrder=@SortOrder,UpdatedAt=SYSUTCDATETIME() FROM dbo.Lessons l JOIN dbo.Courses c ON c.Id=l.CourseId WHERE l.Id=@Id AND l.IsDeleted=0 AND (@IsAdmin=1 OR c.TeacherId=@ActorId); IF @@ROWCOUNT=0 THROW 50003,N'Không thể sắp xếp bài học này.',1; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Video_GetById @Id BIGINT,@ActorId BIGINT,@IsAdmin BIT=0 AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM dbo.Videos WHERE Id=@Id) AND NOT EXISTS(SELECT 1 FROM dbo.Videos v JOIN dbo.VideoAssets a ON a.Id=v.VideoAssetId WHERE v.Id=@Id AND a.IsDeleted=0 AND (@IsAdmin=1 OR a.CreatedBy=@ActorId)) THROW 50003,N'Bạn không có quyền quản lý video này.',1; SELECT v.*,a.CreatedBy,a.ShareScope,(SELECT COUNT(*) FROM dbo.Lessons l WHERE l.VideoId=v.Id AND l.IsDeleted=0) AssetUsageCount FROM dbo.Videos v JOIN dbo.VideoAssets a ON a.Id=v.VideoAssetId WHERE v.Id=@Id AND a.IsDeleted=0 AND (@IsAdmin=1 OR a.CreatedBy=@ActorId); END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Video_Create @Id BIGINT=NULL,@LessonId BIGINT,@Title NVARCHAR(500),@VideoUrl NVARCHAR(1000)=NULL,@PosterUrl NVARCHAR(1000)=NULL,@DurationSeconds INT,@AllowSeek BIT,@AllowSpeed BIT,@RequiredWatchPercent DECIMAL(5,2),@Status VARCHAR(30),@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; SET XACT_ABORT ON; IF @DurationSeconds<=0 OR @RequiredWatchPercent NOT BETWEEN 0 AND 100 THROW 50001,N'Dữ liệu video không hợp lệ.',1; IF @VideoUrl IS NOT NULL AND (@VideoUrl NOT LIKE '/Media/Video/%' OR @VideoUrl LIKE '%..%' OR @VideoUrl LIKE '%\%' OR @VideoUrl LIKE '%?%' OR @VideoUrl LIKE '%#%') THROW 50001,N'VideoUrl phải là URL tương đối an toàn trong /Media/Video/.',1; IF NOT EXISTS(SELECT 1 FROM dbo.Lessons l JOIN dbo.Courses c ON c.Id=l.CourseId WHERE l.Id=@LessonId AND l.IsDeleted=0 AND (@IsAdmin=1 OR c.TeacherId=@ActorId)) THROW 50003,N'Bạn không có quyền quản lý bài học này.',1; BEGIN TRANSACTION; INSERT dbo.VideoAssets(Title,VideoUrl,PosterUrl,DurationSeconds,CreatedBy,Status) VALUES(@Title,@VideoUrl,@PosterUrl,@DurationSeconds,@ActorId,@Status); DECLARE @AssetId BIGINT=SCOPE_IDENTITY(); INSERT dbo.Videos(VideoAssetId,Title,VideoUrl,PosterUrl,DurationSeconds,AllowSeek,AllowSpeed,RequiredWatchPercent,Status) VALUES(@AssetId,@Title,@VideoUrl,@PosterUrl,@DurationSeconds,@AllowSeek,@AllowSpeed,@RequiredWatchPercent,@Status); DECLARE @VideoId BIGINT=SCOPE_IDENTITY(); UPDATE dbo.Lessons SET VideoId=@VideoId,DurationSeconds=@DurationSeconds,UpdatedAt=SYSUTCDATETIME() WHERE Id=@LessonId; INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'CREATE','VIDEO','Video',CONVERT(NVARCHAR(100),@VideoId)); COMMIT; SELECT @VideoId; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Video_Update @Id BIGINT,@LessonId BIGINT,@Title NVARCHAR(500),@VideoUrl NVARCHAR(1000)=NULL,@PosterUrl NVARCHAR(1000)=NULL,@DurationSeconds INT,@AllowSeek BIT,@AllowSpeed BIT,@RequiredWatchPercent DECIMAL(5,2),@Status VARCHAR(30),@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; SET XACT_ABORT ON; IF @DurationSeconds<=0 OR @RequiredWatchPercent NOT BETWEEN 0 AND 100 THROW 50001,N'Dữ liệu video không hợp lệ.',1; IF @VideoUrl IS NOT NULL AND (@VideoUrl NOT LIKE '/Media/Video/%' OR @VideoUrl LIKE '%..%' OR @VideoUrl LIKE '%\%' OR @VideoUrl LIKE '%?%' OR @VideoUrl LIKE '%#%') THROW 50001,N'VideoUrl phải là URL tương đối an toàn trong /Media/Video/.',1; DECLARE @AssetId BIGINT=(SELECT v.VideoAssetId FROM dbo.Videos v JOIN dbo.VideoAssets a ON a.Id=v.VideoAssetId WHERE v.Id=@Id AND a.IsDeleted=0 AND (@IsAdmin=1 OR a.CreatedBy=@ActorId)); IF @AssetId IS NULL THROW 50003,N'Bạn không có quyền quản lý video này.',1; BEGIN TRANSACTION; UPDATE dbo.Videos SET Title=@Title,VideoUrl=@VideoUrl,PosterUrl=@PosterUrl,DurationSeconds=@DurationSeconds,AllowSeek=@AllowSeek,AllowSpeed=@AllowSpeed,RequiredWatchPercent=@RequiredWatchPercent,Status=@Status,UpdatedAt=SYSUTCDATETIME() WHERE Id=@Id; UPDATE dbo.VideoAssets SET Title=@Title,VideoUrl=@VideoUrl,PosterUrl=@PosterUrl,DurationSeconds=@DurationSeconds,Status=@Status,UpdatedAt=SYSUTCDATETIME() WHERE Id=@AssetId; UPDATE l SET DurationSeconds=@DurationSeconds,UpdatedAt=SYSUTCDATETIME() FROM dbo.Lessons l WHERE l.VideoId=@Id AND l.IsDeleted=0; INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'UPDATE','VIDEO','Video',CONVERT(NVARCHAR(100),@Id)); COMMIT; SELECT @Id; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_VideoLibrary_GetList
 @Search NVARCHAR(500)=NULL,@Access VARCHAR(30)='ALL',@Source VARCHAR(30)='ALL',@Usage VARCHAR(30)='ALL',@Status VARCHAR(30)='ALL',@ActorId BIGINT,@IsAdmin BIT=0
AS
BEGIN
 SET NOCOUNT ON;
 SELECT a.Id,a.Title,a.VideoUrl,a.PosterUrl,a.DurationSeconds,a.OriginalFileName,a.FileSize,a.MimeType,a.Status,a.CreatedAt,
  a.CreatedBy,u.FullName CreatedByName,a.ShareScope,ISNULL(useInfo.UsageCount,0) UsageCount,videoInfo.VideoId,videoInfo.VideoId FirstVideoId,
  CAST(IIF(a.CreatedBy=@ActorId,1,0) AS BIT) IsOwner,CAST(IIF(@IsAdmin=1 OR a.CreatedBy=@ActorId,1,0) AS BIT) CanEdit,CAST(IIF(@IsAdmin=1 OR a.CreatedBy=@ActorId,1,0) AS BIT) CanShare,
  CAST(IIF((@IsAdmin=1 OR a.CreatedBy=@ActorId) AND ISNULL(useInfo.UsageCount,0)=0,1,0) AS BIT) CanDelete,
  CASE WHEN a.CreatedBy=@ActorId THEN 'OWNER' WHEN a.ShareScope='SCHOOL' THEN 'SCHOOL' WHEN directShare.IsShared=1 THEN 'SHARED' ELSE 'ADMIN' END AccessType,
  ISNULL(shareInfo.ShareCount,0) SharedTeacherCount
 FROM dbo.VideoAssets a
 JOIN dbo.Users u ON u.Id=a.CreatedBy
 OUTER APPLY(SELECT COUNT(*) UsageCount FROM dbo.Videos v JOIN dbo.Lessons l ON l.VideoId=v.Id AND l.IsDeleted=0 WHERE v.VideoAssetId=a.Id) useInfo
 OUTER APPLY(SELECT MIN(v.Id) VideoId FROM dbo.Videos v WHERE v.VideoAssetId=a.Id) videoInfo
 OUTER APPLY(SELECT CAST(IIF(EXISTS(SELECT 1 FROM dbo.VideoAssetShares s WHERE s.VideoAssetId=a.Id AND s.TeacherId=@ActorId),1,0) AS BIT) IsShared) directShare
 OUTER APPLY(SELECT COUNT(*) ShareCount FROM dbo.VideoAssetShares s WHERE s.VideoAssetId=a.Id) shareInfo
 WHERE a.IsDeleted=0
  AND (@IsAdmin=1 OR a.CreatedBy=@ActorId OR a.ShareScope='SCHOOL' OR directShare.IsShared=1)
  AND (@Access IS NULL OR @Access='' OR @Access='ALL'
       OR (@Access='MINE' AND a.CreatedBy=@ActorId)
       OR (@Access='SHARED' AND a.CreatedBy<>@ActorId AND (a.ShareScope='SCHOOL' OR directShare.IsShared=1))
       OR (@Access='SCHOOL' AND a.ShareScope='SCHOOL'))
  AND (@Status IS NULL OR @Status='' OR @Status='ALL' OR a.Status=@Status)
  AND (@Usage IS NULL OR @Usage='' OR @Usage='ALL' OR (@Usage='USED' AND ISNULL(useInfo.UsageCount,0)>0) OR (@Usage='UNUSED' AND ISNULL(useInfo.UsageCount,0)=0))
  AND (@Source IS NULL OR @Source='' OR @Source='ALL'
       OR (@Source='MP4' AND (a.MimeType='video/mp4' OR a.OriginalFileName LIKE '%.mp4'))
       OR (@Source='WEBM' AND (a.MimeType='video/webm' OR a.OriginalFileName LIKE '%.webm'))
       OR (@Source='OTHER' AND ISNULL(a.MimeType,'') NOT IN('video/mp4','video/webm') AND ISNULL(a.OriginalFileName,'') NOT LIKE '%.mp4' AND ISNULL(a.OriginalFileName,'') NOT LIKE '%.webm'))
  AND (@Search IS NULL OR @Search='' OR a.Title LIKE '%'+@Search+'%' OR a.OriginalFileName LIKE '%'+@Search+'%' OR u.FullName LIKE '%'+@Search+'%')
 ORDER BY a.CreatedAt DESC,a.Id DESC;
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_VideoLibrary_Create @Title NVARCHAR(500),@VideoUrl NVARCHAR(1000)=NULL,@PosterUrl NVARCHAR(1000)=NULL,@DurationSeconds INT,@OriginalFileName NVARCHAR(500)=NULL,@FileSize BIGINT=NULL,@MimeType NVARCHAR(150)=NULL,@ActorId BIGINT AS
BEGIN SET NOCOUNT ON; SET XACT_ABORT ON; IF NULLIF(LTRIM(RTRIM(@Title)),'') IS NULL OR @DurationSeconds<=0 THROW 50001,N'Dữ liệu video thư viện không hợp lệ.',1; IF @VideoUrl IS NOT NULL AND (@VideoUrl NOT LIKE '/Media/Video/%' OR @VideoUrl LIKE '%..%' OR @VideoUrl LIKE '%\%' OR @VideoUrl LIKE '%?%' OR @VideoUrl LIKE '%#%') THROW 50001,N'VideoUrl không hợp lệ.',1; BEGIN TRANSACTION; INSERT dbo.VideoAssets(Title,VideoUrl,PosterUrl,DurationSeconds,OriginalFileName,FileSize,MimeType,CreatedBy) VALUES(@Title,@VideoUrl,@PosterUrl,@DurationSeconds,@OriginalFileName,@FileSize,@MimeType,@ActorId); DECLARE @AssetId BIGINT=SCOPE_IDENTITY(); INSERT dbo.Videos(VideoAssetId,Title,VideoUrl,PosterUrl,DurationSeconds,AllowSeek,AllowSpeed,RequiredWatchPercent,Status) VALUES(@AssetId,@Title,@VideoUrl,@PosterUrl,@DurationSeconds,0,1,80,'ACTIVE'); DECLARE @VideoId BIGINT=SCOPE_IDENTITY(); INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'CREATE','VIDEO_LIBRARY','Video',CONVERT(NVARCHAR(100),@VideoId)); COMMIT; SELECT @AssetId; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_VideoLibrary_Update @Id BIGINT,@Title NVARCHAR(500),@VideoUrl NVARCHAR(1000),@PosterUrl NVARCHAR(1000)=NULL,@DurationSeconds INT,@OriginalFileName NVARCHAR(500)=NULL,@FileSize BIGINT=NULL,@MimeType NVARCHAR(150)=NULL,@Status VARCHAR(30)='ACTIVE',@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NULLIF(LTRIM(RTRIM(@Title)),'') IS NULL OR @DurationSeconds<=0 OR @Status NOT IN('ACTIVE','INACTIVE') THROW 50001,N'Dữ liệu video thư viện không hợp lệ.',1;
 IF @VideoUrl NOT LIKE '/Media/Video/%' OR @VideoUrl LIKE '%..%' OR @VideoUrl LIKE '%\%' OR @VideoUrl LIKE '%?%' OR @VideoUrl LIKE '%#%' THROW 50001,N'VideoUrl không hợp lệ.',1;
 IF EXISTS(SELECT 1 FROM dbo.VideoAssets WHERE Id=@Id AND IsDeleted=0) AND NOT EXISTS(SELECT 1 FROM dbo.VideoAssets WHERE Id=@Id AND IsDeleted=0 AND (@IsAdmin=1 OR CreatedBy=@ActorId)) THROW 50003,N'Bạn không có quyền sửa video này.',1;
 BEGIN TRANSACTION;
 UPDATE dbo.VideoAssets SET Title=@Title,VideoUrl=@VideoUrl,PosterUrl=@PosterUrl,DurationSeconds=@DurationSeconds,OriginalFileName=COALESCE(@OriginalFileName,OriginalFileName),FileSize=COALESCE(@FileSize,FileSize),MimeType=COALESCE(@MimeType,MimeType),Status=@Status,UpdatedAt=SYSUTCDATETIME() WHERE Id=@Id AND IsDeleted=0 AND (@IsAdmin=1 OR CreatedBy=@ActorId);
 DECLARE @Rows INT=@@ROWCOUNT;
 IF @Rows>0
 BEGIN
  UPDATE dbo.Videos SET Title=@Title,VideoUrl=@VideoUrl,PosterUrl=@PosterUrl,DurationSeconds=@DurationSeconds,Status=@Status,UpdatedAt=SYSUTCDATETIME() WHERE VideoAssetId=@Id;
  UPDATE l SET DurationSeconds=@DurationSeconds,UpdatedAt=SYSUTCDATETIME() FROM dbo.Lessons l JOIN dbo.Videos v ON v.Id=l.VideoId WHERE v.VideoAssetId=@Id AND l.IsDeleted=0;
  INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId,NewValuesJson) VALUES(@ActorId,'UPDATE','VIDEO_LIBRARY','VideoAsset',CONVERT(NVARCHAR(100),@Id),(SELECT @Title title,@Status status FOR JSON PATH,WITHOUT_ARRAY_WRAPPER));
 END;
 COMMIT;
 SELECT @Rows;
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_VideoLibrary_Delete @Id BIGINT,@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM dbo.VideoAssets WHERE Id=@Id AND IsDeleted=0) AND NOT EXISTS(SELECT 1 FROM dbo.VideoAssets WHERE Id=@Id AND IsDeleted=0 AND (@IsAdmin=1 OR CreatedBy=@ActorId)) THROW 50003,N'Chỉ tác giả video mới có quyền xóa.',1; IF EXISTS(SELECT 1 FROM dbo.Videos v JOIN dbo.Lessons l ON l.VideoId=v.Id WHERE v.VideoAssetId=@Id AND l.IsDeleted=0) THROW 50006,N'Video đang được sử dụng trong bài học nên không thể xóa.',1; UPDATE dbo.VideoAssets SET IsDeleted=1,UpdatedAt=SYSUTCDATETIME() WHERE Id=@Id AND IsDeleted=0 AND (@IsAdmin=1 OR CreatedBy=@ActorId); DECLARE @Rows INT=@@ROWCOUNT; IF @Rows>0 INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'DELETE','VIDEO_LIBRARY','VideoAsset',CONVERT(NVARCHAR(100),@Id)); SELECT @Rows; END
GO

CREATE OR ALTER PROCEDURE dbo.LMS_VideoLibrary_Sharing_Get @Id BIGINT,@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.VideoAssets WHERE Id=@Id AND IsDeleted=0 AND (@IsAdmin=1 OR CreatedBy=@ActorId)) THROW 50003,N'Chỉ tác giả video mới được quản lý chia sẻ.',1;
 SELECT Id,Title,ShareScope,CreatedBy FROM dbo.VideoAssets WHERE Id=@Id AND IsDeleted=0;
 SELECT u.Id,u.FullName,u.Email,u.TeacherCode,CAST(IIF(s.Id IS NULL,0,1) AS BIT) IsSelected
 FROM dbo.Users u LEFT JOIN dbo.VideoAssetShares s ON s.VideoAssetId=@Id AND s.TeacherId=u.Id
 WHERE u.TeacherCode IS NOT NULL AND u.IsDeleted=0 AND u.Status='ACTIVE' AND u.Id<>(SELECT CreatedBy FROM dbo.VideoAssets WHERE Id=@Id)
 ORDER BY u.FullName,u.Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.LMS_VideoLibrary_Sharing_Save @Id BIGINT,@ShareScope VARCHAR(20),@TeacherIdsJson NVARCHAR(MAX)=N'[]',@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @ShareScope NOT IN('PRIVATE','SELECTED','SCHOOL') THROW 50001,N'Phạm vi chia sẻ không hợp lệ.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.VideoAssets WHERE Id=@Id AND IsDeleted=0 AND (@IsAdmin=1 OR CreatedBy=@ActorId)) THROW 50003,N'Chỉ tác giả video mới được quản lý chia sẻ.',1;
 BEGIN TRANSACTION;
 DELETE dbo.VideoAssetShares WHERE VideoAssetId=@Id;
 IF @ShareScope='SELECTED'
 BEGIN
  INSERT dbo.VideoAssetShares(VideoAssetId,TeacherId,SharedBy)
  SELECT @Id,u.Id,@ActorId FROM dbo.Users u
  WHERE u.TeacherCode IS NOT NULL AND u.IsDeleted=0 AND u.Status='ACTIVE' AND u.Id<>(SELECT CreatedBy FROM dbo.VideoAssets WHERE Id=@Id)
   AND u.Id IN(SELECT TRY_CONVERT(BIGINT,[value]) FROM OPENJSON(COALESCE(@TeacherIdsJson,N'[]')) WHERE TRY_CONVERT(BIGINT,[value]) IS NOT NULL);
  IF NOT EXISTS(SELECT 1 FROM dbo.VideoAssetShares WHERE VideoAssetId=@Id) THROW 50001,N'Hãy chọn ít nhất một giáo viên để chia sẻ.',1;
 END;
 UPDATE dbo.VideoAssets SET ShareScope=@ShareScope,UpdatedAt=SYSUTCDATETIME() WHERE Id=@Id;
 INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId,NewValuesJson) VALUES(@ActorId,'SHARE','VIDEO_LIBRARY','VideoAsset',CONVERT(NVARCHAR(100),@Id),(SELECT @ShareScope shareScope,@TeacherIdsJson teacherIds FOR JSON PATH,WITHOUT_ARRAY_WRAPPER));
 COMMIT;
 SELECT @Id;
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_VideoLibrary_Attach @LessonId BIGINT,@VideoAssetId BIGINT,@AllowSeek BIT,@AllowSpeed BIT,@RequiredWatchPercent DECIMAL(5,2),@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; IF @RequiredWatchPercent NOT BETWEEN 0 AND 100 THROW 50001,N'Tỷ lệ xem bắt buộc không hợp lệ.',1; IF NOT EXISTS(SELECT 1 FROM dbo.Lessons l JOIN dbo.Courses c ON c.Id=l.CourseId WHERE l.Id=@LessonId AND l.IsDeleted=0 AND l.LessonType IN('VIDEO','INTERACTIVE_VIDEO') AND (@IsAdmin=1 OR c.TeacherId=@ActorId)) THROW 50003,N'Bạn không có quyền quản lý bài học này.',1; DECLARE @VideoId BIGINT,@DurationSeconds INT; SELECT @VideoId=v.Id,@DurationSeconds=v.DurationSeconds FROM dbo.VideoAssets a JOIN dbo.Videos v ON v.VideoAssetId=a.Id WHERE a.Id=@VideoAssetId AND a.IsDeleted=0 AND a.Status='ACTIVE' AND v.Status='ACTIVE' AND (@IsAdmin=1 OR a.CreatedBy=@ActorId OR a.ShareScope='SCHOOL' OR EXISTS(SELECT 1 FROM dbo.VideoAssetShares s WHERE s.VideoAssetId=a.Id AND s.TeacherId=@ActorId)); IF @VideoId IS NULL THROW 50003,N'Video không tồn tại hoặc chưa được tác giả chia sẻ cho bạn.',1; UPDATE dbo.Lessons SET VideoId=@VideoId,DurationSeconds=@DurationSeconds,UpdatedAt=SYSUTCDATETIME() WHERE Id=@LessonId; INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'ATTACH','VIDEO_LIBRARY','Video',CONVERT(NVARCHAR(100),@VideoId)); SELECT @VideoId; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Video_AttachToLesson @LessonId BIGINT,@VideoId BIGINT,@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Lessons l JOIN dbo.Courses c ON c.Id=l.CourseId WHERE l.Id=@LessonId AND l.IsDeleted=0 AND l.LessonType IN('VIDEO','INTERACTIVE_VIDEO') AND (@IsAdmin=1 OR c.TeacherId=@ActorId)) THROW 50003,N'Bạn không có quyền quản lý bài học này.',1;
 DECLARE @DurationSeconds INT;
 SELECT @DurationSeconds=v.DurationSeconds FROM dbo.Videos v JOIN dbo.VideoAssets a ON a.Id=v.VideoAssetId
 WHERE v.Id=@VideoId AND v.Status='ACTIVE' AND a.IsDeleted=0 AND a.Status='ACTIVE'
   AND (@IsAdmin=1 OR a.CreatedBy=@ActorId OR a.ShareScope='SCHOOL' OR EXISTS(SELECT 1 FROM dbo.VideoAssetShares s WHERE s.VideoAssetId=a.Id AND s.TeacherId=@ActorId));
 IF @DurationSeconds IS NULL THROW 50003,N'Video không tồn tại hoặc chưa được tác giả chia sẻ cho bạn.',1;
 UPDATE dbo.Lessons SET VideoId=@VideoId,DurationSeconds=@DurationSeconds,UpdatedAt=SYSUTCDATETIME() WHERE Id=@LessonId;
 INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId,NewValuesJson) VALUES(@ActorId,'ATTACH','VIDEO_LIBRARY','Lesson',CONVERT(NVARCHAR(100),@LessonId),(SELECT @VideoId videoId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER));
 SELECT @VideoId;
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_VideoInteraction_GetByVideo @VideoId BIGINT,@ActorId BIGINT,@IsAdmin BIT=0 AS BEGIN SET NOCOUNT ON; IF NOT EXISTS(SELECT 1 FROM dbo.Videos v JOIN dbo.VideoAssets a ON a.Id=v.VideoAssetId WHERE v.Id=@VideoId AND a.IsDeleted=0 AND (@IsAdmin=1 OR a.CreatedBy=@ActorId)) THROW 50003,N'Bạn không có quyền quản lý video này.',1; SELECT vi.*,q.QuestionText,q.QuestionType,q.Description,(SELECT o.OptionCode,o.OptionText FROM dbo.QuestionOptions o WHERE o.QuestionId=q.Id AND o.IsDeleted=0 ORDER BY o.SortOrder FOR JSON PATH) Options FROM dbo.VideoInteractions vi JOIN dbo.Questions q ON q.Id=vi.QuestionId WHERE vi.VideoId=@VideoId AND vi.IsDeleted=0 ORDER BY vi.TimeSeconds,vi.SortOrder; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_VideoInteraction_PreviewAnswer @VideoId BIGINT,@InteractionId BIGINT,@QuestionId BIGINT,@AnswerText NVARCHAR(MAX),@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Type VARCHAR(50),@Mode VARCHAR(30),@Score DECIMAL(8,2),@Correct NVARCHAR(MAX),@IsCorrect BIT;
 SELECT @Type=q.QuestionType,@Mode=q.ShortAnswerMode,@Score=vi.Score
 FROM dbo.VideoInteractions vi JOIN dbo.Videos v ON v.Id=vi.VideoId JOIN dbo.VideoAssets a ON a.Id=v.VideoAssetId JOIN dbo.Questions q ON q.Id=vi.QuestionId
 WHERE vi.Id=@InteractionId AND vi.VideoId=@VideoId AND vi.QuestionId=@QuestionId AND vi.IsDeleted=0 AND vi.Status='ACTIVE' AND q.IsDeleted=0 AND (@IsAdmin=1 OR a.CreatedBy=@ActorId);
 IF @Type IS NULL THROW 50003,N'Bạn không có quyền xem trước câu hỏi này.',1;
 IF @Type IN('SINGLE_CHOICE','TRUE_FALSE','MULTIPLE_CHOICE') BEGIN SELECT @Correct=STRING_AGG(UPPER(LTRIM(RTRIM(OptionCode))),'|') WITHIN GROUP(ORDER BY UPPER(LTRIM(RTRIM(OptionCode)))) FROM dbo.QuestionOptions WHERE QuestionId=@QuestionId AND IsCorrect=1 AND IsDeleted=0; SET @IsCorrect=IIF(UPPER(ISNULL(@AnswerText,''))=ISNULL(@Correct,''),1,0); END
 ELSE IF @Mode='MANUAL_REVIEW' SET @IsCorrect=NULL;
 ELSE IF @Mode='CONTAINS' SET @IsCorrect=IIF(EXISTS(SELECT 1 FROM dbo.QuestionAnswerKeys WHERE QuestionId=@QuestionId AND ((IsCaseSensitive=1 AND CHARINDEX(AnswerText,@AnswerText COLLATE Latin1_General_100_CS_AS)>0) OR (IsCaseSensitive=0 AND CHARINDEX(LOWER(AnswerText),LOWER(@AnswerText))>0))),1,0);
 ELSE SET @IsCorrect=IIF(EXISTS(SELECT 1 FROM dbo.QuestionAnswerKeys WHERE QuestionId=@QuestionId AND ((IsCaseSensitive=1 AND AnswerText=@AnswerText COLLATE Latin1_General_100_CS_AS) OR (IsCaseSensitive=0 AND LOWER(AnswerText)=LOWER(@AnswerText)))),1,0);
 SELECT @IsCorrect IsCorrect,CAST(IIF(@IsCorrect=1,@Score,0) AS DECIMAL(8,2)) ScoreAwarded,IIF(@IsCorrect IS NULL,'PREVIEW_PENDING','PREVIEW_AUTO_GRADED') ReviewStatus,(SELECT Explanation FROM dbo.Questions WHERE Id=@QuestionId) Explanation;
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_VideoInteraction_Create @VideoId BIGINT,@QuestionId BIGINT,@TimeSeconds INT,@EndTimeSeconds INT=NULL,@InteractionType VARCHAR(50),@Required BIT,@PauseVideo BIT,@AllowSkip BIT,@Score DECIMAL(8,2),@AttemptLimit INT,@SortOrder INT,@Status VARCHAR(30),@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; DECLARE @Duration INT=(SELECT v.DurationSeconds FROM dbo.Videos v JOIN dbo.VideoAssets a ON a.Id=v.VideoAssetId WHERE v.Id=@VideoId AND a.IsDeleted=0 AND (@IsAdmin=1 OR a.CreatedBy=@ActorId)); IF @Duration IS NULL THROW 50003,N'Bạn không có quyền quản lý video này.',1; IF NOT EXISTS(SELECT 1 FROM dbo.Questions WHERE Id=@QuestionId AND IsDeleted=0) OR @TimeSeconds<0 OR @TimeSeconds>@Duration OR @AttemptLimit<1 OR @Score<0 THROW 50001,N'Dữ liệu tương tác không hợp lệ.',1; INSERT dbo.VideoInteractions(VideoId,QuestionId,TimeSeconds,EndTimeSeconds,InteractionType,Required,PauseVideo,AllowSkip,Score,AttemptLimit,SortOrder,Status) VALUES(@VideoId,@QuestionId,@TimeSeconds,@EndTimeSeconds,@InteractionType,@Required,@PauseVideo,@AllowSkip,@Score,@AttemptLimit,@SortOrder,@Status); DECLARE @Id BIGINT=SCOPE_IDENTITY(); INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'CREATE','VIDEO_INTERACTION','VideoInteraction',CONVERT(NVARCHAR(100),@Id)); SELECT @Id; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_VideoInteraction_Update @Id BIGINT,@QuestionId BIGINT,@TimeSeconds INT,@EndTimeSeconds INT=NULL,@InteractionType VARCHAR(50),@Required BIT,@PauseVideo BIT,@AllowSkip BIT,@Score DECIMAL(8,2),@AttemptLimit INT,@SortOrder INT,@Status VARCHAR(30),@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; DECLARE @Duration INT=(SELECT v.DurationSeconds FROM dbo.VideoInteractions vi JOIN dbo.Videos v ON v.Id=vi.VideoId JOIN dbo.VideoAssets a ON a.Id=v.VideoAssetId WHERE vi.Id=@Id AND vi.IsDeleted=0 AND (@IsAdmin=1 OR a.CreatedBy=@ActorId)); IF @Duration IS NULL THROW 50003,N'Bạn không có quyền quản lý tương tác này.',1; IF NOT EXISTS(SELECT 1 FROM dbo.Questions WHERE Id=@QuestionId AND IsDeleted=0) OR @TimeSeconds<0 OR @TimeSeconds>@Duration OR @AttemptLimit<1 OR @Score<0 THROW 50001,N'Dữ liệu tương tác không hợp lệ.',1; UPDATE dbo.VideoInteractions SET QuestionId=@QuestionId,TimeSeconds=@TimeSeconds,EndTimeSeconds=@EndTimeSeconds,InteractionType=@InteractionType,Required=@Required,PauseVideo=@PauseVideo,AllowSkip=@AllowSkip,Score=@Score,AttemptLimit=@AttemptLimit,SortOrder=@SortOrder,Status=@Status,UpdatedAt=SYSUTCDATETIME() WHERE Id=@Id; INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'UPDATE','VIDEO_INTERACTION','VideoInteraction',CONVERT(NVARCHAR(100),@Id)); SELECT 1; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_VideoInteraction_Delete @Id BIGINT,@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; UPDATE vi SET IsDeleted=1,UpdatedAt=SYSUTCDATETIME() FROM dbo.VideoInteractions vi JOIN dbo.Videos v ON v.Id=vi.VideoId JOIN dbo.VideoAssets a ON a.Id=v.VideoAssetId WHERE vi.Id=@Id AND vi.IsDeleted=0 AND (@IsAdmin=1 OR a.CreatedBy=@ActorId); DECLARE @Rows INT=@@ROWCOUNT; IF @Rows>0 INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId) VALUES(@ActorId,'DELETE','VIDEO_INTERACTION','VideoInteraction',CONVERT(NVARCHAR(100),@Id)); SELECT @Rows; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_VideoInteraction_Reorder @Id BIGINT,@SortOrder INT,@ActorId BIGINT,@IsAdmin BIT=0 AS
BEGIN SET NOCOUNT ON; UPDATE vi SET SortOrder=@SortOrder,UpdatedAt=SYSUTCDATETIME() FROM dbo.VideoInteractions vi JOIN dbo.Videos v ON v.Id=vi.VideoId JOIN dbo.VideoAssets a ON a.Id=v.VideoAssetId WHERE vi.Id=@Id AND vi.IsDeleted=0 AND (@IsAdmin=1 OR a.CreatedBy=@ActorId); IF @@ROWCOUNT=0 THROW 50003,N'Không thể sắp xếp tương tác này.',1; END
GO
