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
BEGIN SET NOCOUNT ON; SELECT Id,CourseId,Title,Description,SortOrder,Status FROM dbo.Chapters WHERE CourseId=@CourseId AND IsDeleted=0 ORDER BY SortOrder; SELECT Id,CourseId,ChapterId,Title,Description,LessonType,DurationSeconds,SortOrder,IsRequired,PassingScore,Status FROM dbo.Lessons WHERE CourseId=@CourseId AND IsDeleted=0 ORDER BY ChapterId,SortOrder; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Course_Publish @Id BIGINT,@UserId BIGINT AS
BEGIN SET NOCOUNT ON; UPDATE dbo.Courses SET Status='PUBLISHED',PublishedAt=COALESCE(PublishedAt,SYSUTCDATETIME()),UpdatedAt=SYSUTCDATETIME(),UpdatedBy=@UserId WHERE Id=@Id AND IsDeleted=0; END
GO
