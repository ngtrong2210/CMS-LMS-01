Create Or Alter Procedure dbo.LMS_InteractiveContent_GetForTeacher
    @LessonID Bigint,
    @ActorUserID Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Not Exists
    (
        Select
            1
        From dbo.SIM_Lessons
        Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseId
        Where (dbo.SIM_Lessons.LessonID = @LessonID)
            And (dbo.SIM_Lessons.IsDeleted = 0)
            And (@IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorUserID)
    ) Throw 50003, N'Bạn không có quyền quản lý bài học này.', 1;

    Select
        dbo.SIM_Lessons.LessonID,
        dbo.SIM_Lessons.Title,
        dbo.SIM_Lessons.ContentHtml,
        dbo.LMS_InteractiveContents.InteractiveContentID,
        Coalesce(dbo.LMS_InteractiveContents.CompletionRule, 'REQUIRED_QUESTIONS') CompletionRule,
        Cast(Coalesce(dbo.LMS_InteractiveContents.RequireReading, 1) As Bit) RequireReading,
        Cast(Coalesce(dbo.LMS_InteractiveContents.PassingScore, 70) As Decimal(5, 2)) PassingScore,
        Cast(Coalesce(dbo.LMS_InteractiveContents.ShowResultImmediately, 1) As Bit) ShowResultImmediately,
        Cast(Coalesce(dbo.LMS_InteractiveContents.ShowScore, 1) As Bit) ShowScore
    From dbo.SIM_Lessons
    Left Join dbo.LMS_InteractiveContents On dbo.LMS_InteractiveContents.LessonID = dbo.SIM_Lessons.LessonID
    Where (dbo.SIM_Lessons.LessonID = @LessonID);

    Select
        dbo.LMS_ContentInteractions.ContentInteractionID,
        dbo.LMS_ContentInteractions.QuestionID,
        dbo.LMS_ContentInteractions.ContentAnchor,
        dbo.LMS_ContentInteractions.Required,
        dbo.LMS_ContentInteractions.AllowRetry,
        dbo.LMS_ContentInteractions.Score,
        dbo.LMS_ContentInteractions.AttemptLimit,
        dbo.LMS_ContentInteractions.SortOrder,
        dbo.LMS_ContentInteractions.Status,
        dbo.LMS_Questions.QuestionType,
        dbo.LMS_Questions.QuestionText,
        dbo.LMS_Questions.Explanation,
        dbo.LMS_Questions.Difficulty,
        dbo.LMS_Questions.DefaultScore
    From dbo.LMS_InteractiveContents
    Inner Join dbo.LMS_ContentInteractions On dbo.LMS_ContentInteractions.InteractiveContentID = dbo.LMS_InteractiveContents.InteractiveContentID
    Inner Join dbo.LMS_Questions On dbo.LMS_Questions.QuestionID = dbo.LMS_ContentInteractions.QuestionID
    Where (dbo.LMS_InteractiveContents.LessonID = @LessonID)
        And (dbo.LMS_ContentInteractions.IsDeleted = 0)
    Order By
        dbo.LMS_ContentInteractions.SortOrder;

    Select
        Count(Distinct dbo.LMS_StudentAnswers.StudentUserID) StudentCount,
        Count(dbo.LMS_StudentAnswers.StudentAnswerID) AnswerCount,
        Cast(Coalesce(Avg(Case When dbo.LMS_StudentAnswers.IsCorrect = 1 Then 100.0 Else 0.0 End), 0) As Decimal(5, 2)) CorrectPercent
    From dbo.LMS_InteractiveContents
    Inner Join dbo.LMS_ContentInteractions On dbo.LMS_ContentInteractions.InteractiveContentID = dbo.LMS_InteractiveContents.InteractiveContentID
    Left Join dbo.LMS_StudentAnswers On dbo.LMS_StudentAnswers.ContentInteractionID = dbo.LMS_ContentInteractions.ContentInteractionID
    Where (dbo.LMS_InteractiveContents.LessonID = @LessonID)
        And (dbo.LMS_ContentInteractions.IsDeleted = 0);
End
Go

