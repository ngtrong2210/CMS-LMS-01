Set Ansi_nulls On;
Set Quoted_identifier On;
Go

Create Or Alter Procedure dbo.LMS_StudentCourse_GetList
    @StudentId Bigint
As
Begin
    Set Nocount On;

    Select
        dbo.Courses.Id,
        dbo.Courses.Code,
        dbo.Courses.Title,
        dbo.Courses.Slug,
        dbo.Courses.ThumbnailUrl,
        dbo.Courses.ShortDescription,
        dbo.Courses.Level,
        dbo.Courses.Status,
        dbo.CourseCategories.Name CategoryName,
        dbo.Users.FullName TeacherName,
        dbo.Enrollments.Status EnrollmentStatus,
        dbo.Enrollments.ProgressPercent,
        dbo.Enrollments.FinalScore,
        dbo.Enrollments.LastAccessAt,
        (
            Select
                Count(*)
            From dbo.Lessons
            Where (dbo.Lessons.CourseId = dbo.Courses.Id)
                And (dbo.Lessons.IsDeleted = 0)
                And (dbo.Lessons.Status = 'ACTIVE')
    ) LessonCount,
        (
            Select
                Count(*)
            From dbo.StudentLessonProgress
                Inner Join dbo.Lessons On dbo.Lessons.Id = dbo.StudentLessonProgress.LessonId
            Where (dbo.StudentLessonProgress.StudentId = @StudentId)
                And (dbo.Lessons.CourseId = dbo.Courses.Id)
                And (dbo.StudentLessonProgress.Completed = 1)
    ) CompletedLessonCount,
        (
            Select
                Top 1 dbo.Lessons.Id
            From dbo.Lessons
                Left Join dbo.StudentLessonProgress On dbo.StudentLessonProgress.LessonId = dbo.Lessons.Id And dbo.StudentLessonProgress.StudentId = @StudentId
            Where (dbo.Lessons.CourseId = dbo.Courses.Id)
                And (dbo.Lessons.IsDeleted = 0)
                And (dbo.Lessons.Status = 'ACTIVE')
            Order By
                Iif(dbo.StudentLessonProgress.Completed = 1, 1, 0),
                dbo.Lessons.SortOrder,
                dbo.Lessons.Id
    ) ContinueLessonId
    From dbo.Enrollments
        Inner Join dbo.Courses On dbo.Courses.Id = dbo.Enrollments.CourseId
        Inner Join dbo.Users On dbo.Users.Id = dbo.Courses.TeacherId
        Left Join dbo.CourseCategories On dbo.CourseCategories.Id = dbo.Courses.CategoryId
    Where (dbo.Enrollments.StudentId = @StudentId)
        And (dbo.Enrollments.Status <> 'CANCELLED')
        And (dbo.Courses.Status = 'PUBLISHED')
        And (dbo.Courses.IsDeleted = 0)
    Order By
        Coalesce(dbo.Enrollments.LastAccessAt, dbo.Enrollments.EnrolledAt) Desc;

End
Go
Create Or Alter Procedure dbo.LMS_StudentDashboard_Get
    @StudentId Bigint
As
Begin
    Set Nocount On;

    Select
        dbo.Users.FullName,
        (
            Select
                Count(*)
            From dbo.Enrollments
                Inner Join dbo.Courses On dbo.Courses.Id = dbo.Enrollments.CourseId
            Where (dbo.Enrollments.StudentId = @StudentId)
                And (dbo.Enrollments.Status In ('ENROLLED', 'IN_PROGRESS'))
                And (dbo.Courses.Status = 'PUBLISHED')
                And (dbo.Courses.IsDeleted = 0)
    ) ActiveCourseCount,
        (
            Select
                Count(*)
            From dbo.StudentLessonProgress
            Where (StudentId = @StudentId)
                And (Completed = 1)
    ) CompletedLessonCount,
        Cast(
            Isnull(
                (
                    Select
                        Avg(Cast(Score As Decimal(8, 2)))
                    From dbo.StudentLessonProgress
                    Where (StudentId = @StudentId)
                        And (Score > 0)
    ),
                0
    ) As Decimal(8, 2)
    ) AverageScore,
        (
            Select
                Isnull(Sum(WatchDurationSeconds), 0)
            From dbo.LearningSessions
            Where (StudentId = @StudentId)
    ) LearningSeconds
    From dbo.Users
    Where (dbo.Users.Id = @StudentId)
        And (dbo.Users.IsDeleted = 0);

    Exec dbo.LMS_StudentCourse_GetList @StudentId;

End
Go
Create Or Alter Procedure dbo.LMS_StudentCourse_GetDetail
    @CourseId Bigint,
    @StudentId Bigint
