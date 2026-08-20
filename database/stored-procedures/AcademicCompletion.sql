Create Or Alter Procedure dbo.LMS_ClassSubject_Workspace_Ensure
    @ClassSubjectID Bigint,
    @ActorID Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    Declare @DataGroupID Int;
    Declare @YearID Int;
    Declare @YearName Nvarchar(50);
    Declare @Semester Tinyint;
    Declare @ClassID Nvarchar(50);
    Declare @ClassName Nvarchar(500);
    Declare @SubjectID Nvarchar(50);
    Declare @SubjectName Nvarchar(500);
    Declare @TeacherUserID Bigint;
    Declare @CourseID Bigint;

    Select
        @DataGroupID = dbo.SIM_Class_Subject.DataGroupID,
        @YearID = dbo.SIM_Class_Subject.YearID,
        @YearName = dbo.SIM_Year.YearName,
        @Semester = dbo.SIM_Class_Subject.Semester,
        @ClassID = dbo.SIM_Class_Subject.ClassID,
        @ClassName = dbo.SIM_Class.ClassName,
        @SubjectID = dbo.SIM_Class_Subject.SubjectID,
        @SubjectName = dbo.SIM_Subject.SubjectName,
        @TeacherUserID = dbo.SIM_Teacher.UserID
    From dbo.SIM_Class_Subject
        Inner Join dbo.SIM_Year On dbo.SIM_Year.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Year.YearID = dbo.SIM_Class_Subject.YearID
        Inner Join dbo.SIM_Class On dbo.SIM_Class.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Class.ClassID = dbo.SIM_Class_Subject.ClassID
        Inner Join dbo.SIM_Subject On dbo.SIM_Subject.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Subject.SubjectID = dbo.SIM_Class_Subject.SubjectID
        Left Join dbo.SIM_Teacher On dbo.SIM_Teacher.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Teacher.TeacherID = dbo.SIM_Class_Subject.TeacherID
    Where (dbo.SIM_Class_Subject.ClassSubjectID = @ClassSubjectID)
        And (dbo.SIM_Class_Subject.ClassSubjectStatus = 1);

    If @DataGroupID Is Null
        Throw 50002, N'Môn học lớp không tồn tại hoặc đã ngừng hoạt động.', 1;

    If @TeacherUserID Is Null
        Throw 50001, N'Cần phân công giảng viên trước khi khởi tạo nội dung môn học lớp.', 1;

    If @IsAdmin = 0 And @TeacherUserID <> @ActorID
        Throw 50003, N'Bạn không được phân công phụ trách môn học lớp này.', 1;

    Select
        @CourseID = dbo.SIM_Courses.CourseID
    From dbo.SIM_Courses
    Where (dbo.SIM_Courses.DataGroupID = @DataGroupID)
        And (dbo.SIM_Courses.ClassSubjectID = @ClassSubjectID)
        And (dbo.SIM_Courses.IsDeleted = 0);

    If @CourseID Is Null
    Begin
        Declare @Code Nvarchar(100) = Concat(N'MH-', @YearID, N'-HK', @Semester, N'-', @ClassID, N'-', @SubjectID);
        Declare @Slug Nvarchar(500) = Lower(Replace(Replace(@Code, N' ', N'-'), N'_', N'-'));
        Declare @Title Nvarchar(500) = Concat(@SubjectName, N' · ', @ClassName, N' · ', @YearName, N' · Học kỳ ', @Semester);
        Declare @CategoryID Bigint = (Select Top (1) CourseCategoryID From dbo.SIM_CourseCategories Where Status = 'ACTIVE' Order By SortOrder, CourseCategoryID);

        Begin Transaction;

        Insert dbo.SIM_Courses
        (
            Code,
            Title,
            Slug,
            ShortDescription,
            Description,
            TeacherUserID,
            CourseCategoryID,
            DataGroupID,
            ClassSubjectID,
            Level,
            PassingScore,
            Status,
            CreatedByUserID
        )
        Values
            (@Code, @Title, @Slug, Concat(N'Nội dung học tập của ', @SubjectName, N' cho lớp ', @ClassName, N' trong ', @YearName, N'.'), Concat(N'Không gian chương, bài học, video, tài liệu và bài tập của môn học lớp ', @ClassName, N' - ', @SubjectName, N'.'), @TeacherUserID, @CategoryID, @DataGroupID, @ClassSubjectID, 'BEGINNER', 50, 'DRAFT', @ActorID);

        Set @CourseID = Scope_identity();

        Insert dbo.LMS_Enrollments
        (
            CourseID,
            StudentUserID,
            Status,
            CreatedByUserID
        )
        Select
            @CourseID,
            dbo.SIM_Student.UserID,
            'ENROLLED',
            @ActorID
        From dbo.SIM_Student
        Where (dbo.SIM_Student.DataGroupID = @DataGroupID)
            And (dbo.SIM_Student.ClassID = @ClassID)
            And (dbo.SIM_Student.IsActived = 1)
            And (dbo.SIM_Student.UserID Is Not Null)
            And Not Exists
            (
                Select 1
                From dbo.LMS_Enrollments
                Where (dbo.LMS_Enrollments.CourseID = @CourseID)
                    And (dbo.LMS_Enrollments.StudentUserID = dbo.SIM_Student.UserID)
            );

        Commit Transaction;
    End;

    Select
        dbo.SIM_Courses.ClassSubjectID,
        dbo.SIM_Courses.CourseID,
        dbo.SIM_Courses.Title,
        dbo.SIM_Courses.TeacherUserID
    From dbo.SIM_Courses
    Where (dbo.SIM_Courses.CourseID = @CourseID);
