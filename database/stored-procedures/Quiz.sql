Create Or Alter Procedure dbo.LMS_Quiz_GetForTeacher
    @LessonID Bigint,
    @ActorID Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Not Exists
    (
        Select 1
        From dbo.SIM_Lessons
            Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseID
        Where (dbo.SIM_Lessons.LessonID = @LessonID)
            And (dbo.SIM_Lessons.LessonType = 'QUIZ')
            And (dbo.SIM_Lessons.IsDeleted = 0)
            And (@IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorID)
    )
        Throw 50003, N'Không tìm thấy bài kiểm tra hoặc bạn không có quyền cập nhật.', 1;

    Select
        dbo.LMS_Quizzes.QuizID,
        dbo.LMS_Quizzes.LessonID,
        dbo.LMS_Quizzes.Title,
        dbo.LMS_Quizzes.Description,
        dbo.LMS_Quizzes.PassingScore,
        dbo.LMS_Quizzes.TimeLimitMinutes,
        dbo.LMS_Quizzes.MaxAttempts,
        dbo.LMS_Quizzes.ShuffleQuestions,
        dbo.LMS_Quizzes.Status
    From dbo.LMS_Quizzes
    Where (dbo.LMS_Quizzes.LessonID = @LessonID);

    Select
        dbo.LMS_QuizQuestions.QuizQuestionID,
        dbo.LMS_QuizQuestions.QuestionID,
        dbo.LMS_QuizQuestions.Score,
        dbo.LMS_QuizQuestions.SortOrder,
        dbo.LMS_QuizQuestions.IsRequired,
        dbo.LMS_Questions.QuestionType,
        dbo.LMS_Questions.QuestionText
    From dbo.LMS_QuizQuestions
        Inner Join dbo.LMS_Quizzes On dbo.LMS_Quizzes.QuizID = dbo.LMS_QuizQuestions.QuizID
        Inner Join dbo.LMS_Questions On dbo.LMS_Questions.QuestionID = dbo.LMS_QuizQuestions.QuestionID
    Where (dbo.LMS_Quizzes.LessonID = @LessonID)
    Order By dbo.LMS_QuizQuestions.SortOrder;
End
Go

