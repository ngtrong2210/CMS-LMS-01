IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_Users_StudentCode') CREATE UNIQUE INDEX UX_Users_StudentCode ON dbo.Users(StudentCode) WHERE StudentCode IS NOT NULL AND IsDeleted=0;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_Users_TeacherCode') CREATE UNIQUE INDEX UX_Users_TeacherCode ON dbo.Users(TeacherCode) WHERE TeacherCode IS NOT NULL AND IsDeleted=0;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Courses_Status') CREATE INDEX IX_Courses_Status ON dbo.Courses(Status,IsDeleted);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Courses_Teacher') CREATE INDEX IX_Courses_Teacher ON dbo.Courses(TeacherId);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Chapters_Course_Sort') CREATE INDEX IX_Chapters_Course_Sort ON dbo.Chapters(CourseId,SortOrder);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Lessons_Chapter_Sort') CREATE INDEX IX_Lessons_Chapter_Sort ON dbo.Lessons(ChapterId,SortOrder);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Interactions_Video_Time') CREATE INDEX IX_Interactions_Video_Time ON dbo.VideoInteractions(VideoId,TimeSeconds);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Enrollments_Student') CREATE INDEX IX_Enrollments_Student ON dbo.Enrollments(StudentId,Status);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_StudentAnswers_Question') CREATE INDEX IX_StudentAnswers_Question ON dbo.StudentAnswers(QuestionId,StudentId);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_StudentAnswers_Interaction') CREATE INDEX IX_StudentAnswers_Interaction ON dbo.StudentAnswers(InteractionId,StudentId) WHERE InteractionId IS NOT NULL;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_LearningSessions_Student') CREATE INDEX IX_LearningSessions_Student ON dbo.LearningSessions(StudentId,StartedAt DESC);
GO