Create Or Alter Procedure dbo.LMS_InteractiveContent_SaveSettings
    @LessonID Bigint,
    @CompletionRule Varchar(30),
    @RequireReading Bit,
    @PassingScore Decimal(5, 2),
    @ShowResultImmediately Bit,
    @ShowScore Bit,
    @ActorUserID Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If @CompletionRule Not In ('REQUIRED_QUESTIONS', 'ALL_QUESTIONS', 'PASSING_SCORE')
    Or @PassingScore Not Between 0 And 100
        Throw 50001, N'Thiết lập hoàn thành không hợp lệ.', 1;

    If Not Exists
    (
        Select
            1
        From dbo.SIM_Lessons
        Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseId
        Where (dbo.SIM_Lessons.LessonID = @LessonID)
            And (dbo.SIM_Lessons.LessonType = 'INTERACTIVE_CONTENT')
            And (dbo.SIM_Lessons.IsDeleted = 0)
            And (@IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorUserID)
    ) Throw 50003, N'Bài học tương tác không tồn tại hoặc bạn không có quyền quản lý.', 1;

    Merge dbo.LMS_InteractiveContents As Target
    Using
    (
        Select
            @LessonID LessonID
    ) As Source On Source.LessonID = Target.LessonID
    When Matched Then
        Update Set
            CompletionRule = @CompletionRule,
            RequireReading = @RequireReading,
            PassingScore = @PassingScore,
            ShowResultImmediately = @ShowResultImmediately,
            ShowScore = @ShowScore,
            UpdatedByUserID = @ActorUserID,
            UpdatedAt = Sysutcdatetime()
    When Not Matched Then
        Insert (LessonID, CompletionRule, RequireReading, PassingScore, ShowResultImmediately, ShowScore, CreatedByUserID)
        Values (@LessonID, @CompletionRule, @RequireReading, @PassingScore, @ShowResultImmediately, @ShowScore, @ActorUserID);

    Select
        InteractiveContentID
    From dbo.LMS_InteractiveContents
    Where (LessonID = @LessonID);
End
Go

Create Or Alter Procedure dbo.LMS_ContentInteraction_Create
    @LessonID Bigint,
    @QuestionID Bigint,
    @ContentAnchor Nvarchar(100) = Null,
    @Required Bit = 1,
    @AllowRetry Bit = 1,
    @Score Decimal(8, 2) = 10,
    @AttemptLimit Int = 2,
    @SortOrder Int = 1,
    @Status Varchar(30) = 'ACTIVE',
    @ActorUserID Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Declare @InteractiveContentID Bigint;
    Select
        @InteractiveContentID = dbo.LMS_InteractiveContents.InteractiveContentID
    From dbo.LMS_InteractiveContents
    Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_InteractiveContents.LessonID
    Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseId
    Where (dbo.LMS_InteractiveContents.LessonID = @LessonID)
        And (@IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorUserID);

    If @InteractiveContentID Is Null Throw 50003, N'Hãy lưu thiết lập bài học tương tác trước khi thêm câu hỏi.', 1;
    If @Score Not Between 0 And 10000 Or @AttemptLimit Not Between 1 And 100 Or @SortOrder < 1 Throw 50001, N'Thiết lập câu hỏi không hợp lệ.', 1;
    If Not Exists (Select 1 From dbo.LMS_Questions Where QuestionID = @QuestionID And IsDeleted = 0 And Status = 'ACTIVE') Throw 50002, N'Câu hỏi không tồn tại.', 1;

    Insert Into dbo.LMS_ContentInteractions
    (
        InteractiveContentID,
        QuestionID,
        ContentAnchor,
        Required,
        AllowRetry,
        Score,
        AttemptLimit,
        SortOrder,
        Status,
        CreatedByUserID
    )
    Values
    (
        @InteractiveContentID,
        @QuestionID,
        Nullif(Ltrim(Rtrim(@ContentAnchor)), N''),
        @Required,
        @AllowRetry,
        @Score,
        Case When @AllowRetry = 0 Then 1 Else @AttemptLimit End,
        @SortOrder,
        @Status,
        @ActorUserID
    );

    Select
        Cast(Scope_identity() As Bigint);
End
Go

Create Or Alter Procedure dbo.LMS_ContentInteraction_Update
    @ContentInteractionID Bigint,
    @QuestionID Bigint,
    @ContentAnchor Nvarchar(100) = Null,
    @Required Bit = 1,
    @AllowRetry Bit = 1,
    @Score Decimal(8, 2) = 10,
    @AttemptLimit Int = 2,
    @SortOrder Int = 1,
    @Status Varchar(30) = 'ACTIVE',
    @ActorUserID Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Update dbo.LMS_ContentInteractions
    Set
        QuestionID = @QuestionID,
        ContentAnchor = Nullif(Ltrim(Rtrim(@ContentAnchor)), N''),
        Required = @Required,
        AllowRetry = @AllowRetry,
        Score = @Score,
        AttemptLimit = Case When @AllowRetry = 0 Then 1 Else @AttemptLimit End,
        SortOrder = @SortOrder,
        Status = @Status,
        UpdatedByUserID = @ActorUserID,
        UpdatedAt = Sysutcdatetime()
    From dbo.LMS_ContentInteractions
    Inner Join dbo.LMS_InteractiveContents On dbo.LMS_InteractiveContents.InteractiveContentID = dbo.LMS_ContentInteractions.InteractiveContentID
    Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_InteractiveContents.LessonID
    Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseId
    Where (dbo.LMS_ContentInteractions.ContentInteractionID = @ContentInteractionID)
        And (dbo.LMS_ContentInteractions.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorUserID);

    Select
        @@Rowcount;