End
Go

Create Or Alter Procedure dbo.LMS_AssignmentSubmission_Save
    @LessonID Bigint,
    @StudentUserID Bigint,
    @SubmissionText Nvarchar(Max) = Null,
    @FileUrl Nvarchar(1000) = Null,
    @OriginalFileName Nvarchar(500) = Null,
    @StoredFileName Nvarchar(500) = Null,
    @FileSize Bigint = Null,
    @MimeType Nvarchar(150) = Null,
    @Action Varchar(20) = 'SUBMIT'
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    Set @Action = Upper(Ltrim(Rtrim(@Action)));

    If @Action Not In ('DRAFT', 'SUBMIT')
        Throw 50001, N'Thao tác bài nộp không hợp lệ.', 1;

    Declare @CourseID Bigint;
    Declare @AssignmentStartAt Datetime2;
    Declare @DueAt Datetime2;
    Declare @AllowLateSubmission Bit;
    Declare @MaxSubmissionAttempts Int;

    Select
        @CourseID = dbo.SIM_Lessons.CourseID,
        @AssignmentStartAt = dbo.SIM_Lessons.AssignmentStartAt,
        @DueAt = dbo.SIM_Lessons.DueAt,
        @AllowLateSubmission = dbo.SIM_Lessons.AllowLateSubmission,
        @MaxSubmissionAttempts = dbo.SIM_Lessons.MaxSubmissionAttempts
    From dbo.SIM_Lessons
    Where (dbo.SIM_Lessons.LessonID = @LessonID)
        And (dbo.SIM_Lessons.LessonType = 'ASSIGNMENT')
        And (dbo.SIM_Lessons.IsDeleted = 0);

    If @CourseID Is Null
        Throw 50002, N'Bài tập không tồn tại.', 1;

    If Not Exists
    (
        Select 1
        From dbo.LMS_Enrollments
        Where (dbo.LMS_Enrollments.CourseID = @CourseID)
            And (dbo.LMS_Enrollments.StudentUserID = @StudentUserID)
            And (dbo.LMS_Enrollments.Status <> 'CANCELLED')
    )
        Throw 50003, N'Học viên chưa được ghi danh vào môn học.', 1;

    If @AssignmentStartAt Is Not Null And Sysutcdatetime() < @AssignmentStartAt
        Throw 50006, N'Bài tập chưa đến thời gian mở.', 1;

    If @Action = 'SUBMIT' And @DueAt Is Not Null And Sysutcdatetime() > @DueAt And @AllowLateSubmission = 0
        Throw 50006, N'Bài tập đã hết hạn nộp.', 1;

    If Nullif(Ltrim(Rtrim(@SubmissionText)), N'') Is Null And @FileUrl Is Null
        Throw 50001, N'Cần nhập nội dung hoặc chọn file cho bài làm.', 1;

    Begin Transaction;

    Declare @AssignmentSubmissionID Bigint;
    Declare @AttemptNumber Int;

    Select Top (1)
        @AssignmentSubmissionID = dbo.LMS_AssignmentSubmissions.AssignmentSubmissionID,
        @AttemptNumber = dbo.LMS_AssignmentSubmissions.AttemptNumber
    From dbo.LMS_AssignmentSubmissions With (Updlock, Holdlock)
    Where (dbo.LMS_AssignmentSubmissions.LessonID = @LessonID)
        And (dbo.LMS_AssignmentSubmissions.StudentUserID = @StudentUserID)
        And (dbo.LMS_AssignmentSubmissions.SubmissionStatus = 'DRAFT')
    Order By dbo.LMS_AssignmentSubmissions.AttemptNumber Desc;

    If @AssignmentSubmissionID Is Null
    Begin
        Select
            @AttemptNumber = Coalesce(Max(dbo.LMS_AssignmentSubmissions.AttemptNumber), 0) + 1
        From dbo.LMS_AssignmentSubmissions With (Updlock, Holdlock)
        Where (dbo.LMS_AssignmentSubmissions.LessonID = @LessonID)
            And (dbo.LMS_AssignmentSubmissions.StudentUserID = @StudentUserID);

        If @AttemptNumber > @MaxSubmissionAttempts
            Throw 50006, N'Bạn đã sử dụng hết số lần nộp bài cho phép.', 1;

        Insert dbo.LMS_AssignmentSubmissions
        (
            LessonID,
            CourseID,
            StudentUserID,
            AttemptNumber,
            SubmissionText,
            FileUrl,
            OriginalFileName,
            StoredFileName,
            FileSize,
            MimeType,
            SubmittedAt,
            SubmissionStatus,
            IsLate
        )
        Values
            (@LessonID, @CourseID, @StudentUserID, @AttemptNumber, @SubmissionText, @FileUrl, @OriginalFileName, @StoredFileName, @FileSize, @MimeType, Sysutcdatetime(), Iif(@Action = 'SUBMIT', 'SUBMITTED', 'DRAFT'), Iif(@Action = 'SUBMIT' And @DueAt Is Not Null And Sysutcdatetime() > @DueAt, 1, 0));

        Set @AssignmentSubmissionID = Scope_identity();
    End;
    Else
    Begin
        Update dbo.LMS_AssignmentSubmissions
        Set
            SubmissionText = @SubmissionText,
            FileUrl = Coalesce(@FileUrl, FileUrl),
            OriginalFileName = Coalesce(@OriginalFileName, OriginalFileName),
            StoredFileName = Coalesce(@StoredFileName, StoredFileName),
            FileSize = Coalesce(@FileSize, FileSize),
            MimeType = Coalesce(@MimeType, MimeType),
            SubmittedAt = Sysutcdatetime(),
            SubmissionStatus = Iif(@Action = 'SUBMIT', 'SUBMITTED', 'DRAFT'),
            IsLate = Iif(@Action = 'SUBMIT' And @DueAt Is Not Null And Sysutcdatetime() > @DueAt, 1, 0)
        Where (dbo.LMS_AssignmentSubmissions.AssignmentSubmissionID = @AssignmentSubmissionID);
    End;

    If @FileUrl Is Not Null
        Insert dbo.LMS_AssignmentSubmissionFiles
        (
            AssignmentSubmissionID,
            OriginalFileName,
            StoredFileName,
            FileUrl,
            FileSize,
            MimeType
        )
        Values
            (@AssignmentSubmissionID, @OriginalFileName, @StoredFileName, @FileUrl, Coalesce(@FileSize, 0), Coalesce(@MimeType, N'application/octet-stream'));

    If @Action = 'SUBMIT'
    Begin
        Merge dbo.LMS_StudentLessonProgress As Target
        Using (Select @StudentUserID StudentUserID, @CourseID CourseID, @LessonID LessonID) As Source
            On Target.StudentUserID = Source.StudentUserID And Target.LessonID = Source.LessonID
        When Matched Then
            Update Set ProgressPercent = 100, Completed = 1, CompletedAt = Coalesce(Target.CompletedAt, Sysutcdatetime()), LastAccessAt = Sysutcdatetime(), UpdatedAt = Sysutcdatetime()
        When Not Matched Then
            Insert (StudentUserID, CourseID, LessonID, ProgressPercent, Score, AttemptCount, Completed, CompletedAt, LastAccessAt)
            Values (Source.StudentUserID, Source.CourseID, Source.LessonID, 100, 0, @AttemptNumber, 1, Sysutcdatetime(), Sysutcdatetime());
    End;

    Commit Transaction;

    Select
        @AssignmentSubmissionID AssignmentSubmissionID,
        @AttemptNumber AttemptNumber,
        Iif(@Action = 'SUBMIT', 'SUBMITTED', 'DRAFT') SubmissionStatus;
