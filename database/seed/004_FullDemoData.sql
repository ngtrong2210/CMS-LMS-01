SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

DECLARE @AdminId BIGINT=(SELECT Id FROM dbo.Users WHERE Username='admin');
DECLARE @DefaultHash NVARCHAR(500)=(SELECT PasswordHash FROM dbo.Users WHERE Username='student');

/* Users: total 10 accounts, all use demo password 123456. */
DECLARE @DemoUsers TABLE(Username NVARCHAR(100),FullName NVARCHAR(250),Email NVARCHAR(250),StudentCode NVARCHAR(100),TeacherCode NVARCHAR(100),RoleCode VARCHAR(50));
INSERT @DemoUsers VALUES
('teacher02',N'Trần Minh Anh','teacher02@learnhub.vn',NULL,'GV0002','TEACHER'),
('teacher03',N'Lê Quốc Bảo','teacher03@learnhub.vn',NULL,'GV0003','TEACHER'),
('student02',N'Trần Thu Hà','student02@learnhub.vn','HV0002',NULL,'STUDENT'),
('student03',N'Phạm Minh Khang','student03@learnhub.vn','HV0003',NULL,'STUDENT'),
('student04',N'Lê Hoàng Nam','student04@learnhub.vn','HV0004',NULL,'STUDENT'),
('student05',N'Vũ Ngọc Mai','student05@learnhub.vn','HV0005',NULL,'STUDENT'),
('student06',N'Đỗ Thành Công','student06@learnhub.vn','HV0006',NULL,'STUDENT');

INSERT dbo.Users(Username,PasswordHash,FullName,Email,StudentCode,TeacherCode,Status,CreatedBy)
SELECT d.Username,@DefaultHash,d.FullName,d.Email,d.StudentCode,d.TeacherCode,'ACTIVE',@AdminId
FROM @DemoUsers d WHERE NOT EXISTS(SELECT 1 FROM dbo.Users u WHERE u.Username=d.Username);

INSERT dbo.UserRoles(UserId,RoleId)
SELECT u.Id,r.Id FROM @DemoUsers d JOIN dbo.Users u ON u.Username=d.Username JOIN dbo.Roles r ON r.Code=d.RoleCode
WHERE NOT EXISTS(SELECT 1 FROM dbo.UserRoles ur WHERE ur.UserId=u.Id AND ur.RoleId=r.Id);

/* Ten standard course categories. */
DECLARE @Categories TABLE(Code NVARCHAR(100),Name NVARCHAR(250),SortOrder INT);
INSERT @Categories VALUES
('FRONTEND',N'Lập trình Frontend',1),('BACKEND',N'Lập trình Backend',2),('DATABASE',N'Cơ sở dữ liệu',3),('DEVOPS',N'DevOps và Cloud',4),('UIUX',N'Thiết kế UI/UX',5),
('DATA',N'Dữ liệu và AI',6),('SECURITY',N'An toàn thông tin',7),('MOBILE',N'Lập trình Mobile',8),('SOFTSKILL',N'Kỹ năng nghề nghiệp',9),('PROJECT',N'Quản lý dự án',10);
MERGE dbo.CourseCategories AS t USING @Categories AS s ON t.Code=s.Code
WHEN MATCHED THEN UPDATE SET Name=s.Name,SortOrder=s.SortOrder,Status='ACTIVE'
WHEN NOT MATCHED THEN INSERT(Code,Name,SortOrder,Status) VALUES(s.Code,s.Name,s.SortOrder,'ACTIVE');

/* Ten courses including VUE3-001 already seeded. */
DECLARE @Courses TABLE(Code NVARCHAR(100),Title NVARCHAR(500),Slug NVARCHAR(500),CategoryCode NVARCHAR(100),TeacherUsername NVARCHAR(100),Level VARCHAR(50),PassingScore DECIMAL(5,2),Status VARCHAR(30));
INSERT @Courses VALUES
('NET8-002',N'ASP.NET Core 8 Web API thực chiến','asp-net-core-8-web-api','BACKEND','teacher03','INTERMEDIATE',65,'PUBLISHED'),
('SQL-003',N'SQL Server và tối ưu truy vấn','sql-server-va-toi-uu-truy-van','DATABASE','teacher03','INTERMEDIATE',70,'PUBLISHED'),
('DOCKER-004',N'Docker nền tảng cho lập trình viên','docker-nen-tang','DEVOPS','teacher02','BEGINNER',60,'PUBLISHED'),
('UIUX-005',N'Thiết kế giao diện số hiện đại','thiet-ke-giao-dien-so','UIUX','teacher02','BEGINNER',60,'PUBLISHED'),
('DATA-006',N'Phân tích dữ liệu với Python','phan-tich-du-lieu-python','DATA','teacher03','INTERMEDIATE',65,'PUBLISHED'),
('SEC-007',N'Bảo mật ứng dụng Web','bao-mat-ung-dung-web','SECURITY','teacher03','ADVANCED',75,'PUBLISHED'),
('FLUTTER-008',N'Flutter xây dựng ứng dụng đa nền tảng','flutter-da-nen-tang','MOBILE','teacher02','INTERMEDIATE',65,'PUBLISHED'),
('COMM-009',N'Giao tiếp hiệu quả trong công việc','giao-tiep-hieu-qua','SOFTSKILL','teacher02','BEGINNER',60,'PUBLISHED'),
('AGILE-010',N'Agile và Scrum cho đội dự án','agile-scrum-doi-du-an','PROJECT','teacher03','BEGINNER',60,'DRAFT');