Create Or Alter Procedure dbo.LMS_Quiz_Save
    @LessonID Bigint,
    @Title Nvarchar(500),
    @Description Nvarchar(2000) = Null,
    @PassingScore Decimal(5, 2),
    @TimeLimitMinutes Int = Null,
    @MaxAttempts Int,
    @ShuffleQuestions Bit,
    @QuestionIDsJson Nvarchar(Max),
    @ActorID Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    If Not Exists
    (
        Select 1
        From dbo.SIM_Lessons
            Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseID
        Where (dbo.SIM_Lessons.LessonID = @LessonID)
            And (dbo.SIM_Lessons.LessonType = 'QUIZ')
            And (dbo.SIM_Lessons.IsDeleted = 0)
            And (@IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorID)
    )
        Throw 50003, N'Không tìm thấy bài kiểm tra hoặc bạn không có quyền cập nhật.', 1;

    If Nullif(Ltrim(Rtrim(@Title)), N'') Is Null
        Or @PassingScore Not Between 0 And 100
        Or @MaxAttempts Not Between 1 And 20
        Or (@TimeLimitMinutes Is Not Null And @TimeLimitMinutes Not Between 1 And 600)
        Throw 50001, N'Cấu hình bài kiểm tra không hợp lệ.', 1;

    Create Table #tblQuestion
    (
        QuestionID Bigint Not Null Primary Key,
        SortOrder Int Not Null
    );

    Insert #tblQuestion(QuestionID, SortOrder)
    Select
        Convert(Bigint, JsonSource.[value]),
        Convert(Int, JsonSource.[key]) + 1
    From Openjson(Coalesce(@QuestionIDsJson, N'[]')) JsonSource
    Where Try_convert(Bigint, JsonSource.[value]) Is Not Null;

    If Not Exists (Select 1 From #tblQuestion)
        Throw 50001, N'Bài kiểm tra cần ít nhất một câu hỏi.', 1;

    If Exists
    (
        Select 1
        From #tblQuestion
            Left Join dbo.LMS_Questions On dbo.LMS_Questions.QuestionID = #tblQuestion.QuestionID And dbo.LMS_Questions.Status = 'ACTIVE' And dbo.LMS_Questions.IsDeleted = 0
        Where (dbo.LMS_Questions.QuestionID Is Null)
    )
        Throw 50001, N'Danh sách có câu hỏi không còn hoạt động.', 1;

    Begin Transaction;

    Declare @QuizID Bigint = (Select QuizID From dbo.LMS_Quizzes With (Updlock, Holdlock) Where LessonID = @LessonID);

    If @QuizID Is Null
    Begin
        Insert dbo.LMS_Quizzes( LessonID, Title, Description, PassingScore, TimeLimitMinutes, MaxAttempts, ShuffleQuestions, Status, CreatedByUserID)
        Values (@LessonID, @Title, @Description, @PassingScore, @TimeLimitMinutes, @MaxAttempts, @ShuffleQuestions, 'ACTIVE', @ActorID);

        Set @QuizID = Scope_identity();
    End
    Else
        Update dbo.LMS_Quizzes
        Set
            Title = @Title,
            Description = @Description,
            PassingScore = @PassingScore,
            TimeLimitMinutes = @TimeLimitMinutes,
            MaxAttempts = @MaxAttempts,
            ShuffleQuestions = @ShuffleQuestions,
            Status = 'ACTIVE',
            UpdatedAt = Sysutcdatetime()
        Where (QuizID = @QuizID);

    If Exists (Select 1 From dbo.LMS_QuizAttempts Where QuizID = @QuizID)
        And Exists
        (
            Select QuestionID From dbo.LMS_QuizQuestions Where QuizID = @QuizID
            Except
            Select QuestionID From #tblQuestion
        )
        Throw 50004, N'Không thể loại câu hỏi đã có lượt làm. Hãy tạo bài kiểm tra mới nếu cần thay đổi cấu trúc.', 1;

    Delete dbo.LMS_QuizQuestions
    Where (QuizID = @QuizID)
        And Not Exists (Select 1 From #tblQuestion Where #tblQuestion.QuestionID = dbo.LMS_QuizQuestions.QuestionID);

    Merge dbo.LMS_QuizQuestions As Target
    Using
    (
        Select
            @QuizID QuizID,
            #tblQuestion.QuestionID,
            Coalesce(dbo.LMS_Questions.DefaultScore, 10) Score,
            #tblQuestion.SortOrder
        From #tblQuestion
            Inner Join dbo.LMS_Questions On dbo.LMS_Questions.QuestionID = #tblQuestion.QuestionID
    ) As Source
        On Target.QuizID = Source.QuizID And Target.QuestionID = Source.QuestionID
    When Matched Then
        Update Set Score = Source.Score, SortOrder = Source.SortOrder
    When Not Matched Then
        Insert (QuizID, QuestionID, Score, SortOrder, IsRequired)
        Values (Source.QuizID, Source.QuestionID, Source.Score, Source.SortOrder, 1);

    Commit Transaction;

    Select @QuizID QuizID;
End
Go

Create Or Alter Procedure dbo.LMS_Quiz_GetForStudent
    @LessonID Bigint,
    @StudentUserID Bigint
As
Begin
    Set Nocount On;

    Declare @QuizID Bigint;

    Select @QuizID = dbo.LMS_Quizzes.QuizID
    From dbo.LMS_Quizzes
        Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_Quizzes.LessonID
        Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseID
        Inner Join dbo.LMS_Enrollments On dbo.LMS_Enrollments.CourseID = dbo.SIM_Courses.CourseID And dbo.LMS_Enrollments.StudentUserID = @StudentUserID
    Where (dbo.LMS_Quizzes.LessonID = @LessonID)
        And (dbo.LMS_Quizzes.Status = 'ACTIVE')
        And (dbo.SIM_Lessons.Status = 'ACTIVE')
        And (dbo.SIM_Lessons.IsDeleted = 0)
        And (dbo.SIM_Courses.Status = 'PUBLISHED')
        And (dbo.LMS_Enrollments.Status <> 'CANCELLED');

    If @QuizID Is Null
        Throw 50003, N'Bài kiểm tra không tồn tại hoặc bạn chưa được ghi danh.', 1;

    Update dbo.LMS_QuizAttempts
    Set
        SubmittedAt = Sysutcdatetime(),
        Score = 0,
        MaxScore = (Select Coalesce(Sum(Score), 0) From dbo.LMS_QuizQuestions Where QuizID = @QuizID),
        ScorePercent = 0,
        Passed = 0,
        AttemptStatus = 'SUBMITTED'
    Where (QuizID = @QuizID)
        And (StudentUserID = @StudentUserID)
        And (AttemptStatus = 'IN_PROGRESS')
        And Exists
        (
            Select 1
            From dbo.LMS_Quizzes
            Where (dbo.LMS_Quizzes.QuizID = @QuizID)
                And (dbo.LMS_Quizzes.TimeLimitMinutes Is Not Null)
                And (Dateadd(Minute, dbo.LMS_Quizzes.TimeLimitMinutes + 1, dbo.LMS_QuizAttempts.StartedAt) < Sysutcdatetime())
        );

    Select
        dbo.LMS_Quizzes.QuizID,
        dbo.LMS_Quizzes.LessonID,
        dbo.LMS_Quizzes.Title,
        dbo.LMS_Quizzes.Description,
        dbo.LMS_Quizzes.PassingScore,
        dbo.LMS_Quizzes.TimeLimitMinutes,
        dbo.LMS_Quizzes.MaxAttempts,
        dbo.LMS_Quizzes.ShuffleQuestions,
        (Select Count(*) From dbo.LMS_QuizAttempts Where QuizID = @QuizID And StudentUserID = @StudentUserID) AttemptCount
    From dbo.LMS_Quizzes
    Where (dbo.LMS_Quizzes.QuizID = @QuizID);

    Select
        dbo.LMS_QuizQuestions.QuestionID,
        dbo.LMS_Questions.QuestionType,
        dbo.LMS_Questions.QuestionText,
        dbo.LMS_Questions.Description,
        dbo.LMS_QuizQuestions.Score,
        dbo.LMS_QuizQuestions.SortOrder,
        dbo.LMS_QuizQuestions.IsRequired,
        Options.OptionsJson Options
    From dbo.LMS_QuizQuestions
        Inner Join dbo.LMS_Quizzes On dbo.LMS_Quizzes.QuizID = dbo.LMS_QuizQuestions.QuizID
        Inner Join dbo.LMS_Questions On dbo.LMS_Questions.QuestionID = dbo.LMS_QuizQuestions.QuestionID
        Outer Apply
        (
            Select
                dbo.LMS_QuestionOptions.OptionCode,
                dbo.LMS_QuestionOptions.OptionText,
                dbo.LMS_QuestionOptions.SortOrder
            From dbo.LMS_QuestionOptions
            Where (dbo.LMS_QuestionOptions.QuestionID = dbo.LMS_QuizQuestions.QuestionID)
                And (dbo.LMS_QuestionOptions.IsDeleted = 0)
            Order By dbo.LMS_QuestionOptions.SortOrder
            For Json Path
        ) Options(OptionsJson)
    Where (dbo.LMS_QuizQuestions.QuizID = @QuizID)
    Order By
        Case When dbo.LMS_Quizzes.ShuffleQuestions = 0 Then dbo.LMS_QuizQuestions.SortOrder Else 0 End,
        Case When dbo.LMS_Quizzes.ShuffleQuestions = 1 Then Newid() Else Null End;

    Select
        dbo.LMS_QuizAttempts.QuizAttemptID,
        dbo.LMS_QuizAttempts.AttemptNumber,
        dbo.LMS_QuizAttempts.StartedAt,
        dbo.LMS_QuizAttempts.SubmittedAt,
        dbo.LMS_QuizAttempts.Score,
        dbo.LMS_QuizAttempts.MaxScore,
        dbo.LMS_QuizAttempts.ScorePercent,
        dbo.LMS_QuizAttempts.Passed,
        dbo.LMS_QuizAttempts.AttemptStatus
    From dbo.LMS_QuizAttempts
    Where (dbo.LMS_QuizAttempts.QuizID = @QuizID)
        And (dbo.LMS_QuizAttempts.StudentUserID = @StudentUserID)
    Order By dbo.LMS_QuizAttempts.AttemptNumber Desc;
End
Go

Create Or Alter Procedure dbo.LMS_QuizAttempt_Start
    @LessonID Bigint,
    @StudentUserID Bigint
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    Declare @QuizID Bigint;
    Declare @MaxAttempts Int;
    Declare @TimeLimitMinutes Int;

    Select
        @QuizID = dbo.LMS_Quizzes.QuizID,
        @MaxAttempts = dbo.LMS_Quizzes.MaxAttempts,
        @TimeLimitMinutes = dbo.LMS_Quizzes.TimeLimitMinutes
    From dbo.LMS_Quizzes
        Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_Quizzes.LessonID
        Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseID
        Inner Join dbo.LMS_Enrollments On dbo.LMS_Enrollments.CourseID = dbo.SIM_Courses.CourseID And dbo.LMS_Enrollments.StudentUserID = @StudentUserID
    Where (dbo.LMS_Quizzes.LessonID = @LessonID)
        And (dbo.LMS_Quizzes.Status = 'ACTIVE')
        And (dbo.SIM_Courses.Status = 'PUBLISHED')
        And (dbo.LMS_Enrollments.Status <> 'CANCELLED');

    If @QuizID Is Null
        Throw 50003, N'Bài kiểm tra không tồn tại hoặc bạn chưa được ghi danh.', 1;

    Begin Transaction;

    If @TimeLimitMinutes Is Not Null
        Update dbo.LMS_QuizAttempts
        Set
            SubmittedAt = Sysutcdatetime(),
            Score = 0,
            MaxScore = (Select Coalesce(Sum(Score), 0) From dbo.LMS_QuizQuestions Where QuizID = @QuizID),
            ScorePercent = 0,
            Passed = 0,
            AttemptStatus = 'SUBMITTED'
        Where (QuizID = @QuizID)
            And (StudentUserID = @StudentUserID)
            And (AttemptStatus = 'IN_PROGRESS')
            And (Dateadd(Minute, @TimeLimitMinutes + 1, StartedAt) < Sysutcdatetime());

    Declare @QuizAttemptID Bigint = (Select Top (1) QuizAttemptID From dbo.LMS_QuizAttempts With (Updlock, Holdlock) Where QuizID = @QuizID And StudentUserID = @StudentUserID And AttemptStatus = 'IN_PROGRESS' Order By AttemptNumber Desc);

    If @QuizAttemptID Is Null
    Begin
        Declare @AttemptNumber Int = (Select Count(*) + 1 From dbo.LMS_QuizAttempts With (Updlock, Holdlock) Where QuizID = @QuizID And StudentUserID = @StudentUserID);

        If @AttemptNumber > @MaxAttempts
            Throw 50004, N'Bạn đã sử dụng hết số lượt làm bài kiểm tra.', 1;

        Insert dbo.LMS_QuizAttempts(QuizID, StudentUserID, AttemptNumber, AttemptStatus)
        Values (@QuizID, @StudentUserID, @AttemptNumber, 'IN_PROGRESS');

        Set @QuizAttemptID = Scope_identity();
    End;

    Commit Transaction;

    Select
        dbo.LMS_QuizAttempts.QuizAttemptID,
        dbo.LMS_QuizAttempts.AttemptNumber,
        dbo.LMS_QuizAttempts.StartedAt
    From dbo.LMS_QuizAttempts
    Where (dbo.LMS_QuizAttempts.QuizAttemptID = @QuizAttemptID);
End
Go

Create Or Alter Procedure dbo.LMS_QuizAttempt_Submit
    @QuizAttemptID Bigint,
    @StudentUserID Bigint,
    @AnswersJson Nvarchar(Max)
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    Declare @QuizID Bigint;
    Declare @LessonID Bigint;
    Declare @CourseID Bigint;
    Declare @PassingScore Decimal(5, 2);
    Declare @TimeLimitMinutes Int;
    Declare @StartedAt Datetime2;

    Select
        @QuizID = dbo.LMS_QuizAttempts.QuizID,
        @LessonID = dbo.LMS_Quizzes.LessonID,
        @CourseID = dbo.SIM_Lessons.CourseID,
        @PassingScore = dbo.LMS_Quizzes.PassingScore,
        @TimeLimitMinutes = dbo.LMS_Quizzes.TimeLimitMinutes,
        @StartedAt = dbo.LMS_QuizAttempts.StartedAt
    From dbo.LMS_QuizAttempts
        Inner Join dbo.LMS_Quizzes On dbo.LMS_Quizzes.QuizID = dbo.LMS_QuizAttempts.QuizID
        Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_Quizzes.LessonID
    Where (dbo.LMS_QuizAttempts.QuizAttemptID = @QuizAttemptID)
        And (dbo.LMS_QuizAttempts.StudentUserID = @StudentUserID)
        And (dbo.LMS_QuizAttempts.AttemptStatus = 'IN_PROGRESS');

    If @QuizID Is Null
        Throw 50002, N'Lượt làm bài không tồn tại hoặc đã được nộp.', 1;

    If @TimeLimitMinutes Is Not Null And Dateadd(Minute, @TimeLimitMinutes + 1, @StartedAt) < Sysutcdatetime()
        Throw 50004, N'Lượt làm bài đã hết thời gian.', 1;

    Create Table #tblAnswer
    (
        QuestionID Bigint Not Null Primary Key,
        AnswerText Nvarchar(Max) Null
    );

    Insert #tblAnswer(QuestionID, AnswerText)
    Select
        QuestionID,
        Upper(Ltrim(Rtrim(AnswerText)))
    From Openjson(Coalesce(@AnswersJson, N'[]'))
    With
    (
        QuestionID Bigint '$.questionId',
        AnswerText Nvarchar(Max) '$.answerText'
    );

    If Exists (Select 1 From #tblAnswer Where Not Exists (Select 1 From dbo.LMS_QuizQuestions Where QuizID = @QuizID And QuestionID = #tblAnswer.QuestionID))
        Throw 50001, N'Câu trả lời không thuộc bài kiểm tra.', 1;

    Begin Transaction;

    Insert dbo.LMS_QuizAttemptAnswers(QuizAttemptID, QuestionID, AnswerText, IsCorrect, ScoreAwarded)
    Select
        @QuizAttemptID,
        dbo.LMS_QuizQuestions.QuestionID,
        #tblAnswer.AnswerText,
        Result.IsCorrect,
        Iif(Result.IsCorrect = 1, dbo.LMS_QuizQuestions.Score, 0)
    From dbo.LMS_QuizQuestions
        Inner Join dbo.LMS_Questions On dbo.LMS_Questions.QuestionID = dbo.LMS_QuizQuestions.QuestionID
        Left Join #tblAnswer On #tblAnswer.QuestionID = dbo.LMS_QuizQuestions.QuestionID
        Outer Apply
        (
            Select String_agg(Upper(Ltrim(Rtrim(dbo.LMS_QuestionOptions.OptionCode))), '|') Within Group (Order By Upper(Ltrim(Rtrim(dbo.LMS_QuestionOptions.OptionCode)))) CorrectAnswer
            From dbo.LMS_QuestionOptions
            Where (dbo.LMS_QuestionOptions.QuestionID = dbo.LMS_QuizQuestions.QuestionID)
                And (dbo.LMS_QuestionOptions.IsCorrect = 1)
                And (dbo.LMS_QuestionOptions.IsDeleted = 0)
        ) ChoiceAnswer
        Outer Apply
        (
            Select Iif
            (
                dbo.LMS_Questions.QuestionType In ('SINGLE_CHOICE', 'TRUE_FALSE', 'MULTIPLE_CHOICE'),
                Iif(Coalesce(#tblAnswer.AnswerText, '') = Coalesce(ChoiceAnswer.CorrectAnswer, ''), Convert(Bit, 1), Convert(Bit, 0)),
                Iif
                (
                    Exists
                    (
                        Select 1
                        From dbo.LMS_QuestionAnswerKeys
                        Where (dbo.LMS_QuestionAnswerKeys.QuestionID = dbo.LMS_QuizQuestions.QuestionID)
                            And
                            (
                                (dbo.LMS_Questions.ShortAnswerMode = 'CONTAINS' And Charindex(Lower(dbo.LMS_QuestionAnswerKeys.AnswerText), Lower(Coalesce(#tblAnswer.AnswerText, ''))) > 0)
                                Or (dbo.LMS_Questions.ShortAnswerMode <> 'CONTAINS' And Lower(dbo.LMS_QuestionAnswerKeys.AnswerText) = Lower(Coalesce(#tblAnswer.AnswerText, '')))
                            )
                    ),
                    Convert(Bit, 1),
                    Convert(Bit, 0)
                )
            ) IsCorrect
        ) Result
    Where (dbo.LMS_QuizQuestions.QuizID = @QuizID);

    Declare @Score Decimal(8, 2) = (Select Coalesce(Sum(ScoreAwarded), 0) From dbo.LMS_QuizAttemptAnswers Where QuizAttemptID = @QuizAttemptID);
    Declare @MaxScore Decimal(8, 2) = (Select Coalesce(Sum(Score), 0) From dbo.LMS_QuizQuestions Where QuizID = @QuizID);
    Declare @ScorePercent Decimal(5, 2) = Convert(Decimal(5, 2), @Score * 100.0 / Nullif(@MaxScore, 0));
    Declare @Passed Bit = Iif(@ScorePercent >= @PassingScore, 1, 0);

    Update dbo.LMS_QuizAttempts
    Set
        SubmittedAt = Sysutcdatetime(),
        Score = @Score,
        MaxScore = @MaxScore,
        ScorePercent = @ScorePercent,
        Passed = @Passed,
        AttemptStatus = 'SUBMITTED'
    Where (QuizAttemptID = @QuizAttemptID);

    Merge dbo.LMS_StudentLessonProgress As Target
    Using (Select @StudentUserID StudentUserID, @CourseID CourseID, @LessonID LessonID) As Source
        On Target.StudentUserID = Source.StudentUserID And Target.LessonID = Source.LessonID
    When Matched Then
        Update Set Score = @ScorePercent, AttemptCount = Target.AttemptCount + 1, ProgressPercent = 100, Completed = 1, CompletedAt = Coalesce(Target.CompletedAt, Sysutcdatetime()), LastAccessAt = Sysutcdatetime(), UpdatedAt = Sysutcdatetime()
    When Not Matched Then
        Insert (StudentUserID, CourseID, LessonID, ProgressPercent, Score, AttemptCount, Completed, CompletedAt, LastAccessAt, ActiveStudySeconds)
        Values (Source.StudentUserID, Source.CourseID, Source.LessonID, 100, @ScorePercent, 1, 1, Sysutcdatetime(), Sysutcdatetime(), 0);

    Commit Transaction;

    Select
        @QuizAttemptID QuizAttemptID,
        @Score Score,
        @MaxScore MaxScore,
        @ScorePercent ScorePercent,
        @Passed Passed;
End
Go
