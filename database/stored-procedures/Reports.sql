Create Or Alter Procedure dbo.LMS_Report_Dashboard
As
Begin
    Set Nocount On;

    Select
        (Select Count(*) From dbo.Courses Where (IsDeleted = 0)) TotalCourses,
        (Select Count(*) From dbo.Users Where (StudentCode Is Not Null) And (IsDeleted = 0)) TotalStudents,
        (Select Count(*) From dbo.Users Where (TeacherCode Is Not Null) And (IsDeleted = 0)) TotalTeachers,
        (Select Count(*) From dbo.Lessons Where (IsDeleted = 0)) TotalLessons,
        (Select Count(*) From dbo.Videos) TotalVideos,
        (Select Count(*) From dbo.Questions Where (IsDeleted = 0)) TotalQuestions,
        Cast(Isnull((Select Avg(ProgressPercent) From dbo.Enrollments Where (Status <> 'CANCELLED')), 0) As Decimal(5, 2)) CompletionRate,
        Cast(Isnull((Select Avg(FinalScore) From dbo.Enrollments Where (FinalScore Is Not Null)), 0) As Decimal(5, 2)) AverageScore;
End
Go

Create Or Alter Procedure dbo.LMS_Report_CourseOverview
As
Begin
    Set Nocount On;

    Select
        dbo.Courses.Id,
        dbo.Courses.Code,
        dbo.Courses.Title,
        dbo.Courses.Status,
        Count(Distinct dbo.Enrollments.Id) EnrollmentCount,
        Cast(Isnull(Avg(dbo.Enrollments.ProgressPercent), 0) As Decimal(5, 2)) CompletionRate,
        Cast(Isnull(Avg(dbo.Enrollments.FinalScore), 0) As Decimal(8, 2)) AverageScore,
        Count(Distinct dbo.Lessons.Id) LessonCount
    From dbo.Courses
    Left Join dbo.Enrollments On dbo.Enrollments.CourseId = dbo.Courses.Id And dbo.Enrollments.Status <> 'CANCELLED'
    Left Join dbo.Lessons On dbo.Lessons.CourseId = dbo.Courses.Id And dbo.Lessons.IsDeleted = 0
    Where (dbo.Courses.IsDeleted = 0)
    Group By
        dbo.Courses.Id,
        dbo.Courses.Code,
        dbo.Courses.Title,
        dbo.Courses.Status
    Order By dbo.Courses.Title;
End
Go

Create Or Alter Procedure dbo.LMS_Report_StudentProgress
As
Begin
    Set Nocount On;

    Select
        dbo.Users.Id,
        dbo.Users.StudentCode,
        dbo.Users.FullName,
        dbo.Courses.Code CourseCode,
        dbo.Courses.Title CourseTitle,
        dbo.Enrollments.Status,
        dbo.Enrollments.ProgressPercent,
        dbo.Enrollments.FinalScore,
        dbo.Enrollments.LastAccessAt
    From dbo.Enrollments
    Inner Join dbo.Users On dbo.Users.Id = dbo.Enrollments.StudentId
    Inner Join dbo.Courses On dbo.Courses.Id = dbo.Enrollments.CourseId
    Where (dbo.Enrollments.Status <> 'CANCELLED')
    Order By dbo.Enrollments.ProgressPercent Desc;
End
Go

Create Or Alter Procedure dbo.LMS_Report_LessonCompletion
As
Begin
    Set Nocount On;

    Select
        dbo.Lessons.Id,
        dbo.Lessons.Title,
        dbo.Courses.Code CourseCode,
        Count(dbo.StudentLessonProgress.Id) StartedCount,
        Sum(Iif(dbo.StudentLessonProgress.Completed = 1, 1, 0)) CompletedCount,
        Cast(Isnull(Avg(dbo.StudentLessonProgress.Score), 0) As Decimal(8, 2)) AverageScore
    From dbo.Lessons
    Inner Join dbo.Courses On dbo.Courses.Id = dbo.Lessons.CourseId
    Left Join dbo.StudentLessonProgress On dbo.StudentLessonProgress.LessonId = dbo.Lessons.Id
    Where (dbo.Lessons.IsDeleted = 0)
    Group By
        dbo.Lessons.Id,
        dbo.Lessons.Title,
        dbo.Courses.Code
    Order By
        dbo.Courses.Code,
        dbo.Lessons.Id;
End
Go

Create Or Alter Procedure dbo.LMS_Report_QuestionPerformance
As
Begin
    Set Nocount On;

    Select
        dbo.Questions.Id,
        dbo.Questions.QuestionText,
        dbo.Questions.QuestionType,
        Count(dbo.StudentAnswers.Id) AnswerCount,
        Sum(Iif(dbo.StudentAnswers.IsCorrect = 1, 1, 0)) CorrectCount,
        Sum(Iif(dbo.StudentAnswers.IsCorrect = 0, 1, 0)) WrongCount,
        Cast(Isnull(Avg(dbo.StudentAnswers.ScoreAwarded), 0) As Decimal(8, 2)) AverageScore
    From dbo.Questions
    Left Join dbo.StudentAnswers On dbo.StudentAnswers.QuestionId = dbo.Questions.Id
    Where (dbo.Questions.IsDeleted = 0)
    Group By
        dbo.Questions.Id,
        dbo.Questions.QuestionText,
        dbo.Questions.QuestionType
    Order By AnswerCount Desc;
End
Go

Create Or Alter Procedure dbo.LMS_Report_VideoEngagement
As
Begin
    Set Nocount On;

    Select
        dbo.Videos.Id,
        dbo.Videos.Title,
        Count(Distinct dbo.Lessons.Id) LessonUsageCount,
        Count(dbo.StudentVideoProgress.Id) ViewerCount,
        Cast(Isnull(Avg(dbo.StudentVideoProgress.WatchPercent), 0) As Decimal(5, 2)) AverageWatchPercent,
        Sum(Iif(dbo.StudentVideoProgress.Completed = 1, 1, 0)) CompletedCount
    From dbo.Videos
    Left Join dbo.Lessons On dbo.Lessons.VideoId = dbo.Videos.Id And dbo.Lessons.IsDeleted = 0
    Left Join dbo.StudentVideoProgress On dbo.StudentVideoProgress.VideoId = dbo.Videos.Id And dbo.StudentVideoProgress.LessonId = dbo.Lessons.Id
    Group By
        dbo.Videos.Id,
        dbo.Videos.Title
    Order By ViewerCount Desc;
End
Go
