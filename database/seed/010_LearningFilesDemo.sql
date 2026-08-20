Set Nocount On;
Set Xact_abort On;
Set Ansi_nulls On;
Set Quoted_identifier On;

Begin Transaction;

Declare @CourseID Bigint;
Declare @ChapterID Bigint;
Declare @StudentUserID Bigint;
Declare @DocumentLessonID Bigint;
Declare @AssignmentLessonID Bigint;

Select Top 1
    @CourseID = dbo.SIM_Courses.CourseID
From dbo.SIM_Courses
    Inner Join dbo.LMS_Enrollments On dbo.LMS_Enrollments.CourseID = dbo.SIM_Courses.CourseID
Where (dbo.SIM_Courses.Status = 'PUBLISHED')
    And (dbo.SIM_Courses.IsDeleted = 0)
    And (dbo.LMS_Enrollments.Status <> 'CANCELLED')
Order By dbo.SIM_Courses.CourseID;

Select Top 1
    @ChapterID = dbo.SIM_Chapters.ChapterID
From dbo.SIM_Chapters
Where (dbo.SIM_Chapters.CourseID = @CourseID)
    And (dbo.SIM_Chapters.Title = N'Học liệu và bài tập')
    And (dbo.SIM_Chapters.IsDeleted = 0)
Order By dbo.SIM_Chapters.SortOrder,
    dbo.SIM_Chapters.ChapterID;

If @ChapterID Is Null
Begin
    Select Top 1
        @ChapterID = dbo.SIM_Chapters.ChapterID
    From dbo.SIM_Chapters
    Where (dbo.SIM_Chapters.CourseID = @CourseID)
        And (dbo.SIM_Chapters.IsDeleted = 0)
    Order By dbo.SIM_Chapters.SortOrder,
        dbo.SIM_Chapters.ChapterID;
End;

If @CourseID Is Null Or @ChapterID Is Null
    Throw 51000, N'Không tìm thấy khóa học đã xuất bản và chương hợp lệ để tạo dữ liệu file mẫu.', 1;

If Exists
(
    Select 1
    From dbo.SIM_Lessons
    Where (dbo.SIM_Lessons.CourseID = @CourseID)
        And (dbo.SIM_Lessons.ChapterID = @ChapterID)
        And (dbo.SIM_Lessons.Title = N'Tài liệu tham khảo môn học')
        And (dbo.SIM_Lessons.IsDeleted = 0)
)
Begin
    Update dbo.SIM_Lessons
    Set
        LessonType = 'DOCUMENT',
        Description = N'Đọc trực tiếp file PDF kế hoạch học tập trên hệ thống.',
        DocumentUrl = N'/Media/File/Lessons/Demo/51T.XD1_MC_QP_102251_KeHoach.pdf',
        Status = 'ACTIVE',
        UpdatedAt = Sysutcdatetime()
    Where (dbo.SIM_Lessons.CourseID = @CourseID)
        And (dbo.SIM_Lessons.ChapterID = @ChapterID)
        And (dbo.SIM_Lessons.Title = N'Tài liệu tham khảo môn học')
        And (dbo.SIM_Lessons.IsDeleted = 0);
End
Else
Begin
    Insert dbo.SIM_Lessons
    (
        CourseID,
        ChapterID,
        Title,
        Description,
        LessonType,
        DurationSeconds,
        SortOrder,
        IsRequired,
        PassingScore,
        Status,
        IsDeleted,
        DocumentUrl
    )
    Values
    (
        @CourseID,
        @ChapterID,
        N'Tài liệu tham khảo môn học',
        N'Đọc trực tiếp file PDF kế hoạch học tập trên hệ thống.',
        'DOCUMENT',
        900,
        20,
        1,
        0,
        'ACTIVE',
        0,
        N'/Media/File/Lessons/Demo/51T.XD1_MC_QP_102251_KeHoach.pdf'
    );
End;

Select Top 1
    @DocumentLessonID = dbo.SIM_Lessons.LessonID
