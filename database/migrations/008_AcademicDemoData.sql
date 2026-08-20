Set Nocount On;
Set Xact_abort On;

If Not Exists (Select 1 From dbo.SIM_Year Where (DataGroupID = 1) And (YearID = 2025))
    Insert dbo.SIM_Year
    (
        DataGroupID,
        YearID,
        YearName,
        StartAt,
        FinishAt,
        IsActived
    )
    Values
        (1, 2025, N'2025-2026', '2025-08-01', '2026-07-31', 1);

If Not Exists (Select 1 From dbo.SIM_Science Where (DataGroupID = 1) And (ScienceID = N'CNTT'))
    Insert dbo.SIM_Science
    (
        DataGroupID,
        ScienceID,
        ScienceName,
        ScienceShortName,
        IsActived
    )
    Values
        (1, N'CNTT', N'Khoa Công nghệ thông tin', N'CNTT', 1);

If Not Exists (Select 1 From dbo.SIM_Course Where (DataGroupID = 1) And (CourseID = N'K18'))
    Insert dbo.SIM_Course
    (
        DataGroupID,
        CourseID,
        CourseName,
        StartYear,
        FinishYear,
        IsActived
    )
    Values
        (1, N'K18', N'Khóa 18', 2025, 2029, 1);

If Not Exists (Select 1 From dbo.SIM_Teacher Where (DataGroupID = 1) And (TeacherID = N'GV0001'))
    Insert dbo.SIM_Teacher
    (
        DataGroupID,
        TeacherID,
        UserID,
        TeacherFirstName,
        TeacherLastName,
        TeacherShortName,
        ScienceID,
        SubjectGroupID,
        Email,
        IsActived
    )
    Select Top (1)
        1,
        N'GV0001',
        dbo.SYS_Users.UserID,
        dbo.SYS_Users.FullName,
        N'',
        N'GV01',
        N'CNTT',
        N'CNPM',
        dbo.SYS_Users.Email,
        1
    From dbo.SYS_Users
    Where (dbo.SYS_Users.TeacherCode Is Not Null)
        And (dbo.SYS_Users.IsDeleted = 0)
    Order By dbo.SYS_Users.UserID;

If Not Exists (Select 1 From dbo.SIM_Class Where (DataGroupID = 1) And (ClassID = N'K18-CNTT-01'))
    Insert dbo.SIM_Class
    (
        DataGroupID,
        ClassID,
        ClassName,
        ClassShortName,
        ScienceID,
        CourseID,
        TrainingLevelID,
        TrainingType,
        ClassSize,
        StartAt,
        FinishAt,
        ManagerTeacherID,
        IsActived,
        Description
    )
    Values
        (1, N'K18-CNTT-01', N'Lớp Công nghệ thông tin K18 - 01', N'K18-CNTT-01', N'CNTT', N'K18', N'DAIHOC', N'CHINHQUY', 40, '2025-08-01', '2029-07-31', N'GV0001', 1, N'Lớp mẫu dùng kiểm thử luồng quản lý đào tạo và LMS.');

Declare @Subject Table
(
    SubjectID Nvarchar(50) Not Null,
    SubjectName Nvarchar(500) Not Null,
    SubjectShortName Nvarchar(100) Not Null,
    TheoryQuantity Int Not Null,
    PracticeQuantity Int Not Null,
    CreditCount Tinyint Not Null
);

Insert Into @Subject
(
    SubjectID,
    SubjectName,
    SubjectShortName,
    TheoryQuantity,
    PracticeQuantity,
    CreditCount
)
Values
    (N'WEB101', N'Phát triển ứng dụng Web', N'Lập trình Web', 30, 30, 3),
    (N'DATA201', N'Phân tích dữ liệu với Python', N'Phân tích dữ liệu', 30, 30, 3),
    (N'DB202', N'Cơ sở dữ liệu và SQL Server', N'Cơ sở dữ liệu', 30, 30, 3),
    (N'API301', N'Phát triển Web API', N'Web API', 30, 30, 3),
    (N'PM101', N'Quản lý dự án phần mềm', N'Quản lý dự án', 30, 15, 2);

Insert dbo.SIM_Subject
(
    DataGroupID,
    SubjectID,
    SubjectName,
    SubjectShortName,
    ScienceID,
    SubjectGroupID,
    TheoryQuantity,
    PracticeQuantity,
    TestQuantity,
    CreditCount,
    IsActived
)
Select
    1,
    Subject.SubjectID,
    Subject.SubjectName,
    Subject.SubjectShortName,
    N'CNTT',
    N'CNPM',
    Subject.TheoryQuantity,
    Subject.PracticeQuantity,
    2,
    Subject.CreditCount,
    1