As
Begin
    Set Nocount On;

    If Not Exists (
        Select
            1
        From dbo.Enrollments
            Inner Join dbo.Courses On dbo.Courses.Id = dbo.Enrollments.CourseId
        Where (dbo.Enrollments.StudentId = @StudentId)
            And (dbo.Enrollments.CourseId = @CourseId)
            And (dbo.Enrollments.Status <> 'CANCELLED')
            And (dbo.Courses.Status = 'PUBLISHED')
            And (dbo.Courses.IsDeleted = 0)
    ) Return;

    Select
        dbo.Courses.Id,
        dbo.Courses.Code,
        dbo.Courses.Title,
        dbo.Courses.Slug,
        dbo.Courses.ThumbnailUrl,
        dbo.Courses.ShortDescription,
        dbo.Courses.Description,
        dbo.Courses.Level,
        dbo.Courses.PassingScore,
        dbo.CourseCategories.Name CategoryName,
        dbo.Users.FullName TeacherName,
        dbo.Enrollments.Status EnrollmentStatus,
        dbo.Enrollments.ProgressPercent,
        dbo.Enrollments.FinalScore,
        dbo.Enrollments.LastAccessAt
    From dbo.Courses
        Inner Join dbo.Users On dbo.Users.Id = dbo.Courses.TeacherId
        Inner Join dbo.Enrollments On dbo.Enrollments.CourseId = dbo.Courses.Id And dbo.Enrollments.StudentId = @StudentId
        Left Join dbo.CourseCategories On dbo.CourseCategories.Id = dbo.Courses.CategoryId
    Where (dbo.Courses.Id = @CourseId);

    Select
        Id,
        Title,
        Description,
        SortOrder,
        Status
    From dbo.Chapters
    Where (CourseId = @CourseId)
        And (IsDeleted = 0)
        And (Status = 'ACTIVE')
    Order By
        SortOrder,
        Id;

    Select
        dbo.Lessons.Id,
        dbo.Lessons.ChapterId,
        dbo.Lessons.Title,
        dbo.Lessons.Description,
        dbo.Lessons.LessonType,
        dbo.Lessons.DurationSeconds,
        dbo.Lessons.SortOrder,
        dbo.Lessons.IsRequired,
        dbo.Lessons.PassingScore,
        dbo.Lessons.Status,
        Cast(Isnull(dbo.StudentLessonProgress.ProgressPercent, 0) As Decimal(5, 2)) ProgressPercent,
        Cast(Isnull(dbo.StudentLessonProgress.Score, 0) As Decimal(8, 2)) Score,
        Cast(Isnull(dbo.StudentLessonProgress.Completed, 0) As Bit) Completed
    From dbo.Lessons
        Left Join dbo.StudentLessonProgress On dbo.StudentLessonProgress.LessonId = dbo.Lessons.Id And dbo.StudentLessonProgress.StudentId = @StudentId
    Where (dbo.Lessons.CourseId = @CourseId)
        And (dbo.Lessons.IsDeleted = 0)
        And (dbo.Lessons.Status = 'ACTIVE')
    Order By
        dbo.Lessons.ChapterId,
        dbo.Lessons.SortOrder,
        dbo.Lessons.Id;

End
Go
Create Or Alter Procedure dbo.LMS_StudentResults_Get
    @StudentId Bigint,
    @CourseId Bigint = Null
As
Begin
    Set Nocount On;

    Select
        dbo.Enrollments.CourseId,
        dbo.Courses.Code,
        dbo.Courses.Title,
        dbo.Enrollments.Status,
        dbo.Enrollments.ProgressPercent,
        dbo.Enrollments.FinalScore,
        dbo.Enrollments.EnrolledAt,
        dbo.Enrollments.CompletedAt,
        (
            Select
                Count(*)
            From dbo.StudentAnswers
            Where (dbo.StudentAnswers.StudentId = @StudentId)
                And (dbo.StudentAnswers.CourseId = dbo.Courses.Id)
    ) AnswerCount,
        (
            Select
                Count(*)
            From dbo.StudentAnswers
            Where (dbo.StudentAnswers.StudentId = @StudentId)
                And (dbo.StudentAnswers.CourseId = dbo.Courses.Id)
                And (dbo.StudentAnswers.IsCorrect = 1)
    ) CorrectCount
    From dbo.Enrollments
        Inner Join dbo.Courses On dbo.Courses.Id = dbo.Enrollments.CourseId
    Where (dbo.Enrollments.StudentId = @StudentId)
        And (dbo.Enrollments.Status <> 'CANCELLED')
        And (dbo.Courses.Status = 'PUBLISHED')
        And (dbo.Courses.IsDeleted = 0)
        And (@CourseId Is Null Or dbo.Courses.Id = @CourseId)
    Order By
        dbo.Enrollments.EnrolledAt Desc;

    Select
        dbo.StudentLessonProgress.CourseId,
        dbo.StudentLessonProgress.LessonId,
        dbo.Lessons.Title,
        dbo.StudentLessonProgress.ProgressPercent,
        dbo.StudentLessonProgress.Score,
        dbo.StudentLessonProgress.Completed,
        dbo.StudentLessonProgress.CompletedAt,
        dbo.StudentLessonProgress.LastAccessAt,
        (
            Select
                Count(*)
            From dbo.StudentAnswers
            Where (dbo.StudentAnswers.StudentId = @StudentId)
                And (dbo.StudentAnswers.LessonId = dbo.Lessons.Id)
    ) AnswerCount,
        (
            Select
                Count(*)
            From dbo.StudentAnswers
            Where (dbo.StudentAnswers.StudentId = @StudentId)
                And (dbo.StudentAnswers.LessonId = dbo.Lessons.Id)
                And (dbo.StudentAnswers.IsCorrect = 1)
    ) CorrectCount
    From dbo.StudentLessonProgress
        Inner Join dbo.Lessons On dbo.Lessons.Id = dbo.StudentLessonProgress.LessonId
        Inner Join dbo.Courses On dbo.Courses.Id = dbo.Lessons.CourseId
    Where (dbo.StudentLessonProgress.StudentId = @StudentId)
        And (@CourseId Is Null Or dbo.Lessons.CourseId = @CourseId)
        And (dbo.Courses.Status = 'PUBLISHED')
        And (dbo.Courses.IsDeleted = 0)
    Order By
        dbo.Lessons.CourseId,
        dbo.Lessons.SortOrder;