INSERT dbo.Courses(Code,Title,Slug,ShortDescription,Description,TeacherId,CategoryId,Level,PassingScore,Status,PublishedAt,CreatedBy)
SELECT c.Code,c.Title,c.Slug,CONCAT(N'Khóa học ',c.Title,N' với nội dung thực hành chuẩn.'),CONCAT(N'Lộ trình học ',c.Title,N' từ kiến thức nền tảng đến bài tập ứng dụng.'),u.Id,cc.Id,c.Level,c.PassingScore,c.Status,IIF(c.Status='PUBLISHED',DATEADD(day,-10,SYSUTCDATETIME()),NULL),@AdminId
FROM @Courses c JOIN dbo.Users u ON u.Username=c.TeacherUsername JOIN dbo.CourseCategories cc ON cc.Code=c.CategoryCode
WHERE NOT EXISTS(SELECT 1 FROM dbo.Courses x WHERE x.Code=c.Code);

/* Every demo course has at least one chapter, lesson and video. */
INSERT dbo.Chapters(CourseId,Title,Description,SortOrder,Status)
SELECT c.Id,N'Chương 1: Kiến thức nền tảng',N'Giới thiệu và các khái niệm cốt lõi.',1,'ACTIVE'
FROM dbo.Courses c WHERE c.Code<>'VUE3-001' AND NOT EXISTS(SELECT 1 FROM dbo.Chapters ch WHERE ch.CourseId=c.Id);

INSERT dbo.Lessons(CourseId,ChapterId,Title,Description,LessonType,DurationSeconds,SortOrder,IsRequired,PassingScore,Status)
SELECT c.Id,ch.Id,CONCAT(N'Bài mở đầu: ',c.Title),N'Bài giảng tương tác giúp học viên làm quen với chủ đề.','INTERACTIVE_VIDEO',600+((c.Id%5)*60),1,1,c.PassingScore,'ACTIVE'
FROM dbo.Courses c JOIN dbo.Chapters ch ON ch.CourseId=c.Id AND ch.SortOrder=1
WHERE c.Code<>'VUE3-001' AND NOT EXISTS(SELECT 1 FROM dbo.Lessons l WHERE l.CourseId=c.Id);

INSERT dbo.Videos(LessonId,Title,VideoUrl,PosterUrl,DurationSeconds,AllowSeek,AllowSpeed,RequiredWatchPercent,Status)
SELECT l.Id,l.Title,NULL,CONCAT('https://cdn.learnhub.local/posters/',LOWER(c.Code),'.jpg'),l.DurationSeconds,0,1,80,'ACTIVE'
FROM dbo.Lessons l JOIN dbo.Courses c ON c.Id=l.CourseId
WHERE NOT EXISTS(SELECT 1 FROM dbo.Videos v WHERE v.LessonId=l.Id)
  AND l.LessonType IN('VIDEO','INTERACTIVE_VIDEO');

/* Ten short-answer questions and matching answer keys. */
DECLARE @n INT=1;
WHILE @n<=10
BEGIN
    DECLARE @QuestionText NVARCHAR(500)=CONCAT(N'Câu hỏi tự luận mẫu ',FORMAT(@n,'00'),N': nêu một khái niệm chính đã học.');
    IF NOT EXISTS(SELECT 1 FROM dbo.Questions WHERE QuestionText=@QuestionText)
        INSERT dbo.Questions(QuestionType,QuestionText,Description,Explanation,Difficulty,DefaultScore,ShortAnswerMode,CreatedBy,Status)
        VALUES('SHORT_ANSWER',@QuestionText,N'Câu hỏi kiểm tra khả năng ghi nhớ khái niệm.',N'Đáp án mẫu được đối chiếu không phân biệt hoa thường.',IIF(@n<=4,'EASY',IIF(@n<=8,'MEDIUM','HARD')),10,'CONTAINS',@AdminId,'ACTIVE');
    DECLARE @QuestionId BIGINT=(SELECT Id FROM dbo.Questions WHERE QuestionText=@QuestionText);
    IF NOT EXISTS(SELECT 1 FROM dbo.QuestionAnswerKeys WHERE QuestionId=@QuestionId)
        INSERT dbo.QuestionAnswerKeys(QuestionId,AnswerText,IsCaseSensitive,SortOrder) VALUES(@QuestionId,CONCAT(N'khái niệm ',@n),0,1);
    SET @n+=1;