End
Go

Create Or Alter Procedure dbo.LMS_AssignmentSubmission_Validate
    @LessonID Bigint,
    @StudentUserID Bigint,
    @Action Varchar(20) = 'SUBMIT'
As
Begin
    Set Nocount On;

    Declare @CourseID Bigint;
    Declare @AssignmentStartAt Datetime2;
    Declare @DueAt Datetime2;
    Declare @AllowLateSubmission Bit;
    Declare @MaxSubmissionFileSizeMB Int;

    Select
        @CourseID = dbo.SIM_Lessons.CourseID,
        @AssignmentStartAt = dbo.SIM_Lessons.AssignmentStartAt,
        @DueAt = dbo.SIM_Lessons.DueAt,
        @AllowLateSubmission = dbo.SIM_Lessons.AllowLateSubmission,
        @MaxSubmissionFileSizeMB = dbo.SIM_Lessons.MaxSubmissionFileSizeMB
    From dbo.SIM_Lessons
    Where (dbo.SIM_Lessons.LessonID = @LessonID)
        And (dbo.SIM_Lessons.LessonType = 'ASSIGNMENT')
        And (dbo.SIM_Lessons.IsDeleted = 0);

    If @CourseID Is Null
        Throw 50002, N'Bài tập không tồn tại.', 1;

    If Not Exists (Select 1 From dbo.LMS_Enrollments Where CourseID = @CourseID And StudentUserID = @StudentUserID And Status <> 'CANCELLED')
        Throw 50003, N'Học viên chưa được ghi danh vào môn học.', 1;

    If @AssignmentStartAt Is Not Null And Sysutcdatetime() < @AssignmentStartAt
        Throw 50006, N'Bài tập chưa đến thời gian mở.', 1;

    If Upper(@Action) = 'SUBMIT' And @DueAt Is Not Null And Sysutcdatetime() > @DueAt And @AllowLateSubmission = 0
        Throw 50006, N'Bài tập đã hết hạn nộp.', 1;

    Select @MaxSubmissionFileSizeMB MaxSubmissionFileSizeMB;