End
Go

Create Or Alter Procedure dbo.LMS_ContentInteraction_Delete
    @ContentInteractionID Bigint,
    @ActorUserID Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Update dbo.LMS_ContentInteractions
    Set
        IsDeleted = 1,
        UpdatedByUserID = @ActorUserID,
        UpdatedAt = Sysutcdatetime()
    From dbo.LMS_ContentInteractions
    Inner Join dbo.LMS_InteractiveContents On dbo.LMS_InteractiveContents.InteractiveContentID = dbo.LMS_ContentInteractions.InteractiveContentID
    Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_InteractiveContents.LessonID
    Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseId
    Where (dbo.LMS_ContentInteractions.ContentInteractionID = @ContentInteractionID)
        And (dbo.LMS_ContentInteractions.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorUserID);

    Select
        @@Rowcount;
End
Go

Create Or Alter Procedure dbo.LMS_ContentInteraction_Reorder
    @ContentInteractionID Bigint,
    @SortOrder Int,
    @ActorUserID Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Update dbo.LMS_ContentInteractions
    Set
        SortOrder = @SortOrder,
        UpdatedByUserID = @ActorUserID,
        UpdatedAt = Sysutcdatetime()
    From dbo.LMS_ContentInteractions
    Inner Join dbo.LMS_InteractiveContents On dbo.LMS_InteractiveContents.InteractiveContentID = dbo.LMS_ContentInteractions.InteractiveContentID
    Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_InteractiveContents.LessonID
    Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseId
    Where (dbo.LMS_ContentInteractions.ContentInteractionID = @ContentInteractionID)
        And (dbo.LMS_ContentInteractions.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorUserID);

    Select
        @@Rowcount;
End
Go

Create Or Alter Procedure dbo.LMS_InteractiveContent_GetForStudent
    @LessonID Bigint,
    @StudentUserID Bigint
