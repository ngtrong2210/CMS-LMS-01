CREATE OR ALTER PROCEDURE dbo.LMS_Report_Dashboard AS
BEGIN SET NOCOUNT ON;
 SELECT (SELECT COUNT(*) FROM dbo.Courses WHERE IsDeleted=0) TotalCourses,(SELECT COUNT(*) FROM dbo.Users WHERE StudentCode IS NOT NULL AND IsDeleted=0) TotalStudents,(SELECT COUNT(*) FROM dbo.Users WHERE TeacherCode IS NOT NULL AND IsDeleted=0) TotalTeachers,(SELECT COUNT(*) FROM dbo.Lessons WHERE IsDeleted=0) TotalLessons,(SELECT COUNT(*) FROM dbo.Videos) TotalVideos,(SELECT COUNT(*) FROM dbo.Questions WHERE IsDeleted=0) TotalQuestions,CAST(ISNULL((SELECT AVG(ProgressPercent) FROM dbo.Enrollments WHERE Status<>'CANCELLED'),0) AS DECIMAL(5,2)) CompletionRate,CAST(ISNULL((SELECT AVG(FinalScore) FROM dbo.Enrollments WHERE FinalScore IS NOT NULL),0) AS DECIMAL(5,2)) AverageScore;
END
GO