From @Subject Subject
Where Not Exists
(
    Select 1
    From dbo.SIM_Subject
    Where (dbo.SIM_Subject.DataGroupID = 1)
        And (dbo.SIM_Subject.SubjectID = Subject.SubjectID)
);

Declare @ClassSubject Table
(
    ClassSubjectID Bigint Not Null,
    SubjectID Nvarchar(50) Not Null,
    OrderIndex Bigint Not Null
);

Insert Into @ClassSubject
(
    ClassSubjectID,
    SubjectID,
    OrderIndex
)
Values
    (2025001, N'WEB101', 1),
    (2025002, N'DATA201', 2),
    (2025003, N'DB202', 3),
    (2025004, N'API301', 4),
    (2025005, N'PM101', 5);

Insert dbo.SIM_Class_Subject
(
    DataGroupID,
    ClassSubjectID,
    Semester,
    YearID,
    ClassID,
    SubjectID,
    TeacherID,
    TheoryQuantity,
    PracticeQuantity,
    TestQuantity,
    CreditCount,
    ClassSubjectStatus,
    OrderIndex,
    IsLocked,
    CreatedDate,
    CreatedUser
)
Select
    1,
    ClassSubject.ClassSubjectID,
    1,
    2025,
    N'K18-CNTT-01',
    ClassSubject.SubjectID,
    N'GV0001',
    Subject.TheoryQuantity,
    Subject.PracticeQuantity,
    Subject.TestQuantity,
    Subject.CreditCount,
    1,
    ClassSubject.OrderIndex,
    0,
    Sysutcdatetime(),
    N'SYSTEM'
From @ClassSubject ClassSubject
    Inner Join dbo.SIM_Subject Subject On Subject.DataGroupID = 1
        And Subject.SubjectID = ClassSubject.SubjectID
Where Not Exists
(
    Select 1
    From dbo.SIM_Class_Subject
    Where (dbo.SIM_Class_Subject.DataGroupID = 1)
        And (dbo.SIM_Class_Subject.ClassSubjectID = ClassSubject.ClassSubjectID)
);

Insert dbo.SIM_Student
(
    DataGroupID,
    StudentID,
    UserID,
    ClassID,
    StudentFirstName,
    StudentLastName,
    FullName,
    Email,
    Mobile,
    IsActived
)
Select
    1,
    Coalesce(dbo.SYS_Users.StudentCode, N'HV' + Right(N'0000' + Convert(Nvarchar(10), dbo.SYS_Users.UserID), 4)),
    dbo.SYS_Users.UserID,
    N'K18-CNTT-01',
    dbo.SYS_Users.FullName,
    N'',
    dbo.SYS_Users.FullName,
    dbo.SYS_Users.Email,
    Null,
    Convert(Bit, Case When dbo.SYS_Users.Status = 'ACTIVE' Then 1 Else 0 End)
From dbo.SYS_Users
Where (dbo.SYS_Users.StudentCode Is Not Null)
    And (dbo.SYS_Users.IsDeleted = 0)
    And Not Exists
    (
        Select 1
        From dbo.SIM_Student
        Where (dbo.SIM_Student.DataGroupID = 1)
            And (dbo.SIM_Student.UserID = dbo.SYS_Users.UserID)
    );

Update dbo.SYS_Users
Set
    StudentID = dbo.SIM_Student.StudentID,
    DataGroupID = dbo.SIM_Student.DataGroupID
From dbo.SYS_Users
    Inner Join dbo.SIM_Student On dbo.SIM_Student.UserID = dbo.SYS_Users.UserID;

Update dbo.SYS_Users
Set
    TeacherID = dbo.SIM_Teacher.TeacherID,
    DataGroupID = dbo.SIM_Teacher.DataGroupID
From dbo.SYS_Users
    Inner Join dbo.SIM_Teacher On dbo.SIM_Teacher.UserID = dbo.SYS_Users.UserID;

If Not Exists (Select 1 From dbo.SYS_PermissionCategory Where PermissionCategoryID = 1)
    Insert dbo.SYS_PermissionCategory
    (
        PermissionCategoryID,
        PermissionCategoryName,
        IsDefault,
        IsActived,
        SortOrder
    )
    Values
        (1, N'Quản trị hệ thống', 1, 1, 1);