End
Go
Create Or Alter Procedure dbo.LMS_LessonPlayer_GetData
    @LessonId Bigint,
    @StudentId Bigint
As
Begin
    Set Nocount On;

    If Not Exists (
        Select
            1
        From dbo.Lessons
            Inner Join dbo.Courses On dbo.Courses.Id = dbo.Lessons.CourseId
            Inner Join dbo.Enrollments On dbo.Enrollments.CourseId = dbo.Courses.Id And dbo.Enrollments.StudentId = @StudentId
        Where (dbo.Lessons.Id = @LessonId)
            And (dbo.Lessons.IsDeleted = 0)
            And (dbo.Courses.Status = 'PUBLISHED')
            And (dbo.Courses.IsDeleted = 0)
            And (dbo.Enrollments.Status <> 'CANCELLED')
    ) Return;

    Select
        dbo.Lessons.Id,
        dbo.Lessons.CourseId,
        dbo.Lessons.ChapterId,
        dbo.Lessons.Title,
        dbo.Lessons.Description,
        dbo.Lessons.LessonType,
        dbo.Lessons.DurationSeconds,
        dbo.Lessons.PassingScore,
        dbo.Lessons.ContentHtml,
        dbo.Lessons.DocumentUrl,
        dbo.Lessons.AssignmentFolderName,
        dbo.Lessons.AssignmentStartAt,
        dbo.Lessons.DueAt,
        dbo.Lessons.AssignmentMaxScore,
        dbo.Lessons.MaxSubmissionAttempts,
        dbo.Lessons.MaxSubmissionFileSizeMB,
        dbo.Lessons.AllowLateSubmission
    From dbo.Lessons
    Where (dbo.Lessons.Id = @LessonId)
        And (dbo.Lessons.IsDeleted = 0);

    Select
        dbo.Courses.Id,
        dbo.Courses.Code,
        dbo.Courses.Title,
        dbo.Courses.Slug,
        dbo.Users.FullName TeacherName
    From dbo.Courses
        Inner Join dbo.Lessons On dbo.Lessons.CourseId = dbo.Courses.Id
        Inner Join dbo.Users On dbo.Users.Id = dbo.Courses.TeacherId
    Where (dbo.Lessons.Id = @LessonId);

    Select
        dbo.Videos.Id,
        @LessonId LessonId,
        dbo.VideoVersions.Id VideoVersionId,
        dbo.VideoVersions.VersionNumber,
        dbo.VideoVersions.Title,
        dbo.VideoVersions.SourceType,
        dbo.VideoVersions.VideoUrl,
        dbo.VideoVersions.PosterUrl,
        dbo.VideoVersions.DurationSeconds,
        dbo.VideoVersions.AllowSeek,
        dbo.VideoVersions.AllowSpeed,
        dbo.VideoVersions.RequiredWatchPercent
    From dbo.Lessons
        Inner Join dbo.Videos On dbo.Videos.Id = dbo.Lessons.VideoId
        Inner Join dbo.VideoVersions On dbo.VideoVersions.Id = dbo.Lessons.VideoVersionId
    Where (dbo.Lessons.Id = @LessonId)
        And (dbo.Videos.Status = 'ACTIVE')
        And (dbo.VideoVersions.VersionStatus = 'PUBLISHED');

    Select
        dbo.StudentVideoProgress.Id,
        dbo.StudentVideoProgress.CurrentTimeSeconds,
        dbo.StudentVideoProgress.MaxWatchedTimeSeconds,
        dbo.StudentVideoProgress.WatchedSeconds,
        dbo.StudentVideoProgress.WatchPercent,
        dbo.StudentVideoProgress.Completed
    From dbo.StudentVideoProgress
    Where (dbo.StudentVideoProgress.LessonId = @LessonId)
        And (dbo.StudentVideoProgress.StudentId = @StudentId)
        And (dbo.StudentVideoProgress.VideoVersionId = (Select VideoVersionId From dbo.Lessons Where Id = @LessonId));

    Select
        dbo.VideoInteractions.Id,
        dbo.VideoInteractions.VideoId,
        dbo.VideoInteractions.QuestionId,
        dbo.VideoInteractions.TimeSeconds,
        dbo.VideoInteractions.EndTimeSeconds,
        dbo.VideoInteractions.InteractionType,
        dbo.VideoInteractions.Required,
        dbo.VideoInteractions.PauseVideo,
        dbo.VideoInteractions.AllowSkip,
        dbo.VideoInteractions.Score,
        dbo.VideoInteractions.AttemptLimit,
        dbo.VideoInteractions.SortOrder,
        dbo.Questions.QuestionType,
        dbo.Questions.QuestionText,
        dbo.Questions.Description,
        dbo.Questions.Difficulty,
        (
            Select
                dbo.QuestionOptions.Id,
                dbo.QuestionOptions.OptionCode,
                dbo.QuestionOptions.OptionText,
                dbo.QuestionOptions.SortOrder
            From dbo.QuestionOptions
            Where (dbo.QuestionOptions.QuestionId = dbo.Questions.Id)
                And (dbo.QuestionOptions.IsDeleted = 0)
            Order By
                dbo.QuestionOptions.SortOrder
            For Json
                Path
    ) Options
    From dbo.Lessons
        Inner Join dbo.VideoInteractions On dbo.VideoInteractions.VideoId = dbo.Lessons.VideoId
            And dbo.VideoInteractions.VideoVersionId = dbo.Lessons.VideoVersionId
        Inner Join dbo.Questions On dbo.Questions.Id = dbo.VideoInteractions.QuestionId
    Where (dbo.Lessons.Id = @LessonId)
        And (dbo.VideoInteractions.IsDeleted = 0)
        And (dbo.VideoInteractions.Status = 'ACTIVE')
        And (dbo.Questions.IsDeleted = 0)
    Order By
        dbo.VideoInteractions.TimeSeconds;

    /* Deliberately omit IsCorrect And answer keys From the player payload. */
    Select
        dbo.StudentAnswers.InteractionId,
        dbo.StudentAnswers.QuestionId,
        dbo.StudentAnswers.ScoreAwarded,
        dbo.StudentAnswers.ReviewStatus,
        dbo.StudentAnswers.AttemptNumber,
        dbo.StudentAnswers.AnswerText,
        dbo.StudentAnswers.AnsweredAt
    From dbo.StudentAnswers
    Where (dbo.StudentAnswers.StudentId = @StudentId)
        And (dbo.StudentAnswers.LessonId = @LessonId)
        And (dbo.StudentAnswers.VideoVersionId = (Select VideoVersionId From dbo.Lessons Where Id = @LessonId));