End
Go

Create Or Alter Procedure dbo.LMS_AssignmentSubmission_Create
    @LessonID Bigint,
    @StudentUserID Bigint,
    @SubmissionText Nvarchar(Max) = Null,
    @FileUrl Nvarchar(1000) = Null,
    @OriginalFileName Nvarchar(500) = Null,
    @StoredFileName Nvarchar(500) = Null,
    @FileSize Bigint = Null,
    @MimeType Nvarchar(150) = Null
As
Begin
    Set Nocount On;

    Execute dbo.LMS_AssignmentSubmission_Save
        @LessonID = @LessonID,
        @StudentUserID = @StudentUserID,
        @SubmissionText = @SubmissionText,
        @FileUrl = @FileUrl,
        @OriginalFileName = @OriginalFileName,
        @StoredFileName = @StoredFileName,
        @FileSize = @FileSize,
        @MimeType = @MimeType,
        @Action = 'SUBMIT';
End
Go

Create Or Alter Procedure dbo.LMS_AssignmentSubmission_GetForTeacher
    @ActorID Bigint,
    @IsAdmin Bit = 0,
    @ClassSubjectID Bigint = Null,
    @Status Varchar(30) = Null,
    @Search Nvarchar(250) = Null
As
Begin
    Set Nocount On;

    Select
        dbo.LMS_AssignmentSubmissions.AssignmentSubmissionID,
        dbo.LMS_AssignmentSubmissions.AttemptNumber,
        dbo.LMS_AssignmentSubmissions.SubmissionText,
        dbo.LMS_AssignmentSubmissions.FileUrl,
        dbo.LMS_AssignmentSubmissions.OriginalFileName,
        dbo.LMS_AssignmentSubmissions.FileSize,
        dbo.LMS_AssignmentSubmissions.MimeType,
        dbo.LMS_AssignmentSubmissions.SubmittedAt,
        dbo.LMS_AssignmentSubmissions.SubmissionStatus,
        dbo.LMS_AssignmentSubmissions.Score,
        dbo.LMS_AssignmentSubmissions.Feedback,
        dbo.LMS_AssignmentSubmissions.GradedAt,
        dbo.LMS_AssignmentSubmissions.IsLate,
        dbo.SIM_Lessons.LessonID,
        dbo.SIM_Lessons.Title LessonTitle,
        dbo.SIM_Lessons.AssignmentMaxScore,
        dbo.SIM_Chapters.Title ChapterTitle,
        dbo.SIM_Courses.CourseID,
        dbo.SIM_Courses.ClassSubjectID,
        dbo.SIM_Courses.Title CourseTitle,
        dbo.SYS_Users.UserID StudentUserID,
        dbo.SYS_Users.StudentCode,
        dbo.SYS_Users.FullName StudentName,
        dbo.SIM_Class.ClassName,
        dbo.SIM_Subject.SubjectName,
        dbo.SIM_Year.YearName,
        dbo.SIM_Class_Subject.Semester
    From dbo.LMS_AssignmentSubmissions
        Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_AssignmentSubmissions.LessonID
        Inner Join dbo.SIM_Chapters On dbo.SIM_Chapters.ChapterID = dbo.SIM_Lessons.ChapterID
        Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.LMS_AssignmentSubmissions.CourseID
        Inner Join dbo.SYS_Users On dbo.SYS_Users.UserID = dbo.LMS_AssignmentSubmissions.StudentUserID
        Left Join dbo.SIM_Class_Subject On dbo.SIM_Class_Subject.DataGroupID = dbo.SIM_Courses.DataGroupID And dbo.SIM_Class_Subject.ClassSubjectID = dbo.SIM_Courses.ClassSubjectID
        Left Join dbo.SIM_Class On dbo.SIM_Class.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Class.ClassID = dbo.SIM_Class_Subject.ClassID
        Left Join dbo.SIM_Subject On dbo.SIM_Subject.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Subject.SubjectID = dbo.SIM_Class_Subject.SubjectID
        Left Join dbo.SIM_Year On dbo.SIM_Year.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Year.YearID = dbo.SIM_Class_Subject.YearID
    Where (@IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorID)
        And (@ClassSubjectID Is Null Or dbo.SIM_Courses.ClassSubjectID = @ClassSubjectID)
        And (@Status Is Null Or @Status = '' Or dbo.LMS_AssignmentSubmissions.SubmissionStatus = @Status)
        And (@Search Is Null Or @Search = '' Or dbo.SYS_Users.FullName Like N'%' + @Search + N'%' Or dbo.SYS_Users.StudentCode Like N'%' + @Search + N'%' Or dbo.SIM_Lessons.Title Like N'%' + @Search + N'%')
    Order By
        Case When dbo.LMS_AssignmentSubmissions.SubmissionStatus In ('SUBMITTED', 'LATE') Then 0 Else 1 End,
        dbo.LMS_AssignmentSubmissions.SubmittedAt Desc;