END

/* Add a valid interaction to every video that does not have one. */
;WITH VideoSeed AS (
    SELECT v.Id VideoId,v.DurationSeconds,ROW_NUMBER() OVER(ORDER BY v.Id) rn
    FROM dbo.Videos v WHERE NOT EXISTS(SELECT 1 FROM dbo.VideoInteractions vi WHERE vi.VideoId=v.Id AND vi.IsDeleted=0)
), ChoiceQuestions AS (
    SELECT Id,ROW_NUMBER() OVER(ORDER BY Id) rn,COUNT(*) OVER() cnt FROM dbo.Questions WHERE QuestionType='SINGLE_CHOICE' AND IsDeleted=0
)
INSERT dbo.VideoInteractions(VideoId,QuestionId,TimeSeconds,InteractionType,Required,PauseVideo,AllowSkip,Score,AttemptLimit,SortOrder,Status)
SELECT v.VideoId,q.Id,IIF(v.DurationSeconds>90,60,20),'QUESTION',1,1,0,10,2,1,'ACTIVE'
FROM VideoSeed v JOIN ChoiceQuestions q ON q.rn=((v.rn-1)%q.cnt)+1;

/* Ten enrollments across the demo courses and students. */
DECLARE @EnrollmentSeed TABLE(CourseCode NVARCHAR(100),StudentUsername NVARCHAR(100),Progress DECIMAL(5,2),Score DECIMAL(8,2));
INSERT @EnrollmentSeed VALUES
('VUE3-001','student',42,8.40),('NET8-002','student02',25,7.50),('SQL-003','student03',68,8.70),('DOCKER-004','student04',10,7.00),('UIUX-005','student05',82,9.10),
('DATA-006','student06',35,8.00),('SEC-007','student02',55,8.30),('FLUTTER-008','student03',72,8.80),('COMM-009','student04',100,9.20),('AGILE-010','student05',15,7.20);
INSERT dbo.Enrollments(CourseId,StudentId,EnrolledAt,StartedAt,CompletedAt,Status,ProgressPercent,FinalScore,LastAccessAt,CreatedBy)
SELECT c.Id,u.Id,DATEADD(day,-20,SYSUTCDATETIME()),DATEADD(day,-18,SYSUTCDATETIME()),IIF(e.Progress=100,DATEADD(day,-1,SYSUTCDATETIME()),NULL),IIF(e.Progress=100,'COMPLETED','IN_PROGRESS'),e.Progress,e.Score,SYSUTCDATETIME(),@AdminId
FROM @EnrollmentSeed e JOIN dbo.Courses c ON c.Code=e.CourseCode JOIN dbo.Users u ON u.Username=e.StudentUsername
WHERE NOT EXISTS(SELECT 1 FROM dbo.Enrollments x WHERE x.CourseId=c.Id AND x.StudentId=u.Id);

/* Lesson and video progress derived from ten enrollments. */
;WITH Seed AS (
 SELECT TOP(10) e.StudentId,e.CourseId,l.Id LessonId,e.ProgressPercent,e.FinalScore,ROW_NUMBER() OVER(ORDER BY e.Id) rn
 FROM dbo.Enrollments e CROSS APPLY(SELECT TOP 1 Id FROM dbo.Lessons WHERE CourseId=e.CourseId AND IsDeleted=0 ORDER BY SortOrder,Id) l ORDER BY e.Id
)
INSERT dbo.StudentLessonProgress(StudentId,CourseId,LessonId,ProgressPercent,Score,AttemptCount,Completed,CompletedAt,LastAccessAt)
SELECT s.StudentId,s.CourseId,s.LessonId,s.ProgressPercent,ISNULL(s.FinalScore,0),IIF(s.ProgressPercent>0,1,0),IIF(s.ProgressPercent=100,1,0),IIF(s.ProgressPercent=100,DATEADD(day,-1,SYSUTCDATETIME()),NULL),SYSUTCDATETIME()
FROM Seed s WHERE NOT EXISTS(SELECT 1 FROM dbo.StudentLessonProgress p WHERE p.StudentId=s.StudentId AND p.LessonId=s.LessonId);