End
Go
Create Or Alter Procedure dbo.LMS_Enrollment_RecalculateProgress
    @StudentId Bigint,
    @CourseId Bigint
As
Begin
    Set Nocount On;

    Declare @TotalRequired Int = (
        Select
            Count(*)
        From dbo.Lessons
        Where (CourseId = @CourseId)
            And (IsRequired = 1)
            And (IsDeleted = 0)
            And (Status = 'ACTIVE')
    );

    Declare @CompletedRequired Int = (
        Select
            Count(*)
        From dbo.Lessons
            Inner Join dbo.StudentLessonProgress On dbo.StudentLessonProgress.LessonId = dbo.Lessons.Id And dbo.StudentLessonProgress.StudentId = @StudentId And dbo.StudentLessonProgress.Completed = 1
        Where (dbo.Lessons.CourseId = @CourseId)
            And (dbo.Lessons.IsRequired = 1)
            And (dbo.Lessons.IsDeleted = 0)
            And (dbo.Lessons.Status = 'ACTIVE')
    );

    Declare @Progress Decimal(5, 2) = Case When @TotalRequired = 0 Then 0 Else round(@CompletedRequired * 100.0 / @TotalRequired, 2) End;

    Update dbo.Enrollments
    Set
        ProgressPercent = @Progress,
        Status = Case When @TotalRequired > 0 And @CompletedRequired = @TotalRequired Then 'COMPLETED' When Status = 'CANCELLED' Then Status Else 'IN_PROGRESS' End,
        CompletedAt = Case When @TotalRequired > 0 And @CompletedRequired = @TotalRequired Then Coalesce(CompletedAt, Sysutcdatetime()) Else Null End,
        LastAccessAt = Sysutcdatetime()
    Where (StudentId = @StudentId)
        And (CourseId = @CourseId)
        And (Status <> 'CANCELLED');

End
Go
Create Or Alter Procedure dbo.LMS_LessonProgress_Recalculate
    @StudentId Bigint,
    @LessonId Bigint