As
Begin
    Set Nocount On;

    If Not Exists
    (
        Select
            1
        From dbo.SIM_Lessons
        Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseId
        Inner Join dbo.LMS_Enrollments On dbo.LMS_Enrollments.CourseId = dbo.SIM_Courses.CourseID
        Where (dbo.SIM_Lessons.LessonID = @LessonID)
            And (dbo.SIM_Lessons.LessonType = 'INTERACTIVE_CONTENT')
            And (dbo.SIM_Lessons.Status = 'ACTIVE')
            And (dbo.SIM_Lessons.IsDeleted = 0)
            And (dbo.SIM_Courses.Status = 'PUBLISHED')
            And (dbo.LMS_Enrollments.StudentUserID = @StudentUserID)
            And (dbo.LMS_Enrollments.Status <> 'CANCELLED')
    ) Throw 50003, N'Không tìm thấy bài học tương tác hoặc bạn chưa được ghi danh.', 1;

    Select
        dbo.SIM_Lessons.LessonID,
        dbo.SIM_Lessons.CourseId CourseID,
        dbo.SIM_Lessons.Title,
        dbo.SIM_Lessons.Description,
        dbo.SIM_Lessons.ContentHtml,
        dbo.LMS_InteractiveContents.InteractiveContentID,
        dbo.LMS_InteractiveContents.CompletionRule,
        dbo.LMS_InteractiveContents.RequireReading,
        dbo.LMS_InteractiveContents.PassingScore,
        dbo.LMS_InteractiveContents.ShowResultImmediately,
        dbo.LMS_InteractiveContents.ShowScore
    From dbo.SIM_Lessons
    Inner Join dbo.LMS_InteractiveContents On dbo.LMS_InteractiveContents.LessonID = dbo.SIM_Lessons.LessonID
    Where (dbo.SIM_Lessons.LessonID = @LessonID);

    Select
        dbo.LMS_ContentInteractions.ContentInteractionID,
        dbo.LMS_ContentInteractions.QuestionID,
        dbo.LMS_ContentInteractions.ContentAnchor,
        dbo.LMS_ContentInteractions.Required,
        dbo.LMS_ContentInteractions.AllowRetry,
        dbo.LMS_ContentInteractions.Score,
        dbo.LMS_ContentInteractions.AttemptLimit,
        dbo.LMS_ContentInteractions.SortOrder,
        dbo.LMS_Questions.QuestionType,
        dbo.LMS_Questions.QuestionText,
        dbo.LMS_Questions.Description,
        (
            Select
                dbo.LMS_QuestionOptions.QuestionOptionID Id,
                dbo.LMS_QuestionOptions.OptionCode,
                dbo.LMS_QuestionOptions.OptionText,
                dbo.LMS_QuestionOptions.SortOrder
            From dbo.LMS_QuestionOptions
            Where (dbo.LMS_QuestionOptions.QuestionId = dbo.LMS_Questions.QuestionID)
                And (dbo.LMS_QuestionOptions.IsDeleted = 0)
            Order By
                dbo.LMS_QuestionOptions.SortOrder
            For Json Path
        ) Options
    From dbo.LMS_InteractiveContents
    Inner Join dbo.LMS_ContentInteractions On dbo.LMS_ContentInteractions.InteractiveContentID = dbo.LMS_InteractiveContents.InteractiveContentID
    Inner Join dbo.LMS_Questions On dbo.LMS_Questions.QuestionID = dbo.LMS_ContentInteractions.QuestionID
    Where (dbo.LMS_InteractiveContents.LessonID = @LessonID)
        And (dbo.LMS_ContentInteractions.IsDeleted = 0)
        And (dbo.LMS_ContentInteractions.Status = 'ACTIVE')
        And (dbo.LMS_Questions.IsDeleted = 0)
        And (dbo.LMS_Questions.Status = 'ACTIVE')
    Order By
        dbo.LMS_ContentInteractions.SortOrder;

    ;With LatestAnswers As
    (
        Select
            dbo.LMS_StudentAnswers.ContentInteractionID,
            dbo.LMS_StudentAnswers.QuestionId QuestionID,
            dbo.LMS_StudentAnswers.AnswerText,
            Case When dbo.LMS_InteractiveContents.ShowResultImmediately = 1 Then dbo.LMS_StudentAnswers.IsCorrect Else Null End IsCorrect,
            dbo.LMS_StudentAnswers.ScoreAwarded,
            dbo.LMS_StudentAnswers.ReviewStatus,
            dbo.LMS_StudentAnswers.AttemptNumber,
            dbo.LMS_StudentAnswers.AnsweredAt,
            Row_number() Over (Partition By dbo.LMS_StudentAnswers.ContentInteractionID Order By dbo.LMS_StudentAnswers.AttemptNumber Desc, dbo.LMS_StudentAnswers.StudentAnswerID Desc) AnswerRank
        From dbo.LMS_StudentAnswers
        Inner Join dbo.LMS_ContentInteractions On dbo.LMS_ContentInteractions.ContentInteractionID = dbo.LMS_StudentAnswers.ContentInteractionID
        Inner Join dbo.LMS_InteractiveContents On dbo.LMS_InteractiveContents.InteractiveContentID = dbo.LMS_ContentInteractions.InteractiveContentID
        Where (dbo.LMS_StudentAnswers.StudentUserID = @StudentUserID)
            And (dbo.LMS_StudentAnswers.LessonId = @LessonID)
    )
    Select
        LatestAnswers.ContentInteractionID,
        LatestAnswers.QuestionID,
        LatestAnswers.AnswerText,
        LatestAnswers.IsCorrect,
        LatestAnswers.ScoreAwarded,
        LatestAnswers.ReviewStatus,
        LatestAnswers.AttemptNumber,
        LatestAnswers.AnsweredAt
    From LatestAnswers
    Where (LatestAnswers.AnswerRank = 1);

    Select
        Cast(Coalesce(dbo.LMS_StudentLessonProgress.ProgressPercent, 0) As Decimal(5, 2)) ProgressPercent,
        Cast(Coalesce(dbo.LMS_StudentLessonProgress.ReadingProgressPercent, 0) As Decimal(5, 2)) ReadingProgressPercent,
        Cast(Coalesce(dbo.LMS_StudentLessonProgress.LastScrollPercent, 0) As Decimal(5, 2)) LastScrollPercent,
        Cast(Coalesce(dbo.LMS_StudentLessonProgress.Score, 0) As Decimal(8, 2)) Score,
        Cast(Coalesce(dbo.LMS_StudentLessonProgress.Completed, 0) As Bit) Completed,
        dbo.LMS_StudentLessonProgress.CompletedAt
    From dbo.SIM_Lessons
    Left Join dbo.LMS_StudentLessonProgress On dbo.LMS_StudentLessonProgress.LessonId = dbo.SIM_Lessons.LessonID And dbo.LMS_StudentLessonProgress.StudentUserID = @StudentUserID
    Where (dbo.SIM_Lessons.LessonID = @LessonID);
