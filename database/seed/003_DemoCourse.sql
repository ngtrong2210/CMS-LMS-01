IF NOT EXISTS(SELECT 1 FROM dbo.CourseCategories WHERE Code='FRONTEND') INSERT dbo.CourseCategories(Code,Name,SortOrder) VALUES('FRONTEND',N'Lập trình Frontend',1);
DECLARE @TeacherId BIGINT=(SELECT Id FROM dbo.Users WHERE Username='teacher'),@AdminId BIGINT=(SELECT Id FROM dbo.Users WHERE Username='admin'),@CategoryId BIGINT=(SELECT Id FROM dbo.CourseCategories WHERE Code='FRONTEND');
IF NOT EXISTS(SELECT 1 FROM dbo.Courses WHERE Code='VUE3-001') INSERT dbo.Courses(Code,Title,Slug,ShortDescription,Description,TeacherId,CategoryId,Level,PassingScore,Status,PublishedAt,CreatedBy) VALUES('VUE3-001',N'Vue.js 3 từ cơ bản đến nâng cao','vue-js-3-tu-co-ban-den-nang-cao',N'Làm chủ Vue 3 qua video tương tác và dự án thực tế.',N'Khóa học toàn diện về Vue 3, Composition API, Vue Router và Pinia.',@TeacherId,@CategoryId,'ALL_LEVELS',60,'PUBLISHED',SYSUTCDATETIME(),@AdminId);
DECLARE @CourseId BIGINT=(SELECT Id FROM dbo.Courses WHERE Code='VUE3-001');
IF NOT EXISTS(SELECT 1 FROM dbo.Chapters WHERE CourseId=@CourseId)
BEGIN
 INSERT dbo.Chapters(CourseId,Title,SortOrder) VALUES(@CourseId,N'Tổng quan Vue.js',1),(@CourseId,N'Component',2),(@CourseId,N'Vue Router',3),(@CourseId,N'Pinia và quản lý trạng thái',4);
END
DECLARE @C1 BIGINT=(SELECT Id FROM dbo.Chapters WHERE CourseId=@CourseId AND SortOrder=1),@C2 BIGINT=(SELECT Id FROM dbo.Chapters WHERE CourseId=@CourseId AND SortOrder=2),@C3 BIGINT=(SELECT Id FROM dbo.Chapters WHERE CourseId=@CourseId AND SortOrder=3),@C4 BIGINT=(SELECT Id FROM dbo.Chapters WHERE CourseId=@CourseId AND SortOrder=4);
IF NOT EXISTS(SELECT 1 FROM dbo.Lessons WHERE CourseId=@CourseId)
BEGIN
 INSERT dbo.Lessons(CourseId,ChapterId,Title,LessonType,DurationSeconds,SortOrder,PassingScore) VALUES
 (@CourseId,@C1,N'Vue.js là gì?','INTERACTIVE_VIDEO',600,1,60),(@CourseId,@C1,N'Cài đặt môi trường','INTERACTIVE_VIDEO',720,2,60),(@CourseId,@C1,N'Template Syntax','INTERACTIVE_VIDEO',820,3,60),(@CourseId,@C1,N'Computed và Watch','INTERACTIVE_VIDEO',1110,4,60),
 (@CourseId,@C2,N'Component cơ bản','INTERACTIVE_VIDEO',840,1,60),(@CourseId,@C2,N'Props và Emits','INTERACTIVE_VIDEO',1215,2,60),(@CourseId,@C2,N'Slots','INTERACTIVE_VIDEO',820,3,60),(@CourseId,@C2,N'Lifecycle Hooks','INTERACTIVE_VIDEO',1045,4,60),
 (@CourseId,@C3,N'Routing cơ bản','VIDEO',1140,1,60),(@CourseId,@C3,N'Navigation Guards','VIDEO',980,2,60),(@CourseId,@C3,N'Lazy Loading','VIDEO',700,3,60),
 (@CourseId,@C4,N'Khởi tạo Store','VIDEO',1090,1,60),(@CourseId,@C4,N'Actions và Getters','VIDEO',1265,2,60),(@CourseId,@C4,N'Persist State','VIDEO',930,3,60),(@CourseId,@C4,N'Dự án tổng kết','QUIZ',1680,4,70);
END
INSERT dbo.Videos(LessonId,Title,DurationSeconds,AllowSeek,AllowSpeed,RequiredWatchPercent)
SELECT l.Id,l.Title,l.DurationSeconds,0,1,80 FROM dbo.Lessons l WHERE l.CourseId=@CourseId AND l.LessonType='INTERACTIVE_VIDEO' AND NOT EXISTS(SELECT 1 FROM dbo.Videos v WHERE v.LessonId=l.Id);
DECLARE @QuestionCount INT=(SELECT COUNT(*) FROM dbo.Questions WHERE CreatedBy=@TeacherId);
DECLARE @i INT=@QuestionCount+1;
WHILE @i<=30
BEGIN
 INSERT dbo.Questions(QuestionType,QuestionText,Explanation,Difficulty,DefaultScore,CreatedBy) VALUES(CASE WHEN @i%5=0 THEN 'TRUE_FALSE' ELSE 'SINGLE_CHOICE' END,CONCAT(N'Câu hỏi Vue.js số ',@i,N': lựa chọn nào mô tả đúng nhất?'),N'Vue.js tập trung vào xây dựng giao diện người dùng theo hướng component.','EASY',10,@TeacherId);
 DECLARE @Q BIGINT=SCOPE_IDENTITY();
 INSERT dbo.QuestionOptions(QuestionId,OptionCode,OptionText,IsCorrect,SortOrder) VALUES(@Q,'A',N'Đáp án chưa chính xác',0,1),(@Q,'B',N'Đáp án chính xác về Vue.js',1,2),(@Q,'C',N'Đáp án gây nhiễu',0,3),(@Q,'D',N'Không có đáp án nào',0,4);
 SET @i+=1;
END
DECLARE @FirstVideo BIGINT=(SELECT TOP 1 v.Id FROM dbo.Videos v JOIN dbo.Lessons l ON l.Id=v.LessonId WHERE l.CourseId=@CourseId ORDER BY l.SortOrder),@Q1 BIGINT=(SELECT MIN(Id) FROM dbo.Questions WHERE CreatedBy=@TeacherId);
IF NOT EXISTS(SELECT 1 FROM dbo.VideoInteractions WHERE VideoId=@FirstVideo)
 INSERT dbo.VideoInteractions(VideoId,QuestionId,TimeSeconds,InteractionType,Required,PauseVideo,AllowSkip,Score,AttemptLimit,SortOrder) VALUES(@FirstVideo,@Q1,20,'QUESTION',1,1,0,10,2,1),(@FirstVideo,@Q1+1,65,'QUESTION',1,1,0,10,2,2),(@FirstVideo,@Q1+2,150,'QUESTION',1,1,0,10,2,3);
DECLARE @StudentId BIGINT=(SELECT Id FROM dbo.Users WHERE Username='student');
IF NOT EXISTS(SELECT 1 FROM dbo.Enrollments WHERE CourseId=@CourseId AND StudentId=@StudentId) INSERT dbo.Enrollments(CourseId,StudentId,StartedAt,Status,ProgressPercent,FinalScore,LastAccessAt,CreatedBy) VALUES(@CourseId,@StudentId,DATEADD(day,-12,SYSUTCDATETIME()),'IN_PROGRESS',42,8.4,SYSUTCDATETIME(),@AdminId);
GO