As
Begin
    Set Nocount On;

    Declare @CourseId Bigint,
        @PassingScore Decimal(8, 2),
        @VideoCount Int,
        @WatchPercent Decimal(5, 2),
        @WatchSatisfied Bit,
        @InteractionsSatisfied Bit,
        @LessonScore Decimal(8, 2),
        @Completed Bit;

    Declare @VideoId Bigint,
        @VideoVersionId Bigint;

    Select
        @CourseId = CourseId,
        @PassingScore = Isnull(PassingScore, 0),
        @VideoId = VideoId,
        @VideoVersionId = VideoVersionId
    From dbo.Lessons
    Where (Id = @LessonId)
        And (IsDeleted = 0);

    If @CourseId Is Null Return;

    Select
        @VideoCount = Count(*)
    From dbo.VideoVersions
    Where (Id = @VideoVersionId)
        And (VideoId = @VideoId)
        And (VersionStatus = 'PUBLISHED');

    Select
        @WatchPercent = Isnull(Avg(Isnull(dbo.StudentVideoProgress.WatchPercent, 0)), 0),
        @WatchSatisfied = Iif(Count(*) = Sum(Iif(Isnull(dbo.StudentVideoProgress.WatchPercent, 0) >= dbo.VideoVersions.RequiredWatchPercent, 1, 0)), 1, 0)
    From dbo.VideoVersions
        Left Join dbo.StudentVideoProgress On dbo.StudentVideoProgress.VideoVersionId = dbo.VideoVersions.Id And dbo.StudentVideoProgress.StudentId = @StudentId And dbo.StudentVideoProgress.LessonId = @LessonId
    Where (dbo.VideoVersions.Id = @VideoVersionId)
        And (dbo.VideoVersions.VideoId = @VideoId)
        And (dbo.VideoVersions.VersionStatus = 'PUBLISHED');

    If @VideoCount = 0
    Begin
        Set @WatchPercent = 100;

        Set @WatchSatisfied = 1;

    End;

    Set @InteractionsSatisfied = Iif(
            Not Exists (
                Select
                    1
                From dbo.VideoInteractions
                Where (dbo.VideoInteractions.VideoId = @VideoId)
                    And (dbo.VideoInteractions.VideoVersionId = @VideoVersionId)
                    And (dbo.VideoInteractions.Required = 1)
                    And (dbo.VideoInteractions.IsDeleted = 0)
                    And (dbo.VideoInteractions.Status = 'ACTIVE')
                    And Not Exists (
                        Select
                            1
                        From dbo.StudentAnswers
                        Where (dbo.StudentAnswers.StudentId = @StudentId)
                            And (dbo.StudentAnswers.LessonId = @LessonId)
                            And (dbo.StudentAnswers.VideoId = @VideoId)
                            And (dbo.StudentAnswers.VideoVersionId = @VideoVersionId)
                            And (dbo.StudentAnswers.InteractionId = dbo.VideoInteractions.Id)
    )
    ),
            1,
            0
    );

    Select
        @LessonScore = Isnull(Sum(LessonScores.BestScore), 0)
    From (
        Select
            Max(dbo.StudentAnswers.ScoreAwarded) BestScore
        From dbo.StudentAnswers
        Where (dbo.StudentAnswers.StudentId = @StudentId)
            And (dbo.StudentAnswers.LessonId = @LessonId)
            And (@VideoVersionId Is Null Or dbo.StudentAnswers.VideoVersionId = @VideoVersionId)
        Group By Isnull(dbo.StudentAnswers.InteractionId, - dbo.StudentAnswers.QuestionId)
    ) LessonScores;

    Set @Completed = Iif(
        @WatchSatisfied = 1
            And @InteractionsSatisfied = 1
            And @LessonScore >= @PassingScore,
            1,
            0
    );

    Merge dbo.StudentLessonProgress As StudentLessonProgressTarget
    Using (
        Select
            @StudentId StudentId,
            @LessonId LessonId,
            @CourseId CourseId
    ) As StudentLessonProgressSource On StudentLessonProgressTarget.StudentId = StudentLessonProgressSource.StudentId And StudentLessonProgressTarget.LessonId = StudentLessonProgressSource.LessonId
    When Matched Then
    Update
    Set
        ProgressPercent = Iif(@Completed = 1, 100, @WatchPercent),
        Score = @LessonScore,
        Completed = @Completed,
        CompletedAt = Iif(@Completed = 1, Coalesce(StudentLessonProgressTarget.CompletedAt, Sysutcdatetime()), Null),
        LastAccessAt = Sysutcdatetime(),
        UpdatedAt = Sysutcdatetime()
    When Not Matched Then
    Insert (StudentId, CourseId, LessonId, ProgressPercent, Score, AttemptCount, Completed, CompletedAt, LastAccessAt)
    Values
        (@StudentId, @CourseId, @LessonId, Iif(@Completed = 1, 100, @WatchPercent), @LessonScore, 0, @Completed, Iif(@Completed = 1, Sysutcdatetime(), Null), Sysutcdatetime());

    Exec dbo.LMS_Enrollment_RecalculateProgress @StudentId,
        @CourseId;

End
Go
Create Or Alter Procedure dbo.LMS_StudentVideoProgress_Save
    @StudentId Bigint,
    @LessonId Bigint,
    @VideoId Bigint,
    @CurrentTimeSeconds Decimal(10, 2),
    @MaxWatchedTimeSeconds Decimal(10, 2),
    @WatchPercent Decimal(5, 2)
