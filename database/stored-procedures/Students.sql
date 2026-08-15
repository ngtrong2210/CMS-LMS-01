Create Or Alter Procedure dbo.LMS_Student_GetList
    @Search Nvarchar(500) = Null,
    @Status Varchar(30) = Null,
    @Page Int = 1,
    @PageSize Int = 20
As
Begin
    Set Nocount On;

    Select
        dbo.Users.Id,
        dbo.Users.StudentCode,
        dbo.Users.FullName,
        dbo.Users.Email,
        dbo.Users.AvatarUrl,
        dbo.Users.Status,
        dbo.Users.LastLoginAt,
        Count(dbo.Enrollments.Id) CourseCount,
        Cast(Isnull(Avg(dbo.Enrollments.ProgressPercent), 0) As Decimal(5, 2)) ProgressPercent,
        Cast(Isnull(Avg(dbo.Enrollments.FinalScore), 0) As Decimal(8, 2)) AverageScore
    From dbo.Users
    Left Join dbo.Enrollments On dbo.Enrollments.StudentId = dbo.Users.Id And dbo.Enrollments.Status <> 'CANCELLED'
    Where (dbo.Users.StudentCode Is Not Null)
        And (dbo.Users.IsDeleted = 0)
        And (@Status Is Null Or @Status = '' Or dbo.Users.Status = @Status)
        And (@Search Is Null Or @Search = '' Or dbo.Users.FullName Like '%' + @Search + '%' Or dbo.Users.StudentCode Like '%' + @Search + '%' Or dbo.Users.Email Like '%' + @Search + '%')
    Group By
        dbo.Users.Id,
        dbo.Users.StudentCode,
        dbo.Users.FullName,
        dbo.Users.Email,
        dbo.Users.AvatarUrl,
        dbo.Users.Status,
        dbo.Users.LastLoginAt
    Order By dbo.Users.FullName
    Offset (@Page - 1) * @PageSize Rows
    Fetch Next @PageSize Rows Only;

    Select
        Count(*)
    From dbo.Users
    Where (dbo.Users.StudentCode Is Not Null)
        And (dbo.Users.IsDeleted = 0)
        And (@Status Is Null Or @Status = '' Or dbo.Users.Status = @Status)
        And (@Search Is Null Or @Search = '' Or dbo.Users.FullName Like '%' + @Search + '%' Or dbo.Users.StudentCode Like '%' + @Search + '%' Or dbo.Users.Email Like '%' + @Search + '%');
End
Go

Create Or Alter Procedure dbo.LMS_Student_GetById
    @Id Bigint
As
Begin
    Set Nocount On;

    Select
        Id,
        Username,
        FullName,
        Email,
        StudentCode,
        AvatarUrl,
        Status,
        LastLoginAt,
        CreatedAt
    From dbo.Users
    Where (Id = @Id)
        And (StudentCode Is Not Null)
        And (IsDeleted = 0);

    Select
        dbo.Enrollments.Id,
        dbo.Courses.Code,
        dbo.Courses.Title,
        dbo.Enrollments.Status,
        dbo.Enrollments.ProgressPercent,
        dbo.Enrollments.FinalScore,
        dbo.Enrollments.EnrolledAt,
        dbo.Enrollments.CompletedAt
    From dbo.Enrollments
    Inner Join dbo.Courses On dbo.Courses.Id = dbo.Enrollments.CourseId
    Where (dbo.Enrollments.StudentId = @Id);

    Select
        dbo.StudentLessonProgress.CourseId,
        dbo.StudentLessonProgress.LessonId,
        dbo.Lessons.Title,
        dbo.StudentLessonProgress.ProgressPercent,
        dbo.StudentLessonProgress.Score,
        dbo.StudentLessonProgress.Completed,
        dbo.StudentLessonProgress.LastAccessAt
    From dbo.StudentLessonProgress
    Inner Join dbo.Lessons On dbo.Lessons.Id = dbo.StudentLessonProgress.LessonId
    Where (dbo.StudentLessonProgress.StudentId = @Id);

    Select
        dbo.StudentAnswers.CourseId,
        dbo.StudentAnswers.LessonId,
        dbo.StudentAnswers.QuestionId,
        dbo.StudentAnswers.AttemptNumber,
        dbo.StudentAnswers.AnswerText,
        dbo.StudentAnswers.IsCorrect,
        dbo.StudentAnswers.ScoreAwarded,
        dbo.StudentAnswers.ReviewStatus,
        dbo.StudentAnswers.AnsweredAt
    From dbo.StudentAnswers
    Where (dbo.StudentAnswers.StudentId = @Id)
    Order By dbo.StudentAnswers.AnsweredAt Desc;

    Select
        SessionId,
        CourseId,
        LessonId,
        VideoId,
        StartedAt,
        EndedAt,
        WatchDurationSeconds,
        LastPositionSeconds,
        Completed
    From dbo.LearningSessions
    Where (StudentId = @Id)
    Order By StartedAt Desc;