End
Go

Create Or Alter Procedure dbo.LMS_InteractiveContent_Recalculate
    @LessonID Bigint,
    @StudentUserID Bigint
As
Begin
    Set Nocount On;

    Declare @CourseID Bigint;
    Declare @CompletionRule Varchar(30);
    Declare @RequireReading Bit;
    Declare @PassingScore Decimal(5, 2);
    Declare @ReadingProgress Decimal(5, 2) = 0;
    Declare @TotalQuestions Int = 0;
    Declare @AnsweredQuestions Int = 0;
    Declare @RequiredQuestions Int = 0;
    Declare @AnsweredRequired Int = 0;
    Declare @MaximumScore Decimal(10, 2) = 0;
    Declare @EarnedScore Decimal(10, 2) = 0;
    Declare @ScorePercent Decimal(5, 2) = 0;
    Declare @AnswerProgress Decimal(5, 2) = 0;
    Declare @ProgressPercent Decimal(5, 2) = 0;
    Declare @Completed Bit = 0;

    Select
        @CourseID = dbo.SIM_Lessons.CourseId,
        @CompletionRule = dbo.LMS_InteractiveContents.CompletionRule,
        @RequireReading = dbo.LMS_InteractiveContents.RequireReading,
        @PassingScore = dbo.LMS_InteractiveContents.PassingScore
    From dbo.SIM_Lessons
    Inner Join dbo.LMS_InteractiveContents On dbo.LMS_InteractiveContents.LessonID = dbo.SIM_Lessons.LessonID
    Where (dbo.SIM_Lessons.LessonID = @LessonID);

    Select
        @ReadingProgress = Coalesce(ReadingProgressPercent, 0)
    From dbo.LMS_StudentLessonProgress
    Where (StudentUserID = @StudentUserID)
        And (LessonId = @LessonID);

    ;With BestAnswers As
    (
        Select
            dbo.LMS_StudentAnswers.ContentInteractionID,
            Max(dbo.LMS_StudentAnswers.ScoreAwarded) BestScore
        From dbo.LMS_StudentAnswers
        Where (dbo.LMS_StudentAnswers.StudentUserID = @StudentUserID)
            And (dbo.LMS_StudentAnswers.LessonId = @LessonID)
            And (dbo.LMS_StudentAnswers.ContentInteractionID Is Not Null)
        Group By
            dbo.LMS_StudentAnswers.ContentInteractionID
    )
    Select
        @TotalQuestions = Count(dbo.LMS_ContentInteractions.ContentInteractionID),
        @AnsweredQuestions = Count(BestAnswers.ContentInteractionID),
        @RequiredQuestions = Sum(Case When dbo.LMS_ContentInteractions.Required = 1 Then 1 Else 0 End),
        @AnsweredRequired = Sum(Case When dbo.LMS_ContentInteractions.Required = 1 And BestAnswers.ContentInteractionID Is Not Null Then 1 Else 0 End),
        @MaximumScore = Coalesce(Sum(dbo.LMS_ContentInteractions.Score), 0),
        @EarnedScore = Coalesce(Sum(BestAnswers.BestScore), 0)
    From dbo.LMS_InteractiveContents
    Inner Join dbo.LMS_ContentInteractions On dbo.LMS_ContentInteractions.InteractiveContentID = dbo.LMS_InteractiveContents.InteractiveContentID
    Left Join BestAnswers On BestAnswers.ContentInteractionID = dbo.LMS_ContentInteractions.ContentInteractionID
    Where (dbo.LMS_InteractiveContents.LessonID = @LessonID)
        And (dbo.LMS_ContentInteractions.Status = 'ACTIVE')
        And (dbo.LMS_ContentInteractions.IsDeleted = 0);

    Set @ScorePercent = Case When @MaximumScore = 0 Then 0 Else Round(@EarnedScore * 100.0 / @MaximumScore, 2) End;
    Set @AnswerProgress = Case When @TotalQuestions = 0 Then 100 Else Round(@AnsweredQuestions * 100.0 / @TotalQuestions, 2) End;
    Set @ProgressPercent = Case When @RequireReading = 1 Then Round((@ReadingProgress + @AnswerProgress) / 2.0, 2) Else @AnswerProgress End;
    Set @Completed = Case
        When @RequireReading = 1 And @ReadingProgress < 100 Then 0
        When @CompletionRule = 'ALL_QUESTIONS' And @AnsweredQuestions = @TotalQuestions Then 1
        When @CompletionRule = 'PASSING_SCORE' And @ScorePercent >= @PassingScore Then 1
        When @CompletionRule = 'REQUIRED_QUESTIONS' And @AnsweredRequired = @RequiredQuestions Then 1
        Else 0
    End;

    Merge dbo.LMS_StudentLessonProgress As Target
    Using (Select @StudentUserID StudentUserID, @LessonID LessonId, @CourseID CourseId) As Source
        On Source.StudentUserID = Target.StudentUserID And Source.LessonId = Target.LessonId
    When Matched Then
        Update Set
            ProgressPercent = Case When @Completed = 1 Then 100 Else @ProgressPercent End,
            Score = @ScorePercent,
            Completed = @Completed,
            CompletedAt = Case When @Completed = 1 Then Coalesce(Target.CompletedAt, Sysutcdatetime()) Else Null End,
            LastAccessAt = Sysutcdatetime(),
            UpdatedAt = Sysutcdatetime()
    When Not Matched Then
        Insert (StudentUserID, CourseId, LessonId, ProgressPercent, Score, AttemptCount, Completed, CompletedAt, LastAccessAt, ReadingProgressPercent, LastScrollPercent)
        Values (@StudentUserID, @CourseID, @LessonID, Case When @Completed = 1 Then 100 Else @ProgressPercent End, @ScorePercent, 0, @Completed, Case When @Completed = 1 Then Sysutcdatetime() Else Null End, Sysutcdatetime(), 0, 0);

    Exec dbo.LMS_Enrollment_RecalculateProgress @StudentUserID, @CourseID;

    Select
        @TotalQuestions TotalQuestions,
        @AnsweredQuestions AnsweredQuestions,
        @RequiredQuestions RequiredQuestions,
        @AnsweredRequired AnsweredRequired,
        @ScorePercent Score,
        @ProgressPercent ProgressPercent,
        @Completed Completed;