;WITH Seed AS (
 SELECT TOP(10) e.StudentId,e.CourseId,l.Id LessonId,v.Id VideoId,v.DurationSeconds,e.ProgressPercent
 FROM dbo.Enrollments e CROSS APPLY(SELECT TOP 1 Id FROM dbo.Lessons WHERE CourseId=e.CourseId AND IsDeleted=0 ORDER BY SortOrder,Id) l
 JOIN dbo.Videos v ON v.LessonId=l.Id ORDER BY e.Id
)
INSERT dbo.StudentVideoProgress(StudentId,CourseId,LessonId,VideoId,CurrentTimeSeconds,MaxWatchedTimeSeconds,WatchedSeconds,WatchPercent,Completed,CompletedAt,LastAccessAt)
SELECT s.StudentId,s.CourseId,s.LessonId,s.VideoId,ROUND(s.DurationSeconds*s.ProgressPercent/100.0,2),ROUND(s.DurationSeconds*s.ProgressPercent/100.0,2),ROUND(s.DurationSeconds*s.ProgressPercent/100.0,2),s.ProgressPercent,IIF(s.ProgressPercent>=80,1,0),IIF(s.ProgressPercent>=80,SYSUTCDATETIME(),NULL),SYSUTCDATETIME()
FROM Seed s WHERE NOT EXISTS(SELECT 1 FROM dbo.StudentVideoProgress p WHERE p.StudentId=s.StudentId AND p.VideoId=s.VideoId);

/* About ten graded answers; official score is consistent with option B. */
;WITH EnrollmentRows AS (
 SELECT TOP(10) e.Id,e.StudentId,e.CourseId,l.Id LessonId,v.Id VideoId,vi.Id InteractionId,ROW_NUMBER() OVER(ORDER BY e.Id) rn
 FROM dbo.Enrollments e CROSS APPLY(SELECT TOP 1 Id FROM dbo.Lessons WHERE CourseId=e.CourseId ORDER BY SortOrder,Id) l
 LEFT JOIN dbo.Videos v ON v.LessonId=l.Id LEFT JOIN dbo.VideoInteractions vi ON vi.VideoId=v.Id AND vi.IsDeleted=0 ORDER BY e.Id
), Questions AS (
 SELECT TOP(10) q.Id QuestionId,q.DefaultScore,ROW_NUMBER() OVER(ORDER BY q.Id) rn FROM dbo.Questions q WHERE q.QuestionType='SINGLE_CHOICE' AND q.IsDeleted=0
)
INSERT dbo.StudentAnswers(StudentId,CourseId,LessonId,VideoId,InteractionId,QuestionId,AttemptNumber,AnswerText,IsCorrect,ScoreAwarded,ReviewStatus,AnsweredAt,TimeInVideoSeconds,TimeSpentSeconds)
SELECT e.StudentId,e.CourseId,e.LessonId,e.VideoId,e.InteractionId,q.QuestionId,1,'B',1,q.DefaultScore,'AUTO_GRADED',DATEADD(minute,-e.rn*20,SYSUTCDATETIME()),60,8+e.rn
FROM EnrollmentRows e JOIN Questions q ON q.rn=e.rn
WHERE NOT EXISTS(SELECT 1 FROM dbo.StudentAnswers a WHERE a.StudentId=e.StudentId AND a.LessonId=e.LessonId AND a.QuestionId=q.QuestionId);

INSERT dbo.StudentAnswerOptions(StudentAnswerId,QuestionOptionId)
SELECT a.Id,o.Id FROM dbo.StudentAnswers a JOIN dbo.QuestionOptions o ON o.QuestionId=a.QuestionId AND o.OptionCode='B'
WHERE NOT EXISTS(SELECT 1 FROM dbo.StudentAnswerOptions x WHERE x.StudentAnswerId=a.Id AND x.QuestionOptionId=o.Id);