If Not Exists (Select 1 From dbo.SYS_PermissionCategory Where PermissionCategoryID = 2)
    Insert dbo.SYS_PermissionCategory
    (
        PermissionCategoryID,
        PermissionCategoryName,
        IsDefault,
        IsActived,
        SortOrder
    )
    Values
        (2, N'Đào tạo và học tập', 0, 1, 2);

Declare @PermissionGroup Table
(
    PermissionGroupID Nvarchar(50) Not Null,
    PermissionGroupName Nvarchar(100) Not Null,
    PermissionCategoryID Int Not Null,
    SortOrder Int Not Null
);

Insert Into @PermissionGroup
(
    PermissionGroupID,
    PermissionGroupName,
    PermissionCategoryID,
    SortOrder
)
Values
    (N'SYSTEM', N'Hệ thống và tài khoản', 1, 1),
    (N'ACADEMIC', N'Cơ cấu đào tạo', 2, 1),
    (N'CONTENT', N'Nội dung và học liệu', 2, 2),
    (N'LEARNING', N'Quá trình học tập', 2, 3),
    (N'REPORT', N'Báo cáo và thống kê', 2, 4);

Insert dbo.SYS_PermissionGroup
(
    PermissionGroupID,
    PermissionGroupName,
    PermissionCategoryID,
    SortOrder,
    IsActived
)
Select
    PermissionGroup.PermissionGroupID,
    PermissionGroup.PermissionGroupName,
    PermissionGroup.PermissionCategoryID,
    PermissionGroup.SortOrder,
    1
From @PermissionGroup PermissionGroup
Where Not Exists
(
    Select 1
    From dbo.SYS_PermissionGroup
    Where (dbo.SYS_PermissionGroup.PermissionGroupID = PermissionGroup.PermissionGroupID)
);

Update dbo.SYS_Permissions
Set
    PermissionCategoryID = Case When Module In ('USER', 'ROLE', 'SETTING') Then 1 Else 2 End,
    PermissionGroupID = Case
        When Module In ('USER', 'ROLE', 'SETTING') Then N'SYSTEM'
        When Module In ('COURSE', 'CHAPTER', 'LESSON', 'VIDEO', 'QUESTION') Then N'CONTENT'
        When Module In ('STUDENT', 'ENROLLMENT') Then N'ACADEMIC'
        When Module In ('REPORT', 'DASHBOARD') Then N'REPORT'
        Else N'LEARNING'
    End
Where (PermissionCategoryID Is Null)
    Or (PermissionGroupID Is Null);

;With OnlineCourse As
(
    Select
        dbo.SIM_Courses.CourseID,
        Row_number() Over (Order By dbo.SIM_Courses.CourseID) RowNumber
    From dbo.SIM_Courses
    Where (dbo.SIM_Courses.IsDeleted = 0)
        And (dbo.SIM_Courses.ClassSubjectID Is Null)
),
ClassSubject As
(
    Select
        dbo.SIM_Class_Subject.ClassSubjectID,
        Row_number() Over (Order By dbo.SIM_Class_Subject.OrderIndex, dbo.SIM_Class_Subject.ClassSubjectID) RowNumber
    From dbo.SIM_Class_Subject
    Where (dbo.SIM_Class_Subject.DataGroupID = 1)
        And Not Exists
        (
            Select 1
            From dbo.SIM_Courses
            Where (dbo.SIM_Courses.DataGroupID = dbo.SIM_Class_Subject.DataGroupID)
                And (dbo.SIM_Courses.ClassSubjectID = dbo.SIM_Class_Subject.ClassSubjectID)
                And (dbo.SIM_Courses.IsDeleted = 0)
        )
)
Update dbo.SIM_Courses
Set
    DataGroupID = 1,
    ClassSubjectID = ClassSubject.ClassSubjectID
From dbo.SIM_Courses
    Inner Join OnlineCourse On OnlineCourse.CourseID = dbo.SIM_Courses.CourseID
    Inner Join ClassSubject On ClassSubject.RowNumber = OnlineCourse.RowNumber;

Declare @Timetable Table
(
    ClassSubjectID Bigint Not Null,
    DayOfWeek Tinyint Not Null,
    StartPeriod Tinyint Not Null,
    EndPeriod Tinyint Not Null,
    StartTime Time(0) Not Null,
    EndTime Time(0) Not Null,
    RoomName Nvarchar(100) Not Null
);