End
Go

Create Or Alter Procedure dbo.LMS_AssignmentSubmission_Grade
    @AssignmentSubmissionID Bigint,
    @Score Decimal(8, 2) = Null,
    @Feedback Nvarchar(Max) = Null,
    @Action Varchar(20),
    @ActorID Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    Set @Action = Upper(Ltrim(Rtrim(@Action)));

    If @Action Not In ('GRADE', 'RETURN')
        Throw 50001, N'Thao tác chấm bài không hợp lệ.', 1;

    Declare @LessonID Bigint;
    Declare @StudentUserID Bigint;
    Declare @CourseID Bigint;
    Declare @AssignmentMaxScore Decimal(8, 2);

    Select
        @LessonID = dbo.LMS_AssignmentSubmissions.LessonID,
        @StudentUserID = dbo.LMS_AssignmentSubmissions.StudentUserID,
        @CourseID = dbo.LMS_AssignmentSubmissions.CourseID,
        @AssignmentMaxScore = dbo.SIM_Lessons.AssignmentMaxScore
    From dbo.LMS_AssignmentSubmissions
        Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_AssignmentSubmissions.LessonID
        Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.LMS_AssignmentSubmissions.CourseID
    Where (dbo.LMS_AssignmentSubmissions.AssignmentSubmissionID = @AssignmentSubmissionID)
        And (@IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorID);

    If @LessonID Is Null
        Throw 50003, N'Không tìm thấy bài nộp hoặc bạn không có quyền chấm.', 1;

    If @Action = 'GRADE' And (@Score Is Null Or @Score < 0 Or @Score > @AssignmentMaxScore)
        Throw 50001, N'Điểm phải nằm trong khoảng từ 0 đến điểm tối đa của bài tập.', 1;

    Begin Transaction;

    Update dbo.LMS_AssignmentSubmissions
    Set
        Score = Iif(@Action = 'GRADE', @Score, Null),
        Feedback = @Feedback,
        SubmissionStatus = Iif(@Action = 'GRADE', 'GRADED', 'RETURNED'),
        GradedByUserID = @ActorID,
        GradedAt = Sysutcdatetime()
    Where (dbo.LMS_AssignmentSubmissions.AssignmentSubmissionID = @AssignmentSubmissionID);

    If @Action = 'GRADE'
        Update dbo.LMS_StudentLessonProgress
        Set
            Score = @Score,
            ProgressPercent = 100,
            Completed = 1,
            CompletedAt = Coalesce(CompletedAt, Sysutcdatetime()),
            UpdatedAt = Sysutcdatetime()
        Where (dbo.LMS_StudentLessonProgress.StudentUserID = @StudentUserID)
            And (dbo.LMS_StudentLessonProgress.LessonID = @LessonID);
    Else
        Update dbo.LMS_StudentLessonProgress
        Set
            Completed = 0,
            CompletedAt = Null,
            ProgressPercent = 80,
            UpdatedAt = Sysutcdatetime()
        Where (dbo.LMS_StudentLessonProgress.StudentUserID = @StudentUserID)
            And (dbo.LMS_StudentLessonProgress.LessonID = @LessonID);

    Commit Transaction;

    Select
        @AssignmentSubmissionID AssignmentSubmissionID,
        Iif(@Action = 'GRADE', 'GRADED', 'RETURNED') SubmissionStatus,
        Iif(@Action = 'GRADE', @Score, Null) Score;
