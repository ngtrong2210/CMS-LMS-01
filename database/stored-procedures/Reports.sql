CREATE OR ALTER PROCEDURE dbo.LMS_Report_Dashboard AS
BEGIN SET NOCOUNT ON;
 SELECT (SELECT COUNT(*) FROM dbo.Courses WHERE IsDeleted=0) TotalCourses,(SELECT COUNT(*) FROM dbo.Users WHERE StudentCode IS NOT NULL AND IsDeleted=0) TotalStudents,(SELECT COUNT(*) FROM dbo.Users WHERE TeacherCode IS NOT NULL AND IsDeleted=0) TotalTeachers,(SELECT COUNT(*) FROM dbo.Lessons WHERE IsDeleted=0) TotalLessons,(SELECT COUNT(*) FROM dbo.Videos) TotalVideos,(SELECT COUNT(*) FROM dbo.Questions WHERE IsDeleted=0) TotalQuestions,CAST(ISNULL((SELECT AVG(ProgressPercent) FROM dbo.Enrollments WHERE Status<>'CANCELLED'),0) AS DECIMAL(5,2)) CompletionRate,CAST(ISNULL((SELECT AVG(FinalScore) FROM dbo.Enrollments WHERE FinalScore IS NOT NULL),0) AS DECIMAL(5,2)) AverageScore;
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Report_CourseOverview AS
BEGIN SET NOCOUNT ON; SELECT c.Id,c.Code,c.Title,c.Status,COUNT(DISTINCT e.Id) EnrollmentCount,CAST(ISNULL(AVG(e.ProgressPercent),0) AS DECIMAL(5,2)) CompletionRate,CAST(ISNULL(AVG(e.FinalScore),0) AS DECIMAL(8,2)) AverageScore,COUNT(DISTINCT l.Id) LessonCount FROM dbo.Courses c LEFT JOIN dbo.Enrollments e ON e.CourseId=c.Id AND e.Status<>'CANCELLED' LEFT JOIN dbo.Lessons l ON l.CourseId=c.Id AND l.IsDeleted=0 WHERE c.IsDeleted=0 GROUP BY c.Id,c.Code,c.Title,c.Status ORDER BY c.Title; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Report_StudentProgress AS
BEGIN SET NOCOUNT ON; SELECT u.Id,u.StudentCode,u.FullName,c.Code CourseCode,c.Title CourseTitle,e.Status,e.ProgressPercent,e.FinalScore,e.LastAccessAt FROM dbo.Enrollments e JOIN dbo.Users u ON u.Id=e.StudentId JOIN dbo.Courses c ON c.Id=e.CourseId WHERE e.Status<>'CANCELLED' ORDER BY e.ProgressPercent DESC; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Report_LessonCompletion AS
BEGIN SET NOCOUNT ON; SELECT l.Id,l.Title,c.Code CourseCode,COUNT(p.Id) StartedCount,SUM(IIF(p.Completed=1,1,0)) CompletedCount,CAST(ISNULL(AVG(p.Score),0) AS DECIMAL(8,2)) AverageScore FROM dbo.Lessons l JOIN dbo.Courses c ON c.Id=l.CourseId LEFT JOIN dbo.StudentLessonProgress p ON p.LessonId=l.Id WHERE l.IsDeleted=0 GROUP BY l.Id,l.Title,c.Code ORDER BY c.Code,l.Id; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Report_QuestionPerformance AS
BEGIN SET NOCOUNT ON; SELECT q.Id,q.QuestionText,q.QuestionType,COUNT(a.Id) AnswerCount,SUM(IIF(a.IsCorrect=1,1,0)) CorrectCount,SUM(IIF(a.IsCorrect=0,1,0)) WrongCount,CAST(ISNULL(AVG(a.ScoreAwarded),0) AS DECIMAL(8,2)) AverageScore FROM dbo.Questions q LEFT JOIN dbo.StudentAnswers a ON a.QuestionId=q.Id WHERE q.IsDeleted=0 GROUP BY q.Id,q.QuestionText,q.QuestionType ORDER BY AnswerCount DESC; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Report_VideoEngagement AS
BEGIN SET NOCOUNT ON; SELECT v.Id,v.Title,COUNT(DISTINCT l.Id) LessonUsageCount,COUNT(p.Id) ViewerCount,CAST(ISNULL(AVG(p.WatchPercent),0) AS DECIMAL(5,2)) AverageWatchPercent,SUM(IIF(p.Completed=1,1,0)) CompletedCount FROM dbo.Videos v LEFT JOIN dbo.Lessons l ON l.VideoId=v.Id AND l.IsDeleted=0 LEFT JOIN dbo.StudentVideoProgress p ON p.VideoId=v.Id AND p.LessonId=l.Id GROUP BY v.Id,v.Title ORDER BY ViewerCount DESC; END
GO