End
Go

Create Or Alter Procedure dbo.LMS_InteractiveContent_SaveReadingProgress
    @LessonID Bigint,
    @StudentUserID Bigint,
    @ReadingProgressPercent Decimal(5, 2),
    @LastScrollPercent Decimal(5, 2)
As
Begin
    Set Nocount On;

    Declare @CourseID Bigint;
    Select
        @CourseID = dbo.SIM_Lessons.CourseId
    From dbo.SIM_Lessons
    Inner Join dbo.LMS_Enrollments On dbo.LMS_Enrollments.CourseId = dbo.SIM_Lessons.CourseId
    Where (dbo.SIM_Lessons.LessonID = @LessonID)
        And (dbo.SIM_Lessons.LessonType = 'INTERACTIVE_CONTENT')
        And (dbo.LMS_Enrollments.StudentUserID = @StudentUserID)
        And (dbo.LMS_Enrollments.Status <> 'CANCELLED');

    If @CourseID Is Null Throw 50003, N'Bạn không có quyền học bài này.', 1;

    Set @ReadingProgressPercent = Case When @ReadingProgressPercent < 0 Then 0 When @ReadingProgressPercent > 100 Then 100 Else @ReadingProgressPercent End;
    Set @LastScrollPercent = Case When @LastScrollPercent < 0 Then 0 When @LastScrollPercent > 100 Then 100 Else @LastScrollPercent End;

    Merge dbo.LMS_StudentLessonProgress As Target
    Using (Select @StudentUserID StudentUserID, @LessonID LessonId, @CourseID CourseId) As Source
        On Source.StudentUserID = Target.StudentUserID And Source.LessonId = Target.LessonId
    When Matched Then
        Update Set
            ReadingProgressPercent = Case When @ReadingProgressPercent > Target.ReadingProgressPercent Then @ReadingProgressPercent Else Target.ReadingProgressPercent End,
            LastScrollPercent = @LastScrollPercent,
            LastAccessAt = Sysutcdatetime(),
            UpdatedAt = Sysutcdatetime()
    When Not Matched Then
        Insert (StudentUserID, CourseId, LessonId, ProgressPercent, Score, AttemptCount, Completed, LastAccessAt, ReadingProgressPercent, LastScrollPercent)
        Values (@StudentUserID, @CourseID, @LessonID, 0, 0, 0, 0, Sysutcdatetime(), @ReadingProgressPercent, @LastScrollPercent);

    Exec dbo.LMS_InteractiveContent_Recalculate @LessonID, @StudentUserID;