End
Go

Create Or Alter Procedure dbo.LMS_Enrollment_GetList
    @Page Int = 1,
    @PageSize Int = 20
As
Begin
    Set Nocount On;

    Select
        dbo.Enrollments.Id,
        dbo.Enrollments.CourseId,
        dbo.Courses.Code CourseCode,
        dbo.Courses.Title CourseTitle,
        dbo.Enrollments.StudentId,
        dbo.Users.StudentCode,
        dbo.Users.FullName StudentName,
        dbo.Enrollments.EnrolledAt,
        dbo.Enrollments.Status,
        dbo.Enrollments.ProgressPercent,
        dbo.Enrollments.FinalScore,
        dbo.Enrollments.LastAccessAt
    From dbo.Enrollments
    Inner Join dbo.Courses On dbo.Courses.Id = dbo.Enrollments.CourseId
    Inner Join dbo.Users On dbo.Users.Id = dbo.Enrollments.StudentId
    Order By dbo.Enrollments.EnrolledAt Desc
    Offset (@Page - 1) * @PageSize Rows
    Fetch Next @PageSize Rows Only;

    Select
        Count(*)
    From dbo.Enrollments;
End
Go

Create Or Alter Procedure dbo.LMS_Enrollment_Create
    @CourseId Bigint,
    @StudentId Bigint,
    @ActorId Bigint
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    If Not Exists
    (
        Select
            1
        From dbo.Courses
        Where (Id = @CourseId)
            And (IsDeleted = 0)
    )
        Or Not Exists
        (
            Select
                1
            From dbo.Users
            Where (Id = @StudentId)
                And (StudentCode Is Not Null)
                And (IsDeleted = 0)
        )
        Throw 50002, N'Khóa học hoặc học viên không tồn tại.', 1;

    If Exists
    (
        Select
            1
        From dbo.Enrollments
        Where (CourseId = @CourseId)
            And (StudentId = @StudentId)
            And (Status <> 'CANCELLED')
    )
        Throw 50006, N'Học viên đã được ghi danh vào khóa học.', 1;

    Begin Transaction;

    Declare @Id Bigint;

    Select
        @Id = Id
    From dbo.Enrollments With (Updlock, Holdlock)
    Where (CourseId = @CourseId)
        And (StudentId = @StudentId)
        And (Status = 'CANCELLED');

    If @Id Is Not Null
        Update dbo.Enrollments
        Set Status = 'ENROLLED',
            ProgressPercent = 0,
            FinalScore = Null,
            EnrolledAt = Sysutcdatetime(),
            StartedAt = Null,
            CompletedAt = Null,
            LastAccessAt = Null,
            CreatedBy = @ActorId
        Where (Id = @Id);
    Else
    Begin
        Insert dbo.Enrollments
        (
            CourseId,
            StudentId,
            Status,
            ProgressPercent,
            CreatedBy
        )
        Values
        (
            @CourseId,
            @StudentId,
            'ENROLLED',
            0,
            @ActorId
        );

        Set @Id = Scope_identity();
    End

    Insert dbo.AuditLogs
    (
        UserId,
        Action,
        Module,
        EntityName,
        EntityId
    )
    Values
    (
        @ActorId,
        'CREATE',
        'ENROLLMENT',
        'Enrollment',
        Convert(Nvarchar(100), @Id)
    );

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
        @StudentId,
        @ActorId,
        'ENROLLMENT',
        N'Bạn đã được ghi danh khóa học',
        Concat(N'Bạn có thể bắt đầu học khóa “', dbo.SIM_Courses.Title, N'”.'),
        'COURSE',
        dbo.SIM_Courses.CourseID,
        Concat(N'/lms/courses/', dbo.SIM_Courses.CourseID)
    From dbo.SIM_Courses
    Where (dbo.SIM_Courses.CourseID = @CourseId);

    Commit;

    Select
        @Id;
End
Go

Create Or Alter Procedure dbo.LMS_Enrollment_Cancel
    @Id Bigint,
    @ActorId Bigint
As
Begin
    Set Nocount On;

    Update dbo.Enrollments
    Set Status = 'CANCELLED',
        LastAccessAt = Sysutcdatetime()
    Where (Id = @Id)
        And (Status <> 'CANCELLED');

    Declare @Rows Int = @@Rowcount;

    If @Rows > 0
        Insert dbo.AuditLogs
        (
            UserId,
            Action,
            Module,
            EntityName,
            EntityId
        )
        Values
        (
            @ActorId,
            'CANCEL',
            'ENROLLMENT',
            'Enrollment',
            Convert(Nvarchar(100), @Id)
        );

    Select
        @Rows;
End
Go