Insert Into @Timetable
(
    ClassSubjectID,
    DayOfWeek,
    StartPeriod,
    EndPeriod,
    StartTime,
    EndTime,
    RoomName
)
Values
    (2025001, 2, 1, 3, '07:00', '09:30', N'A.201'),
    (2025002, 3, 4, 6, '09:45', '12:15', N'LAB.02'),
    (2025003, 4, 1, 3, '07:00', '09:30', N'LAB.01'),
    (2025004, 5, 7, 9, '13:00', '15:30', N'LAB.03'),
    (2025005, 6, 4, 5, '09:45', '11:25', N'B.305');

Insert dbo.SIM_Timetable
(
    DataGroupID,
    ClassSubjectID,
    DayOfWeek,
    StartPeriod,
    EndPeriod,
    StartTime,
    EndTime,
    RoomName,
    EffectiveFrom,
    EffectiveTo,
    TimetableStatus
)
Select
    1,
    Timetable.ClassSubjectID,
    Timetable.DayOfWeek,
    Timetable.StartPeriod,
    Timetable.EndPeriod,
    Timetable.StartTime,
    Timetable.EndTime,
    Timetable.RoomName,
    Convert(Date, '2025-08-01'),
    Convert(Date, '2026-01-31'),
    1
From @Timetable Timetable
Where Not Exists
(
    Select 1
    From dbo.SIM_Timetable
    Where (dbo.SIM_Timetable.DataGroupID = 1)
        And (dbo.SIM_Timetable.ClassSubjectID = Timetable.ClassSubjectID)
        And (dbo.SIM_Timetable.DayOfWeek = Timetable.DayOfWeek)
        And (dbo.SIM_Timetable.StartTime = Timetable.StartTime)
        And (dbo.SIM_Timetable.TimetableStatus = 1)
);

Declare @DemoOnlineCourseID Bigint;
Declare @DemoChapterID Bigint;

Select Top (1)
    @DemoOnlineCourseID = dbo.SIM_Courses.CourseID
From dbo.SIM_Courses
Where (dbo.SIM_Courses.ClassSubjectID Is Not Null)
    And (dbo.SIM_Courses.IsDeleted = 0)
Order By dbo.SIM_Courses.CourseID;