As
Begin
    Set Nocount On;

    Set Xact_abort On;

    Declare @CourseId Bigint,
        @Duration Int,
        @VideoVersionId Bigint;

    Select
        @CourseId = dbo.Lessons.CourseId,
        @VideoVersionId = dbo.Lessons.VideoVersionId,
        @Duration = dbo.VideoVersions.DurationSeconds
    From dbo.Lessons
        Inner Join dbo.Videos On dbo.Videos.Id = dbo.Lessons.VideoId
        Inner Join dbo.VideoVersions On dbo.VideoVersions.Id = dbo.Lessons.VideoVersionId
    Where (dbo.Videos.Id = @VideoId)
        And (dbo.Lessons.Id = @LessonId)
        And (dbo.Lessons.IsDeleted = 0)
        And (dbo.Videos.Status = 'ACTIVE')
        And (dbo.VideoVersions.VersionStatus = 'PUBLISHED');

    If @CourseId Is Null Throw 50001,
    N'Video hoặc bài học không hợp lệ.',
    1;

    If Not Exists (
        Select
            1
        From dbo.Enrollments
            Inner Join dbo.Courses On dbo.Courses.Id = dbo.Enrollments.CourseId
        Where (dbo.Enrollments.StudentId = @StudentId)
            And (dbo.Enrollments.CourseId = @CourseId)
            And (dbo.Enrollments.Status <> 'CANCELLED')
            And (dbo.Courses.Status = 'PUBLISHED')
            And (dbo.Courses.IsDeleted = 0)
    ) Throw 50003,
    N'Bạn chưa được ghi danh vào khóa học này.',
    1;

    Set @CurrentTimeSeconds = Case When @CurrentTimeSeconds < 0 Then 0 When @CurrentTimeSeconds > @Duration Then @Duration Else @CurrentTimeSeconds End;

    Set @MaxWatchedTimeSeconds = Case When @MaxWatchedTimeSeconds < 0 Then 0 When @MaxWatchedTimeSeconds > @Duration Then @Duration Else @MaxWatchedTimeSeconds End;

    Begin Transaction;

    Update dbo.StudentVideoProgress
    Set
        CurrentTimeSeconds = @CurrentTimeSeconds,
        MaxWatchedTimeSeconds = Case When MaxWatchedTimeSeconds > @MaxWatchedTimeSeconds Then MaxWatchedTimeSeconds Else @MaxWatchedTimeSeconds End,
        WatchedSeconds = Case When WatchedSeconds > @MaxWatchedTimeSeconds Then WatchedSeconds Else @MaxWatchedTimeSeconds End,
        WatchPercent = Case When WatchPercent > round(@MaxWatchedTimeSeconds * 100.0 / Nullif(@Duration, 0), 2) Then WatchPercent Else round(@MaxWatchedTimeSeconds * 100.0 / Nullif(@Duration, 0), 2) End,
        LastAccessAt = Sysutcdatetime(),
        UpdatedAt = Sysutcdatetime()
    Where (StudentId = @StudentId)
        And (LessonId = @LessonId)
        And (VideoId = @VideoId)
        And (VideoVersionId = @VideoVersionId);

    If @@Rowcount = 0
    Insert dbo.StudentVideoProgress (StudentId, CourseId, LessonId, VideoId, VideoVersionId, CurrentTimeSeconds, MaxWatchedTimeSeconds, WatchedSeconds, WatchPercent, Completed, LastAccessAt)
    Values
        (@StudentId, @CourseId, @LessonId, @VideoId, @VideoVersionId, @CurrentTimeSeconds, @MaxWatchedTimeSeconds, @MaxWatchedTimeSeconds, round(@MaxWatchedTimeSeconds * 100.0 / Nullif(@Duration, 0), 2), 0, Sysutcdatetime());

    Declare @Required Decimal(5, 2) = (
        Select
            RequiredWatchPercent
        From dbo.VideoVersions
        Where (Id = @VideoVersionId)
            And (VideoId = @VideoId)
    );

    Update dbo.StudentVideoProgress
    Set
        Completed = Iif(WatchPercent >= @Required, 1, 0),
        CompletedAt = Iif(WatchPercent >= @Required, Coalesce(CompletedAt, Sysutcdatetime()), Null)
    Where (StudentId = @StudentId)
        And (LessonId = @LessonId)
        And (VideoId = @VideoId)
        And (VideoVersionId = @VideoVersionId);

    Exec dbo.LMS_LessonProgress_Recalculate @StudentId,
        @LessonId;

    Commit Transaction;

End
Go
Create Or Alter Procedure dbo.LMS_StudentAnswer_Submit
    @StudentId Bigint,
    @LessonId Bigint,
    @VideoId Bigint = Null,
    @InteractionId Bigint = Null,
    @QuestionId Bigint,
    @AnswerText Nvarchar(Max),
    @TimeInVideoSeconds Decimal(10, 2) = Null,
    @TimeSpentSeconds Int = Null