End
Go

Create Or Alter Procedure dbo.LMS_InteractiveContent_SubmitAnswer
    @LessonID Bigint,
    @ContentInteractionID Bigint,
    @QuestionID Bigint,
    @StudentUserID Bigint,
    @AnswerText Nvarchar(Max),
    @TimeSpentSeconds Int = Null
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    Declare @CourseID Bigint;
    Declare @QuestionType Varchar(50);
    Declare @ShortAnswerMode Varchar(30);
    Declare @Score Decimal(8, 2);
    Declare @AttemptLimit Int;
    Declare @ShowResultImmediately Bit;
    Declare @CorrectAnswer Nvarchar(Max);
    Declare @IsCorrect Bit;
    Declare @AttemptNumber Int;
    Declare @Explanation Nvarchar(Max);

    Select
        @CourseID = dbo.SIM_Lessons.CourseId,
        @QuestionType = dbo.LMS_Questions.QuestionType,
        @ShortAnswerMode = dbo.LMS_Questions.ShortAnswerMode,
        @Score = dbo.LMS_ContentInteractions.Score,
        @AttemptLimit = dbo.LMS_ContentInteractions.AttemptLimit,
        @ShowResultImmediately = dbo.LMS_InteractiveContents.ShowResultImmediately,
        @Explanation = dbo.LMS_Questions.Explanation
    From dbo.LMS_ContentInteractions
    Inner Join dbo.LMS_InteractiveContents On dbo.LMS_InteractiveContents.InteractiveContentID = dbo.LMS_ContentInteractions.InteractiveContentID
    Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_InteractiveContents.LessonID
    Inner Join dbo.LMS_Questions On dbo.LMS_Questions.QuestionID = dbo.LMS_ContentInteractions.QuestionID
    Inner Join dbo.LMS_Enrollments On dbo.LMS_Enrollments.CourseId = dbo.SIM_Lessons.CourseId
    Where (dbo.LMS_ContentInteractions.ContentInteractionID = @ContentInteractionID)
        And (dbo.LMS_ContentInteractions.QuestionID = @QuestionID)
        And (dbo.SIM_Lessons.LessonID = @LessonID)
        And (dbo.SIM_Lessons.LessonType = 'INTERACTIVE_CONTENT')
        And (dbo.LMS_ContentInteractions.Status = 'ACTIVE')
        And (dbo.LMS_ContentInteractions.IsDeleted = 0)
        And (dbo.LMS_Enrollments.StudentUserID = @StudentUserID)
        And (dbo.LMS_Enrollments.Status <> 'CANCELLED');

    If @CourseID Is Null Throw 50003, N'Câu hỏi không thuộc bài học hoặc bạn chưa được ghi danh.', 1;

    Begin Transaction;

    Select
        @AttemptNumber = Count(*) + 1
    From dbo.LMS_StudentAnswers With (Updlock, Holdlock)
    Where (StudentUserID = @StudentUserID)
        And (LessonId = @LessonID)
        And (ContentInteractionID = @ContentInteractionID);

    If @AttemptNumber > @AttemptLimit Throw 50004, N'Bạn đã sử dụng hết số lần trả lời.', 1;

    If @QuestionType In ('SINGLE_CHOICE', 'TRUE_FALSE', 'MULTIPLE_CHOICE')
    Begin
        Select
            @CorrectAnswer = String_agg(Upper(Ltrim(Rtrim(OptionCode))), '|') Within Group (Order By Upper(Ltrim(Rtrim(OptionCode))))
        From dbo.LMS_QuestionOptions
        Where (QuestionId = @QuestionID)
            And (IsCorrect = 1)
            And (IsDeleted = 0);

        Set @IsCorrect = Case When Upper(Coalesce(@AnswerText, '')) = Coalesce(@CorrectAnswer, '') Then 1 Else 0 End;
    End
    Else If @ShortAnswerMode = 'MANUAL_REVIEW'
        Set @IsCorrect = Null;
    Else If @ShortAnswerMode = 'CONTAINS'
        Set @IsCorrect = Case When Exists
        (
            Select
                1
            From dbo.LMS_QuestionAnswerKeys
            Where (QuestionId = @QuestionID)
                And ((IsCaseSensitive = 1 And Charindex(AnswerText, @AnswerText Collate Latin1_General_100_CS_AS) > 0) Or (IsCaseSensitive = 0 And Charindex(Lower(AnswerText), Lower(@AnswerText)) > 0))
        ) Then 1 Else 0 End;
    Else
        Set @IsCorrect = Case When Exists
        (
            Select
                1
            From dbo.LMS_QuestionAnswerKeys
            Where (QuestionId = @QuestionID)
                And ((IsCaseSensitive = 1 And AnswerText = @AnswerText Collate Latin1_General_100_CS_AS) Or (IsCaseSensitive = 0 And Lower(AnswerText) = Lower(@AnswerText)))
        ) Then 1 Else 0 End;

    Insert Into dbo.LMS_StudentAnswers
    (
        StudentUserID,
        CourseId,
        LessonId,
        ContentInteractionID,
        QuestionId,
        AttemptNumber,
        AnswerText,
        IsCorrect,
        ScoreAwarded,
        ReviewStatus,
        TimeSpentSeconds
    )
    Values
    (
        @StudentUserID,
        @CourseID,
        @LessonID,
        @ContentInteractionID,
        @QuestionID,
        @AttemptNumber,
        @AnswerText,
        @IsCorrect,
        Case When @IsCorrect = 1 Then @Score Else 0 End,
        Case When @IsCorrect Is Null Then 'PENDING_REVIEW' Else 'AUTO_GRADED' End,
        @TimeSpentSeconds
    );

    Declare @StudentAnswerID Bigint = Scope_identity();

    If @QuestionType In ('SINGLE_CHOICE', 'TRUE_FALSE', 'MULTIPLE_CHOICE')
        Insert Into dbo.LMS_StudentAnswerOptions(StudentAnswerId, QuestionOptionId)
        Select
            @StudentAnswerID,
            dbo.LMS_QuestionOptions.QuestionOptionID
        From dbo.LMS_QuestionOptions
        Inner Join String_split(@AnswerText, '|') SelectedOption On Upper(Ltrim(Rtrim(SelectedOption.value))) = Upper(dbo.LMS_QuestionOptions.OptionCode)
        Where (dbo.LMS_QuestionOptions.QuestionId = @QuestionID)
            And (dbo.LMS_QuestionOptions.IsDeleted = 0);

    Exec dbo.LMS_InteractiveContent_Recalculate @LessonID, @StudentUserID;

    Declare @CurrentLessonScore Decimal(8, 2) = 0;
    Select
        @CurrentLessonScore = Score
    From dbo.LMS_StudentLessonProgress
    Where (StudentUserID = @StudentUserID)
        And (LessonId = @LessonID);

    Commit Transaction;

    Select
        @StudentAnswerID AnswerId,
        Case When @ShowResultImmediately = 1 Then @IsCorrect Else Null End IsCorrect,
        Case When @IsCorrect = 1 Then @Score Else 0 End ScoreAwarded,
        @CurrentLessonScore CurrentLessonScore,
        @AttemptNumber AttemptNumber,
        Case When @IsCorrect Is Null Then 'PENDING_REVIEW' Else 'AUTO_GRADED' End ReviewStatus,
        Case When @ShowResultImmediately = 1 Then @Explanation Else Null End Explanation;