End
Go

Create Or Alter Procedure dbo.LMS_StudySession_Start
    @StudentUserID Bigint,
    @CourseID Bigint = Null,
    @ChapterID Bigint = Null,
    @LessonID Bigint = Null,
    @PageUrl Nvarchar(1000) = Null,
    @ClientSessionKey Nvarchar(100) = Null
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    If @LessonID Is Not Null
        Select @CourseID = dbo.SIM_Lessons.CourseID, @ChapterID = dbo.SIM_Lessons.ChapterID From dbo.SIM_Lessons Where dbo.SIM_Lessons.LessonID = @LessonID And dbo.SIM_Lessons.IsDeleted = 0;
    Else If @ChapterID Is Not Null
        Select @CourseID = dbo.SIM_Chapters.CourseID From dbo.SIM_Chapters Where dbo.SIM_Chapters.ChapterID = @ChapterID And dbo.SIM_Chapters.IsDeleted = 0;

    If @CourseID Is Null Or Not Exists
    (
        Select 1
        From dbo.LMS_Enrollments
        Where (dbo.LMS_Enrollments.StudentUserID = @StudentUserID)
            And (dbo.LMS_Enrollments.CourseID = @CourseID)
            And (dbo.LMS_Enrollments.Status <> 'CANCELLED')
    )
        Throw 50003, N'Học viên chưa được ghi danh vào môn học này.', 1;

    Begin Transaction;

    Create Table #tblClosedStudySession
    (
        StudySessionID Uniqueidentifier Not Null,
        StudentUserID Bigint Not Null,
        CourseID Bigint Not Null,
        LessonID Bigint Null,
        ActiveDurationSeconds Int Not Null
    );

    Update dbo.LMS_StudySessions
    Set
        EndedAt = Sysutcdatetime(),
        ActiveDurationSeconds = ActiveDurationSeconds + Case When Datediff(Second, LastHeartbeatAt, Sysutcdatetime()) Between 1 And 45 Then Datediff(Second, LastHeartbeatAt, Sysutcdatetime()) Else 0 End
    Output
        Inserted.StudySessionID,
        Inserted.StudentUserID,
        Inserted.CourseID,
        Inserted.LessonID,
        Inserted.ActiveDurationSeconds
    Into #tblClosedStudySession
    Where (StudentUserID = @StudentUserID)
        And ((@LessonID Is Not Null And LessonID = @LessonID) Or (@LessonID Is Null And CourseID = @CourseID))
        And (EndedAt Is Null)
        And (IsAggregated = 0);

    Merge dbo.LMS_StudentLessonProgress As Target
    Using
    (
        Select
            StudentUserID,
            CourseID,
            LessonID,
            Sum(ActiveDurationSeconds) ActiveDurationSeconds
        From #tblClosedStudySession
        Where (LessonID Is Not Null)
        Group By
            StudentUserID,
            CourseID,
            LessonID
    ) As Source
        On Target.StudentUserID = Source.StudentUserID And Target.LessonID = Source.LessonID
    When Matched Then
        Update Set ActiveStudySeconds = Target.ActiveStudySeconds + Source.ActiveDurationSeconds, LastAccessAt = Sysutcdatetime(), UpdatedAt = Sysutcdatetime()
    When Not Matched Then
        Insert (StudentUserID, CourseID, LessonID, ProgressPercent, Score, AttemptCount, Completed, LastAccessAt, ActiveStudySeconds)
        Values (Source.StudentUserID, Source.CourseID, Source.LessonID, 0, 0, 0, 0, Sysutcdatetime(), Source.ActiveDurationSeconds);

    Update dbo.LMS_StudySessions
    Set IsAggregated = 1
    From dbo.LMS_StudySessions
        Inner Join #tblClosedStudySession On #tblClosedStudySession.StudySessionID = dbo.LMS_StudySessions.StudySessionID;

    Declare @StudySessionID Uniqueidentifier = Newid();
    Declare @ClassSubjectID Bigint = (Select ClassSubjectID From dbo.SIM_Courses Where CourseID = @CourseID);

    Insert dbo.LMS_StudySessions
    (
        StudySessionID,
        StudentUserID,
        ClassSubjectID,
        CourseID,
        ChapterID,
        LessonID,
        PageUrl,
        ClientSessionKey
    )
    Values
        (@StudySessionID, @StudentUserID, @ClassSubjectID, @CourseID, @ChapterID, @LessonID, @PageUrl, @ClientSessionKey);

    Commit Transaction;

    Select
        @StudySessionID StudySessionID,
        Sysutcdatetime() StartedAt;