From dbo.SIM_Lessons
Where (dbo.SIM_Lessons.CourseID = @CourseID)
    And (dbo.SIM_Lessons.ChapterID = @ChapterID)
    And (dbo.SIM_Lessons.Title = N'Tài liệu tham khảo môn học')
    And (dbo.SIM_Lessons.IsDeleted = 0)
Order By dbo.SIM_Lessons.LessonID;

If Not Exists
(
    Select 1
    From dbo.SIM_Lessons
    Where (dbo.SIM_Lessons.CourseID = @CourseID)
        And (dbo.SIM_Lessons.ChapterID = @ChapterID)
        And (dbo.SIM_Lessons.Title = N'Tài liệu biểu mẫu học kỳ')
        And (dbo.SIM_Lessons.IsDeleted = 0)
)
Begin
    Insert dbo.SIM_Lessons
    (
        CourseID,
        ChapterID,
        Title,
        Description,
        LessonType,
        DurationSeconds,
        SortOrder,
        IsRequired,
        PassingScore,
        Status,
        IsDeleted,
        DocumentUrl
    )
    Values
    (
        @CourseID,
        @ChapterID,
        N'Tài liệu biểu mẫu học kỳ',
        N'Tài liệu PDF mẫu dùng để kiểm tra chế độ đọc trực tiếp và tải xuống.',
        'DOCUMENT',
        600,
        21,
        0,
        0,
        'ACTIVE',
        0,
        N'/Media/File/Lessons/Demo/mau_hk.pdf'
    );
End
Else
Begin
    Update dbo.SIM_Lessons
    Set
        DocumentUrl = N'/Media/File/Lessons/Demo/mau_hk.pdf',
        Status = 'ACTIVE',
        UpdatedAt = Sysutcdatetime()
    Where (dbo.SIM_Lessons.CourseID = @CourseID)
        And (dbo.SIM_Lessons.ChapterID = @ChapterID)
        And (dbo.SIM_Lessons.Title = N'Tài liệu biểu mẫu học kỳ')
        And (dbo.SIM_Lessons.IsDeleted = 0);
End;

If Exists
(
    Select 1
    From dbo.SIM_Lessons
    Where (dbo.SIM_Lessons.CourseID = @CourseID)
        And (dbo.SIM_Lessons.ChapterID = @ChapterID)
        And (dbo.SIM_Lessons.Title = N'Bài tập mở đầu')
        And (dbo.SIM_Lessons.IsDeleted = 0)
)
Begin
    Update dbo.SIM_Lessons
    Set
        LessonType = 'ASSIGNMENT',
        Description = N'Tải đề PDF, sau đó nộp bằng file hoặc soạn bài trực tuyến.',
        ContentHtml = N'<h2>Yêu cầu bài tập</h2><p>Đọc tài liệu đính kèm và trình bày nội dung theo biểu mẫu. Học viên có thể tải file bài làm hoặc soạn trực tiếp trên hệ thống.</p>',
        DocumentUrl = N'/Media/File/Lessons/Demo/STGV.pdf',
        AssignmentFolderName = N'Bai-tap-bieu-mau-STGV',
        AssignmentStartAt = Dateadd(Day, -1, Sysutcdatetime()),
        DueAt = Dateadd(Day, 30, Sysutcdatetime()),
        AssignmentMaxScore = 100,
        MaxSubmissionAttempts = 3,
        MaxSubmissionFileSizeMB = 50,
        AllowLateSubmission = 1,
        Status = 'ACTIVE',
        UpdatedAt = Sysutcdatetime()
    Where (dbo.SIM_Lessons.CourseID = @CourseID)
        And (dbo.SIM_Lessons.ChapterID = @ChapterID)
        And (dbo.SIM_Lessons.Title = N'Bài tập mở đầu')
        And (dbo.SIM_Lessons.IsDeleted = 0);