/* Ten learning sessions with stable identifiers. */
DECLARE @Sessions TABLE(rn INT,SessionId UNIQUEIDENTIFIER);
INSERT @Sessions VALUES
(1,'10000000-0000-0000-0000-000000000001'),(2,'10000000-0000-0000-0000-000000000002'),(3,'10000000-0000-0000-0000-000000000003'),(4,'10000000-0000-0000-0000-000000000004'),(5,'10000000-0000-0000-0000-000000000005'),
(6,'10000000-0000-0000-0000-000000000006'),(7,'10000000-0000-0000-0000-000000000007'),(8,'10000000-0000-0000-0000-000000000008'),(9,'10000000-0000-0000-0000-000000000009'),(10,'10000000-0000-0000-0000-000000000010');
;WITH ProgressRows AS (
 SELECT TOP(10) p.StudentId,p.CourseId,p.LessonId,p.VideoId,p.CurrentTimeSeconds,p.MaxWatchedTimeSeconds,p.Completed,ROW_NUMBER() OVER(ORDER BY p.Id) rn FROM dbo.StudentVideoProgress p ORDER BY p.Id
)
INSERT dbo.LearningSessions(SessionId,StudentId,CourseId,LessonId,VideoId,StartedAt,EndedAt,WatchDurationSeconds,LastPositionSeconds,MaxPositionSeconds,SeekCount,PauseCount,InteractionCount,Completed)
SELECT s.SessionId,p.StudentId,p.CourseId,p.LessonId,p.VideoId,DATEADD(hour,-p.rn,SYSUTCDATETIME()),DATEADD(minute,-p.rn,SYSUTCDATETIME()),CAST(p.MaxWatchedTimeSeconds AS INT),p.CurrentTimeSeconds,p.MaxWatchedTimeSeconds,p.rn%3,p.rn%4,1,p.Completed
FROM ProgressRows p JOIN @Sessions s ON s.rn=p.rn WHERE NOT EXISTS(SELECT 1 FROM dbo.LearningSessions x WHERE x.SessionId=s.SessionId);

/* Ten audit events. */
DECLARE @AuditSeed TABLE(EntityId NVARCHAR(100),Action VARCHAR(100),Module VARCHAR(100),EntityName VARCHAR(100),NewValuesJson NVARCHAR(MAX));
INSERT @AuditSeed VALUES
('DEMO-001','CREATE','COURSE','Course',N'{"code":"NET8-002","status":"PUBLISHED"}'),('DEMO-002','UPDATE','COURSE','Course',N'{"field":"description"}'),('DEMO-003','PUBLISH','COURSE','Course',N'{"status":"PUBLISHED"}'),
('DEMO-004','CREATE','QUESTION','Question',N'{"type":"SINGLE_CHOICE"}'),('DEMO-005','UPDATE','QUESTION','Question',N'{"difficulty":"MEDIUM"}'),('DEMO-006','CREATE','VIDEO','VideoInteraction',N'{"timeSeconds":60}'),
('DEMO-007','CREATE','ENROLLMENT','Enrollment',N'{"status":"IN_PROGRESS"}'),('DEMO-008','UPDATE','ENROLLMENT','Enrollment',N'{"progress":55}'),('DEMO-009','UPDATE','USER','User',N'{"status":"ACTIVE"}'),('DEMO-010','UPDATE','ROLE','RolePermission',N'{"permission":"REPORT_VIEW"}');
INSERT dbo.AuditLogs(UserId,Action,Module,EntityName,EntityId,NewValuesJson,IpAddress,UserAgent,CreatedAt)
SELECT @AdminId,a.Action,a.Module,a.EntityName,a.EntityId,a.NewValuesJson,'127.0.0.1','LearnHub Demo Seeder',DATEADD(minute,-ROW_NUMBER() OVER(ORDER BY a.EntityId)*15,SYSUTCDATETIME())
FROM @AuditSeed a WHERE NOT EXISTS(SELECT 1 FROM dbo.AuditLogs x WHERE x.EntityId=a.EntityId AND x.UserAgent='LearnHub Demo Seeder');

/* Refresh token rows are intentionally non-functional demo hashes. */
SET @n=1;
WHILE @n<=10
BEGIN
    DECLARE @TokenHash VARCHAR(128)=CONCAT('DEMO-SEED-TOKEN-HASH-',FORMAT(@n,'000'));
    IF NOT EXISTS(SELECT 1 FROM dbo.RefreshTokens WHERE TokenHash=@TokenHash)
        INSERT dbo.RefreshTokens(UserId,TokenHash,ExpiresAt,CreatedIp,IsRevoked,RevokedAt,RevokedIp)
        VALUES((SELECT TOP 1 Id FROM dbo.Users WHERE Username=IIF(@n%2=0,'student','admin')),@TokenHash,DATEADD(day,14,SYSUTCDATETIME()),'127.0.0.1',IIF(@n<=2,1,0),IIF(@n<=2,SYSUTCDATETIME(),NULL),IIF(@n<=2,'127.0.0.1',NULL));
    SET @n+=1;
END

COMMIT TRANSACTION;
GO