If @DemoOnlineCourseID Is Not Null
Begin
    Select
        @DemoChapterID = dbo.SIM_Chapters.ChapterID
    From dbo.SIM_Chapters
    Where (dbo.SIM_Chapters.CourseID = @DemoOnlineCourseID)
        And (dbo.SIM_Chapters.Title = N'Học liệu và bài tập')
        And (dbo.SIM_Chapters.IsDeleted = 0);

    If @DemoChapterID Is Null
    Begin
        Insert dbo.SIM_Chapters
        (
            CourseID,
            Title,
            Description,
            SortOrder,
            Status,
            IsDeleted
        )
        Values
            (@DemoOnlineCourseID, N'Học liệu và bài tập', N'Dữ liệu mẫu cho bài soạn thảo, tài liệu và bài tập nộp file.', 99, 'ACTIVE', 0);

        Set @DemoChapterID = Scope_identity();
    End;

    If Not Exists (Select 1 From dbo.SIM_Lessons Where CourseID = @DemoOnlineCourseID And ChapterID = @DemoChapterID And Title = N'Bài đọc: Quy trình học trực tuyến' And IsDeleted = 0)
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
            Status,
            IsDeleted
        )
        Values
            (@DemoOnlineCourseID, @DemoChapterID, N'Bài đọc: Quy trình học trực tuyến', N'Nội dung được soạn trực tiếp bằng trình biên tập.', 'EDITOR', 600, 1, 1, 0, N'<h2>Mục tiêu bài học</h2><p>Đọc nội dung, ghi chú các ý chính và hoàn thành bài tập ở cuối chương.</p><ul><li>Hiểu luồng học theo môn và chương.</li><li>Biết cách nộp bài trên hệ thống.</li></ul>', 'ACTIVE', 0);

    If Not Exists (Select 1 From dbo.SIM_Lessons Where CourseID = @DemoOnlineCourseID And ChapterID = @DemoChapterID And Title = N'Tài liệu tham khảo môn học' And IsDeleted = 0)
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
            IsDeleted
        )
        Values
            (@DemoOnlineCourseID, @DemoChapterID, N'Tài liệu tham khảo môn học', N'Giảng viên có thể tải PDF, Word hoặc tài liệu học tập vào bài này.', 'DOCUMENT', 900, 2, 1, 0, 'ACTIVE', 0);

    If Not Exists (Select 1 From dbo.SIM_Lessons Where CourseID = @DemoOnlineCourseID And ChapterID = @DemoChapterID And Title = N'Bài tập thực hành số 01' And IsDeleted = 0)
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
            AssignmentFolderName,
            DueAt,
            MaxSubmissionFileSizeMB,
            AllowLateSubmission,
            Status,
            IsDeleted
        )
        Values
            (@DemoOnlineCourseID, @DemoChapterID, N'Bài tập thực hành số 01', N'Hoàn thành yêu cầu và nộp file bài làm.', 'ASSIGNMENT', 1800, 3, 1, 5, N'<h2>Yêu cầu</h2><p>Chuẩn bị báo cáo ngắn, lưu dưới dạng PDF hoặc DOCX và nộp trực tiếp trên hệ thống.</p>', N'Bai-tap-thuc-hanh-01', '2026-01-31T23:59:59', 50, 1, 'ACTIVE', 0);

    Declare @DemoAssignmentLessonID Bigint;
    Declare @DemoStudentUserID Bigint;

    Select
        @DemoAssignmentLessonID = dbo.SIM_Lessons.LessonID
    From dbo.SIM_Lessons
    Where (dbo.SIM_Lessons.CourseID = @DemoOnlineCourseID)
        And (dbo.SIM_Lessons.ChapterID = @DemoChapterID)
        And (dbo.SIM_Lessons.Title = N'Bài tập thực hành số 01')
        And (dbo.SIM_Lessons.IsDeleted = 0);

    Select Top (1)
        @DemoStudentUserID = dbo.SIM_Student.UserID
    From dbo.SIM_Student
    Where (dbo.SIM_Student.UserID Is Not Null)
        And (dbo.SIM_Student.IsActived = 1)
    Order By dbo.SIM_Student.StudentID;

    If @DemoAssignmentLessonID Is Not Null
        And @DemoStudentUserID Is Not Null
        And Not Exists
        (
            Select 1
            From dbo.LMS_AssignmentSubmissions
            Where (dbo.LMS_AssignmentSubmissions.LessonID = @DemoAssignmentLessonID)
                And (dbo.LMS_AssignmentSubmissions.StudentUserID = @DemoStudentUserID)
        )
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
            (@DemoAssignmentLessonID, @DemoOnlineCourseID, @DemoStudentUserID, 1, N'Bài nộp mẫu: học viên đã hoàn thành nội dung thực hành và gửi báo cáo.', Sysutcdatetime(), 'SUBMITTED', 1);

    Declare @SharedDemoVideoAssetID Bigint;
    Declare @SharedDemoVideoID Bigint;
    Declare @SharedDemoVideoVersionID Bigint;
    Declare @SharedDemoTeacherUserID Bigint;

    Select Top (1)
        @SharedDemoTeacherUserID = dbo.SIM_Teacher.UserID
    From dbo.SIM_Teacher
    Where (dbo.SIM_Teacher.UserID Is Not Null)
        And (dbo.SIM_Teacher.IsActived = 1)
    Order By dbo.SIM_Teacher.TeacherID;

    Select
        @SharedDemoVideoAssetID = dbo.SIM_VideoAssets.VideoAssetID
    From dbo.SIM_VideoAssets
    Where (dbo.SIM_VideoAssets.Title = N'Video mẫu đồng bộ chưa chấm')
        And (dbo.SIM_VideoAssets.IsDeleted = 0);

    If @SharedDemoVideoAssetID Is Null And @SharedDemoTeacherUserID Is Not Null
    Begin
        Insert dbo.SIM_VideoAssets
        (
            Title,
            SourceType,
            VideoUrl,
            DurationSeconds,
            OriginalFileName,
            MimeType,
            CreatedByUserID,
            ShareScope,
            Status,
            IsDeleted
        )
        Values
            (N'Video mẫu đồng bộ chưa chấm', 'LOCAL', N'/Media/Video/demo/z3.mp4', 180, N'z3.mp4', N'video/mp4', @SharedDemoTeacherUserID, 'PRIVATE', 'ACTIVE', 0);

        Set @SharedDemoVideoAssetID = Scope_identity();
    End;

    Select
        @SharedDemoVideoID = dbo.SIM_Videos.VideoID
    From dbo.SIM_Videos
    Where (dbo.SIM_Videos.VideoAssetID = @SharedDemoVideoAssetID);

    If @SharedDemoVideoID Is Null And @SharedDemoVideoAssetID Is Not Null
    Begin
        Insert dbo.SIM_Videos
        (
            VideoAssetID,
            Title,
            SourceType,
            VideoUrl,
            DurationSeconds,
            AllowSeek,
            AllowSpeed,
            RequiredWatchPercent,
            Status
        )
        Values
            (@SharedDemoVideoAssetID, N'Video mẫu đồng bộ chưa chấm', 'LOCAL', N'/Media/Video/demo/z3.mp4', 180, 0, 1, 80, 'ACTIVE');

        Set @SharedDemoVideoID = Scope_identity();
    End;

    Select
        @SharedDemoVideoVersionID = dbo.SIM_VideoVersions.VideoVersionID
    From dbo.SIM_VideoVersions
    Where (dbo.SIM_VideoVersions.VideoID = @SharedDemoVideoID)
        And (dbo.SIM_VideoVersions.VersionNumber = 1);

    If @SharedDemoVideoVersionID Is Null And @SharedDemoVideoID Is Not Null
    Begin
        Insert dbo.SIM_VideoVersions
        (
            VideoID,
            VersionNumber,
            Title,
            SourceType,
            VideoUrl,
            DurationSeconds,
            AllowSeek,
            AllowSpeed,
            RequiredWatchPercent,
            OriginalFileName,
            MimeType,
            ChangeSummary,
            VersionStatus,
            CreatedByUserID,
            PublishedByUserID,
            PublishedAt
        )
        Values
            (@SharedDemoVideoID, 1, N'Video mẫu đồng bộ chưa chấm', 'LOCAL', N'/Media/Video/demo/z3.mp4', 180, 0, 1, 80, N'z3.mp4', N'video/mp4', N'Dữ liệu mẫu để kiểm tra sửa đồng bộ nhiều bài học trước khi có điểm.', 'PUBLISHED', @SharedDemoTeacherUserID, @SharedDemoTeacherUserID, Sysutcdatetime());

        Set @SharedDemoVideoVersionID = Scope_identity();
    End;

    Update dbo.SIM_Videos
    Set
        CurrentVideoVersionID = @SharedDemoVideoVersionID
    Where (dbo.SIM_Videos.VideoID = @SharedDemoVideoID)
        And (dbo.SIM_Videos.CurrentVideoVersionID Is Null);

    If @SharedDemoVideoID Is Not Null And @SharedDemoVideoVersionID Is Not Null
    Begin
        If Not Exists (Select 1 From dbo.SIM_Lessons Where CourseID = @DemoOnlineCourseID And ChapterID = @DemoChapterID And Title = N'Video dùng chung mẫu A' And IsDeleted = 0)
            Insert dbo.SIM_Lessons
            (
                CourseID,
                ChapterID,
                VideoID,
                VideoVersionID,
                Title,
                Description,
                LessonType,
                DurationSeconds,
                SortOrder,
                IsRequired,
                PassingScore,
                Status,
                IsDeleted
            )
            Values
                (@DemoOnlineCourseID, @DemoChapterID, @SharedDemoVideoID, @SharedDemoVideoVersionID, N'Video dùng chung mẫu A', N'Bài mẫu thứ nhất tham chiếu cùng một video chưa có điểm.', 'VIDEO', 180, 10, 0, 0, 'ACTIVE', 0);

        If Not Exists (Select 1 From dbo.SIM_Lessons Where CourseID = @DemoOnlineCourseID And ChapterID = @DemoChapterID And Title = N'Video dùng chung mẫu B' And IsDeleted = 0)
            Insert dbo.SIM_Lessons
            (
                CourseID,
                ChapterID,
                VideoID,
                VideoVersionID,
                Title,
                Description,
                LessonType,
                DurationSeconds,
                SortOrder,
                IsRequired,
                PassingScore,
                Status,
                IsDeleted
            )
            Values
                (@DemoOnlineCourseID, @DemoChapterID, @SharedDemoVideoID, @SharedDemoVideoVersionID, N'Video dùng chung mẫu B', N'Bài mẫu thứ hai tham chiếu cùng một video chưa có điểm.', 'VIDEO', 180, 11, 0, 0, 'ACTIVE', 0);
    End;
End;
Go