End
Else
Begin
    Insert dbo.SIM_Lessons
    (
        CourseID,
        ChapterID,
        Title,
        Description,
        LessonType,
        DurationSeconds,
        SortOrder,
        IsRequired,
        PassingScore,
        ContentHtml,
        DocumentUrl,
        AssignmentFolderName,
        AssignmentStartAt,
        DueAt,
        AssignmentMaxScore,
        MaxSubmissionAttempts,
        MaxSubmissionFileSizeMB,
        AllowLateSubmission,
        Status,
        IsDeleted
    )
    Values
    (
        @CourseID,
        @ChapterID,
        N'Bài tập mở đầu',
        N'Tải đề PDF, sau đó nộp bằng file hoặc soạn bài trực tuyến.',
        'ASSIGNMENT',
        900,
        22,
        1,
        50,
        N'<h2>Yêu cầu bài tập</h2><p>Đọc tài liệu đính kèm và trình bày nội dung theo biểu mẫu. Học viên có thể tải file bài làm hoặc soạn trực tiếp trên hệ thống.</p>',
        N'/Media/File/Lessons/Demo/STGV.pdf',
        N'Bai-tap-bieu-mau-STGV',
        Dateadd(Day, -1, Sysutcdatetime()),
        Dateadd(Day, 30, Sysutcdatetime()),
        100,
        3,
        50,
        1,
        'ACTIVE',
        0
    );
End;

Select Top 1
    @AssignmentLessonID = dbo.SIM_Lessons.LessonID
From dbo.SIM_Lessons
Where (dbo.SIM_Lessons.CourseID = @CourseID)
    And (dbo.SIM_Lessons.ChapterID = @ChapterID)
    And (dbo.SIM_Lessons.Title = N'Bài tập mở đầu')
    And (dbo.SIM_Lessons.IsDeleted = 0)
Order By dbo.SIM_Lessons.LessonID;

Select Top 1
    @StudentUserID = dbo.LMS_Enrollments.StudentUserID
From dbo.LMS_Enrollments
    Inner Join dbo.SYS_Users On dbo.SYS_Users.UserID = dbo.LMS_Enrollments.StudentUserID
Where (dbo.LMS_Enrollments.CourseID = @CourseID)
    And (dbo.LMS_Enrollments.Status <> 'CANCELLED')
Order By Case When dbo.SYS_Users.Username = N'student' Then 0 Else 1 End,
    dbo.LMS_Enrollments.StudentUserID;

If @StudentUserID Is Not Null
    And Not Exists
    (
        Select 1
        From dbo.LMS_AssignmentSubmissions
        Where (dbo.LMS_AssignmentSubmissions.LessonID = @AssignmentLessonID)
            And (dbo.LMS_AssignmentSubmissions.StudentUserID = @StudentUserID)
    )
Begin
    Insert dbo.LMS_AssignmentSubmissions
    (
        LessonID,
        CourseID,
        StudentUserID,
        AttemptNumber,
        SubmissionText,
        SubmittedAt,
        SubmissionStatus,
        IsLate
    )
    Values
    (
        @AssignmentLessonID,
        @CourseID,
        @StudentUserID,
        1,
        N'Bản nháp mẫu: học viên đang soạn nội dung trực tuyến và có thể tiếp tục hoàn thiện trước khi nộp.',
        Sysutcdatetime(),
        'DRAFT',
        0
    );
End;

Commit Transaction;

Select
    dbo.SIM_Lessons.LessonID,
    dbo.SIM_Lessons.Title,
    dbo.SIM_Lessons.LessonType,
    dbo.SIM_Lessons.DocumentUrl
From dbo.SIM_Lessons
Where (dbo.SIM_Lessons.LessonID In (@DocumentLessonID, @AssignmentLessonID))
    Or
    (
        (dbo.SIM_Lessons.CourseID = @CourseID)
        And (dbo.SIM_Lessons.ChapterID = @ChapterID)
        And (dbo.SIM_Lessons.Title = N'Tài liệu biểu mẫu học kỳ')
    )
Order By dbo.SIM_Lessons.SortOrder,
    dbo.SIM_Lessons.LessonID;
Go