End
Go

Create Or Alter Procedure dbo.LMS_InteractiveContent_Complete
    @LessonID Bigint,
    @StudentUserID Bigint
As
Begin
    Set Nocount On;

    Declare @Result Table
    (
        TotalQuestions Int,
        AnsweredQuestions Int,
        RequiredQuestions Int,
        AnsweredRequired Int,
        Score Decimal(5, 2),
        ProgressPercent Decimal(5, 2),
        Completed Bit
    );

    Insert Into @Result
    Exec dbo.LMS_InteractiveContent_Recalculate @LessonID, @StudentUserID;

    If Not Exists (Select 1 From @Result Where Completed = 1)
    Begin
        Select
            TotalQuestions,
            AnsweredQuestions,
            RequiredQuestions,
            AnsweredRequired,
            Score,
            ProgressPercent,
            Completed,
            Case
                When AnsweredRequired < RequiredQuestions Then Concat(N'Bạn còn ', RequiredQuestions - AnsweredRequired, N' câu hỏi bắt buộc chưa hoàn thành.')
                Else N'Bạn chưa đạt điều kiện đọc bài hoặc điểm tối thiểu.'
            End BlockReason
        From @Result;
        Return;
    End;

    Select
        TotalQuestions,
        AnsweredQuestions,
        RequiredQuestions,
        AnsweredRequired,
        Score,
        Cast(100 As Decimal(5, 2)) ProgressPercent,
        Completed,
        Cast(Null As Nvarchar(500)) BlockReason
    From @Result;
End
Go