As
Begin
    Set Nocount On;

    Set Xact_abort On;

    Declare @CourseId Bigint,
        @Type Varchar(50),
        @Mode Varchar(30),
        @Score Decimal(8, 2),
        @Correct Nvarchar(Max),
        @IsCorrect Bit,
        @Attempt Int,
        @AttemptLimit Int = 1,
        @VideoVersionId Bigint;

    Select
        @CourseId = CourseId,
        @VideoVersionId = VideoVersionId
    From dbo.Lessons
    Where (Id = @LessonId)
        And (IsDeleted = 0);

    Select
        @Type = QuestionType,
        @Mode = ShortAnswerMode,
        @Score = DefaultScore
    From dbo.Questions
    Where (Id = @QuestionId)
        And (IsDeleted = 0)
        And (Status = 'ACTIVE');

    If @CourseId Is Null
    Or @Type Is Null Throw 50002,
    N'Câu hỏi hoặc bài học không hợp lệ.',
    1;

    If Not Exists (
        Select
            1
        From dbo.Enrollments
            Inner Join dbo.Courses On dbo.Courses.Id = dbo.Enrollments.CourseId
        Where (dbo.Enrollments.StudentId = @StudentId)
            And (dbo.Enrollments.CourseId = @CourseId)
            And (dbo.Enrollments.Status <> 'CANCELLED')
            And (dbo.Courses.Status = 'PUBLISHED')
            And (dbo.Courses.IsDeleted = 0)
    ) Throw 50003,
    N'Bạn chưa được ghi danh vào khóa học này.',
    1;

    If @VideoId Is Not Null
    And Not Exists (
        Select
            1
        From dbo.Lessons
            Inner Join dbo.Videos On dbo.Videos.Id = dbo.Lessons.VideoId
            Inner Join dbo.VideoVersions On dbo.VideoVersions.Id = dbo.Lessons.VideoVersionId
        Where (dbo.Lessons.Id = @LessonId)
            And (dbo.Videos.Id = @VideoId)
            And (dbo.Videos.Status = 'ACTIVE')
            And (dbo.VideoVersions.Id = @VideoVersionId)
    ) Throw 50005,
    N'Video không thuộc bài học này.',
    1;

    If @InteractionId Is Null
    And Exists (
        Select
            1
        From dbo.Lessons
            Inner Join dbo.Videos On dbo.Videos.Id = dbo.Lessons.VideoId
            Inner Join dbo.VideoVersions On dbo.VideoVersions.Id = dbo.Lessons.VideoVersionId
        Where (dbo.Lessons.Id = @LessonId)
            And (dbo.Videos.Status = 'ACTIVE')
            And (dbo.VideoVersions.Id = @VideoVersionId)
    ) Throw 50005,
    N'Bài học video yêu cầu một tương tác câu hỏi hợp lệ.',
    1;

    If @InteractionId Is Not Null
    Begin
        Select
            @AttemptLimit = dbo.VideoInteractions.AttemptLimit,
            @Score = dbo.VideoInteractions.Score
        From dbo.VideoInteractions
            Inner Join dbo.Lessons On dbo.Lessons.VideoId = dbo.VideoInteractions.VideoId And dbo.Lessons.VideoVersionId = dbo.VideoInteractions.VideoVersionId
        Where (dbo.VideoInteractions.Id = @InteractionId)
            And (dbo.VideoInteractions.QuestionId = @QuestionId)
            And (dbo.Lessons.Id = @LessonId)
            And (@VideoId Is Null Or dbo.VideoInteractions.VideoId = @VideoId)
            And (dbo.VideoInteractions.IsDeleted = 0)
            And (dbo.VideoInteractions.Status = 'ACTIVE');

        If @@Rowcount = 0
        Or @AttemptLimit Is Null Throw 50005,
        N'Câu hỏi không thuộc tương tác của bài học này.',
        1;

    End

    Begin Try
        Begin Transaction;

        Declare @LockResult Int;

        Declare @LockResource Nvarchar(255) = Concat('LMS:Answer:', @StudentId, ':', @LessonId, ':', @QuestionId, ':', Isnull(@InteractionId, 0));

        Exec @LockResult = sys.sp_getapplock @Resource = @LockResource,
            @LockMode = 'Exclusive',
            @LockOwner = 'Transaction',
            @LockTimeout = 10000;

        If @LockResult < 0
            Throw 50004, N'Không thể khóa lượt trả lời. Vui lòng thử lại.', 1;

        Select
            @Attempt = Count(*) + 1
        From dbo.StudentAnswers With (Updlock, Holdlock)
        Where (StudentId = @StudentId)
            And (LessonId = @LessonId)
            And (Isnull(VideoVersionId, 0) = Isnull(@VideoVersionId, 0))
            And (QuestionId = @QuestionId)
            And (Isnull(InteractionId, 0) = Isnull(@InteractionId, 0));

        If @Attempt > @AttemptLimit
            Throw 50004, N'Bạn đã sử dụng hết số lần trả lời cho câu hỏi này.', 1;

        If @Type In ('SINGLE_CHOICE', 'TRUE_FALSE', 'MULTIPLE_CHOICE')
        Begin
            Select
                @Correct = String_agg(Upper(Ltrim(Rtrim(OptionCode))), '|') Within Group (Order By Upper(Ltrim(Rtrim(OptionCode))))
            From dbo.QuestionOptions
            Where (QuestionId = @QuestionId)
                And (IsCorrect = 1)
                And (IsDeleted = 0);

            Set @IsCorrect = Iif(Upper(Isnull(@AnswerText, '')) = Isnull(@Correct, ''), 1, 0);

        End
        Else If @Mode = 'MANUAL_REVIEW'
            Set @IsCorrect = Null;

        Else If @Mode = 'CONTAINS'
            Set @IsCorrect = Iif(
            Exists (
                Select
                    1
                From dbo.QuestionAnswerKeys
                Where (QuestionId = @QuestionId)
                    And ((IsCaseSensitive = 1 And Charindex(AnswerText, @AnswerText collate Latin1_General_100_CS_AS) > 0) Or (IsCaseSensitive = 0 And Charindex(Lower(AnswerText), Lower(@AnswerText)) > 0))
    ),
            1,
            0
    );

        Else
            Set @IsCorrect = Iif(
            Exists (
                Select
                    1
                From dbo.QuestionAnswerKeys
                Where (QuestionId = @QuestionId)
                    And ((IsCaseSensitive = 1 And AnswerText = @AnswerText collate Latin1_General_100_CS_AS) Or (IsCaseSensitive = 0 And Lower(AnswerText) = Lower(@AnswerText)))
    ),
            1,
            0
    );

        Insert dbo.StudentAnswers (StudentId, CourseId, LessonId, VideoId, VideoVersionId, InteractionId, QuestionId, AttemptNumber, AnswerText, IsCorrect, ScoreAwarded, ReviewStatus, TimeInVideoSeconds, TimeSpentSeconds)
        Values
        (@StudentId, @CourseId, @LessonId, @VideoId, @VideoVersionId, @InteractionId, @QuestionId, @Attempt, @AnswerText, @IsCorrect, Iif(@IsCorrect = 1, @Score, 0), Iif(@IsCorrect Is Null, 'PENDING_REVIEW', 'AUTO_GRADED'), @TimeInVideoSeconds, @TimeSpentSeconds);

        Declare @AnswerId Bigint = Scope_identity();

        If @Type In ('SINGLE_CHOICE', 'TRUE_FALSE', 'MULTIPLE_CHOICE')
            Insert dbo.StudentAnswerOptions (StudentAnswerId, QuestionOptionId)
            Select
                @AnswerId,
                dbo.QuestionOptions.Id
            From dbo.QuestionOptions
            Inner Join String_split(@AnswerText, '|') SelectedOptions On Upper(Ltrim(Rtrim(SelectedOptions.value))) = Upper(dbo.QuestionOptions.OptionCode)
            Where (dbo.QuestionOptions.QuestionId = @QuestionId)
                And (dbo.QuestionOptions.IsDeleted = 0);

        Declare @WasLessonCompleted Bit = Isnull
        (
            (
                Select
                    dbo.LMS_StudentLessonProgress.Completed
                From dbo.LMS_StudentLessonProgress
                Where (dbo.LMS_StudentLessonProgress.StudentUserID = @StudentId)
                    And (dbo.LMS_StudentLessonProgress.LessonID = @LessonId)
            ),
            0
        );

        Exec dbo.LMS_LessonProgress_Recalculate @StudentId,
            @LessonId;

        If @WasLessonCompleted = 0
            And Exists
            (
                Select
                    1
                From dbo.LMS_StudentLessonProgress
                Where (dbo.LMS_StudentLessonProgress.StudentUserID = @StudentId)
                    And (dbo.LMS_StudentLessonProgress.LessonID = @LessonId)
                    And (dbo.LMS_StudentLessonProgress.Completed = 1)
            )
        Begin
            Insert Into dbo.SYS_Notifications
            (
                RecipientUserID,
                ActorUserID,
                NotificationType,
                Title,
                Message,
                ReferenceType,
                ReferenceID,
                ActionUrl
            )
            Select
                RecipientUser.UserID,
                @StudentId,
                'LESSON_COMPLETED',
                N'Học viên đã hoàn thành bài học',
                Concat(StudentUser.FullName, N' đã hoàn thành “', dbo.SIM_Lessons.Title, N'” với ', Convert(Nvarchar(30), Cast(dbo.LMS_StudentLessonProgress.Score As Decimal(8, 2))), N' điểm.'),
                'LESSON_PROGRESS',
                dbo.LMS_StudentLessonProgress.StudentLessonProgressID,
                N'/cms/reports'
            From dbo.LMS_StudentLessonProgress
            Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_StudentLessonProgress.LessonID
            Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseID
            Inner Join dbo.SYS_Users As StudentUser On StudentUser.UserID = dbo.LMS_StudentLessonProgress.StudentUserID
            Cross Join dbo.SYS_Users As RecipientUser
            Where (dbo.LMS_StudentLessonProgress.StudentUserID = @StudentId)
                And (dbo.LMS_StudentLessonProgress.LessonID = @LessonId)
                And (dbo.LMS_StudentLessonProgress.Completed = 1)
                And
                (
                    RecipientUser.UserID = dbo.SIM_Courses.TeacherUserID
                    Or Exists
                    (
                        Select
                            1
                        From dbo.SYS_UserRoles
                        Inner Join dbo.SYS_Roles On dbo.SYS_Roles.RoleID = dbo.SYS_UserRoles.RoleID
                        Where (dbo.SYS_UserRoles.UserID = RecipientUser.UserID)
                            And (dbo.SYS_Roles.Code = 'ADMIN')
                    )
                )
                And (RecipientUser.IsDeleted = 0)
                And Not Exists
                (
                    Select
                        1
                    From dbo.SYS_Notifications
                    Where (dbo.SYS_Notifications.RecipientUserID = RecipientUser.UserID)
                        And (dbo.SYS_Notifications.NotificationType = 'LESSON_COMPLETED')
                        And (dbo.SYS_Notifications.ReferenceType = 'LESSON_PROGRESS')
                        And (dbo.SYS_Notifications.ReferenceID = dbo.LMS_StudentLessonProgress.StudentLessonProgressID)
                );
        End;

        Select
        @AnswerId AnswerId,
        @IsCorrect IsCorrect,
        Cast(Iif(@IsCorrect = 1, @Score, 0) As Decimal(8, 2)) ScoreAwarded,
        Cast(
            (
                Select
                    Isnull(Sum(BestScore), 0)
                From (
                    Select
                        Max(ScoreAwarded) BestScore
                    From dbo.StudentAnswers
                    Where (StudentId = @StudentId)
                        And (LessonId = @LessonId)
                        And (@VideoVersionId Is Null Or VideoVersionId = @VideoVersionId)
                    Group By Isnull(InteractionId, - QuestionId)
                ) LessonScores
            ) As Decimal(8, 2)
    ) CurrentLessonScore,
        @Attempt AttemptNumber,
        Iif(@IsCorrect Is Null, 'PENDING_REVIEW', 'AUTO_GRADED') ReviewStatus,
        (
            Select
                Explanation
            From dbo.Questions
            Where (Id = @QuestionId)
    ) Explanation;

        Commit Transaction;

    End Try
    Begin Catch
        If @@Trancount > 0
            Rollback Transaction;

        Throw;

    End Catch
End
Go