End
Go

Create Or Alter Procedure dbo.LMS_StudySession_Heartbeat
    @StudySessionID Uniqueidentifier,
    @StudentUserID Bigint
As
Begin
    Set Nocount On;

    Update dbo.LMS_StudySessions
    Set
        ActiveDurationSeconds = ActiveDurationSeconds + Case When Datediff(Second, LastHeartbeatAt, Sysutcdatetime()) Between 1 And 45 Then Datediff(Second, LastHeartbeatAt, Sysutcdatetime()) Else 0 End,
        LastHeartbeatAt = Sysutcdatetime()
    Where (StudySessionID = @StudySessionID)
        And (StudentUserID = @StudentUserID)
        And (EndedAt Is Null);

    Select
        ActiveDurationSeconds,
        LastHeartbeatAt
    From dbo.LMS_StudySessions
    Where (StudySessionID = @StudySessionID)
        And (StudentUserID = @StudentUserID)
        And (EndedAt Is Null);
End
Go

Create Or Alter Procedure dbo.LMS_StudySession_End
    @StudySessionID Uniqueidentifier,
    @StudentUserID Bigint,
    @IsCompleted Bit = 0
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    Begin Transaction;

    Update dbo.LMS_StudySessions
    Set
        ActiveDurationSeconds = ActiveDurationSeconds + Case When Datediff(Second, LastHeartbeatAt, Sysutcdatetime()) Between 1 And 45 Then Datediff(Second, LastHeartbeatAt, Sysutcdatetime()) Else 0 End,
        LastHeartbeatAt = Sysutcdatetime(),
        EndedAt = Sysutcdatetime(),
        IsCompleted = @IsCompleted
    Where (StudySessionID = @StudySessionID)
        And (StudentUserID = @StudentUserID)
        And (EndedAt Is Null);

    Declare @CourseID Bigint;
    Declare @LessonID Bigint;
    Declare @ActiveDurationSeconds Int;

    Select
        @CourseID = CourseID,
        @LessonID = LessonID,
        @ActiveDurationSeconds = ActiveDurationSeconds
    From dbo.LMS_StudySessions With (Updlock, Holdlock)
    Where (StudySessionID = @StudySessionID)
        And (StudentUserID = @StudentUserID)
        And (IsAggregated = 0);

    If @LessonID Is Not Null
    Begin
        Merge dbo.LMS_StudentLessonProgress As Target
        Using (Select @StudentUserID StudentUserID, @CourseID CourseID, @LessonID LessonID) As Source
            On Target.StudentUserID = Source.StudentUserID And Target.LessonID = Source.LessonID
        When Matched Then
            Update Set ActiveStudySeconds = Target.ActiveStudySeconds + @ActiveDurationSeconds, LastAccessAt = Sysutcdatetime(), UpdatedAt = Sysutcdatetime(), Completed = Iif(@IsCompleted = 1, 1, Target.Completed), CompletedAt = Iif(@IsCompleted = 1, Coalesce(Target.CompletedAt, Sysutcdatetime()), Target.CompletedAt), ProgressPercent = Iif(@IsCompleted = 1, 100, Target.ProgressPercent)
        When Not Matched Then
            Insert (StudentUserID, CourseID, LessonID, ProgressPercent, Score, AttemptCount, Completed, CompletedAt, LastAccessAt, ActiveStudySeconds)
            Values (Source.StudentUserID, Source.CourseID, Source.LessonID, Iif(@IsCompleted = 1, 100, 0), 0, 0, @IsCompleted, Iif(@IsCompleted = 1, Sysutcdatetime(), Null), Sysutcdatetime(), @ActiveDurationSeconds);
    End;

    Update dbo.LMS_StudySessions
    Set IsAggregated = 1
    Where (StudySessionID = @StudySessionID)
        And (StudentUserID = @StudentUserID)
        And (IsAggregated = 0);

    Commit Transaction;

    Select
        ActiveDurationSeconds,
        EndedAt,
        IsCompleted
    From dbo.LMS_StudySessions
    Where (StudySessionID = @StudySessionID)
        And (StudentUserID = @StudentUserID);
End
Go
